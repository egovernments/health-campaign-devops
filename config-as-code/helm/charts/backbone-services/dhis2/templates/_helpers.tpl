{{/*
Expand the name of the chart.
*/}}
{{- define "dhis2-core-helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dhis2-core-helm.fullname" -}}
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
{{- define "dhis2-core-helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dhis2-core-helm.labels" -}}
helm.sh/chart: {{ include "dhis2-core-helm.chart" . }}
{{ include "dhis2-core-helm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dhis2-core-helm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dhis2-core-helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "dhis2-core-helm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dhis2-core-helm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Effective storage type. An explicit storage.type (filesystem, minio or s3) wins; otherwise the
presence of the minIO/S3 blocks decides, preserving the behavior from before storage.type existed.
*/}}
{{- define "dhis2-core-helm.storageType" -}}
{{- $type := default "" .Values.storage.type -}}
{{- if $type -}}
{{- if not (has $type (list "filesystem" "minio" "s3")) -}}
{{- fail (printf "storage.type must be one of filesystem, minio or s3, got %q" $type) -}}
{{- end -}}
{{- $type -}}
{{- else if hasKey .Values "minIO" -}}
minio
{{- else if hasKey .Values "S3" -}}
s3
{{- else -}}
filesystem
{{- end -}}
{{- end }}

{{/*
Database connection settings. An empty database.hostname resolves to the PostgreSQL service
installed next to this chart by the dhis2 umbrella chart. Username, password and database name fall
back to the Bitnami-style global.postgresql.auth values so umbrella consumers set credentials once.
*/}}
{{- define "dhis2-core-helm.databaseHostname" -}}
{{- default (printf "%s-postgresql-rw" (include "dhis2-core-helm.fullname" .)) .Values.database.hostname -}}
{{- end }}

{{- define "dhis2-core-helm.databaseUsername" -}}
{{- coalesce (dig "postgresql" "auth" "username" "" (default dict .Values.global)) .Values.database.username -}}
{{- end }}

{{- define "dhis2-core-helm.databasePassword" -}}
{{- coalesce (dig "postgresql" "auth" "password" "" (default dict .Values.global)) .Values.database.password -}}
{{- end }}

{{- define "dhis2-core-helm.databaseName" -}}
{{- coalesce (dig "postgresql" "auth" "database" "" (default dict .Values.global)) .Values.database.database -}}
{{- end }}

{{/*
MinIO endpoint. An empty minIO.endpoint resolves to the MinIO service installed next to this chart
by the dhis2 umbrella chart.
*/}}
{{- define "dhis2-core-helm.minioEndpoint" -}}
{{- default (printf "http://%s-minio:9000" .Release.Name) .Values.minIO.endpoint -}}
{{- end }}

{{/*
Doris hostname. An empty doris.hostname resolves to the frontend service of the Doris cluster
installed next to this chart when the bundled dorisCluster is enabled.
*/}}
{{- define "dhis2-core-helm.dorisHostname" -}}
{{- if .Values.doris.hostname -}}
{{- .Values.doris.hostname -}}
{{- else if .Values.dorisCluster.enabled -}}
{{- printf "%s-fe-service" .Values.dorisCluster.dorisCluster.name -}}
{{- else -}}
{{- required "doris.hostname is required when doris.enabled is true and dorisCluster.enabled is false" .Values.doris.hostname -}}
{{- end -}}
{{- end }}
