# Enterprise Homelab: Infrastructure as Code & Kubernetes

Данный репозиторий содержит полную конфигурацию Infrastructure-as-Code (IaC) для управления локальным вычислительным кластером и системой хранения данных. Проект демонстрирует применение Enterprise-практик (Zero-Touch Provisioning, GitOps, CSI) в рамках bare-metal инфраструктуры.

## 1. Вычислительные мощности (Compute & Storage)

Архитектура стенда строго разделяет вычислительный слой (Compute) и слой хранения данных (Storage), обеспечивая максимальную производительность для кластера Kubernetes.

| Узел | Роль | OS | CPU | RAM | GPU | Дисковая подсистема |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Node .22** | Compute / KVM | EndeavourOS (Linux 6.18) | AMD Ryzen 9 9950X3D | 64 GB | NVIDIA RTX 4090 | 2TB NVMe (BTRFS) |
| **Node .23** | Workstation / KVM | Manjaro (Linux 6.18) | AMD Ryzen 7 9800X3D | 32 GB | AMD RX 9070 XT | 2TB NVMe (BTRFS) |
| **Node .30** | Storage / iSCSI | TrueNAS SCALE 25.10.1 | AMD Ryzen 7 9700X | 32 GB | - | ZFS: NVME & RAID5 |

*Примечание: Вычислительные узлы используют KVM/libvirt. Конфигурация виртуальных машин Terraform (`host-passthrough`) позволяет гостевым ОС получать прямой доступ к 3D V-Cache процессоров AMD.*

## 2. Сетевая инфраструктура и Маршрутизация

Сетевой слой управляется маршрутизатором **Xiaomi AX3600** под управлением **OpenWrt 24.10.3** (Linux 6.6.104).

*   **DHCP & IPAM:** Служба `dnsmasq` обеспечивает статическую привязку IP-адресов по MAC-адресам для базовой инфраструктуры: `compute-9950x` (192.168.1.22), `workstation-9800x` (192.168.1.23) и `truenas-core` (192.168.1.30).
*   **Load Balancing:** Внутри Kubernetes маршрутизация трафика обеспечивается контроллером **MetalLB** с выделенным пулом адресов L2 (`192.168.1.200-192.168.1.239`).
*   **Firewall & DNAT:** Настроены правила проброса портов (Port Forwarding) из WAN для RDP (3389), RustDesk (21115-21119) и балансировщика Nginx Proxy Manager (80/443 -> 30021/30022).

## 3. Стек технологий

*   **Infrastructure as Code:** Terraform (управление KVM-доменами).
*   **Configuration Management:** Ansible (подготовка узлов, настройка Cgroups/Containerd, генерация секретов).
*   **Kubernetes Stack:** v1.31, Flannel CNI, Helm.
*   **Storage (CSI):** `democratic-csi` интегрирован с TrueNAS API. Обеспечивает динамический провижининг iSCSI таргетов и ZFS датасетов напрямую в поды (PVC).
*   **Резервное копирование:** Restic (с шифрованием и дедупликацией), бэкапы отправляются в S3-совместимое хранилище на TrueNAS.

## 4. Жизненный цикл и Развертывание (Zero-Touch)

Единой точкой входа для управления инфраструктурой является `Makefile`. Процесс развертывания полностью автоматизирован и не требует ручного вмешательства (Zero-Touch Provisioning).

` ` `bash
# Разворачивает виртуальные машины, генерирует динамический inventory,
# инициализирует кластер K8s, подключает worker-узлы и деплоит CSI драйвер.
make all

# Полное удаление стенда (Terraform destroy + очистка PVC)
make down

# Мониторинг состояния гипервизоров и перезапуск узлов
make vm-status
make vm-start
` ` `

Взаимодействие между Terraform и Ansible реализовано бесшовно через динамическую генерацию файла инвентаризации ресурсом `local_file` (шаблонизация актуальных IP-адресов K8s-узлов).

## 5. Roadmap и Архитектурные планы

1.  **Миграция Storage-слоя:** Полный отказ от встроенных приложений (`.ix-apps`) на TrueNAS для высвобождения 32 ГБ оперативной памяти под ZFS ARC (кэш чтения). Перенос баз данных и приложений (Nextcloud, Jellyfin) в поды Kubernetes.
2.  **CI/CD Pipeline:** Настройка выделенного сервера `gitlab-srv` (уже инициализирован через Terraform) и перенос запуска `ansible-playbook` и `terraform apply` внутрь GitLab Runners.
3.  **Логирование и Мониторинг:** Исправление Race Condition в назначении LoadBalancer IP для сервиса Loki (переход от хардкода адреса `.206` к аннотациям MetalLB).
4.  **Hardware AI-Stack:** Внедрение Kubernetes Device Plugins для проброса NVIDIA RTX 4090 и AMD RX 9070 XT внутрь контейнеров с целью локального развертывания LLM (DeepSeek-R1 / Ollama).
