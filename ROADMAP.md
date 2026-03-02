# 🗺 Homelab Roadmap: The X3D Sovereign

## ✅ Phase 1: Foundation (Completed)
- [cite_start]**Compute:** Автоматизация ВМ на Ryzen 9950X3D/9800X3D[cite: 30, 446].
- [cite_start]**Network:** MetalLB для управления локальными IP сервисов[cite: 3, 395].
- [cite_start]**Storage:** TrueNAS SCALE + iSCSI Democratic CSI[cite: 3, 411, 416].
- [cite_start]**Core Services:** Nextcloud, Jellyfin и Speedtest[cite: 387, 389, 391].

## 🔄 Phase 2: Observability & Protection (Active)
- [cite_start]**Monitoring:** Prometheus, Grafana и алерты в Telegram[cite: 16, 429].
- [cite_start]**Backup:** Безопасный бэкап GitLab в S3 через Restic + Vault[cite: 83, 91, 430].
- [ ] **Loki Stack:** Централизованный сбор логов со всех подов и нод.
- [ ] **Velero:** Снапшоты всего K8s кластера в S3 на TrueNAS.

## 🚀 Phase 3: Connectivity & CI/CD (Upcoming)
- [ ] **Ingress Nginx:** Установка контроллера для управления трафиком по домену.
- [ ] **Cert-Manager:** Автоматическое получение SSL сертификатов Let's Encrypt.
- [ ] **Headscale:** Развертывание собственной Mesh-сети (Self-hosted Tailscale).
- [ ] **GitLab CI/CD:** Настройка раннеров для авто-деплоя.

## 🧠 Phase 4: Advanced Tech (Long-term)
- [ ] **GPU Passthrough:** Проброс видеокарт в K8s для Ollama и DeepSeek-R1.
- [ ] **External Secrets:** Синхронизация паролей из Vault в K8s Secrets.
- [ ] **Local AI:** Интеграция LLM в домашнюю автоматизацию.
