# Manual de Ingeniería: (`audit/sys-audit-check.sh`)

![Stable Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?exclude_prereleases&color=blue&label=stable)
![Pre-release Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?include_prereleases&color=orange&label=dev-build)
![Dev Build Status](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml/badge.svg?branch=dev)
![Platform](https://img.shields.io/badge/platform-Linux-steelblue)
![License](https://img.shields.io/github/license/K-aatech/bash-system-tools)

## 1. Descripción General
*Utility* profesional de auditoría para la infraestructura de K'aatech. Diseñada para proporcionar visibilidad inmediata sobre la salud, seguridad y rendimiento de servidores Linux (optimizada para Ubuntu Server 22.04+).


### **Características principales:**
* **Integridad de Archivos:** Verificación de permisos críticos en `/etc/passwd`, `/etc/shadow` y `/etc/sudoers`.
* **Auditoría de Red:** Listado de puertos en escucha y *sockets* activos.
* **Rendimiento de CPU:** Monitoreo de *Load Average* (1m, 5m, 15m), *I/O Wait* (latencia de disco) y top 3 de procesos.
* **Monitoreo de memoria:** Calcula el porcentaje de uso de memoria RAM y alerta si excede el 80%.
* **Auditoria de almacenamiento:** Escanea todas las particiones montadas y advierte si el uso es superior al 90%.
* **Gestión de Procesos:** Identificación de procesos *Zombie* y rastreo de su proceso padre (PPID).
* **Salud Térmica:** Lectura de sensores de temperatura y estado de ventiladores (requiere `lm-sensors`).
* ***Logging* Persistente:** Sistema automático de rotación de *logs* (hasta 5 archivos por defecto).

## 2. Detalles Técnicos
- **Lógica:** Operaciones de lectura y validación de estado del sistema con sistema de *logging* persistente y rotación automática.
- **Umbrales (*Thresholds*):**
  - **RAM:** >80% (*Warn*) - Basado en la necesidad de mantener *buffer* para picos de carga.
  - **Disco:** >90% (*Critical*) - Margen de seguridad estándar para evitar bloqueos de escritura.
  - **Temperatura CPU:** >75°C (*Alert*) - Límite preventivo antes de *thermal throttling*.
  - ***I/O Wait*:** >5.0% - Indica latencia de disco impactando el rendimiento del CPU.

## 3. Dependencias
El *script* es minimalista y utiliza herramientas estándar de POSIX:
- `bash` (v4.0+)
- `awk`, `sed`, `grep`, `ps`, `df`, `free`, `uptime`, `top` (Coreutils)
- `ss` (iproute2) para auditoría de red.
- `lm-sensors` (Opcional, para datos térmicos). El *script* gestiona su instalación interactiva.

## 4. Instalación y Uso
El *script* requiere privilegios de **root** para rotación de *logs*, verificación de `/etc/shadow` e instalación de dependencias.

### Instalación en el Sistema (*Standalone*)
Para desplegar el monitor como una herramienta global del sistema:

```bash
# 1. Descargar la versión estable v1.7.0
sudo curl -L -o /usr/local/bin/sys-audit-check.sh https://raw.githubusercontent.com/K-aatech/bash-system-tools/v1.7.0/audit/sys-audit-check.sh

# 2. Asegurar propiedad y permisos restringidos (Solo Root)
sudo chown root:root /usr/local/bin/sys-audit-check.sh
sudo chmod 700 /usr/local/bin/sys-audit-check.sh

# 3. Ejecución
sudo sys-audit-check.sh
```

> [!NOTE]
> Al instalarlo en `/usr/local/bin`, puedes ejecutarlo simplemente llamando a `sys-audit-check.sh` desde cualquier ubicación si dicha ruta está en tu `$PATH`.

## 5. Resolución de Problemas (*Troubleshooting*)
* **"*Thermal sensors not reporting data*":** Verifique si está en una VM o si necesita ejecutar `sudo sensors-detect`.
* **"*Critical dependency missing*":** El *script* intentará identificar qué comando falta. Instale el paquete correspondiente (ej: `sysstat` para `iostat` o `lm-sensors`).
* **Error de escritura en *Log*:** Asegúrese de que el *script* se ejecute con `sudo` para poder escribir y rotar en `/var/log`.

## 6. Recuperación ante Desastres (Plan de Acción)
Si el *script* reporta niveles críticos:

1. **[*CRITICAL*] *File Integrity*:** Riesgo de seguridad. Un archivo crítico (como `/etc/shadow`) tiene permisos de escritura universal. Ejecutar `sudo chmod 600 /etc/shadow` inmediatamente.
2. **[*WARN*] *Zombie Processes*:** Identificar el proceso padre (PPID) reportado por el *script* y enviar señal `SIGHUP` o `SIGCHLD` para limpiar huérfanos.
3. **[*WARN*] *High I/O Wait*:** El disco está saturado. Revisar procesos con alta escritura usando `iotop` o revisar salud de arreglos RAID.

## 7. Limpieza y Logs

* ***Logs***: Se almacenan en `/var/log/kaatech_audit.log`.
* **Rotación**: El *script* mantiene hasta 5 archivos históricos (`.1` a `.5`) de forma autónoma.
* **Archivos Temporales**: El *script* no deja archivos temporales residuales; utiliza *pipes* y variables de entorno para procesar datos en memoria.


|Nivel|Significado|Acción Recomendada|
|:----|:----|:----|
|[*INFO*]|Operación normal o chequeo exitoso.|Ninguna.|
|[*WARN*]|Umbral superado (RAM, Disco, Temp) o procesos *Zombie*.|Revisar carga del sistema o limpiar huérfanos.|
|[*CRITICAL*]|Riesgo de seguridad (*World-writable files*) o falta de archivos.|Intervención inmediata. Corregir permisos de archivos críticos.|


### 7.1 Gestión Avanzada de Salidas (*Streams*)
El *script* separa los flujos de información siguiendo el estándar **POSIX**, lo que permite una integración profesional con sistemas de monitoreo:

- **Stdout (Canal 1):** Mensajes `[INFO]` y `[ OK ]`.
- **Stderr (Canal 2):** Mensajes `[WARN]` y `[CRIT]`.

Debido a la arquitectura de la librería de logging, una ejecución puede generar tres fuentes de datos:
1. **Archivo Maestro:** `$LOG_FILE` (definido en el script). Es persistente y siempre en texto plano.
2. **Captura de Info:** `./sys-audit-check.sh > info.log`.
3. **Captura de Alertas:** `./sys-audit-check.sh 2> alertas.log`.

> [!IMPORTANT]
> **Nota sobre Colores ANSI:** La librería detecta automáticamente si la salida es una terminal para aplicar colores. Si usted redirige **solo uno** de los flujos pero mantiene el otro en pantalla, es posible que los archivos `.log` resultantes contengan códigos de color ANSI. Para una captura totalmente limpia en archivos externos, se recomienda redirigir ambos flujos simultáneamente:

```bash
sudo ./audit/sys-audit-check.sh > audit_info.log 2> audit_alertas.log
```
