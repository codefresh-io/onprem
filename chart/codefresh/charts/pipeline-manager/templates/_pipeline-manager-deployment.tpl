{{/*
We create Deployment resource as template to be able to use many deployments but with 
different name and version. This is for Istio POC.
*/}}
{{- define "pipeline.manager.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "pipeline.manager.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "pipeline.manager.fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    release: {{ .Release.Name  | quote }}
    heritage: {{ .Release.Service  | quote }}
    version: {{ .version | default "base" | quote  }}
    test: value
spec:
  replicas: {{ default 1 .Values.replicaCount }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 50%
      maxSurge: 50%
  selector:
    matchLabels:
      app: {{ template "pipeline.manager.fullname" . }}
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
        app: {{ template "pipeline.manager.fullname" . }}
        chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
        release: {{ .Release.Name  | quote }}
        heritage: {{ .Release.Service  | quote }}
        version: {{ .version | default "base" | quote  }}
    spec:
      {{- if not .Values.global.devEnvironment }}
      {{- $podSecurityContext := (kindIs "invalid" .Values.global.podSecurityContextOverride) | ternary .Values.podSecurityContext .Values.global.podSecurityContextOverride }}
      {{- with $podSecurityContext }}
      securityContext:
{{ toYaml . | indent 8}}
      {{- end }}
      {{- end }}
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
      terminationGracePeriodSeconds: 10
      containers:
      - name: {{ template "pipeline.manager.fullname" . }}
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
        {{- range $key, $value := .Values.env }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end }}
        - name: NODE_ENV
          value: kubernetes
        - name: MONGO_URI
          valueFrom:
            secretKeyRef:
              name: {{ template "pipeline.manager.fullname" . }}
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
              name: {{ template "pipeline.manager.fullname" . }}
              key: safe-secret
        {{- if .Values.stepsCatalogEnabled }}
        - name: STEPS_CATALOG_ENABLED
          value: "true"
        - name: STEPS_CATALOG_GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: {{ template "pipeline.manager.fullname" . }}
              key: steps-catalog-github-token
        {{- end}}
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
        - name: REDIS_URL
          value: {{ default (printf "%s-%s" .Release.Name .Values.global.redisService) .Values.global.redisUrl }}
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: redis-password
        - name: PORT
          value: "{{ .Values.global.pipelineManagerPort }}"
        - name: SERVICE_NAME
          value: {{ template "pipeline.manager.name" . }}
        - name: FORMAT_LOGS_TO_ELK
          value: "{{ .Values.formatLogsToElk }}"
        - name: API_URI
          value: "{{ .Release.Name }}-{{ .Values.global.cfapiService }}"
        - name: API_PORT
          value: {{ .Values.global.cfapiInternalPort | quote }}
        - name: CONTEXT_MANAGER_URI
          value: "{{ .Release.Name }}-{{ .Values.global.contextManagerService }}"
        - name: CONTEXT_MANAGER_PORT
          value: {{ .Values.global.contextManagerPort | quote }}
        - name: RUNTIME_ENVIRONMENT_MANAGER_URI
          value: "{{ .Release.Name }}-{{ .Values.global.runtimeEnvironmentManagerService }}"
        - name: RUNTIME_ENVIRONMENT_MANAGER_PORT
          value: {{ .Values.global.runtimeEnvironmentManagerPort | quote }}
        - name: STEPS_CATALOG_ON_PREMISE
          value: {{ .Values.global.stepsCatalogOnPremise | quote }}
        ports:
        - containerPort: {{ .Values.targetPort }}
          protocol: TCP
        readinessProbe:
          httpGet:
            path: /api/ready
            port: {{ .Values.targetPort }}
          periodSeconds: 5
          successThreshold: 1
          failureThreshold: 2
          timeoutSeconds: 10

        livenessProbe:
          httpGet:
            path: /api/health
            port: {{ .Values.targetPort }}
          periodSeconds: 50
          successThreshold: 1
          failureThreshold: 3
          initialDelaySeconds: 30
          timeoutSeconds: 10


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