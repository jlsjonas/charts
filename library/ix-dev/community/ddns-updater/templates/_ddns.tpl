{{- define "ddns.workload" -}}
workload:
  ddns:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.ddnsNetwork.hostNetwork }}
      containers:
        ddns:
          enabled: true
          primary: true
          imageSelector: image
          securityContext:
            runAsUser: {{ .Values.ddnsRunAs.user }}
            runAsGroup: {{ .Values.ddnsRunAs.group }}
          env:
            LISTENING_PORT: {{ .Values.ddnsNetwork.webPort }}
            DATADIR: /updater/data
            BACKUP_DIRECTORY: /updater/data/backup
          envFrom:
            - configMapRef:
                name: ddns-config
          envList:
          {{ with .Values.ddnsConfig.additionalEnvs }}
            {{ range $env := . }}
            {{ $env.name }}: {{ $env.value }}
            {{ end }}
          {{ end }}
          probes:
            liveness:
              enabled: true
              type: exec
              command:
                - /updater/app
                - healthcheck
            readiness:
              enabled: true
              type: exec
              command:
                - /updater/app
                - healthcheck
            startup:
              enabled: true
              type: exec
              command:
                - /updater/app
                - healthcheck
      initContainers:
      {{- include "ix.v1.common.app.permissions" (dict "containerName" "01-permissions"
                                                        "UID" .Values.ddnsRunAs.user
                                                        "GID" .Values.ddnsRunAs.group
                                                        "mode" "check"
                                                        "type" "init") | nindent 8 }}

{{/* Service */}}
service:
  ddns:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: ddns
    ports:
      webui:
        enabled: true
        primary: true
        port: {{ .Values.ddnsNetwork.webPort }}
        nodePort: {{ .Values.ddnsNetwork.webPort }}
        targetSelector: ddns

{{/* Persistence */}}
persistence:
  data:
    enabled: true
    type: {{ .Values.ddnsStorage.data.type }}
    datasetName: {{ .Values.ddnsStorage.data.datasetName | default "" }}
    hostPath: {{ .Values.ddnsStorage.data.hostPath | default "" }}
    targetSelector:
      ddns:
        ddns:
          mountPath: /updater/data
        01-permissions:
          mountPath: /mnt/directories/data
{{- end -}}
