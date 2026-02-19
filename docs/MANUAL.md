# 📘 Полное руководство по эксплуатации Homelab K8s

Этот документ описывает внутреннее устройство кластера и шаги по его восстановлению или масштабированию.

## 🏗 Схема инфраструктуры
1. **Compute Node (AMD Ryzen 9 9950X)**: 
   - Запускает воркер-ноды Kubernetes (`k8s-worker-0, 1, 2`).
   - Использует уникальные ISO-образы для Cloud-Init (`init-comp-N.iso`).
2. **Workstation Node (AMD Ryzen 7 9800X)**:
   - Запускает Master-ноду (`k8s-master`) и GitLab (`gitlab-srv`).
3. **Storage Node (AMD Ryzen 7 9700X)**:
   - TrueNAS SCALE (IP: 192.168.1.176).
   - Раздает хранилище по iSCSI через **Democratic CSI**.

## 🔧 Настройка TrueNAS (Storage)
Чтобы кластер мог нарезать диски, на TrueNAS должны быть:
1. **Portal**: ID 2 (0.0.0.0:3260).
2. **Initiator Group**: ID 1 (Allow All).
3. **Target**: ID 2 (`k8s-target-nvme`).
4. **Dataset**: `NVME/k8s-vols` (тип: FILESYSTEM).
5. **API Key**: Создан для пользователя `km`.

## 🚀 Процесс развертывания (Makefile)
Команда `make all` выполняет следующие этапы:
1. **Terraform Apply**: Создает виртуалки и прописывает `hostname`.
2. **Ansible Prepare**: Ставит `conntrack`, `containerd` и модули ядра.
3. **Ansible Master Init**: Запускает `kubeadm init`, забирает `admin.conf` на Manjaro.
4. **Ansible Worker Join**: Динамически читает токен с мастера и подключает воркеров.
5. **CNI Apply**: Устанавливает Flannel для сетевой связности.

## 🛠 Устранение неполадок
- **Ноды в NotReady**: Проверь статус Flannel (`kubectl get pods -n kube-flannel`).
- **iSCSI не мапится**: Проверь пинг до TrueNAS и наличие сессий (`iscsiadm -m session`).
- **Ошибка Duplicate Hostname**: Убедись, что в Terraform для каждого воркера создается свой `libvirt_cloudinit_disk`.

## 📈 Масштабирование
Чтобы добавить воркеров:
1. Измени `worker_count` в `terraform/variables.tf`.
2. Запусти `make up` и `make cluster`.
