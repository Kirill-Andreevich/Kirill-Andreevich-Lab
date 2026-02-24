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

# Ищем файлы, исключая скрытые, venv и архив
FILES=$(find . -type f \( -name "*.tf" -o -name "*.yml" -o -name "*.yaml" -o -name "Makefile" -o -name "inventory.ini" \) \
    -not -path "*/.*" \
    -not -path "*/venv/*" \
    -not -path "*/archive/*")

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
        *zfs-iscsi-values*)       echo "Конфигурация Democratic CSI для работы с ZFS на TrueNAS (.30)." >> $OUTPUT ;;
        *Makefile*)               echo "Команды автоматизации: tf-apply, k8s-setup, clean." >> $OUTPUT ;;
        *)                        echo "Активный конфигурационный файл или манифест приложения." >> $OUTPUT ;;
    esac
    
    echo "--------------------------------------" >> $OUTPUT
    cat "$FILE" >> $OUTPUT
    echo -e "\n=== END OF FILE ===" >> $OUTPUT
done

echo "Сборка завершена. В отчете только актуальные файлы (без venv и archive)."

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
