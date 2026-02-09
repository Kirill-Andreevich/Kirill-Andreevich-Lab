# 🌌 Homelab Infrastructure as Code (IaC)

Репозиторий для управления домашней лабораторией на базе **TrueNAS SCALE (Fangtooth)** и высокопроизводительных узлов **Ryzen 9000-й серии**. Все конфигурации автоматизированы через Ansible.

---

## 🛠 Hardware Stack

| Node | OS | CPU | RAM | GPU | Role |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Compute-Node** | EndeavourOS | AMD Ryzen 9 9950X3D (32T) | 64GB DDR5 | **NVIDIA RTX 4090** | AI / Heavy Computing |
| **Storage-Node** | TrueNAS SCALE | AMD Ryzen 7 9700X | 32GB RAM | ZFS Pool | NAS / Core Services |
| **Workstation** | Manjaro | AMD Ryzen 7 9800X3D | 32GB RAM | **RX 9070 XT** | Dev / Gaming |

---

## 💾 Storage Architecture (ZFS)

Мониторинг состояния пулов осуществляется через `node_exporter` с включенным коллектором ZFS.

*   **Pool: NVME** (Mirror-0 & Mirror-1) — Высокоскоростное хранилище для приложений и БД.
*   **Pool: RAID5** (RAID-Z1) — Хранилище медиа и бэкапов (4 диска).
*   **Pool: boot-pool** — Системный раздел TrueNAS.

---

## 📊 Monitoring Stack

Архитектура сбора метрик построена на **Prometheus + Grafana**, развернутых в Docker-контейнерах на Storage-Node.

1.  **Prometheus**: Агрегатор метрик (порт `30104`).
2.  **Grafana**: Визуализация данных (порт `30037`).
3.  **Node Exporter**: Сбор системных метрик (CPU, RAM, Disk, ZFS) на всех узлах (порт `9100`).
4.  **GPU Exporters**:
    *   `nvidia-device-exporter` для RTX 4090.
    *   `amdgpu_exporter` для RX 9070 XT.

---

## 🚀 Deployment (Ansible)

Все сервисы разворачиваются из изолированного Python venv.

### Подготовка окружения:
```bash
source venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install community.docker
