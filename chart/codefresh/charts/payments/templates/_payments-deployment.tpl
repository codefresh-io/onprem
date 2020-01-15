{{/*
We create Deployment resource as template to be able to use many deployments but with
different name and version. This is for Istio POC.
*/}}
{{- define "payments.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "payments.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "payments.fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    release: {{ .Release.Name  | quote }}
    heritage: {{ .Release.Service  | quote }}
    version: {{ .Values.imageTag | quote }}
spec:
  replicas: {{ default 1 .Values.replicaCount }}
  strategy:
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 100%
  selector:
    matchLabels:
      app: {{ template "payments.fullname" . }}
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
        app: {{ template "payments.fullname" . }}
        chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
        release: {{ .Release.Name  | quote }}
        heritage: {{ .Release.Service  | quote }}
        version: {{ .version | default "base" | quote  }}
    spec:
      {{- with (default .Values.global.appServiceTolerations .Values.tolerations ) }}
      tolerations:
{{ toYaml . | indent 8}}
      {{- end }}
      affinity:
{{ toYaml (default .Values.global.appServiceAffinity .Values.affinity) | indent 8 }}
      imagePullSecrets:
        - name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}-registry"
      containers:
      - name: {{ template "payments.fullname" . }}
        image: "{{ .Values.image }}:{{ .imageTag }}"
        imagePullPolicy: {{ default "" .Values.imagePullPolicy | quote }}
        resources:
{{ toYaml .Values.resources | indent 10 }}
        env:
        {{- if $.Values.global.env }}
        {{- range $key, $value := $.Values.global.env }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end}}
        {{- end}}
        {{- range $key, $value := .Values.env }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end }}
        - name: API_URL
          value: {{ .Values.global.appUrl | quote }}
        - name: API_PROTOCOL
          value: {{ .Values.global.appProtocol | quote }}
        - name: INTERNAL_API_URI
          value: "{{ .Release.Name }}-{{ .Values.global.cfapiService }}"
        - name: INTERNAL_API_PORT
          value: "{{ .Values.global.cfapiInternalPort }}"
        - name: MONGO_URI
          {{ if .Values.mongoURI }}
          valueFrom:
            secretKeyRef:
              name: {{ template "payments.fullname" . }}
              key: mongo-uri
          {{ else }}
          value: "mongodb://{{ .Values.global.mongodbUsername }}:{{ .Values.global.mongodbPassword }}@{{ .Release.Name }}-{{ .Values.global.mongoService }}:{{ .Values.global.mongoPort }}/{{ .Values.global.paymentsService }}"
          {{ end }}
        - name: NEWRELIC_LICENSE_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: newrelic-license-key
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
        - name: PORT
          value: "{{ .Values.global.paymentsServicePort }}"
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
        - name: STRIPE_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: stripe-secret-key
        - name: STRIPE_WEBHOOK_SIGN_SECRET
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: stripe-webhook-sign-secret
        - name: GITHUB_WEBHOOK_SIGN_SECRET
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: github-webhook-sign-secret
        - name: STRIPE_IGNORE_ACCOUNT_NOT_FOUND_ERRORS
          valueFrom:
            configMapKeyRef:
              name:  {{ template "payments.fullname" . }}
              key: stripe-ignore-account-not-found-errors
        - name: SERVICE_NAME
          value: {{ template "payments.name" . }}
        - name: FORMAT_LOGS_TO_ELK
          value: "{{ .Values.formatLogsToElk }}"
        readinessProbe:
          httpGet:
            path: /api/ping
            port: {{ .Values.targetPort }}
          periodSeconds: 5
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 2
{{- end }}
