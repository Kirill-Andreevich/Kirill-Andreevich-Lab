# 🏗 Kirill's Zen 5 Infrastructure Lab

Профессиональный стенд для отработки IaC-подходов и автоматизированного развертывания AI-сервисов.

## 🎯 Философия
**"One Button to Rule Them All"**: Вся инфраструктура от гипервизора до DeepSeek-R1 должна разворачиваться одной командой `make all`. Никакого ручного вмешательства.

## 💻 Hardware Topology
*   **Compute Node (.22):** AMD Ryzen 9 9950X3D | 128GB RAM | NVIDIA RTX 4090.
*   **Workstation (.234):** AMD Ryzen 7 9800X3D | AMD RX 9070 XT.
*   **Storage (.176):** TrueNAS ZFS.

## 🛠 Tech Stack
*   **Infrastructure:** Terraform (Libvirt).
*   **Configuration:** Ansible (Role-based).
*   **AI Stack:** Ollama (DeepSeek-R1 / Qwen 2.5 Coder).

## 📝 Текущий статус R&D
* [in progress] Настройка прозрачного L2 Bridge (br0) для Zero-Conf связности.
* [done] Миграция на архитектуру Terraform v2 (for_each).
* [done] Автогенерация динамического инвентаря Ansible.
