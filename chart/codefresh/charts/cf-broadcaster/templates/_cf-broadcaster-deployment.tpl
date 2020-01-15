{{/*
We create Deployment resource as template to be able to use many deployments but with 
different name and version. This is for Istio POC.
*/}}
{{- define "cf-broadcaster.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "cf-broadcaster.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "cf-broadcaster.name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
    version: {{ .version | default "base" | quote  }}
spec:
  replicas: {{ default 1 .Values.replicaCount }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 50%
      maxSurge: 50%
  selector:
    matchLabels:
      app: {{ template "cf-broadcaster.fullname" . }}
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
        app: {{ template "cf-broadcaster.fullname" . }}
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
      imagePullSecrets:
      - name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}-registry"
      containers:
      - name: {{ template "cf-broadcaster.fullname" . }}
        {{- if .Values.global.privateRegistry }}
        image: "{{ .Values.global.dockerRegistry }}{{ .Values.image }}:{{ .imageTag }}"
        {{- else }}
        image: "{{ .Values.dockerRegistry }}{{ .Values.image }}:{{ .imageTag }}"
        {{- end }}
        imagePullPolicy: {{ default "" .Values.imagePullPolicy | quote }}
        resources:
{{ toYaml .Values.resources | indent 10 }}
        env:
          - name: REDIS_URL
            value: {{ .Values.global.runtimeRedisHost }}
          - name: REDIS_PASSWORD
            value: {{ .Values.global.runtimeRedisPassword }}
          - name: REDIS_PORT
            value: {{ .Values.global.runtimeRedisPort | quote }}
          - name: REDIS_DB
            value: {{ .Values.global.runtimeRedisDb | quote }}
          - name: MONGO_URI
            value: {{ .Values.global.runtimeMongoURI }}
          - name: SERVICE_NAME
            value: {{ template "cf-broadcaster.name" . }}
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

          {{- if .Values.global.env }}
          {{- range $key, $value := .Values.global.env }}
          - name: {{ $key }}
            value: {{ $value | quote }}
          {{- end}}
          {{- end}}
          {{- range $key, $value := .Values.env }}
          - name: {{ $key }}
            value: {{ $value | quote }}
          {{- end }}
          - name: PORT
            value: {{ .Values.port | quote }}
          - name: NEWRELIC_LICENSE_KEY
            valueFrom:
              secretKeyRef:
                name: {{ template "cf-broadcaster.fullname" . }}
                key: newrelic-license-key
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
{{- end }}
