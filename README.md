<div align="center">
  <h1>🚀 Enterprise Homelab: K8s, GitOps & IaC</h1>
  <p><b>Полностью автоматизированная bare-metal лаборатория на архитектуре Zen 5 (9950X3D + 9800X3D)</b></p>

  <!-- Бейджи стека технологий -->
  <img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" />
  <img src="https://img.shields.io/badge/Ansible-000000?style=for-the-badge&logo=ansible&logoColor=white" />
  <img src="https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" />
  <img src="https://img.shields.io/badge/TrueNAS_SCALE-0095D5?style=for-the-badge&logo=truenas&logoColor=white" />
  <img src="https://img.shields.io/badge/OpenWrt-00B5E2?style=for-the-badge&logo=openwrt&logoColor=white" />
  <img src="https://img.shields.io/badge/AMD_Ryzen-ED1C24?style=for-the-badge&logo=amd&logoColor=white" />
</div>

<br>

Данный репозиторий содержит конфигурацию **Infrastructure-as-Code (IaC)** для управления локальным вычислительным кластером. Проект демонстрирует Enterprise-подход: Zero-Touch Provisioning, строгое разделение Compute/Storage слоев и динамическое управление дисками через CSI.

## 🖥️ 1. Вычислительные мощности (Compute)

Вычислительный слой использует KVM/libvirt с прямым пробросом процессора (`host-passthrough`) для максимальной утилизации 3D V-Cache виртуальными машинами Kubernetes.

| Узел | Роль | OS | CPU | RAM | GPU |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Node .22** | Compute / KVM | EndeavourOS (Linux 6.18) | AMD Ryzen 9 **9950X3D** | 64 GB | NVIDIA RTX 4090 |
| **Node .23** | Workstation / KVM | Manjaro (Linux 6.18) | AMD Ryzen 7 **9800X3D** | 32 GB | AMD RX 9070 XT |

## 💽 2. Слой хранения данных (TrueNAS Storage)

Сердце системы хранения — узел **Node .30** на базе AMD Ryzen 7 **9700X** (32 GB RAM) под управлением **TrueNAS SCALE 25.10.1**. 

Интеграция с Kubernetes выполнена через драйвер `democratic-csi`, который автоматически нарезает ZFS-датасеты и раздает их подам по протоколу iSCSI. Дисковая подсистема разделена на 2 основных ZFS-пула:

| Пул ZFS | Объем | Назначение и Датасеты |
| :--- | :--- | :--- |
| ⚡ **NVME** | ~ 1 TB | **Tier-1 Storage:** Базы данных, кэш и Persistent Volumes для K8s (`NVME/k8s-vols`). Обеспечивает максимальный IOPS для подов. |
| 🗄️ **RAID5** | ~ 5.15 TB | **Tier-2 Storage:** Файловое хранилище, тяжелые медиаданные (`RAID5/media`) и S3-бакет для резервного копирования Restic (`RAID5/s3-backups`). |

## 🌐 3. Сеть и Маршрутизация (OpenWrt)

Сетевая связность и IPAM управляются шлюзом **Xiaomi AX3600** (OpenWrt 24.10.3).
*   **DHCP/DNS:** Жесткие MAC-привязки для узлов `.22`, `.23` и `.30`.
*   **Load Balancing (K8s):** Выделенный L2-пул MetalLB `192.168.1.200-239` для балансировки входящего трафика сервисов.
*   **Firewall & DNAT:** Проброс портов на Nginx Proxy Manager (80/443 -> 30021/30022), RDP и RustDesk.

## 🛠️ 4. Жизненный цикл (Zero-Touch Provisioning)

Единой точкой входа для автоматизации является `Makefile`. Terraform и Ansible работают бесшовно благодаря динамической генерации `inventory`-файлов.

` ` `bash
# Разворачивает KVM-машины, генерирует инвентарь и накатывает Kubernetes + CSI
make all

# Удалить стенд (Terraform destroy + очистка PVC)
make down

# Управление питанием нод
make vm-status
make vm-start
` ` `

## 🗺️ 5. Планы развития (Roadmap)

Подробный план развития инфраструктуры, включая задачи по миграции сервисов, внедрению CI/CD (GitLab) и развертыванию AI-стека (Ollama/DeepSeek) с пробросом GPU, задокументирован отдельно.

👉 **[Ознакомиться с Roadmap проекта](./ROADMAP.md)**
