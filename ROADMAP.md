# 🗺️ Roadmap: Kirill-Andreevich-Lab

## ✅ Phase 1: Инфраструктура
- [x] Terraform: Развертывание K8s Master и Workers (QEMU/KVM + Ubuntu 24.04).
- [x] Cloud-init: Статичные IP (Netplan) без DHCP-сюрпризов.
- [x] Ansible: Подготовка узлов, настройка iSCSI/Multipath.

## ✅ Phase 2: K8s Core & Storage
- [x] Kubeadm: Инициализация кластера v1.31, сеть Flannel.
- [x] Helm: Установка Democratic CSI (TrueNAS API v2.0).
- [x] Security: Секреты (API Keys, SSH) вынесены в отдельный `zfs-iscsi-secrets.yaml` и скрыты из Git.
- [x] Storage: Динамический провижининг iSCSI (ZVOL) работает корректно (Binding).

## 🔄 Phase 3: Приложения ("Бессмертные" поды)
- [x] Nextcloud: Deployment + iSCSI PVC.
- [x] Jellyfin: Deployment + iSCSI PVC (настройки и база).
- [x] Speedtest: Stateless Deployment.
- [ ] Jellyfin: Подключение тяжелой медиатеки через NFS/SMB (ReadWriteMany).
- [ ] Ingress Controller & Cert-Manager (TLS терминация).

## 📅 Phase 4: AI & Автоматизация
- [ ] Развертывание GitLab Server (Libvirt VM).
- [ ] Ollama + DeepSeek-R1 (Проброс GPU).

## 🛠 Технический долг (Tech Debt) & Рефакторинг
- [ ] **Makefile:** Разбить монолитный `make all` на независимые этапы (`make infra`, `make k8s`, `make storage`, `make apps`).
- [ ] **Синхронизация деплоя:** Заменить жесткие `sleep` на умные `kubectl wait`. Сейчас из-за асинхронности K8s и таймаутов TrueNAS команду `make all` при развороте с нуля приходится запускать 3 раза.
