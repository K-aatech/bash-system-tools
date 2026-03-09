# 📚 Librería: `logging.sh`

- [📚 Librería: `logging.sh`](#-librería-loggingsh)
  - [⚙️ Configuración y Variables](#️-configuración-y-variables)
    - [`KISA_LOG_FILE`](#kisa_log_file)
    - [`KISA_MAX_LOGS`](#kisa_max_logs)
  - [📝 Dominio: Gestión de Eventos](#-dominio-gestión-de-eventos)
    - [`log_event`](#log_event)
  - [🔄 Dominio: Mantenimiento](#-dominio-mantenimiento)
    - [`rotate_logs`](#rotate_logs)

---

## ⚙️ Configuración y Variables

Variables globales que permiten la inyección de parámetros.

### `KISA_LOG_FILE`

**Descripción:** Define la ruta absoluta del archivo de registro.
**Inyección:** Se puede personalizar definiendo `LOG_FILE` antes de cargar la librería.
**Default:** `/tmp/kaatech_report.log`

### `KISA_MAX_LOGS`

**Descripción:** Número máximo de archivos históricos para la rotación.
**Inyección:** Se puede personalizar mediante `MAX_LOG_FILES`.
**Default:** `5`

---

## 📝 Dominio: Gestión de Eventos

### `log_event`

**Nivel de Riesgo:** Bajo (Informativo)

| Atributo             | Detalles                                                                                                   |
| :------------------- | :--------------------------------------------------------------------------------------------------------- |
| **Propósito**        | Despachar mensajes formateados a la terminal y al archivo de persistencia de forma simultánea.             |
| **Parámetros**       | `$1`: Nivel (INFO, OK, WARN, CRIT), `$2`: Mensaje.                                                         |
| **Dependencias**     | `date`, `sed`, `printf`, `dirname`.                                                                        |
| **Salida/Efecto**    | Salida colorizada en `stderr`. Escritura sanitizada (sin ANSI) en el archivo definido por `KISA_LOG_FILE`. |
| **Estado de Salida** | `0`: Siempre exitoso (fallo silencioso en escritura si no hay permisos).                                   |

**Ejemplo:**

```bash
LOG_FILE="/var/log/myapp.log" log_event "OK" "Servicio iniciado"
```

## 🔄 Dominio: Mantenimiento

### `rotate_logs`

**Nivel de Riesgo:** Medio (Manipulación de Archivos)

| **Atributo**         | **Detalles**                                                                                              |
| -------------------- | --------------------------------------------------------------------------------------------------------- |
| **Propósito**        | Realizar una rotación de archivos `.log`, `.log.1`, etc., para evitar el agotamiento de espacio en disco. |
| **Parámetros**       | Ninguno.                                                                                                  |
| **Dependencias**     | `mv`, `rm`, `touch`, `dirname`.                                                                           |
| **Salida/Efecto**    | Renombrado cíclico de archivos históricos y creación de un nuevo archivo base con permisos `0640`.        |
| **Estado de Salida** | `0`: Éxito o retorno temprano si el directorio no es escribible.                                          |

**Ejemplo:**

```Bash
# Se recomienda ejecutar al inicio de cada proceso de despliegue
rotate_logs
```
