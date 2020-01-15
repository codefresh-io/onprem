{{/*
We create Deployment resource as template to be able to use many deployments but with
different name and version. This is for Istio POC.
*/}}
{{- define "onboarding-status.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "onboarding-status.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "onboarding-status.name" . }}
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
      app: {{ template "onboarding-status.fullname" . }}
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
        app: {{ template "onboarding-status.fullname" . }}
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
        - name: "{{ template "onboarding-status.name" . }}-registry"
      containers:
      - name: {{ template "onboarding-status.fullname" . }}
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
          {{- if .Values.requiredInfraComponenets.mongo }}
          - name: MONGO_URI
            valueFrom:
              secretKeyRef:
                name: {{ template "onboarding-status.name" . }}
                key: mongo-uri
          {{- end}}

          {{- if .Values.requiredInfraComponenets.eventBus }}
          - name: EVENTBUS_URI
            valueFrom:
              secretKeyRef:
                name: {{ template "onboarding-status.name" . }}
                key: eventbus-uri
          {{- end}}

          {{- if .Values.requiredInfraComponenets.postgres }}
          - name: POSTGRES_USER
            valueFrom:
              secretKeyRef:
                name: {{ template "onboarding-status.name" . }}
                key: postgres-user
          - name: POSTGRES_HOST
            valueFrom:
              secretKeyRef:
                name: {{ template "onboarding-status.name" . }}
                key: postgres-host
          - name: POSTGRES_DATABASE
            valueFrom:
              secretKeyRef:
                name: {{ template "onboarding-status.name" . }}
                key: postgres-database
          - name: POSTGRES_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ template "onboarding-status.name" . }}
                key: postgres-password
          {{- end}}

          - name: SERVICE_NAME
            value: {{ template "onboarding-status.name" . }}
          - name: FORMAT_LOGS_TO_ELK
            value: "{{ .Values.formatLogsToElk }}"

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
                name: {{ template "onboarding-status.name" . }}
                key: newrelic-license-key
        ports:
        - containerPort: {{ .Values.port }}
          protocol: TCP
        {{- if .Values.global.addResolvConf }}
        volumeMounts:
        - mountPath: /etc/resolv.conf
          name: resolvconf
          subPath: resolv.conf
          readOnly: true
        {{- end }}
        readinessProbe:
          httpGet:
            path: /api/ping
            port: {{ .Values.port }}
          periodSeconds: 5
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 2
      volumes:
      {{- if .Values.global.addResolvConf }}
      - name: resolvconf
        configMap:
          name: {{ .Release.Name }}-{{ .Values.global.codefresh }}-resolvconf
      {{- end }}
{{- end }}
