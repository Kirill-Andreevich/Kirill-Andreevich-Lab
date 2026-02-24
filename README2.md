# 🚀 Bare-Metal Kubernetes Homelab (IaC)

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/ansible-%231A1918.svg?style=for-the-badge&logo=ansible&logoColor=white)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![TrueNAS](https://img.shields.io/badge/TrueNAS-0095D5?style=for-the-badge&logo=truenas&logoColor=white)

Полностью автоматизированный проект по развертыванию отказоустойчивого Kubernetes-кластера на "голом железе" (KVM/libvirt) с использованием подхода **Infrastructure as Code**.

## 🏗 Архитектура

Проект состоит из трех основных слоев автоматизации:
1. **Инфраструктурный слой (Terraform):** Нарезка виртуальных машин в KVM, настройка Cloud-Init, статическая IP-адресация.
2. **Конфигурационный слой (Ansible):** Подготовка ОС (Ubuntu 24.04), настройка iSCSI/Multipath, инициализация кластера Kubeadm.
3. **Слой оркестрации (Kubernetes/Helm):** Развертывание CNI (Flannel), LoadBalancer (MetalLB) и CSI драйвера (Democratic CSI).

```mermaid
graph TD
    subgraph KVM Hypervisors
        M[k8s-master .100]
        W1[k8s-worker-0 .110]
        W2[k8s-worker-1 .111]
        W3[k8s-worker-2 .112]
    end

    subgraph "External Storage"
        T[(TrueNAS SCALE .30)]
    end

    TF[Terraform] -->|Provisions VMs & IPs| M
    TF -->|Provisions VMs & IPs| W1
    TF -->|Provisions VMs & IPs| W2
    TF -->|Provisions VMs & IPs| W3

    ANS[Ansible] -->|Installs K8s & iscsid| M
    ANS -->|Installs K8s & iscsid| W1
    ANS -->|Installs K8s & iscsid| W2
    ANS -->|Installs K8s & iscsid| W3

    M -.->|Democratic CSI API| T
    W1 -.->|iSCSI Block Mount| T
    W2 -.->|iSCSI Block Mount| T
    W3 -.->|iSCSI Block Mount| T

    Client((Web Client)) -->|EXTERNAL-IP| MetalLB
    MetalLB -->|Routes| W1
    MetalLB -->|Routes| W2
