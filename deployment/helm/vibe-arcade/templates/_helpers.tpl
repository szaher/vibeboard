{{/*
Expand the name of the chart.
*/}}
{{- define "vibe-arcade.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vibe-arcade.fullname" -}}
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
{{- define "vibe-arcade.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vibe-arcade.labels" -}}
helm.sh/chart: {{ include "vibe-arcade.chart" . }}
{{ include "vibe-arcade.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vibe-arcade.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vibe-arcade.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vibe-arcade.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "vibe-arcade.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the PostgreSQL service
*/}}
{{- define "vibe-arcade.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "vibe-arcade.fullname" .) }}
{{- end }}

{{/*
Create the name of the Redis service
*/}}
{{- define "vibe-arcade.redis.fullname" -}}
{{- printf "%s-redis" (include "vibe-arcade.fullname" .) }}
{{- end }}