{{/*
We create Deployment resource as template to be able to use many deployments but with 
different name and version. This is for Istio POC.
*/}}
{{- define "segment-reporter.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "segment-reporter.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "segment-reporter.fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    release: {{ .Release.Name  | quote }}
    heritage: {{ .Release.Service  | quote }}
    version: {{ .version | default "base" | quote  }}
spec:
  replicas: {{ default 1 .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ template "segment-reporter.fullname" . }}
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
        app: {{ template "segment-reporter.fullname" . }}
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
      - name: {{ template "segment-reporter.fullname" . }}
        image: "{{ .Values.image }}:{{ .imageTag }}"
        imagePullPolicy: {{ default "" .Values.imagePullPolicy | quote }}
        resources:
{{ toYaml .Values.resources | indent 10 }}
        env:
        - name: BL_USERS
          value: {{ .Values.blacklistUsers | quote }}
        - name: NODE_ENV
          value: production
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
        - name: EVENTBUS_INTERVAL
          value: {{ .Values.eventbusInterval | quote }}
        - name: SEGMENT_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: segment-key
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
          failureThreshold: 5
        volumeMounts:
          - name: docker-socket
            mountPath: /var/run/docker.sock
      volumes:
        - name: docker-socket
          hostPath:
            path: /var/run/docker.sock
      restartPolicy: Always
      tolerations:
{{ toYaml (default .Values.global.internalServiceTolerations .Values.tolerations) | indent 6 }}
{{- end }}
