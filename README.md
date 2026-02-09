# Kirill-Andreevich-Lab 🚀

### Overview
Automated Hybrid HomeLab built on cutting-edge **Zen 5** architecture. Managed via **Ansible** and **Docker**.

### Hardware Stack
- **Compute Node (EndeavourOS):** AMD Ryzen 9 9950X3D (32 threads) | 64GB DDR5 | NVIDIA RTX 4090.
- **Storage Node (TrueNAS SCALE):** AMD Ryzen 7 9700X | 32GB RAM | ZFS Pool.
- **Workstation (Manjaro):** AMD Ryzen 7 9800X3D | 32GB RAM | RX 9070 XT.

### Features
- [x] **Infrastructure as Code:** Automated node provisioning via Ansible.
- [x] **Containerization:** Optimized Docker engine deployment on Arch-based systems.
- [x] **GPU Monitoring:** Real-time metrics for **RTX 4090** via nvidia-gpu-exporter (systemd service).
- [x] **Network Security:** Automated firewall management (firewalld/ufw) via Ansible.

### How to run
1. Clone this repo.
2. Activate python venv: `source venv/bin/activate`
3. Run provisioning: `python -m ansible.cli.playbook -i inventory.ini setup_gpu_monitoring.yml -K`
