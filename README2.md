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

Цель проекта — реализовать **Zero-Touch Provisioning** (развертывание с нуля одной командой) на собственном оборудовании, используя принципы Infrastructure as Code (IaC).

### ✨ Ключевые фичи
* **Dynamic Storage:** Интеграция с TrueNAS SCALE по API v2. K8s автоматически нарезает ZVOL-диски и монтирует их в поды.
* **L2 Load Balancing:** MetalLB раздает сервисам IP из локальной сети в диапазоне `192.168.1.200-239`.
* **Stateful Workloads:** Поддержка приложений с сохранением состояния (Nextcloud, Jellyfin).
* **Security:** Секреты и ключи доступа исключены из Git для безопасности.

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
Для управления проектом используется единый Makefile.

<details open>
<summary><b>Основные команды</b></summary>

Команда	Описание
make all	Полный цикл деплоя. Terraform -> Ansible -> K8s -> Apps.
make apps	Передеплоить только пользовательские манифесты.
make down	Удаление стенда. Очистка PVC и уничтожение ВМ.
make clean-pvc	Принудительная очистка ZVOL на TrueNAS при блокировках iSCSI.
￼
Экспортировать в Таблицы
￼
</details>

📂 Структура репозитория
Plaintext
￼
.
├── ansible/            # Конфигурация ОС и установка K8s
├── democratic-csi/     # Helm-чарт для интеграции с TrueNAS
├── kubernetes/
│   ├── apps/           # Манифесты приложений (Jellyfin, Nextcloud, Speedtest)
│   └── main/           # Системные настройки MetalLB
├── terraform/          # IaC: создание ВМ и Cloud-Init
├── Makefile            # Точка входа автоматизации
└── ROADMAP.md          # Планы и трекинг техдолга
