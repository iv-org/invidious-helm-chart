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
    {{- $databaseUrl := .Values.config.database_url | default "" }}
    {{- $db := .Values.config.db | default dict }}

    {{/* config.database_url and config.db are mutually exclusive.
         An explicit `db: null` counts as unset, so that users can clear
         the key from their values file when switching to database_url. */}}
    {{- if and $databaseUrl (kindIs "map" (get .Values.config "db")) }}
    {{- fail "use either config.database_url or config.db, not both" }}
    {{- end }}

    {{- if $databaseUrl }}
    {{/* database_url takes precedence over db, matching upstream Invidious behavior */}}
    {{- $_ := unset .Values.config "db" }}
    {{- else }}
    {{/* database_url is not used, so don't render an empty value for it */}}
    {{- $_ := unset .Values.config "database_url" }}

        {{- if not $db }}
        {{- $_ := set .Values.config "db" dict }}
        {{- end }}

        {{/* Treat explicitly empty values (e.g. `port: ""`) as missing */}}
        {{- range $key, $value := .Values.config.db }}
        {{- if not $value }}
        {{- $_ := unset $.Values.config.db $key }}
        {{- end }}
        {{- end }}

        {{/* Set default PostgreSQL host if using in-chart PostgreSQL */}}
        {{- if .Values.postgresql.enabled }}
            {{- if not (hasKey .Values.config.db "host") }}
            {{- $_ := set .Values.config.db "host" (printf "%s-postgresql" .Release.Name) }}
            {{- end }}
            {{- if not (hasKey .Values.config.db "user") }}
            {{- $_ := set .Values.config.db "user" .Values.postgresql.auth.username }}
            {{- end }}
            {{- if not (hasKey .Values.config.db "password") }}
            {{- $_ := set .Values.config.db "password" .Values.postgresql.auth.password }}
            {{- end }}
            {{- if not (hasKey .Values.config.db "dbname") }}
            {{- $_ := set .Values.config.db "dbname" .Values.postgresql.auth.database }}
            {{- end }}
        {{- else }}
        {{/* Fail if external database settings are incomplete */}}
            {{- $missing := list }}
            {{- range $key := list "user" "password" "host" "dbname" }}
            {{- if not (hasKey $.Values.config.db $key) }}
            {{- $missing = append $missing $key }}
            {{- end }}
            {{- end }}
            {{- if $missing }}
            {{- fail (printf "config.db must contain %s when postgresql.enabled is false, or use config.database_url instead" (join ", " $missing)) }}
            {{- end }}
        {{- end }}

        {{- if not (hasKey .Values.config.db "port") }}
        {{- $_ := set .Values.config.db "port" 5432 }}
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

    {{/* Default invidious_companion config if companion sidecar is enabled */}}
    {{- if .Values.companion.enabled }}
        {{- $companion := dict }}
        {{- if .Values.config.invidious_companion }}
        {{- $companion = index .Values.config.invidious_companion 0 }}
        {{- end }}
        {{- if not $companion.private_url }}
        {{- $_ := set $companion "private_url" "http://localhost:8282/companion" }}
        {{- end }}
        {{- if and (not $companion.public_url) .Values.companion.ingress.enabled .Values.companion.ingress.hosts }}
        {{- $scheme := ternary "https" "http" (not (empty .Values.companion.ingress.tls)) }}
        {{- $host := (index .Values.companion.ingress.hosts 0).host }}
        {{- $_ := set $companion "public_url" (printf "%s://%s/companion" $scheme $host) }}
        {{- end }}
        {{- $_ := set .Values.config "invidious_companion" (list $companion) }}
        {{- if not (regexMatch "^[a-zA-Z0-9]{16}$" .Values.companion.secretKey) }}
        {{- fail "companion.secretKey is required when companion.enabled=true and must be exactly 16 alphanumeric characters (e.g. 'pwgen 16 1')" }}
        {{- end }}
        {{- if and .Values.config.invidious_companion_key (ne .Values.config.invidious_companion_key .Values.companion.secretKey) }}
        {{- fail "config.invidious_companion_key and companion.secretKey must match; set only companion.secretKey" }}
        {{- end }}
        {{- $_ := set .Values.config "invidious_companion_key" .Values.companion.secretKey }}
    {{- end }}
{{- end -}}
