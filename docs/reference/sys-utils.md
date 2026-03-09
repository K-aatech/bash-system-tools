# 📚 Librería: `sys-utils.sh`

- [📚 Librería: `sys-utils.sh`](#-librería-sys-utilssh)
  - [⚙️ Configuración y Constantes](#️-configuración-y-constantes)
    - [`KISA_PATH_POLICY`](#kisa_path_policy)
  - [🛠️ Dominio: Integridad del Sistema](#️-dominio-integridad-del-sistema)
    - [`require_root_privileges`](#require_root_privileges)
    - [`verify_binary_existence`](#verify_binary_existence)
    - [`verify_service_status`](#verify_service_status)
    - [`install_missing_dependencies`](#install_missing_dependencies)
  - [🔍 Dominio: Auditoría de Seguridad](#-dominio-auditoría-de-seguridad)
    - [`audit_baseline_permissions`](#audit_baseline_permissions)
    - [`verify_path_owner_mode`](#verify_path_owner_mode)
    - [`audit_container_health`](#audit_container_health)
  - [🖥️ Dominio: Interfaz y Usuario](#️-dominio-interfaz-y-usuario)
    - [`print_section`](#print_section)
    - [`request_input`](#request_input)
  - [📊 Dominio: Descubrimiento de datos](#-dominio-descubrimiento-de-datos)
    - [`fetch_host_metadata`](#fetch_host_metadata)

---

## ⚙️ Configuración y Constantes

Variables globales que definen el comportamiento de la librería.

### `KISA_PATH_POLICY`

**Tipo:** Matriz de Solo Lectura (*Readonly Array*)
**Descripción:** Define la matriz de permisos esperados para archivos críticos del sistema. Utilizada por el motor de auditoría para verificar desviaciones de seguridad.

## 🛠️ Dominio: Integridad del Sistema

Funciones diseñadas para garantizar que el entorno de ejecución cumpla con los requisitos mínimos de seguridad y *software*.

### `require_root_privileges`

**Nivel de Riesgo:** Alto (Control de Acceso)

| Atributo             | Detalles                                                                                         |
| :------------------- | :----------------------------------------------------------------------------------------------- |
| **Propósito**        | Detener inmediatamente la ejecución si el script no cuenta con permisos de superusuario (UID 0). |
| **Parámetros**       | N/A                                                                                              |
| **Dependencias**     | Variable de entorno `${EUID}`                                                                    |
| **Salida/Efecto**    | Termina el proceso (`exit 1`) si la validación falla.                                            |
| **Estado de salida** | `0`: Éxito, `1`: Fallo                                                                           |

**Example:**

```bash
require_root_privileges
```

### `verify_binary_existence`

**Nivel de riesgo:** Medio (Pre-vuelo)

| **Atributo**         | **Detalles**                                                                                 |
| -------------------- | -------------------------------------------------------------------------------------------- |
| **Propósito**        | Validar que las herramientas necesarias para la ejecución existan en el `$PATH` del sistema. |
| **Parámetros**       | `$@`: Lista de nombres de binarios (strings).                                                |
| **Dependencias**     | Comando `command -v`                                                                         |
| **Salida/Efecto**    | Genera un evento `log_event "CRIT"` y aborta si falta algún binario.                         |
| **Estado de salida** | `0`: Todos encontrados, `1`: Al menos uno falta                                              |

**Example:**

```bash
verify_binary_existence "openssl" "nginx"
```

### `verify_service_status`

**Nivel de Riesgo:** Medio (Pre-vuelo)

| **Atributo**      | **Detalles**                                                                    |
| ----------------- | ------------------------------------------------------------------------------- |
| **Propósito**     | Validar que una lista de servicios de Systemd estén registrados y activos.      |
| **Parámetros**    | `$@`: Nombres de los servicios (ej. `nginx.service`).                           |
| **Salida/Efecto** | Lanza un error crítico si el servicio no existe; advierte si no está corriendo. |

**Ejemplo:**

```Bash
verify_service_status "piler.service" "piler-smtp.service"
```

### `install_missing_dependencies`

**Nivel de riesgo:** Alto (Cambio de sistema)

| **Atributo**         | **Detalles**                                                                                                        |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Propósito**        | Detectar binarios faltantes e intentar instalarlos automáticamente usando el gestor de paquetes de la distribución. |
| **Parámetros**       | `$@`: Lista de binarios requeridos.                                                                                 |
| **Dependencias**     | Función interna `_get_package_manager`.                                                                             |
| **Salida/Efecto**    | Actualiza repositorios e instala paquetes. Requiere confirmación en modo interactivo.                               |
| **Estado de salida** | `0`: Éxito, `1`: Fallo o abortado por usuario                                                                       |

**Example:**

```Bash
install_missing_dependencies "memcached" "php-cli"
```

## 🔍 Dominio: Auditoría de Seguridad

Herramientas para la verificación proactiva de la superficie de ataque y cumplimiento de políticas de seguridad.

### `audit_baseline_permissions`

**Nivel de riesgo:** Medio (Lógico)

| **Atributo**         | **Detalles**                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------- |
| **Propósito**        | Ejecutar una auditoría completa sobre archivos críticos del sistema según la política KISA. |
| **Parámetros**       | N/A                                                                                         |
| **Dependencias**     | Constante `KISA_PATH_POLICY` y función `verify_path_owner_mode`.                            |
| **Salida/Efecto**    | Reporta cada desajuste de permisos encontrado vía `log_event`.                              |
| **Estado de salida** | `int`: Número total de problemas encontrados.                                               |

**Example:**

```bash
audit_baseline_permissions
```

### `verify_path_owner_mode`

**Nivel de Riesgo:** Bajo (Lectura)

| **Atributo**   | **Detalles**                                                              |
| -------------- | ------------------------------------------------------------------------- |
| **Propósito**  | Comprobar si un archivo tiene exactamente los permisos octales indicados. |
| **Parámetros** | `$1`: Ruta al archivo, `$2`: Modo esperado (ej. 600).                     |
| **Retorno**    | `0` si coincide, `1` si hay discrepancia o el archivo no existe.          |

**Ejemplo:**

```Bash
verify_path_owner_mode "/etc/shadow" "600"
```

### `audit_container_health`

**Nivel de Riesgo:** Bajo (Lectura)

| **Atributo**         | **Detalles**                                                                          |
| -------------------- | ------------------------------------------------------------------------------------- |
| **Propósito**        | Verificar el estado del motor Docker y listar contenedores que no estén en ejecución. |
| **Parámetros**       | N/A                                                                                   |
| **Dependencias**     | Binario `docker`                                                                      |
| **Salida/Efecto**    | Resumen informativo de salud de contenedores en la salida estándar.                   |
| **Estado de salida** | `0`: Éxito                                                                            |

**Example:**

```Bash
# Ejecutar diagnóstico de contenedores
audit_container_health
```

## 🖥️ Dominio: Interfaz y Usuario

Estandarización de la interfaz de línea de comandos y métodos de captura de datos para el usuario.

### `print_section`

**Nivel de Riesgo:** Bajo (Visual)

| **Atributo**      | **Detalles**                                                                                |
| ----------------- | ------------------------------------------------------------------------------------------- |
| **Propósito**     | Imprimir un encabezado visual estilizado y con color para separar fases lógicas del script. |
| **Parámetros**    | `$1`: Título de la sección.                                                                 |
| **Salida/Efecto** | Imprime texto formateado a `stdout`.                                                        |

**Example:**

```Bash
print_section "Ejecutando diagnóstico de contenedores"
```

### `request_input`

**Nivel de riesgo:** Medio (Lógico)

| **Atributo**      | **Detalles**                                                                                      |
| ----------------- | ------------------------------------------------------------------------------------------------- |
| **Propósito**     | Capturar entrada de usuario de forma segura, permitiendo ocultar caracteres para datos sensibles. |
| **Parámetros**    | `$1`: Nombre de variable, `$2`: Texto de prompt, `$3`: Flag secreto (1/0).                        |
| **Salida/Efecto** | Asigna el valor capturado a la variable global especificada.                                      |

**Example:**

```Bash
request_input "DB_PASSWORD" "Ingrese contraseña de DB" 1
```

## 📊 Dominio: Descubrimiento de datos

Funciones para la recolección y exportación de metadatos del sistema anfitrión.

### `fetch_host_metadata`

**Nivel de Riesgo:** Bajo (Lectura)

| **Atributo**      | **Detalles**                                                                                |
| ----------------- | ------------------------------------------------------------------------------------------- |
| **Propósito**     | Recolectar información clave del sistema y exportarla en variables globales estandarizadas. |
| **Parámetros**    | N/A                                                                                         |
| **Salida/Efecto** | Exporta `KISA_HOSTNAME`, `KISA_UPTIME`, `KISA_KERNEL`, `KISA_DISTRO`, y `KISA_ARCH`.        |
