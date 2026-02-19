# 🏗 Kirill's Zen 5 Infrastructure Lab

Профессиональный стенд для отработки IaC-подходов, тюнинга гипервизоров и автоматизированного развертывания сред на базе архитектуры AMD Zen 5.

## 🎯 Философия
**"One Button to Rule Them All"**: Вся инфраструктура от гипервизора до компонентов Kubernetes разворачивается одной командой `make all`. 100% повторяемость, 0% ручного вмешательства.

## 💻 Hardware Topology (The Beast)
*Инфраструктура распределена между тремя узлами Zen 5 в общей L2-сети.*

*   **🚀 Compute Node (Main):** Ryzen 9 9950X3D | RTX 4090 | 32GB DDR5.
*   **🖥 Workstation (Control):** Ryzen 7 9800X3D | RX 9070 XT | 32GB DDR5.
*   **💾 Storage Node (Data):** Ryzen 7 9700X | TrueNAS SCALE | 32GB DDR5.
    *   **⚡ NVME Pool (RAID 10 / Striped Mirror):** High-performance tier для iSCSI и K8s PV.
    *   **📦 RAID5 Pool (RAID-Z1):** 4x HDD для медиа-контента и архивов.

## 🛠 Tech Stack
*   **Infrastructure:** Terraform (Libvirt / QEMU / KVM).
*   **Configuration:** Ansible (Core-playbooks).
*   **Container Runtime:** Containerd v1.7.28 (SystemdCgroup).
*   **Orchestration:** Kubernetes v1.31 (Stable Repo).
*   **Automation:** GNU Makefile.

## 🚀 Quick Start
```bash
make all   # Поднять всё: ВМ -> K8s -> Приложения
make down  # Полная очистка стенда
```

## 🔧 Документация
*   [🗺 Full Roadmap](./ROADMAP.md) — Планы развития и текущий статус.
*   [🛠 Tech Details](./docs/TECH_DETAILS.md) — Кейсы с Yandex Mirror, GPG и тюнингом ядра.

*Created with 🧠 by Kirill's Homelab Automation*
