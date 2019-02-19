#!/usr/bin/env bash

msg() { echo -e "\e[32mINFO [$(date +%F\ %T)] ---> $1\e[0m"; }
warning() { echo -e "\e[33mWARNING [$(date +%F\ %T)] ---> $1\e[0m"; }
err() { echo -e "\e[31mERR [$(date +%F\ %T)] ---> $1\e[0m" ; exit 1; }

check() { command -v $1 >/dev/null 2>&1 || err "$1 binary is required!"; }

ver() { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }

os=
case "$(uname -s)" in
  Linux)
    os=linux
  ;;
  Darwin)
    os=darwin
  ;;
  *)
  ;;
esac

if [ $os == "linux" ]; then
  BASE64="base64 -w0"
else
  BASE64="base64"
fi

exists() {
	if command -v $1 >/dev/null 2>&1; then
		msg "$1 binary installed"
	else
		warning "Please install $1 to proceed"
		exit 1
	fi
}

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=%s\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

dnsRegexp='(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{0,62}[a-zA-Z0-9]\.)+[a-zA-Z]{2,63}$)'

function regexMatch() {
   if [[ $(echo $1 | grep -P $2) ]]; then
      true
   elif [[ -n $3 ]]; then
      err "$3"
   else
      err "$key contains invalid value: $value"
   fi
}

approveContext() {
	echo "Your kubectl is configured with the following context: "
	CURRENT_CONTEXT=$(kubectl config current-context)
    kubectl config get-contexts ${CURRENT_CONTEXT}
	read -r -p "Are you sure you want to continue? [y/N] " response

	if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
	then
			echo ""
	else
			echo "Exiting..."
			exit 0
	fi
}

HELM_VERSION="${CF_HELM_VERSION:-2.12.0}"
checkHelmInstalled() {
  if command -v $1 >/dev/null 2>&1; then
    helm_version=$(helm version --client --short | sed 's/.*\: v//' | sed 's/+.*//')
    msg "helm is already installed and has version v$helm_version"
    [ $(ver $helm_version) -lt $(ver $HELM_VERSION) ] && \
    err "You have older helm version than required. Please upgrade to v$HELM_VERSION or newer !"
  else
    warning "helm is not installed"
    if [[ ! "$YES" == 'true' ]]; then
    read -p "Do you want to install helm ? [y/n] " yn
      case ${yn} in
        y|Y)
          helmInstall
      ;;
        *)
          err "Need helm to deploy Codefresh app ! Exiting..."
          #exit 1
      ;;
      esac
    else
      helmInstall
    fi
  fi
}

helmInstall() {
  msg "Downloading and installing helm..."
  case "$(uname -s)" in
    Linux)
      os=linux
    ;;
    Darwin)
      os=darwin
    ;;
    *)
    ;;
  esac
  wget https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-${os}-amd64.tar.gz -P /tmp/
  tar xvf /tmp/helm-v${HELM_VERSION}-${os}-amd64.tar.gz -C /tmp/
  chmod +x /tmp/${os}-amd64/helm

  echo sudo mv /tmp/${os}-amd64/helm /usr/local/bin/
  sudo mv /tmp/${os}-amd64/helm /usr/local/bin/
  rm -rf /tmp/helm-v${HELM_VERSION}-${os}-amd64 /tmp/helm-v${HELM_VERSION}-${os}-amd64.tar.gz
}

checkTillerInstalled() {
  status=$(kubectl -nkube-system get pod -l app=helm -l name=tiller -o=go-template --template='{{  range $i, $v := .items }}{{ if eq $v.status.phase "Running" }}{{ $v.status.phase }}{{ end }}{{ end }}')
  SCRIPTS_DIR=$(dirname "${BASH_SOURCE}")
  if [ "$status" == "Running" ]; then
    msg "Tiller is installed and running"
    helm init -c
    helm_version=$(helm version --client --short | sed 's/.*\: v//' | sed 's/+.*//')
    tiller_version=$(helm version --server --short | sed 's/.*\: v//' | sed 's/+.*//')
    if [[ ! "$YES" == 'true' ]] && [ $(ver $tiller_version) -lt $(ver $helm_version) ]; then
      warning "You're running helm v$helm_version but tiller has v$tiller_version."
      read -p  " Do you want to upgrade tiller to v$helm_version ? [y/n] " yn
      case ${yn} in
        y|Y)
          kubectl create -f "${SCRIPTS_DIR}"/../tiller-rbac-config.yaml > /dev/null 2>&1
          helm init --upgrade --service-account tiller --wait
      ;;
        *)
          err "You need to upgrade tiller ! Exiting..."
      ;;
      esac
    fi
    if [[ "$YES" == 'true' ]] && [ $(ver $tiller_version) -lt $(ver $helm_version) ]; then
      err "You're running helm v$helm_version but tiller has v$tiller_version . You need to upgrade tiller ! Exiting..."
    fi
  else
    warning "Unable to determine tiller at its default location."
    if [[ ! "$YES" == 'true' ]]; then
      read -p  " Do you want to deploy tiller ? [y/n] " yn
      case ${yn} in
        y|Y)
          kubectl create -f "${SCRIPTS_DIR}"/../tiller-rbac-config.yaml
          helm init --service-account tiller --wait
      ;;
        *)
          err "Need to deploy tiller ! Exiting..."
          exit 1
      ;;
      esac
    else
      kubectl create -f "${SCRIPTS_DIR}"/../tiller-rbac-config.yaml
      helm init --service-account tiller --wait
    fi
  fi

}

checkTillerStatus() {
	while true; do
    status=$(kubectl -nkube-system get pod -l app=helm -l name=tiller -o=go-template --template='{{  range $i, $v := .items }}{{ if eq $v.status.phase "Running" }}{{ $v.status.phase }}{{ end }}{{ end }}')

	  msg "Tiller status = $status"
	  [ "$status" == "Running" ] && break

	  msg "Sleeping 5 seconds ..."
	  sleep 5

	done
}