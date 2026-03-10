apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: homelab-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "0" # Важно для загрузки больших файлов в Nextcloud
spec:
  ingressClassName: nginx
  rules:
  - host: ${NEXTCLOUD_DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nextcloud-svc
            port:
              number: 80
  - host: ${JELLYFIN_DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: jellyfin-svc
            port:
              number: 8096
