# 🏗 Kirill's Zen 5 Infrastructure Lab

Профессиональный стенд для отработки IaC-подходов, тюнинга гипервизоров и автоматизированного развертывания AI-сервисов.

## 🎯 Философия
**"One Button to Rule Them All"**: Вся инфраструктура от гипервизора до DeepSeek-R1 разворачивается одной командой `make all`. Никакого ручного вмешательства.

---

## 💻 Hardware Topology (The Beast)

Инфраструктура распределена между тремя узлами на базе архитектуры AMD Zen 5, объединенными в общую L2-сеть.

### 🚀 Compute Node (Main Hypervisor)
*   **Host OS:** EndeavourOS (Kernel: 6.18.8-zen2-1-zen)
*   **CPU:** AMD Ryzen 9 9950X3D (32 threads @ 5.76 GHz)
*   **GPU:** NVIDIA GeForce RTX 4090 [Discrete] — GPU Passthrough для LLM.
*   **RAM:** 64GB DDR5 (Swap: Disabled)
*   **Storage:** 2TB NVMe (BTRFS)
*   **Network:** `192.168.1.22` (Interface: `br0` L2 Bridge)

### 🖥 Workstation (Dev & Control Plane)
*   **Host OS:** Manjaro Linux (Kernel: 6.18.8-1-MANJARO)
*   **CPU:** AMD Ryzen 7 9800X3D (16 threads @ 5.27 GHz)
*   **GPU:** AMD Radeon RX 9070 XT
*   **RAM:** 32GB DDR5
*   **Storage:** 2TB NVMe (BTRFS)
*   **Network:** `192.168.1.234`

### 💾 Storage Node (Data Lake)
*   **OS:** TrueNAS SCALE (Goldeye 25.10.1)
*   **CPU:** AMD Ryzen 7 9700X
*   **RAM:** 32GB DDR5 (ARC Cache: ~18GB)
*   **Pools:** RAID-Z1 (HDD Array) + NVMe Pool
*   **Role:** NFS/iSCSI targets для ВМ, хранение бэкапов и датасетов.
*   **Network:** `192.168.1.176`

---

## 🛠 Tech Stack
*   **Infrastructure:** Terraform (Libvirt / QEMU / KVM).
*   **Configuration:** Ansible (Role-based).
*   **Observability:** Prometheus & Grafana (Stack in progress).
*   **AI Stack:** Ollama (DeepSeek-R1 / Qwen 2.5 Coder).

## 🔧 Ключевые доработки (Technical R&D)

### 1. Storage & Boot Stability
*   **Проблема:** Стандартные Cloud-образы «висли» при загрузке из-за нехватки места (2GB).
*   **Решение:** Автоматическое расширение системного диска до **20GB** средствами Terraform.

### 2. Networking (L2 Bridge)
*   **Проблема:** Блокировка DHCP-трафика хостом (Arch) для гостевых ВМ.
*   **Решение:** Тюнинг `sysctl` (`net.bridge.bridge-nf-call-iptables = 0`) и загрузка модуля `br_netfilter`.
*   **Zero-Conf:** Использование `wait_for_lease = true` для динамического получения IP.

### 3. Automation & Telemetry
*   **Inventory:** Динамическая фильтрация IPv4 через Terraform для генерации Ansible Inventory.
*   **Guest Insight:** Внедрение **QEMU Guest Agent** через Cloud-Init для обратной связи с гипервизором.

---

## 🗺 Infrastructure Evolution (Roadmap 2026)

### Phase 1: Foundation ✅
* **IaC Core:** Переход на модульную архитектуру Terraform v2 (for_each/modules).
* **L2 Networking:** Проектирование Zero-Conf связности через Linux Bridge.
* **Automated Bootstrap:** Кастомизация Cloud-Init (диски, агенты, SSH-keys).
* **Dynamic Inventory:** Автогенерация Ansible-инвентаря на лету.

### Phase 2: Observability & Scaling 🏗
* [ ] **Prometheus Auto-Discovery:** Автоматическая постановка новых ВМ на мониторинг через генерацию `targets.json` из Terraform.
* [ ] **Stress-Testing:** Развертывание гетерогенного зоопарка из 20-30 ВМ одной командой `make all`.
* [ ] **VictoriaMetrics Integration:** Переход на долгосрочное хранение метрик производительности Zen 5.

### Phase 3: CI/CD & Containers 🚀
* [ ] **Self-hosted GitLab:** Деплой управляющего узла для запуска GitOps-пайплайнов.
* [ ] **Legacy to Cloud-Native:** Миграция монолитных сервисов в Docker Compose (App/DB/Nginx).
* [ ] **GitOps Pipeline:** Автоматический запуск `terraform apply` при пуше в репозиторий.

### Phase 4: The Final Boss (K8s Cluster) 👑
* [ ] **Bare-metal Kubernetes:** Развертывание кластера через `kubeadm` на 3 физических узлах.
* [ ] **GPU-Orchestration:** Проброс NVIDIA RTX 4090 в K8s для инференса LLM.
* [ ] **DeepSeek-R1 Production:** Деплой AI-стека в Kubernetes с автомасштабированием воркеров.

---
*Created with 🧠 by Kirill's Homelab Automation*
