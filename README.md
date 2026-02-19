# 🏗 Kirill's Zen 5 Infrastructure Lab

Профессиональный стенд для отработки IaC-подходов, тюнинга гипервизоров и автоматизированного развертывания сред на базе архитектуры AMD Zen 5.

## 🎯 Философия
**"One Button to Rule Them All"**: Вся инфраструктура от гипервизора до компонентов Kubernetes разворачивается одной командой `make all`. 100% повторяемость, 0% ручного вмешательства.

## 💻 Hardware Topology (The Beast)
*Инфраструктура распределена между тремя узлами Zen 5 в общей L2-сети.*

*   **🚀 Compute Node (Main):** Ryzen 9 9950X (32 threads) | RTX 4090 | 64GB DDR5.
*   **🖥 Workstation (Control):** Ryzen 7 9800X | RX 9070 XT | 32GB DDR5.
*   **💾 Storage Node (Data):** Ryzen 7 9700X | TrueNAS SCALE | RAID-Z1.

## 🛠 Tech Stack
*   **Infrastructure:** Terraform (Libvirt / QEMU / KVM).
*   **Configuration:** Ansible (Core-playbooks).
*   **Container Runtime:** Containerd v1.7.28 (SystemdCgroup).
*   **Orchestration:** Kubernetes v1.31 (Stable Repo).
*   **Automation:** GNU Makefile.

## 🚀 Quick Start
```bash
make all   # Поднять всё: ВМ -> K8s -> Приложения
make apps  # Только деплой сервисов (Nextcloud, Jellyfin, Speedtest)
make down  # Полная очистка стенда
```

## 🔧 Документация
*   [🗺 Full Roadmap](./ROADMAP.md) — Планы развития и текущий статус.
*   [🛠 Tech Details](./docs/TECH_DETAILS.md) — Кейсы с Yandex Mirror, GPG и тюнингом ядра.

*Created with 🧠 by Kirill's Homelab Automation*
