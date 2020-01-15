{{/*
   genreate global istio virtual service according to host name
*/}}
{{- define "cfui.renderGlobalVirtualServiceByHost" -}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: {{ template "cfui.fullname" $ }}-{{ .version | replace "." "-"}}
spec:
  hosts:
  - {{ .appUrl }}
  gateways:
  - {{ template "cfui.fullname" $ }}
  http:
    - match:
        - uri:
            prefix: /nomios
      route:
        - destination:
            host: {{- printf " %s-nomios.%s.svc.cluster.local" $.Release.Name $.Release.Namespace  | trunc 63 | trimSuffix "-" }}
            port:
              number: 80
            subset: {{ .nomiosVersion | replace "." "-" }}
          headers:
            request:
              add:
                x-codefresh-version: {{ .nomiosVersion | replace "." "-" }}
    - match:
        - uri:
            prefix: /ws
        - uri:
            prefix: /api
      route:
        - destination:
            host: {{- printf " %s-cfapi.%s.svc.cluster.local" $.Release.Name $.Release.Namespace  | trunc 63 | trimSuffix "-" }}
            port:
              number: 80
            subset: {{ .cfapiVersion | replace "." "-" }}
          headers:
            request:
              add:
                x-codefresh-version: {{ .cfapiVersion | replace "." "-" }}
    - route:
        - destination:
            host: {{- printf " %s-cfui.%s.svc.cluster.local" $.Release.Name $.Release.Namespace  | trunc 63 | trimSuffix "-" }}
            port:
              number: 80
            subset: {{ .cfuiVersion | replace "." "-" }}
          headers:
            request:
              add:
                x-codefresh-version: {{ .cfuiVersion | replace "." "-" }}
{{- end }}
