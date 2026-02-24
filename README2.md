<div align="center">
  <h1>🚀 Bare-Metal Kubernetes Homelab (IaC)</h1>

  <p>
    <img src="https://img.shields.io/badge/terraform-%235835CC.svg?style=flat-square&logo=terraform&logoColor=white" alt="Terraform" />
    <img src="https://img.shields.io/badge/ansible-%231A1918.svg?style=flat-square&logo=ansible&logoColor=white" alt="Ansible" />
    <img src="https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat-square&logo=kubernetes&logoColor=white" alt="Kubernetes" />
    <img src="https://img.shields.io/badge/TrueNAS-0095D5?style=flat-square&logo=truenas&logoColor=white" alt="TrueNAS" />
    <img src="https://img.shields.io/badge/MetalLB-005571?style=flat-square&logo=linux&logoColor=white" alt="MetalLB" />
  </p>

  <p><b>Полностью автоматизированный проект по развертыванию отказоустойчивого Kubernetes-кластера на KVM/libvirt с динамическим iSCSI хранилищем.</b></p>
</div>

---

## 🎯 О проекте

Цель проекта — реализовать **Zero-Touch Provisioning** (развертывание с нуля одной командой) на собственном оборудовании, используя принципы Infrastructure as Code (IaC)[cite: 346, 348].

### ✨ Ключевые фичи
* **Dynamic Storage:** Интеграция с TrueNAS SCALE по API v2[cite: 354]. K8s автоматически нарезает ZVOL-диски и монтирует их в поды[cite: 343, 344].
* **L2 Load Balancing:** MetalLB раздает сервисам IP из локальной сети (192.168.1.200-239)[cite: 345].
* **Stateful Workloads:** Поддержка приложений с сохранением состояния: Nextcloud и Jellyfin[cite: 339, 341].
* **Security:** Секреты (SSH, API токены) исключены из Git для безопасности[cite: 351].

---

## 🏗 Архитектура стенда

<details>
<summary><b>📊 Посмотреть диаграмму архитектуры (Mermaid)</b></summary>

```mermaid
graph TD
    subgraph KVM Hypervisors
        M[k8s-master .100]
        W1[k8s-worker-0 .110]
        W2[k8s-worker-1 .111]
        W3[k8s-worker-2 .112]
    end

    subgraph External Storage
        T[(TrueNAS SCALE .30)]
    end

    TF[Terraform] -->|Provisions VMs| M & W1 & W2 & W3
    ANS[Ansible] -->|Installs K8s & iscsid| M & W1 & W2 & W3

    M -.->|CSI API v2| T
    W1 & W2 & W3 -.->|iSCSI Block Mount| T

    Client((Web Client)) -->|EXTERNAL-IP| MetalLB
    MetalLB -->|Routes| W1 & W2


</details>

🛠 Управление (Быстрый старт)
Для управления проектом используется единый Makefile.￼

<details open>
<summary><b>Основные команды</b></summary>

Команда,Описание
make all,"Полный цикл деплоя. Поднимает инфраструктуру, настраивает K8s и деплоит приложения."
make apps,"Передеплоить только пользовательские манифесты (Jellyfin, Nextcloud, Speedtest).+2"
make down,Удаление стенда. Безопасно отключает хранилище и уничтожает ВМ.
make clean-pvc,Принудительная очистка ZVOL на TrueNAS при блокировках iSCSI.

</details>

.
├── ansible/            # Конфигурация ОС и установка K8s
├── democratic-csi/     # Helm-чарт для интеграции с TrueNAS
├── kubernetes/
│   ├── apps/           # Манифесты приложений (Jellyfin, Nextcloud, Speedtest)
│   └── main/           # Системные настройки MetalLB
├── terraform/          # IaC: создание ВМ и Cloud-Init
├── Makefile            # Точка входа автоматизации
└── ROADMAP.md          # Планы и трекинг техдолга

EOF
