{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "cf-broadcaster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "cf-broadcaster.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
   Create a default fully qualified app name.
   We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
   If release name contains chart name it will be used as a full name.
  */}}
{{- define "cf-broadcaster.fqdn" -}}
  {{- $name := "" -}}
  {{- if $.Values.fullnameOverride -}}
    {{- $name =$.Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- $name = default .Chart.Name .Values.nameOverride -}}
    {{- if contains $name .Release.Name -}}
      {{- $name = .Release.Name | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
      {{- $name = printf "%s-%s" .Release.Name $name -}}
    {{- end -}}
  {{- end -}}
{{- printf "%s.%s.svc.cluster.local" $name .Release.Namespace  | trunc 63 | trimSuffix "-" -}}
{{- end -}}
