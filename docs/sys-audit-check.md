# Manual de Ingeniería: (`audit/sys-audit-check.sh`)

![Stable Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?exclude_prereleases&color=blue&label=stable)
![CI Status](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml/badge.svg?branch=main)
![Platform](https://img.shields.io/badge/platform-Linux-steelblue)
![License](https://img.shields.io/github/license/K-aatech/bash-system-tools)

## 1. Descripción General
Utility profesional de auditoría para la infraestructura de **K'aatech**. Diseñada para proporcionar visibilidad inmediata sobre la salud, seguridad y rendimiento de servidores Linux, con un enfoque en la detección temprana de cuellos de botella y riesgos de seguridad (optimizada para entornos tipo Debian/Ubuntu).

### **Capacidades Operativas:**
* **Integridad Crítica:** Verificación de permisos y propiedad en archivos sensibles del sistema.
* **Networking:** Mapeo de puertos en escucha mediante `ss` (Socket Statistics).
* **CPU & I/O:** Monitoreo de *Load Average* y latencia de disco (*I/O Wait*).
* **Gestión Térmica:** Detección de *Thermal Throttling* preventivo (vía `lm-sensors`).
* **Logging Idempotente:** Sistema de rotación autónoma que evita la saturación de `/var/log`.

---

## 2. Configuración y Umbrales (Thresholds)
El script utiliza **Gobernanza de Variables** de Bash. Los valores por defecto pueden ser sobrescritos inyectando variables de entorno sin modificar el código fuente:

| Variable | Valor Defecto | Nivel | Descripción |
| :--- | :--- | :--- | :--- |
| `THRESHOLD_RAM` | `80` | `WARN` | Porcentaje de uso de memoria física. |
| `THRESHOLD_DISK` | `90` | `CRIT` | Uso de espacio en particiones montadas. |
| `THRESHOLD_TEMP` | `75` | `WARN` | Grados Celsius antes de alerta térmica. |
| `THRESHOLD_IOWAIT`| `5.0` | `WARN` | % de CPU esperando por E/S de disco. |

---

## 3. Arquitectura de Salida (POSIX Streams)
Para facilitar la integración con sistemas de monitoreo y agregadores de logs, el script separa estrictamente sus flujos de datos:

* **Stdout (1):** Registros informativos, estado de salud OK y reportes de inventario.
* **Stderr (2):** Todas las alertas `[WARN]` y fallos críticos `[CRIT]`.

### Ejemplo de captura profesional:
```bash
# Separar logs informativos de alertas críticas en archivos distintos
sudo ./sys-audit-check.sh > audit_inventory.log 2> audit_alerts.log
```

## 4. Instalación y Despliegue
El *script* debe residir en una ruta protegida. Solo el usuario `root` debe tener permisos de ejecución para garantizar la validez de la auditoría y acceso a archivos restringidos.

### Despliegue Estándar:
1. Descarga:
```bash
sudo curl -L -o /usr/local/bin/sys-audit-check.sh [URL_REPOS_K_AATECH]
```

2. Hardening de permisos:
```bash
sudo chown root:root /usr/local/bin/sys-audit-check.sh && sudo chmod 700 /usr/local/bin/sys-audit-check.sh
```

3. Ejecución:
```bash
sudo sys-audit-check.sh
```

## 5. Plan de Acción ante Incidentes (*Runbook*)
### A. [CRIT] Security Risk: World-Writable Files
Se detectó que un archivo crítico (ej. `/etc/shadow`) es escribible por usuarios no privilegiados.

- Acción: Ejecutar c`hmod 600 /etc/shadow` inmediatamente. Auditar el historial de comandos para identificar el origen del cambio de permisos.

### B. [WARN] *High I/O Wait Detected*
La CPU está perdiendo ciclos esperando al subsistema de almacenamiento.

- Acción: Identificar procesos con alta carga de escritura usando `top` o `iotop`. Verificar salud de arreglos RAID o latencia en volúmenes de red (NFS/EBS).

### C. [WARN] *Zombie Processes*
Procesos en estado Z. El *script* reportará el PID y el **PPID** (Parent PID).

- Acción: El proceso padre ha fallado en recolectar el estado de sus hijos. Enviar `SIGHUP` o `SIGCHLD` al PPID reportado. Si el problema persiste, considere reiniciar el servicio padre.

## 6. Resolución de Problemas (*Troubleshooting*)
- **"*Thermal sensors not reporting data*":** Común en entornos virtualizados donde el acceso al *hardware* físico está restringido. No afecta el resto de la auditoría.

- **Falla de dependencia:** El *script* intentará instalar `lm-sensors` si detecta una terminal interactiva (TTY). En entornos automatizados (CI/CD/Ansible), se recomienda pre-instalar el paquete.
