{{- define "webdav.workload" -}}
workload:
  webdav:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.webdavNetwork.hostNetwork }}
      containers:
        webdav:
          enabled: true
          primary: true
          imageSelector: image
          securityContext:
            runAsUser: {{ .Values.webdavRunAs.user }}
            runAsGroup: {{ .Values.webdavRunAs.group }}
          env:
          envList:
          {{ with .Values.webdavConfig.additionalEnvs }}
            {{ range $env := . }}
            - name: {{ $env.name }}
              value: {{ $env.value }}
            {{ end }}
          {{ end }}
          probes:
            liveness:
              enabled: true
              path: /health
              port: "{{ .Values.webdavNetwork.httpPort }}"
            readiness:
              enabled: true
              path: /health
              port: "{{ .Values.webdavNetwork.httpPort }}"
            startup:
              enabled: true
              path: /health
              port: "{{ .Values.webdavNetwork.httpPort }}"
      initContainers:
      {{- include "ix.v1.common.app.permissions" (dict "containerName" "01-permissions"
                                                        "UID" .Values.webdavRunAs.user
                                                        "GID" .Values.webdavRunAs.group
                                                        "mode" "check"
                                                        "type" "init") | nindent 8 }}

{{/* Service */}}
service:
  webdav:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: webdav
    ports:
      http:
        enabled: true
        primary: true
        port: {{ .Values.webdavNetwork.httpPort }}
        nodePort: {{ .Values.webdavNetwork.httpPort }}
        targetSelector: webdav
      https:
        enabled: {{ ne (int .Values.webdavNetwork.cerfiticateID) 0 }}
        port: {{ .Values.webdavNetwork.httpsPort }}
        nodePort: {{ .Values.webdavNetwork.httpsPort }}
        targetSelector: webdav

{{/* Persistence */}}
persistence:
  httpd-conf:
    enabled: true
    type: configmap
    objectName: config
    targetSelector:
      webdav:
        webdav:
          mountPath: /usr/local/apache2/conf/httpd.conf
          subPath: httpd.conf
  webdav-conf:
    enabled: true
    type: configmap
    objectName: config
    targetSelector:
      webdav:
        webdav:
          mountPath: /usr/local/apache2/conf/Includes/webdav.conf
          subPath: webdav.conf
  # TODO: Do we want persistency for logs (error/access)? (/var/log)
  varlogs:
    enabled: true
    type: emptyDir
    medium: Memory
    targetSelector:
      webdav:
        webdav:
          mountPath: /var/log
  apachelogs:
    enabled: true
    type: emptyDir
    medium: Memory
    targetSelector:
      webdav:
        webdav:
          mountPath: /usr/local/apache2/logs
{{/*
  config:
    enabled: true
    type: {{ .Values.lidarrStorage.config.type }}
    datasetName: {{ .Values.lidarrStorage.config.datasetName | default "" }}
    hostPath: {{ .Values.lidarrStorage.config.hostPath | default "" }}
    targetSelector:
      lidarr:
        lidarr:
          mountPath: /config
        01-permissions:
          mountPath: /mnt/directories/config
  {{- range $idx, $storage := .Values.lidarrStorage.additionalStorages }}
  {{ printf "lidarr-%v" (int $idx) }}:
    enabled: true
    type: {{ $storage.type }}
    datasetName: {{ $storage.datasetName | default "" }}
    hostPath: {{ $storage.hostPath | default "" }}
    targetSelector:
      lidarr:
        lidarr:
          mountPath: {{ $storage.mountPath }}
        01-permissions:
          mountPath: /mnt/directories{{ $storage.mountPath }}
  {{- end }}*/}}
{{- end -}}
