#!/bin/bash

# --- НАСТРОЙКИ ---
USER="km"
HOSTS=("192.168.1.22" "192.168.1.23") 
LOCAL_REPORT_DIR="project_reports"
REMOTE_REPORT_DIR="~/homelab_reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M")

# Цвета
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}=== Сборка отчетов Homelab ($TIMESTAMP) ===${NC}"

# 1. Создаем локальную папку
mkdir -p "$LOCAL_REPORT_DIR"

# 2. ГЕНЕРАЦИЯ СТРУКТУРЫ
STRUCT_FILE="$LOCAL_REPORT_DIR/structure_$TIMESTAMP.txt"
echo -n "Создаю карту структуры... "
echo "=== КАРТА СТРУКТУРЫ ($TIMESTAMP) ===" > "$STRUCT_FILE"
tree -a -I '.git|venv|archive|docs|*.tfstate*|.terraform*|*-secrets.yaml' >> "$STRUCT_FILE"
echo -e "${GREEN}OK${NC}"

# 3. ГЕНЕРАЦИЯ ДАМПА (В красивом Markdown)
DUMP_FILE="$LOCAL_REPORT_DIR/dump_$TIMESTAMP.md"
echo -n "Создаю Markdown-дамп кода... "
echo "# Полный дамп конфигурации Homelab" > "$DUMP_FILE"
echo "> Сгенерировано: $(date)" >> "$DUMP_FILE"
echo "" >> "$DUMP_FILE"

FILES=$(find . -maxdepth 3 -type f \( -name "*.tf" -o -name "*.yml" -o -name "*.yaml" -o -name "Makefile" -o -name "inventory.ini" \) \
    -not -path "*/.*" -not -path "*/venv/*" -not -path "*/archive/*" -not -path "*/docs/*" -not -name "*-secrets.yaml" | sort)

for FILE in $FILES; do
    echo "## Файл: \`$FILE\`" >> "$DUMP_FILE"
    
    EXT="${FILE##*.}"
    if [ "$EXT" = "tf" ]; then LANG="hcl"
    elif [ "$EXT" = "yml" ] || [ "$EXT" = "yaml" ]; then LANG="yaml"
    elif [ "$EXT" = "ini" ]; then LANG="ini"
    elif [ "$(basename "$FILE")" = "Makefile" ]; then LANG="makefile"
    else LANG="text"
    fi

    echo '```'"$LANG" >> "$DUMP_FILE"
    cat "$FILE" >> "$DUMP_FILE"
    echo '```' >> "$DUMP_FILE"
    echo "" >> "$DUMP_FILE"
done
echo -e "${GREEN}OK${NC}"

# 4. ВЫГРУЗКА НА ХОСТЫ (Та самая, которая пропала)
echo -e "${BLUE}>>> Начинаю выгрузку на ноды...${NC}"
for host in "${HOSTS[@]}"; do
    # Проверяем, доступен ли хост, чтобы скрипт не висел
    if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
        ssh "$USER@$host" "mkdir -p $REMOTE_REPORT_DIR"
        rsync -avz "$LOCAL_REPORT_DIR/" "$USER@$host:$REMOTE_REPORT_DIR/"
        echo -e "${GREEN}>>> Успешно выгружено на $host${NC}"
    else
        echo -e "\033[0;31m>>> Хост $host недоступен, пропускаю!${NC}"
    fi
done

echo -e "${GREEN}=== Все задачи завершены! ===${NC}"
