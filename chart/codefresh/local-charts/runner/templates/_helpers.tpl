{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Calculates Existing pvc name
*/}}
{{- define "runner.existingPvc" -}}
{{- $existingPvc := coalesce .Values.existingPvc .Values.existingClaim .Values.pvcName .Values.varLibDockerVolume.existingPvc | default "" -}}
{{- printf "%s" $existingPvc -}}
{{- end -}}

{{/*
Calculates storage class name
*/}}
{{- define "runner.storageClass" -}}
{{- $storageClass := coalesce .Values.storageClass .Values.StorageClass .Values.varLibDockerVolume.storageClass .Values.global.storageClass | default "" -}}
{{- printf "%s" $storageClass -}}
{{- end -}}

{{/*
Calculates storage size
*/}}

{{- define "runner.storageSize" -}}
{{- $storageSize := coalesce .Values.storageSize .Values.varLibDockerVolume.storageSize .Values.varLibDockerVolume.size -}}
{{- printf "%s" $storageSize -}}
{{- end -}}