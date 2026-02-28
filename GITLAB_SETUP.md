# Инструкция по развертыванию и настройке GitLab + Runner

Эта дока описывает, как поднять свой GitLab с нуля, защитить его и привязать к нему Kubernetes Runner для CI/CD пайплайнов.

## 1. Достаем пароль root после установки
После того как Ansible поднял Docker-контейнер с GitLab, нужно вытащить временный пароль админа.
Выполняем с хостовой машины:
```bash
ssh -o StrictHostKeyChecking=no km@192.168.1.101 "sudo cat /srv/gitlab/config/initial_root_password | grep Password:"

Заходим по адресу http://192.168.1.101, логин root, пароль из вывода команды выше. СРАЗУ меняем пароль в настройках профиля!
## 2. Создаем репозиторий и пушим код
В веб-интерфейсе GitLab:
1. Нажимаем **Create blank project**.
2. Имя проекта: `homelab`.
3. 🛑 **ОБЯЗАТЕЛЬНО:** Снимаем галочку `Initialize repository with a README`.
4. Жмем **Create project**.

Привязываем локальный код и пушим на сервер:
```bash
git remote add gitlab http://192.168.1.101/root/homelab.git
git push -u gitlab main
3. Защита от случайного удаления в Terraform
Чтобы случайно не снести виртуалку с Гитлабом командой terraform destroy, в terraform/main.tf в ресурсе виртуалки добавлен блок:

Terraform
￼
  lifecycle {
    prevent_destroy      = true
    replace_triggered_by = [libvirt_cloudinit_disk.init_gitlab]
  }
4. Установка GitLab Runner в Kubernetes
Чтобы заработали CI/CD пайплайны, нужен агент.

В GitLab идем в Settings -> CI/CD -> Runners.

Жмем New project runner.

Платформа: Linux, Тег: k8s.

🛑 ОБЯЗАТЕЛЬНО: Ставим галочку Run untagged jobs.

Жмем Create runner и копируем полученный токен (начинается на glrt-).

Установка через Helm (с обходом бага TLS 1.3 на S3):
Из-за ошибки tls: server did not echo the legacy session ID качаем чарт локально и ставим из файла:

Bash
￼
# Качаем архив локально
wget https://gitlab-charts.s3.amazonaws.com/gitlab-runner-0.86.0.tgz

# Устанавливаем в кластер
helm upgrade --install gitlab-runner ./gitlab-runner-0.86.0.tgz \
  --namespace gitlab-runner \
  --create-namespace \
  --set gitlabUrl=http://192.168.1.101 \
  --set runnerToken="СЮДА_ВСТАВИТЬ_ТОКЕН_GLRT" \
  --set rbac.create=true \
  --set runners.tags="k8s" \
  --set runners.runUntagged=true \
  --set runners.privileged=true
Проверка статуса раннера:

Bash
￼
kubectl get pods -n gitlab-runner

## 5. Траблшутинг (Решение проблем)

### Проблема: Runner завис в статусе ContainerCreating
Если в Kubernetes под раннера долго не запускается, а команда `kubectl describe pod ...` показывает ошибку:
`plugin type="flannel" failed (add): failed to load flannel 'subnet.env': no such file or directory`

**Причина:**
На нодах кластера не загружен модуль ядра `br_netfilter` или не включены параметры `bridge-nf-call-iptables`.

**Решение:**
1. Проверь статус сетевых подов: `kubectl get pods -n kube-flannel`.
2. Если они в `CrashLoopBackOff`, проверь наличие модуля: `lsmod | grep br_netfilter`.
3. Чтобы исправить вручную на всех нодах:
   ```bash
   sudo modprobe br_netfilter
   sudo sysctl -w net.bridge.bridge-nf-call-iptables=1

### Исправление прав (RBAC)
Если джоба падает с ошибкой Forbidden для аккаунта `default`:
```bash
kubectl create clusterrolebinding gitlab-runner-default-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=gitlab-runner:default
