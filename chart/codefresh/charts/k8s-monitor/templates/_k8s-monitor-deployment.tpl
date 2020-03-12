{{/*
We create Deployment resource as template to be able to use many deployments but with 
different name and version. This is for Istio POC.
*/}}
{{- define "k8s-monitor.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "k8s-monitor.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "k8s-monitor.fullname" . }}
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
      app: {{ template "k8s-monitor.fullname" . }}
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
        app: {{ template "k8s-monitor.fullname" . }}
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
      terminationGracePeriodSeconds: 10
      containers:
      - name: {{ template "k8s-monitor.fullname" . }}
        {{- if .Values.global.privateRegistry }}
        image: "{{ .Values.global.dockerRegistry }}{{ .Values.image }}:{{ .Values.imageTag }}"
        {{- else }}
        image: "{{ .Values.dockerRegistry }}{{ .Values.image }}:{{ .Values.imageTag }}"
        {{- end }}
        securityContext:
          allowPrivilegeEscalation: false
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
        - name: NODE_ENV
          value: kubernetes
        - name: PORT
          value: "{{ .Values.targetPort }}"
        - name: MONGO_URI
          valueFrom:
            secretKeyRef:
              name: {{ template "k8s-monitor.fullname" . }}
              key: mongo-uri
        - name: NEWRELIC_LICENSE_KEY
          valueFrom:
            secretKeyRef:
              name: "{{ .Release.Name }}-{{ .Values.global.codefresh }}"
              key: newrelic-license-key
        ports:
        - containerPort: {{ .Values.targetPort }}
          protocol: TCP

        readinessProbe:
          httpGet:
            path: /api/ready
            port: {{ .Values.targetPort }}
          periodSeconds: 10
          successThreshold: 1
          failureThreshold: 3
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
      securityContext:
        runAsNonRoot: true
        runAsGroup: 0
      restartPolicy: Always
{{- end }}
