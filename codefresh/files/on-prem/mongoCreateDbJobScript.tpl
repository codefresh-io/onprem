{{- if .Values.global.seedJobs }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "fullname" . }}-template
  labels:
    app: {{ template "fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    release: {{ .Release.Name  | quote }}
    heritage: {{ .Release.Service  | quote }}
spec:
  template:
    metadata:
      name: {{ template "fullname" . }}-template
      labels:
        app: {{ template "fullname" . }}
        chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
        release: {{ .Release.Name  | quote }}
        heritage: {{ .Release.Service  | quote }}
    spec:
      containers:
      - name: {{ template "fullname" . }}-dbname
        image: {{ .Values.mongodbImage }}
        imagePullPolicy: IfNotPresent
        env:
          - name: MONGODB_ROOT_PASSWORD
            value: {{ .Values.mongodb.mongodbRootPassword }}
          - name: MONGODB_ADDRESS
            value: {{ .Release.Name }}-{{ .Values.global.mongoService }}:{{ .Values.global.mongoPort }}
          - name: MONGODB_DATABASE
            value: {{ .Values.global.AnydbDatabase }}
          - name: MONGODB_USER
            value: {{ .Values.global.mongodbUsername }}
          - name: MONGODB_PASSWORD
            value: {{ .Values.global.mongodbPassword }}
        command:
          - "/bin/bash"
          - "-exc"
          - |
{{ .Files.Get (print .Values.mongoCreateDbJobScript ) | indent 12  }}
{{- end }}
