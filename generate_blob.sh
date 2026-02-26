#!/bin/bash

# --- НАСТРОЙКИ ---
OUTPUT="homelab_full_config.txt"
REMOTE_USER="km"
REMOTE_HOST="192.168.1.22"
REMOTE_DEST="~/"

# --- СБОР ДАННЫХ ---
echo "=== ОТЧЕТ ПО КОНФИГУРАЦИИ HOMELAB ===" > $OUTPUT
echo "Дата сборки: $(date)" >> $OUTPUT
echo "--------------------------------------" >> $OUTPUT

# Ищем файлы, исключая скрытые, venv, архив, документацию и СЕКРЕТЫ!
FILES=$(find . -type f \( -name "*.tf" -o -name "*.yml" -o -name "*.yaml" -o -name "Makefile" -o -name "inventory.ini" \) \
    -not -path "*/.*" \
    -not -path "*/venv/*" \
    -not -path "*/archive/*" \
    -not -path "*/docs/*" \
    -not -name "*-secrets.yaml")
FILES="./Makefile $FILES"

for FILE in $FILES; do
    echo -e "\n\nFILE: $FILE" >> $OUTPUT
    echo "DESCRIPTION:" >> $OUTPUT

    case "$FILE" in
        *terraform/providers.tf*) echo "Настройка подключения к гипервизорам .22 и .23 через libvirt." >> $OUTPUT ;;
        *terraform/main.tf*)      echo "Описание ресурсов виртуальных машин (CPU, RAM, Disks)." >> $OUTPUT ;;
        *terraform/variables.tf*) echo "Глобальные переменные: новая сетка IP (Master .100, Workers .111+)." >> $OUTPUT ;;
        *ansible/inventory.ini*)  echo "Список хостов для Ansible с актуальными IP-адресами." >> $OUTPUT ;;
        *ansible/04_setup_iscsi*) echo "Настройка iSCSI-дисков. Portal переведен на TrueNAS (.30)." >> $OUTPUT ;;
        *ansible/05_init_k8s*)    echo "Инициализация кластера Kubernetes на Master-ноде." >> $OUTPUT ;;
        *zfs-iscsi-base.yaml* | *zfs-iscsi-prod.yaml*) echo "Конфигурация CSI для TrueNAS (база и прод). Секреты исключены." >> $OUTPUT ;;
        *Makefile*)               echo "Команды автоматизации: all, down, apps, clean-pvc." >> $OUTPUT ;;
        *)                        echo "Активный конфигурационный файл или манифест приложения." >> $OUTPUT ;;
    esac

    echo "--------------------------------------" >> $OUTPUT
    cat "$FILE" >> $OUTPUT
    echo -e "\n=== END OF FILE ===" >> $OUTPUT
done

echo "Сборка завершена. В отчете только актуальные файлы (без venv, archive, docs и секретов)."

# --- ПЕРЕНОС ФАЙЛА ---
echo "Отправка на $REMOTE_HOST..."
if scp "$OUTPUT" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DEST"; then
    echo "Файл успешно скопирован на $REMOTE_HOST."
    rm "$OUTPUT"
    echo "Локальная копия удалена."
else
    echo "ОШИБКА: Не удалось отправить файл. Он сохранен локально: $OUTPUT"
    exit 1
fi

echo "Готово!"
