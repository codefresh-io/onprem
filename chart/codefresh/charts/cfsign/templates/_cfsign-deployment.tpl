{{/*
We create Deployment resource as template to be able to use many deployments but with 
different name and version. This is for Istio POC.
*/}}
{{- define "cfsign.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "cfsign.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "cfsign.fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    release: {{ .Release.Name  | quote }}
    heritage: {{ .Release.Service  | quote }}
    version: {{ .version | default "base" | quote  }}
spec:
  replicas: {{ default 1 .Values.replicaCount }}
  revisionHistoryLimit: 50
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: {{ template "cfsign.fullname" . }}
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
        app: {{ template "cfsign.fullname" . }}
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
      - name: {{ template "cfsign.fullname" . }}
        {{- if .Values.global.privateRegistry }}
        image: "{{ .Values.global.dockerRegistry }}{{ .Values.image }}:{{ .imageTag }}"
        {{- else }}
        image: "{{ .Values.dockerRegistry }}{{ .Values.image }}:{{ .imageTag }}"
        {{- end }}
        imagePullPolicy: {{ default "" .Values.imagePullPolicy | quote }}
        resources:
{{ toYaml .Values.resources | indent 10 }}
        ports:
          - containerPort: {{ .Values.port }}
            protocol: TCP
        volumeMounts:
        {{- if .Values.global.onprem }}
        - mountPath: /cacerts/cf-ca.pem
          name: cf-ca
          subPath: ca.pem
        - mountPath: /cacerts/cf-ca-key.pem
          name: cf-ca
          subPath: ca-key.pem
        {{- else }}
        - mountPath: /cacerts
          name: cf-ca
        {{- end }}
        - mountPath: /certs
          name: certs-data
      restartPolicy: Always
      volumes:
      - name: cf-ca
        secret:
        {{- if .Values.global.onprem }}
          secretName: cf-codefresh-certs-client
        {{- else }}
          secretName: {{ template "cfsign.fullname" . }}
        {{- end }}
      - name: certs-data
        {{- if not .Values.global.onprem }}
        persistentVolumeClaim:
          claimName: {{ template "cfsign.fullname" . }}
        {{- end }}
{{- end }}
