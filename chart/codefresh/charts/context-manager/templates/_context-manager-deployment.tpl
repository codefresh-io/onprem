{{/*
We create Deployment resource as template to be able to use many deployments but with
different name and version. This is for Istio POC.
*/}}
{{- define "context-manager.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "context-manager.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "context-manager.fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    release: {{ .Release.Name  | quote }}
    heritage: {{ .Release.Service  | quote }}
    version: {{ .version | default "base" | quote  }}
spec:
  replicas: {{ default 1 .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ template "context-manager.fullname" . }}
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
        app: {{ template "context-manager.fullname" . }}
        chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
        release: {{ .Release.Name  | quote }}
        heritage: {{ .Release.Service  | quote }}
        version: {{ .version | default "base" | quote  }}
    spec:
      # In production Kubernetes clusters we have multiple tiers of worker nodes.
      # The following setting makes sure that your applicaiton will run on
      # service nodes which don't run internal pods like monitoring.
      # This is needed to ensure a good quality of service.
      {{- with (default $.Values.global.appServiceTolerations $.Values.tolerations ) }}
      tolerations:
{{ toYaml . | indent 8}}
      {{- end }}
      affinity:
{{ toYaml (default .Values.global.appServiceAffinity .Values.affinity) | indent 8 }}
      imagePullSecrets:
        - name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}-registry"
      terminationGracePeriodSeconds: 10
      containers:
      - name: {{ template "context-manager.fullname" . }}
        {{- if .Values.global.privateRegistry }}
        image: "{{ .Values.global.dockerRegistry }}{{ .Values.image }}:{{ .imageTag }}"
        {{- else }}
        image: "{{ .Values.dockerRegistry }}{{ .Values.image }}:{{ .imageTag }}"
        {{- end }}
        imagePullPolicy: {{ default "" .Values.imagePullPolicy | quote }}
        resources:
{{ toYaml .Values.resources | indent 10 }}
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
        - name: NODE_ENV
          value: kubernetes
        - name: MONGO_URI
          valueFrom:
            secretKeyRef:
              name: {{ template "context-manager.fullname" . }}
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
        - name: SAFE_SECRET
          valueFrom:
            secretKeyRef:
              name: {{ template "context-manager.fullname" . }}
              key: safe-secret
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: postgres-password
        - name: NEWRELIC_LICENSE_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: newrelic-license-key
        - name: PORT
          value: "{{ .Values.global.contextManagerPort }}"
        - name: SERVICE_NAME
          value: {{ template "context-manager.name" . }}
        - name: FORMAT_LOGS_TO_ELK
          value: "{{ .Values.formatLogsToElk }}"
        - name: API_URI
          value: "{{ .Release.Name }}-{{ .Values.global.cfapiService }}"
        - name: API_PORT
          value: {{ .Values.global.cfapiInternalPort | quote }}
        ports:
        - containerPort: {{ .Values.targetPort }}
          protocol: TCP
        readinessProbe:
          httpGet:
            path: /api/ping
            port: {{ .Values.targetPort }}
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
