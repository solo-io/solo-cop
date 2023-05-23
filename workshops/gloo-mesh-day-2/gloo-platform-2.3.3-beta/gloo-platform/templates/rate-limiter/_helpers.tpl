{{- define "rate-limiter.extraLabels" -}}
{{- range $key, $value := $.Values.rateLimiter.extraLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

{{- define "rate-limiter.extraTemplateAnnotations" -}}
{{- range $key, $value := $.Values.rateLimiter.extraTemplateAnnotations }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}