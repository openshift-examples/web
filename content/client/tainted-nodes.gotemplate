{{- /* YAML that we're looking for
  spec:
    taints:
    - effect: NoSchedule
      key: app
      value: myapp
*/ -}}

{{- define "node-details" -}}
    {{- if $taints := (index .spec "taints") -}}
        {{- println "NODE:" .metadata.name -}}
        {{- println "TAINTS:" -}}
        {{- range $taints -}}
            {{- println " " "Key:" .key -}}
            {{- println " " "Value:" .value -}}
            {{- println " " "Effect:" .effect -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

{{- block "tainted-nodes" . -}}
    {{- if eq .kind "List" -}}
        {{- range .items -}}
            {{- template "node-details" . -}}
        {{- end -}}
    {{- else -}}
        {{- template "node-details" . -}}
    {{- end -}}
{{- end -}}