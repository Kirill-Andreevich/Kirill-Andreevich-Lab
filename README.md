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

---

## 🌐 Сетевая архитектура и IPAM (IP Address Management)

Сетевой контур управляется шлюзом **Xiaomi AX3600** (OpenWrt 24.10.3). В проекте реализована строгая статическая маршрутизация и разделение L2/L3 трафика.

**Таблица распределения адресов (Subnet: 192.168.1.0/24):**

| Диапазон / IP | Назначение (Роль) | Описание |
| :--- | :--- | :--- |
| `192.168.1.1` | **Gateway / DNS** | Роутер OpenWrt. Единая точка входа (NAT) и Firewall. |
| `192.168.1.20 - .29` | **Bare-Metal Hypervisors** | Узлы виртуализации KVM (`.22` - 9950X3D, `.23` - 9800X3D). |
| `192.168.1.30` | **Storage Layer** | TrueNAS SCALE (iSCSI Target & S3 Backup Backend). |
| `192.168.1.100 - .109` | **K8s Control Plane** | Master-узлы Кубернетеса (`.100`) и инфраструктурные ВМ (`.101` - GitLab). |
| `192.168.1.110 - .199` | **K8s Workers** | Вычислительные узлы кластера (масштабируются динамически). |
| `192.168.1.200 - .239` | **MetalLB LoadBalancer** | L2-пул для балансировщика K8s. Выдается сервисам (Ingress) "на лету". |
| `192.168.1.240 - .254` | **DHCP Guest Pool** | Динамическая выдача (Lease: 12h) для личных и гостевых устройств. |

*Внутренняя сеть Kubernetes:* Используется CNI **Flannel** с оверлейной подсетью `10.244.0.0/16`.

---

## 🧠 Инженерные решения и паттерны (Architecture Concepts)

Этот стенд — демонстрация того, как Enterprise-решения адаптируются для bare-metal инфраструктуры:

1. **Blue/Green Traffic Shifting (Управление трафиком на L3):** 
   Перенос stateful-сервисов (Nextcloud, Jellyfin) с Docker на TrueNAS внутрь K8s выполняется с нулевым даунтаймом. На шлюзе OpenWrt настроены DNAT-правила (`dest_ip` подменяется через систему UCI). Это дает "рычаг" мгновенного переключения входящего трафика 80/443 портов между старыми контейнерами и новым K8s Ingress Controller.
2. **Compute / Storage Decoupling (Разделение слоев):**
   Вычислительные ноды (K8s Workers) не хранят состояние (Stateless). Вся база данных и кэши лежат на ZFS-пуле `NVME` узла `.30`. Драйвер `democratic-csi` автоматически нарезает iSCSI-LUN'ы и монтирует их в поды, обеспечивая отказоустойчивость: если worker-нода умирает, под переезжает на соседнюю ноду и забирает свой ZFS-том по сети.
3. **Disaster Recovery (S3 & Restic):**
   Реализовано инкрементальное резервное копирование с дедупликацией. Данные кластера и IaC-манифесты бэкапятся утилитой `restic` в S3-совместимый бакет `homelab-backups`, который поднят на отказоустойчивом `RAID5` массиве в TrueNAS.
4. **Hardware AI-Stack (в разработке):**
   Архитектура KVM `host-passthrough` позволяет утилизировать 3D V-Cache процессоров Zen 5. Внедряется механизм Kubernetes Device Plugins для проброса дискретных GPU (RTX 4090 и RX 9070 XT) напрямую в контейнеры для локального инференса LLM (DeepSeek-R1).
