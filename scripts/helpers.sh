#!/bin/bash

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