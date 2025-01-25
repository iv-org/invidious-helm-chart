{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "invidious.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "invidious.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "invidious.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "invidious.labels" -}}
helm.sh/chart: {{ include "invidious.chart" . }}
{{ include "invidious.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "invidious.selectorLabels" -}}
app.kubernetes.io/name: {{ include "invidious.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Initialize default values and validate database configuration
*/}}
{{- define "invidious.init-defaults" -}}
    {{/* Set default PostgreSQL host if using in-chart PostgreSQL */}}
    {{- if .Values.postgresql.enabled }}
        {{- if not .Values.config.db.host }}
        {{- $_ := set .Values.config.db "host" (printf "%s-postgresql" .Release.Name) }}
        {{- end }}
    {{- else }}
    {{/* Fail if external database host is not provided when in-chart PostgreSQL is disabled */}}
        {{- if not .Values.config.db.host }}
        {{- fail "config.db.host must be set when postgresql.enabled is false" }}
        {{- end }}
    {{- end }}

    {{/* Set signature server if sighelper is enabled */}}
    {{- if .Values.sighelper.enabled }}
        {{- if not .Values.config.signature_server }}
        {{- $serviceName := printf "%s-sighelper" (include "invidious.fullname" .) }}
        {{- $servicePort := .Values.sighelper.service.port | default 12999 | int }}
        {{- $_ := set .Values.config "signature_server" (printf "%s:%d" $serviceName $servicePort) }}
        {{- end }}
    {{- end }}
{{- end -}}
