{{/*
We create Deployment resource as template to be able to use many deployments but with
different name and version. This is for Istio POC.
*/}}
{{- define "cluster-providers.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "cluster-providers.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "cluster-providers.fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    release: {{ .Release.Name  | quote }}
    heritage: {{ .Release.Service  | quote }}
    version: {{ .version | default "base" | quote  }}
spec:
  replicas: {{ default 1 .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ template "cluster-providers.fullname" . }}
  template:
    metadata:
      {{- if .Values.redeploy }}
      annotations:
        forceRedeployUniqId: {{ now | quote }}
        sidecar.istio.io/inject: {{ $.Values.global.istio.enabled | default "false" | quote }}
      {{- else }}
      annotations:
        sidecar.istio.io/inject: {{ $.Values.global.istio.enabled | default "false" | quote }}
      {{- end }}
      labels:
        app: {{ template "cluster-providers.fullname" . }}
        chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
        release: {{ .Release.Name  | quote }}
        heritage: {{ .Release.Service  | quote }}
        version: {{ .version | default "base" | quote  }}
    spec:
      # In production Kubernetes clusters we have multiple tiers of worker nodes.
      # The following setting makes sure that your applicaiton will run on
      # service nodes which don't run internal pods like monitoring.
      # This is needed to ensure a good quality of service.
      {{- with (default .Values.global.appServiceTolerations .Values.tolerations ) }}
      tolerations:
{{ toYaml . | indent 8}}
      {{- end }}
      affinity:
{{ toYaml (default .Values.global.appServiceAffinity .Values.affinity) | indent 8 }}
      {{- if .Values.global.hostAliases }}
      hostAliases:
{{ toYaml .Values.global.hostAliases | indent 8 }}
      {{- end }}
      imagePullSecrets:
        - name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}-registry"
      terminationGracePeriodSeconds: 10
      containers:
        - name: {{ template "cluster-providers.fullname" . }}
          {{- if .Values.global.privateRegistry }}
          image: "{{ .Values.global.dockerRegistry }}{{ .Values.image }}:{{ .imageTag }}"
          {{- else }}
          image: "{{ .Values.dockerRegistry }}{{ .Values.image }}:{{ .imageTag }}"
          {{- end }}
          imagePullPolicy: {{ default "" .Values.imagePullPolicy | quote }}
          resources:
  {{ toYaml .Values.resources | indent 12 }}
          env:
          {{- if .Values.global.env }}
          {{- range $key, $value := .Values.global.env }}
          - name: {{ $key }}
            value: {{ $value | quote }}
          {{- end}}
          {{- end}}
          {{- range $key, $value := $.Values.env }}
          - name: {{ $key }}
            value: {{ $value | quote }}
          {{- end }}
          - name: API_PROTOCOL
            value: {{ .Values.global.appProtocol | quote }}
          - name: API_URL
            value: {{ .appUrl | default $.Values.global.appUrl | quote }}
          - name: INTERNAL_API_URI
            value: "{{ .Release.Name }}-{{ .Values.global.cfapiService }}"
          - name: INTERNAL_API_PORT
            value: "{{ .Values.global.cfapiInternalPort }}"
          - name: RUNTIME_ENVIRONMENT_MANAGER_URI
            value: "{{ .Release.Name }}-{{ .Values.global.runtimeEnvironmentManagerService }}"
          - name: RUNTIME_ENVIRONMENT_MANAGER_PORT
            value: {{ .Values.global.runtimeEnvironmentManagerPort | quote }}
          - name: NODE_ENV
            value: kubernetes
          - name: GC_AUTH_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ template "cluster-providers.fullname" . }}
                key: client-id
          - name: GC_AUTH_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ template "cluster-providers.fullname" . }}
                key: client-secret

          {{- if .Values.aksAuthClientId }}
          - name: AKS_AUTH_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ template "cluster-providers.fullname" . }}
                key: aks-auth-client-id
          - name: AKS_AUTH_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ template "cluster-providers.fullname" . }}
                key: aks-auth-client-secret
          - name: AKS_AUTH_COOKIE_ENCRYPTION_KEY
            valueFrom:
              secretKeyRef:
                name: {{ template "cluster-providers.fullname" . }}
                key: aks-auth-cookie-encryption-key
          - name: AKS_AUTH_COOKIE_ENCRYPTION_IV
            valueFrom:
              secretKeyRef:
                name: {{ template "cluster-providers.fullname" . }}
                key: aks-auth-cookie-encryption-iv
          {{- end }}

          - name: MONGO_URI
            valueFrom:
              secretKeyRef:
                name: {{ template "cluster-providers.fullname" . }}
                key: mongo-uri
          - name: RABBIT_PASSWORD
            valueFrom:
              secretKeyRef:
                name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
                key: rabbitmq-password
          - name: RABBIT_USER
            valueFrom:
              secretKeyRef:
                name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
                key: rabbitmq-username
          - name: EVENTBUS_URI
            value: amqp://$(RABBIT_USER):$(RABBIT_PASSWORD)@{{ default (printf "%s-%s" .Release.Name .Values.global.rabbitService) .Values.global.rabbitmqHostname }}
          - name: POSTGRES_HOST
            value: {{ default (printf "%s-%s" .Release.Name .Values.global.postgresService) .Values.global.postgresHostname | quote }}
          - name: POSTGRES_DATABASE
            value: {{ .Values.global.postgresDatabase }}
          - name: POSTGRES_USER
            valueFrom:
              secretKeyRef:
                name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
                key: postgres-user
          - name: POSTGRES_PASSWORD
            valueFrom:
              secretKeyRef:
                name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
                key: postgres-password
          - name: PORT
            value: "{{ .Values.global.clusterProvidersPort }}"
          - name: NEWRELIC_LICENSE_KEY
            valueFrom:
              secretKeyRef:
                name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
                key: newrelic-license-key
          - name: SAFE_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ template "cluster-providers.fullname" . }}
                key: safe-secret
          - name: SERVICE_NAME
            value: {{ template "cluster-providers.name" . }}
          - name: FORMAT_LOGS_TO_ELK
            value: "{{ .Values.formatLogsToElk }}"
          ports:
            - containerPort: {{ .Values.port }}
              protocol: TCP
          readinessProbe:
            httpGet:
              path: /api/ping
              port: {{ .Values.port }}
            periodSeconds: 5
            timeoutSeconds: 5
            successThreshold: 1
            failureThreshold: 2
        {{- if .Values.global.addResolvConf }}
          volumeMounts:
            - mountPath: /etc/resolv.conf
              name: resolvconf
              subPath: resolv.conf
              readOnly: true
      volumes:
        - name: resolvconf
          configMap:
            name: {{ .Release.Name }}-{{ .Values.global.codefresh }}-resolvconf
      {{- end }}
      restartPolicy: Always
{{- end }}
