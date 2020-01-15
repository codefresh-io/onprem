{{/*
We create Deployment resource as template to be able to use many deployments but with 
different name and version. This is for Istio POC.
*/}}
{{- define "cfui.renderDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "cfui.fullname" $ }}-{{ .version | default "base" }}
  labels:
    app: {{ template "cfui.fullname" $ }}
    chart: "{{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}"
    release: {{ $.Release.Name  | quote }}
    heritage: {{ $.Release.Service  | quote }}
    version: {{ .version | default "base" | quote  }}
    stable-version: {{ .stableVersion | default "false" | quote  }}
spec:
  replicas: {{ default 1 $.Values.replicaCount }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 50%
      maxSurge: 50%
  selector:
    matchLabels:
      app: {{ template "cfui.fullname" $ }}
  template:
    metadata:      
      {{- if $.Values.redeploy }}
      annotations:        
        forceRedeployUniqId: {{ now | quote }}
        sidecar.istio.io/inject: {{ or $.Values.istio.enabled $.Values.global.istio.enabled  | default false | quote }}
      {{- else }}
      annotations:
        sidecar.istio.io/inject: {{ or $.Values.istio.enabled $.Values.global.istio.enabled  | default false | quote }}
      {{- end }}
      labels:
        app: {{ template "cfui.fullname" $ }}
        chart: "{{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}"
        release: {{ $.Release.Name  | quote }}
        heritage: {{ $.Release.Service  | quote }}
        version: {{ .version | default "base" | quote  }}
        stable-version: {{ .stableVersion | default "false" | quote  }}
    spec:
      affinity:
{{ toYaml (default $.Values.global.appServiceAffinity $.Values.affinity) | indent 8 }}
      imagePullSecrets:
        - name: "{{ template "cfui.fullname" $ }}-registry"
      containers:
      - name: {{ template "cfui.fullname" $ }}
        {{- if $.Values.global.privateRegistry }}          
        image: "{{ $.Values.global.dockerRegistry }}{{ $.Values.image }}:{{ .imageTag }}"
        {{- else }} 
        image: "{{ $.Values.dockerRegistry }}{{ $.Values.image }}:{{ .imageTag }}"
        {{- end }}
        imagePullPolicy: {{ default "" $.Values.imagePullPolicy | quote }}
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
          - name: PORT
            {{- if $.Values.global.maintenanceMode }}
            value: {{ $.Values.global.maintenancePort | quote }}
            {{- else }}
            value: {{ $.Values.port | quote }}
            {{- end }}
          - name: CODEFRESH_API_URL_PREFIEX
            value: "/api"
          - name: CODEFRESH_API_URL_BASE
            value: "{{ $.Values.global.appProtocol }}://{{ .appUrl | default $.Values.global.appUrl }}"
          - name: ROLLBAR_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: {{ template "cfui.fullname" $ }}
                key: rollbar-access-token
          - name: STRIPE_PUBLIC_KEY
            valueFrom:
              secretKeyRef:
                name: {{ template "cfui.fullname" $ }}
                key: stripe-public-key
          # other licenses and keys
          - name: NEWRELIC_LICENSE_KEY
            valueFrom:
              secretKeyRef:
                name: {{ template "cfui.fullname" $ }}
                key: newrelic-license-key
          - name: SEGMENT_KEY
            valueFrom:
              secretKeyRef:
                name: {{ template "cfui.fullname" $ }}
                key: segment-key
          - name: LOGGLY_TOKEN
            valueFrom:
              secretKeyRef:
                name: {{ template "cfui.fullname" $ }}
                key: loggly-token
          - name: SLACK_APP_ID
            valueFrom:
              secretKeyRef:
                name: {{ template "cfui.fullname" $ }}
                key: slack-app-id
          - name: SLACK_REDIRECTURI
            value: "{{ $.Values.global.appProtocol }}://{{ .appUrl | default $.Values.global.appUrl }}/slack-return"
          - name: CF_REGISTRY_DOMAIN
            valueFrom:
              configMapKeyRef:
                name: {{ template "cfui.fullname" $ }}
                key: cfcr-domain
        ports:
        {{- if $.Values.global.maintenanceMode }}
        - containerPort: {{ $.Values.global.maintenancePort }}
        {{- else }}
        - containerPort: {{ $.Values.port }}
        {{- end }}
          protocol: TCP
        {{- if $.Values.global.addResolvConf }}
        volumeMounts:
        - mountPath: /etc/resolv.conf
          name: resolvconf
          subPath: resolv.conf
          readOnly: true
        {{- end }}
{{- if $.Values.global.maintenanceMode }}
{{ toYaml $.Values.global.maintenanceContainer | indent 6 }}
{{- end }}
      volumes:
      {{- if $.Values.global.addResolvConf }}
      - name: resolvconf
        configMap:
          name: {{ $.Release.Name }}-{{ $.Values.global.codefresh }}-resolvconf
      {{- end }}
{{- if $.Values.global.maintenanceMode }}
{{ toYaml $.Values.global.maintenanceVolumes | indent 6 }}
{{- end }}
{{- end }}
