{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "consul.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "consul.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Calculates Existing pvc name
*/}}
{{- define "consul.existingPvc" -}}
{{- $existingPvc := coalesce .Values.existingPvc .Values.existingClaim .Values.pvcName .Values.persistence.existingClaim | default "" -}}
{{- printf "%s" $existingPvc -}}
{{- end -}}


{{/*
Calculates storage class name
*/}}
{{- define "consul.storageClass" -}}
{{- $storageClass := coalesce .Values.storageClass .Values.StorageClass .Values.persistence.storageClass .Values.global.storageClass | default "" -}}
{{- printf "%s" $storageClass -}}
{{- end -}}

{{/*
Calculates storage size
*/}}
{{- define "consul.storageSize" -}}
{{- $storageSize := coalesce .Values.storageSize .Values.persistence.size .Values.Storage -}}
{{- printf "%s" $storageSize -}}
{{- end -}}