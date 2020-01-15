{{/*
We create Deployment resource as template to be able to use many deployments but with
different name and version. This is for Istio POC.
*/}}
{{- define "cfapi.renderDeployment" -}}
{{- $natsService := printf "nats://%s-%s.%s.svc:%v" $.Release.Name .Values.global.natsService $.Release.Namespace $.Values.global.natsPort }}
{{- $tlsSignService := printf "http://%s-%s.%s.svc:%v" $.Release.Name .Values.global.tlsSignService $.Release.Namespace $.Values.global.tlsSignPort }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "cfapi.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "cfapi.fullname" $ }}
    chart: "{{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}"
    release: {{ $.Release.Name  | quote }}
    heritage: {{ $.Release.Service  | quote }}
    version: {{ .version | default "base" | quote  }}
    stable-version: {{ .stableVersion | default "false" | quote  }}
spec:
  replicas: {{ default 1 $.Values.replicaCount }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 50%
  selector:
    matchLabels:
      app: {{ template "cfapi.fullname" $ }}
  template:
    metadata:
      annotations:
        checksum-config: {{ $.Files.Get (print $.Values.getRuntimeEnvs ) | sha256sum }}
      {{- if $.Values.redeploy }}
        forceRedeployUniqId: {{ now | quote }}
        sidecar.istio.io/inject: {{ or $.Values.istio.enabled $.Values.global.istio.enabled  | default false | quote }}
      {{- else }}
        sidecar.istio.io/inject: {{ or $.Values.istio.enabled $.Values.global.istio.enabled  | default false | quote }}
      {{- end }}
      labels:
        app: {{ template "cfapi.fullname" $ }}
        chart: "{{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}"
        release: {{ $.Release.Name  | quote }}
        heritage: {{ $.Release.Service  | quote }}
        version: {{ .version | default "base" | quote  }}
        stable-version: {{ .stableVersion | default "false" | quote  }}
    spec:
      {{- if $.Values.rbacEnable }}
      serviceAccountName: {{ template "cfapi.fullname" $ }}
      {{- end }}
      {{- with (default $.Values.global.appServiceTolerations $.Values.tolerations ) }}
      tolerations:
{{ toYaml . | indent 8}}
      {{- end }}
      affinity:
{{ toYaml (default $.Values.global.appServiceAffinity $.Values.affinity) | indent 8 }}
      {{- if $.Values.global.hostAliases }}
      hostAliases:
{{ toYaml $.Values.global.hostAliases | indent 8 }}
      {{- end }}
      imagePullSecrets:
        - name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}-registry"
      terminationGracePeriodSeconds: 40
      restartPolicy: Always
      containers:
      - name: {{ template "cfapi.fullname" $ }}
        {{- if $.Values.global.privateRegistry }}
        image: "{{ $.Values.global.dockerRegistry }}{{ $.Values.image }}:{{ .imageTag }}"
        {{- else }}
        image: "{{ $.Values.dockerRegistry }}{{ $.Values.image }}:{{ .imageTag }}"
        {{- end }}
        imagePullPolicy: {{ default "" $.Values.imagePullPolicy | quote }}
        resources:
{{ toYaml $.Values.resources | indent 10 }}
        env:
        {{- if $.Values.global.env }}
        {{- range $key, $value := $.Values.global.env }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end}}
        {{- end}}
        {{- range $key, $value := $.Values.env }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end }}
        - name: API_SAFE_SECRET
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: api-safe-secret
        - name: BITBUCKET_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name:  {{ template "cfapi.fullname" $ }}
              key: bitbucket-client-id
        - name: BITBUCKET_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name:  {{ template "cfapi.fullname" $ }}
              key: bitbucket-client-secret
        - name: BITBUCKET_LOGIN_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name:  {{ template "cfapi.fullname" $ }}
              key: bitbucket-login-client-id
        - name: BITBUCKET_LOGIN_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name:  {{ template "cfapi.fullname" $ }}
              key: bitbucket-login-client-secret
        - name: BL_USERS
          valueFrom:
            configMapKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: segment-blacklist-users
        - name: CF_HOST_NAME
          value: {{ .appUrl | default $.Values.global.appUrl | quote }}
        - name: CF_REGISTRY_PROTOCOL
          value: {{ default "http" $.Values.internalRegistryProtocol | quote }}
        - name: CF_REGISTRY_ADMIN_TOKEN
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: registry-admin-token
        - name: CF_REGISTRY_API_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: reg-auth-api-key
        - name: CF_REGISTRY_DOMAIN
          valueFrom:
            configMapKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: cfcr-domain
        - name: CLUSTER_PROVIDERS_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.clusterProvidersService }}"
        - name: CLUSTER_PROVIDERS_PORT
          value: "{{ $.Values.global.clusterProvidersPort }}"
        - name: CONSUL_HOST
          value: {{ default (printf "%s-%s" $.Release.Name $.Values.global.consulService) $.Values.global.consulHost | quote }}
        - name: EXTERNAL_URL
          value: {{ default (printf "%s://%s" $.Values.global.appProtocol (.appUrl | default $.Values.global.appUrl) ) $.Values.global.externalUrl }}
        - name: FIREBASE_SECRET
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: firebase-secret
        - name: FIREBASE_URL
          valueFrom:
            configMapKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: firebase-url
        - name: INTERNAL_USE_GITHUB_ACCESS_TOKEN
          valueFrom:
            secretKeyRef:
              name:  {{ template "cfapi.fullname" $ }}
              key: github-internal-token
        - name: INTERNAL_SERVER_PORT
          value: {{ $.Values.targetInternalPort | quote }}
        - name: GITHUB_API_HOST
          value: {{ $.Values.github.apiHost | quote }}
        - name: GITHUB_API_PATH_PREFIX
          value: "{{ $.Values.github.apiPathPrefix }}"
        - name: GITHUB_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name:  {{ template "cfapi.fullname" $ }}
              key: github-client-id
        - name: GITHUB_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name:  {{ template "cfapi.fullname" $ }}
              key: github-client-secret
        - name: GITHUB_LOGIN_HOST
          value: {{ $.Values.github.loginHost | quote }}
        - name: GITHUB_PROTOCOL
          value: {{ $.Values.github.protocol | quote }}
        - name: GITLAB_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name:  {{ template "cfapi.fullname" $ }}
              key: gitlab-client-id
        - name: GITLAB_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name:  {{ template "cfapi.fullname" $ }}
              key: gitlab-client-secret
        - name: GITLAB_LOGIN_HOST
          value: {{ $.Values.gitlab.loginHost | quote }}
        - name: GITLAB_PROTOCOL
          value: {{ $.Values.gitlab.protocol | quote }}
        - name: GOOGLE_COMPUTE_ENGINE_PROJECT
          valueFrom:
            configMapKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: google-compute-engine-project
        - name: LOGGLY_TOKEN
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: loggly-token
        - name: MONGO_URI
          valueFrom:
            secretKeyRef:
              name: "{{ template "cfapi.fullname" $ }}"
              key: mongo-uri
        - name: NEWRELIC_LICENSE_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: newrelic-license-key
        {{- with $.Values.global.tlsRejectUnauthorized }}
        - name: NODE_TLS_REJECT_UNAUTHORIZED
          value: {{ $.Values.global.tlsRejectUnauthorized | quote }}
        {{- end }}
        - name: PAYMENTS_SERVICE
          value: "{{ $.Release.Name }}-{{ $.Values.global.paymentsService }}"
        - name: PAYMENTS_URI
          value: $(PAYMENTS_SERVICE)
        - name: PAYMENTS_PORT
          value: {{ $.Values.global.paymentsServicePort | quote }}
        - name: PORT
          {{- if $.Values.global.maintenanceMode }}
          value: {{ $.Values.global.maintenancePort | quote }}
          {{- else }}
          value: {{ $.Values.targetPort | quote }}
          {{- end }}
        - name: POSTGRES_DATABASE
          value: {{ $.Values.global.postgresDatabase }}
        - name: POSTGRES_HOST
          value: {{ default (printf "%s-%s" $.Release.Name $.Values.global.postgresService) $.Values.global.postgresHostname | quote }}
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: postgres-password
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: postgres-user
        - name: PROTOCOL
          value: {{ $.Values.global.appProtocol | quote }}
        {{- if $.Values.global.rabbitmqNoPassword }}
        - name: RABBIT_URL
          value: amqp://{{.Values.global.rabbitmqHostname }}
        {{- else }}
        - name: RABBIT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: rabbitmq-password
        - name: RABBIT_USER
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: rabbitmq-username
        - name: RABBIT_URL
          value: amqp://$(RABBIT_USER):$(RABBIT_PASSWORD)@{{ default (printf "%s-%s" $.Release.Name $.Values.global.rabbitService) $.Values.global.rabbitmqHostname }}
        {{- end }}
        - name: REDIS_URL
          value: {{ default (printf "%s-%s" $.Release.Name $.Values.global.redisService) $.Values.global.redisUrl }}
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: redis-password
        - name: QUEUE_SERVERS
          value: {{ default $natsService $.Values.global.queueServers | quote }}
        - name: SLACK_APP_ID
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: slack-app-id
        - name: SLACK_APP_SECRET
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: slack-app-secret
        - name: SLACK_INTERNAL
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: slack-internal
        - name: SEGMENT_ACTIVE
          value: {{ $.Values.segmentEnable | quote }}
        - name: SEGMENT_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: segment-key
        - name: STRIPE_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: stripe-secret-key
        - name: TLS_SIGN_CLIENT_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
              key: tls-client-key
        - name: GCS_PRIVATE_KEY
          valueFrom:
            secretKeyRef:
              name: {{ template "cfapi.fullname" $ }}
              key: gcs-private-key
        - name: ZENDESK_KEY
          value: {{ $.Values.global.zendeskKey | quote }}
        - name: ZENDESK_TOKEN
          value: {{ $.Values.global.zendeskToken | quote }}
        - name: ZENDESK_OWNER_MAIL
          value: {{ $.Values.global.zendeskOwnerMail | quote }}
        - name: ZENDESK_NAMESPACE
          value: {{ $.Values.global.zendeskNamespace | quote }}
        - name: ZENDESK_ORGANIZATION_WEBHOOK
          value: {{ $.Values.global.zendeskOrganizationWebhook | quote }}
        - name: TLS_SIGN_URL
          value: "{{ $tlsSignService }}"
        - name: API_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.cfapiService }}"
        - name: API_PORT
          value: {{ $.Values.global.cfapiInternalPort | quote }}
        - name: CLUSTER_PROVIDERS_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.clusterProvidersService }}"
        - name: CLUSTER_PROVIDERS_PORT
          value: {{ $.Values.global.clusterProvidersPort | quote }}
        - name: KUBE_INTEGRATION_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.kubeIntegrationService }}"
        - name: KUBE_INTEGRATION_PORT
          value: {{ $.Values.global.kubeIntegrationPort | quote }}
        - name: ACCOUNTS_REFERRALS_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.accountsReferralsService }}"
        - name: ACCOUNTS_REFERRALS_PORT
          value: {{ $.Values.global.accountsReferralsPort | quote }}
        - name: CHARTS_MANAGER_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.chartsManagerService }}"
        - name: CHARTS_MANAGER_PORT
          value: {{ $.Values.global.chartsManagerPort | quote }}
        - name: DIND_PROVIDER_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.dindProviderService }}"
        - name: DIND_PROVIDER_PORT
          value: {{ $.Values.global.dindProviderPort | quote }}
        - name: CONTEXT_MANAGER_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.contextManagerService }}"
        - name: CONTEXT_MANAGER_PORT
          value: {{ $.Values.global.contextManagerPort | quote }}
        - name: PIPELINE_MANAGER_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.pipelineManagerService }}"
        - name: K8S_MONITOR_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.cfk8smonitorService }}"
        - name: PIPELINE_MANAGER_PORT
          value: {{ $.Values.global.pipelineManagerPort | quote }}
        - name: ANALYTIC_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.cfanalyticService }}"
        - name: ANALYTIC_PORT
          value: {{ $.Values.global.cfanalyticPort | quote }}
        - name: ONBOARDING_STATUS_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.onboardingStatusService }}"
        - name: ONBOARDING_STATUS_PORT
          value: {{ $.Values.global.onboardingStatusPort | quote }}
        - name: RUNTIME_ENVIRONMENT_MANAGER_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.runtimeEnvironmentManagerService }}"
        - name: RUNTIME_ENVIRONMENT_MANAGER_PORT
          value: {{ $.Values.global.runtimeEnvironmentManagerPort | quote }}
        - name: BROADCASTER_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.broadcasterService }}"
        - name: BROADCASTER_PORT
          value: {{ $.Values.global.broadcasterPort | quote }}
        - name: RUNTIME_REDIS_HOST
          value: {{ $.Values.global.runtimeRedisHost | quote }}
        - name: RUNTIME_REDIS_PASSWORD
          value: {{ $.Values.global.runtimeRedisPassword | quote }}
        - name: RUNTIME_REDIS_DB
          value: {{ $.Values.global.runtimeRedisDb | quote }}
        - name: RUNTIME_REDIS_PORT
          value: {{ $.Values.global.runtimeRedisPort | quote }}
        - name: RUNTIME_MONGO_URI
          value: {{ $.Values.global.runtimeMongoURI | quote }}
        - name: DEPLOYMENT_TEMPLATE_IMAGES_JSON_PATH
          value: /etc/admin/deploymentTemplateImages.json
        - name: HELM_REPO_MANAGER_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.helmRepoManagerService }}"
        - name: HELM_REPO_MANAGER_PORT
          value: "{{ default "80" $.Values.global.helmRepoManagerPort }}"
        - name: HELM_REPO_MANAGER_PROTOCOL
          value: "{{ default "http" $.Values.global.helmRepoManagerProtocol }}"
        - name: HERMES_URI
          value: "{{ $.Release.Name }}-{{ $.Values.global.hermesService }}"
        - name: HERMES_PORT
          value: "{{ default "80" $.Values.global.hermesPort }}"
        - name: HERMES_PROTOCOL
          value: "{{ default "http" $.Values.global.hermesProtocol }}"
        - name: KUBECTL_HELM_IMAGE_BASE_NAME
          value: "{{ $.Values.kubectlHelmImage }}"
        {{- if $.Values.expirationToken }}
        - name: SYSTEM_EXPIRATION_TOKEN
          value: {{ $.Values.cfet }}
        - name: SYSTEM_EXPIRATION_URL
          value: {{ $.Values.expirationURL }}
        {{- end }}
        - name: SERVICE_NAME
          value: {{ template "cfapi.name" $ }}
        {{- if $.Values.formatLogsToElk }}
        - name: FORMAT_LOGS_TO_ELK
          value: "{{ $.Values.formatLogsToElk }}"
        {{- end }}
        - name: AUTH0_LOGIN_HOST
          value: "{{ $.Values.auth0LoginHost }}"
        #- name: OAUTH_ROUTER_CALLBACK
        #  valueFrom:
        #    configMapKeyRef:
        #      name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}"
        #      key: oauth-router-callback
        ports:
        {{- if $.Values.global.maintenanceMode }}
        - containerPort: {{ $.Values.global.maintenancePort }}
          {{- else }}
        - containerPort: {{ $.Values.targetPort }}
        {{- end }}
          protocol: TCP
        - containerPort: {{ $.Values.targetInternalPort }}
          protocol: TCP
        readinessProbe:
          {{- if $.Values.global.maintenanceMode }}
          httpGet:
            path: /api/ping
            port: {{ $.Values.global.maintenancePort }}
          {{- else }}
          exec:
            command:
            - /opt/healthcheck/run
          {{- end }}
          initialDelaySeconds: 1
          periodSeconds: 5
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 2
        livenessProbe:
          {{- if $.Values.global.maintenanceMode }}
          httpGet:
            path: /api/ping
            port: {{ $.Values.global.maintenancePort }}
          {{- else }}
          exec:
            command:
            - /opt/healthcheck/run
          {{- end }}
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 2
        volumeMounts:
        - name: config
          mountPath: /etc/admin/providers.json
          subPath: providers.json
        - name: config
          mountPath: /etc/admin/accounts.json
          subPath: accounts.json
        - name: config
          mountPath: /etc/admin/users.json
          subPath: users.json
        - name: runtime-environments
          mountPath: /etc/admin/runtimeEnvironments.json
          subPath: runtimeEnvironments.json
        {{- if $.Values.sshMasterSecret }}
        - name: ssh-secrets
          mountPath: /etc/admin/sshMasterSecret.json
          subPath: sshMasterSecret
        {{- end }}
        - name: node-clusters
          mountPath: /root/.kube/config
          subPath: kube-config
        - name: dind-clusters
          mountPath: /etc/kubeconfig
        - mountPath: /opt/healthcheck
          name: cfapi-healthcheck-scripts
        - mountPath: /etc/ssl/cf/
          readOnly: true
          name: cf-certs-client
        {{- if $.Values.awsCredentials }}
        - name: api-secrets-aws
          mountPath: /root/.aws/credentials
          subPath: aws-credentials
        {{- end }}
        {{- if $.Values.gceCredentials }}
        - name: api-secrets-gce
          mountPath: /etc/admin/gce_creds.json
          subPath: gce-credentials
        {{- end }}
        {{- if $.Values.azureCredentials }}
        - name: api-secrets-azure
          mountPath: /etc/admin/azure_creds.json
          subPath: azure-credentials
        {{- end }}
        {{- if $.Values.deploymentTemplateImages }}
        - name: config
          mountPath: /etc/admin/deploymentTemplateImages.json
          subPath: deploymentTemplateImages.json
        {{- end }}
	      {{- if $.Values.global.addResolvConf }}
        - mountPath: /etc/resolv.conf
          name: resolvconf
          subPath: resolv.conf
          readOnly: true
        {{- end }}
{{- if $.Values.global.maintenanceMode }}
{{ toYaml $.Values.global.maintenanceContainer | indent 6 }}
{{- end }}
      volumes:
      - name: config
        configMap:
          name: {{ template "cfapi.fullname" $ }}
      - name: runtime-environments
        configMap:
          name: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}-runtime-envs"
      - name: node-clusters
        secret:
          secretName: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}-node-clusters"
      - name: dind-clusters
        secret:
          secretName: "{{ $.Values.dindClustersSecret }}"
          optional: true
      - name: cfapi-healthcheck-scripts
        configMap:
          defaultMode: 484
          name: {{ template "cfapi.fullname" $ }}-healthcheck
      - name: cf-certs-client
        secret:
          secretName: "{{ $.Release.Name }}-{{ $.Values.global.codefresh }}-certs-client"
      {{- if $.Values.awsCredentials }}
      - name: api-secrets-aws
        secret:
          secretName: {{ template "cfapi.fullname" $ }}
      {{- end }}
      {{- if $.Values.gceCredentials }}
      - name: api-secrets-gce
        secret:
          secretName: {{ template "cfapi.fullname" $ }}
      {{- end }}
      {{- if $.Values.azureCredentials }}
      - name: api-secrets-azure
        secret:
          secretName: {{ template "cfapi.fullname" $ }}
      {{- end }}
      {{- if $.Values.sshMasterSecret }}
      - name: ssh-secrets
        secret:
          secretName: {{ template "cfapi.fullname" $ }}
      {{- end }}
      {{- if $.Values.global.addResolvConf }}
      - name: resolvconf
        configMap:
          name: {{ $.Release.Name }}-{{ $.Values.global.codefresh }}-resolvconf
      {{- end }}
{{- if $.Values.global.maintenanceMode }}
{{ toYaml $.Values.global.maintenanceVolumes | indent 6 }}
{{- end }}
{{- end }}
