{{/*
We create Deployment resource as template to be able to use many deployments but with
different name and version. This is for Istio POC.
*/}}
{{- define "charts-manager.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "charts-manager.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "charts-manager.fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    release: {{ .Release.Name  | quote }}
    heritage: {{ .Release.Service  | quote }}
    version: {{ .version | default "base" | quote  }}
spec:
  replicas: {{ default 1 .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ template "charts-manager.fullname" . }}
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
        app: {{ template "charts-manager.fullname" . }}
        chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
        release: {{ .Release.Name  | quote }}
        heritage: {{ .Release.Service  | quote }}
        version: {{ .version | default "base" | quote  }}
    spec:
      # In production Kubernetes clusters we have multiple tiers of worker nodes.
      # The following setting makes sure that your applicaiton will run on
      # service nodes which don't run internal pods like monitoring.
      # This is needed to ensure a good quality of service.
      affinity:
{{ toYaml (default .Values.global.appServiceAffinity .Values.affinity) | indent 8 }}
      imagePullSecrets:
        - name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}-registry"
      terminationGracePeriodSeconds: 10
      containers:
      - name: {{ template "charts-manager.fullname" . }}
        {{- if .Values.global.privateRegistry }}
        image: "{{ .Values.global.dockerRegistry }}{{ .Values.image }}:{{ .imageTag }}"
        {{- else }}
        image: "{{ .Values.dockerRegistry }}{{ .Values.image }}:{{ .imageTag }}"
        {{- end }}
        imagePullPolicy: {{ default "" .Values.imagePullPolicy | quote }}
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
        - name: NODE_ENV
          value: kubernetes
        - name: MONGO_URI
          valueFrom:
            secretKeyRef:
              name: {{ template "charts-manager.fullname" . }}
              key: mongo-uri
        - name: NEWRELIC_LICENSE_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: newrelic-license-key
        - name: PORT
          value: "{{ .Values.global.chartsManagerPort }}"
        - name: SERVICE_NAME
          value: {{ template "charts-manager.name" . }}
        - name: FORMAT_LOGS_TO_ELK
          value: "{{ .Values.formatLogsToElk }}"
      {{- if .Values.global.privateRegistry }}
        - name: DISABLE_PUBLIC_REPOS
          value: "{{ .Values.disablePublicRepos }}"
        {{- end }}
        - name: CLUSTER_PROVIDERS_URI
          value: "{{ .Release.Name }}-{{ .Values.global.clusterProvidersService }}"
        - name: CLUSTER_PROVIDERS_PORT
          value: {{ .Values.global.clusterProvidersPort | quote }}
        - name: CONTEXT_MANAGER_URI
          value: "{{ .Release.Name }}-{{ .Values.global.contextManagerService }}"
        - name: CONTEXT_MANAGER_PORT
          value: {{ .Values.global.contextManagerPort | quote }}
        - name: API_URI
          value: "{{ .Release.Name }}-{{ .Values.global.cfapiService }}"
        - name: API_PORT
          value: {{ .Values.global.cfapiInternalPort | quote }}
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
          failureThreshold: 5
      restartPolicy: Always
{{- end }}
