{{- define "healthcheck" }}
#!/bin/sh

reply_external=$(curl -o /dev/null --silent --head --write-out "%{http_code}" http://localhost:{{ $.Values.targetPort }}/api/ping)
reply_internal=$(curl -o /dev/null --silent --head --write-out "%{http_code}" http://localhost:{{ $.Values.targetInternalPort }}/api/ping)
if [ "${reply_external}" != 200 -o "${reply_internal}" != 200 ] ;then
	curl -I http://localhost:{{ $.Values.targetPort }}/api/ping
	curl -I http://localhost:{{ $.Values.targetInternalPort }}/api/ping
	exit 1
else
	echo OK
fi
{{- end }}