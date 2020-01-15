{{/*
We create Deployment resource as template to be able to use many deployments but with
different name and version. This is for Istio POC.
*/}}
{{- define "kube-integration.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "kube-integration.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "kube-integration.fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    release: {{ .Release.Name  | quote }}
    heritage: {{ .Release.Service  | quote }}
    version: {{ .version | default "base" | quote  }}
spec:
  replicas: {{ default 1 .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ template "kube-integration.fullname" . }}
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
        app: {{ template "kube-integration.fullname" . }}
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
      {{- if .Values.global.hostAliases }}
      hostAliases:
{{ toYaml .Values.global.hostAliases | indent 8 }}
      {{- end }}
      imagePullSecrets:
        - name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}-registry"
      terminationGracePeriodSeconds: 10
      containers:
      - name: {{ template "kube-integration.fullname" . }}
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
        - name: AGENT
          value: {{ .Values.global.agent }}
        # Mode variable to start it as http server
        - name: MODE
          value: "1"
        - name: NODE_ENV
          value: kubernetes
        - name: MONGO_URI
          valueFrom:
            secretKeyRef:
              name: {{ template "kube-integration.fullname" . }}
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
          #value: 'amqp://{{ .Values.global.rabbitmqUsername }}:{{ .Values.global.rabbitmqPassword }}@{{ default (printf "%s-%s" .Release.Name .Values.global.rabbitService) .Values.global.rabbitmqHostname }}'
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
        - name: NEWRELIC_LICENSE_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: newrelic-license-key
        - name: PORT
          value: "{{ .Values.global.kubeIntegrationPort }}"
        - name: SERVICE_NAME
          value: {{ template "kube-integration.name" . }}
        - name: FORMAT_LOGS_TO_ELK
          value: "{{ .Values.formatLogsToElk }}"
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
