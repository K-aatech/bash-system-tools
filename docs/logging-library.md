# Engineering Manual: logging.sh (*Core Library*)

![Stable Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?color=blue&label=stable)
![Pre-release Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?include_prereleases&color=orange&label=dev-build)
![Dev Build Status](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml/badge.svg?branch=dev)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)
![License](https://img.shields.io/github/license/K-aatech/bash-system-tools)

## 1. Descripción General
Librería centralizada de funciones de registro (*logging*) y gestión de archivos para el ecosistema **K'aatech**. Su propósito es estandarizar cómo todos los *scripts* de la *suite* reportan eventos, gestionan colores en terminal y mantienen un histórico de *logs* organizado mediante rotación automática.

## 2. Detalles Técnicos
- **Lógica**: Basada en inyección de variables de entorno y detección de flujo. Proporciona funciones reutilizables que detectan automáticamente si la salida es una terminal (para aplicar colores ANSI) o un archivo (para texto plano).
- **Umbrales / Configuración:**
  - `LOG_FILE`: Default `/var/log/kaatech_report.log` - Ruta donde se centraliza la actividad.
  - `MAX_LOG_FILES`: Default `5` - Límite de archivos históricos para evitar el agotamiento de espacio en disco.
  - `TTY Detection`: Verifica `[[ -t 1 ]]` para decidir el uso de colores, garantizando *logs* limpios en archivos.

## 3. Dependencias
Esta librería es ultra-minimalista para maximizar la compatibilidad:
- `bash` (v4.0+)
- `coreutils` (`date`, `touch`, `seq`, `mv`)

## 4. Instalación y Uso
Al ser una librería, no se ejecuta directamente. Debe ser "fuenteada" (`sourced`) por otros `scripts`.

### Modo de integración recomendado:

```bash
# 1. Definir variables personalizadas (Opcional)
export LOG_FILE="/var/log/mi_servicio.log"
export MAX_LOG_FILES=10

# 2. Cargar la librería
LIB_PATH="$(dirname "$0")/../lib/logging.sh"
if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
else
    # Fallback log_event function...
fi
```

### Funciones disponibles:

- `log_event "LEVEL" "Message"`: Registra eventos (INFO, OK, WARN, CRIT).
- `rotate_logs`: Ejecuta el ciclo de rotación basado en `MAX_LOG_FILES`.

## 5. Resolución de Problemas (*Troubleshooting*)

- **Error "Permission denied" en /var/log**: El *script* que utiliza la librería debe ejecutarse con privilegios de `root` o el usuario debe tener permisos de escritura en el directorio de *logs*.
- **Logs muestran caracteres extraños (^[[33m)**: Esto ocurre si se fuerza la salida de colores hacia un archivo. La librería previene esto automáticamente mediante detección de TTY, pero asegúrese de no haber modificado las variables `CLR_*` manualmente.

## 6. Recuperación ante Desastres (Plan de Acción)

1. **Log de crecimiento descontrolado**: Si un archivo de *log* crece demasiado rápido, verifique que `rotate_logs` se esté llamando correctamente al inicio de la ejecución del *script* principal.
2. **Falla en rotación**: Si los archivos `.1`, `.2` no se crean, verifique que no haya archivos con permisos de solo lectura en el directorio de destino que bloqueen el comando `mv`.

## 7. Limpieza y Logs

- **Archivos generados**: Eliminar manualmente los archivos definidos en la variable `LOG_FILE` y sus versiones numeradas (`.1`, `.2`, etc.).

- **Configuraciones**: La librería no modifica archivos del sistema por sí sola, solo interactúa con el sistema de archivos en las rutas de *log* indicadas.

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
