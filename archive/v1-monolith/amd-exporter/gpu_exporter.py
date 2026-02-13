import time, amdsmi
from prometheus_client import start_http_server, Gauge

amdsmi.amdsmi_init()
handles = amdsmi.amdsmi_get_processor_handles()

TEMP = Gauge('amd_gpu_temp', 'Celsius', ['id'])

if __name__ == '__main__':
    start_http_server(9254)
    while True:
        for i, h in enumerate(handles):
            try:
                # Универсальный вызов для свежих либ
                t = amdsmi.amdsmi_get_gpu_thermal_info(h, amdsmi.AmdSmiThermalElementType.EDGE)['temperature']
                TEMP.labels(id=i).set(t)
            except:
                continue
        time.sleep(2)
