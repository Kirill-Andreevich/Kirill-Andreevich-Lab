FROM python:3.12-slim

# Ставим зависимости для работы с видеокартой
RUN apt-get update && apt-get install -y libpci3 libdrm2 && rm -rf /var/lib/apt/lists/*

# Ставим либы для экспортера
RUN pip install prometheus_client amdsmi

# Копируем наш скрипт
COPY gpu_exporter.py /app/gpu_exporter.py
WORKDIR /app

# Прокидываем системные либы AMD (если нужно будет)
ENV LD_LIBRARY_PATH=/opt/rocm/lib
ENV PYTHONPATH=/app

CMD ["python", "gpu_exporter.py"]
