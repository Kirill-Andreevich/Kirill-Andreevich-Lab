<div align="center">
  <h1>🚀 Enterprise Homelab: DevOps & SRE Sandbox</h1>
  <p><b>Инженерный полигон для отработки навыков IaC, GitOps, кластеризации и управления инфраструктурой на базе архитектуры Zen 5.</b></p>

  <img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" />
  <img src="https://img.shields.io/badge/Ansible-000000?style=for-the-badge&logo=ansible&logoColor=white" />
  <img src="https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" />
  <img src="https://img.shields.io/badge/TrueNAS_SCALE-0095D5?style=for-the-badge&logo=truenas&logoColor=white" />
  <img src="https://img.shields.io/badge/OpenWrt-00B5E2?style=for-the-badge&logo=openwrt&logoColor=white" />
</div>

<br>

## 🎯 Цель проекта
Данный репозиторий — это лабораторный стенд для прокачки hard-skills DevOps инженера. Он описывает полностью автоматизированный процесс создания вычислительного кластера, начиная от разметки "голого" железа и заканчивая динамическим выделением томов хранения.

## ✨ Что умеет данный код (Возможности)

Весь цикл развертывания инфраструктуры полностью автоматизирован (Zero-Touch Provisioning). На данный момент кодовая база умеет:

*   **Полная автоматизация виртуализации (IaC):** Terraform изолированно поднимает KVM-машины (Master, Workers, GitLab) с прямым пробросом процессора (`host-passthrough`), используя модульную архитектуру и раздельные стейты.
*   **Динамическая инвентаризация:** Terraform "на лету" генерирует файл `hosts.ini`, передавая Ansible актуальные IP-адреса свежесозданных виртуальных машин.
*   **Bootstrap кластера Kubernetes (v1.31):** Ansible самостоятельно подготавливает ноды (настраивает Containerd и SystemdCgroup), инициализирует master-узел, генерирует токены и бесшовно подключает worker-узлы.
*   **Сетевая фабрика и балансировка (MetalLB):** Развертывание Flannel CNI и настройка MetalLB (L2 Advertisement) для автоматической выдачи статических IP-адресов сервисам из пула `192.168.1.200-239`.
*   **Enterprise Storage Provisioning (CSI):** Глубокая интеграция кластера с TrueNAS SCALE через `democratic-csi`. Кластер общается с NAS по API, автоматически нарезает ZFS-датасеты и презентует их подам по протоколу iSCSI без ручного вмешательства.
*   **Резервное копирование (Restic):** Скрипты для создания инкрементальных S3-бэкапов с дедупликацией в бакет `homelab-backups` на TrueNAS.
*   **Мониторинг и Алертинг:** Развернут стек сбора логов (Promtail + Loki) с кастомными правилами Prometheus (например, мониторинг температуры процессоров и потребления ОЗУ с отправкой алертов в Telegram).
*   **Безопасное управление секретами:** Все пароли и доступы (iSCSI, S3, Alertmanager) надежно зашифрованы с помощью Ansible Vault и шаблонизируются через Jinja2 прямо перед деплоем.

## 🖥️ Аппаратная архитектура (Compute & Storage)

Инфраструктура строго разделяет вычислительный слой и слой хранения данных.

| Узел (IP) | Роль | OS | CPU | RAM | GPU |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Node .22** | Compute | EndeavourOS | AMD Ryzen 9 **9950X3D** | 64 GB | NVIDIA RTX 4090 |
| **Node .23** | Workstation | Manjaro | AMD Ryzen 7 **9800X3D** | 32 GB | AMD RX 9070 XT |
| **Node .30** | Storage / iSCSI | **TrueNAS SCALE 25.10.1** | AMD Ryzen 7 **9700X** | 32 GB | - |

**Дисковая подсистема ZFS (Узел .30):**
*   ⚡ **NVME (Tier-1, ~1 TB):** Высокоскоростной пул для баз данных и Persistent Volumes Кубернетеса (`NVME/k8s-vols`). 
*   🗄️ **RAID5 (Tier-2, ~5.15 TB):** Объемное файловое хранилище тяжелых медиаданных и S3-бакет для резервного копирования (`RAID5/s3-backups`).

## 🌐 Сеть и Маршрутизация

Управление сетевым слоем осуществляется через шлюз **Xiaomi AX3600** (OpenWrt 24.10.3):
*   **IPAM:** Жесткие DHCP MAC-привязки для обеспечения неизменности адресов базовых узлов.
*   **Traffic Shifting (Рычаг):** Управление входящим трафиком (DNAT) для бесшовного (Blue/Green) переключения 80/443 портов между старыми контейнерами TrueNAS Docker и новым K8s Ingress Controller.

## 🗺️ Планы развития (Roadmap)

Текущий фокус: Миграция stateful-сервисов в кластер, запуск GitLab CI/CD пайплайнов и проброс видеокарт (Device Plugins) для локального AI-стека.

👉 **[Ознакомиться с детальным Roadmap проекта](./ROADMAP.md)**
