# 📚 Librería: `deploy-utils.sh`

- [📚 Librería: `deploy-utils.sh`](#-librería-deploy-utilssh)
  - [🔍 Dominio: Descubrimiento de Entorno (*Discovery*)](#-dominio-descubrimiento-de-entorno-discovery)
    - [`fetch_php_fpm_socket`](#fetch_php_fpm_socket)
  - [⚙️ Dominio: Gestión de Servicios](#️-dominio-gestión-de-servicios)
    - [`manage_service_unit`](#manage_service_unit)
  - [🌐 Dominio: Despliegue Web](#-dominio-despliegue-web)
    - [`deploy_nginx_vhost`](#deploy_nginx_vhost)
  - [🔐 Dominio: Seguridad y Secretos](#-dominio-seguridad-y-secretos)
    - [`generate_secure_secret`](#generate_secure_secret)

---

## 🔍 Dominio: Descubrimiento de Entorno (*Discovery*)

Funciones para detectar dinámicamente rutas y componentes del *stack*.

### `fetch_php_fpm_socket`

**Nivel de Riesgo:** Bajo (Lectura)

| Atributo             | Detalles                                                                    |
| :------------------- | :-------------------------------------------------------------------------- |
| **Propósito**        | Detectar la ruta del socket Unix de PHP-FPM basado en la versión instalada. |
| **Parámetros**       | Ninguno.                                                                    |
| **Dependencias**     | `php`, `find`.                                                              |
| **Salida/Efecto**    | Imprime la ruta absoluta del socket (ej. `/var/run/php/php8.3-fpm.sock`).   |
| **Estado de Salida** | `0`: Si se encuentra un socket, `1`: Si no se detecta ninguno.              |

**Ejemplo:**

```bash
PHP_SOCKET=$(fetch_php_fpm_socket)
```

## ⚙️ Dominio: Gestión de Servicios

Abstracción de comandos de control del sistema.

### `manage_service_unit`

**Nivel de Riesgo:** Medio (Cambio de Estado)

| **Atributo**         | **Detalles**                                                                          |
| -------------------- | ------------------------------------------------------------------------------------- |
| **Propósito**        | Ejecutar acciones de systemd (start, stop, etc.) con validación previa de existencia. |
| **Parámetros**       | `$1`: Acción, `$2`: Nombre del servicio.                                              |
| **Dependencias**     | `systemctl`.                                                                          |
| **Salida/Efecto**    | Cambia el estado del servicio y registra el resultado en el log.                      |
| **Estado de Salida** | `0`: Éxito, `1`: Fallo o servicio inexistente.                                        |

**Ejemplo:**

```Bash
manage_service_unit "restart" "piler"
```

## 🌐 Dominio: Despliegue Web

Gestión de VirtualHosts y configuraciones de servidor.

### `deploy_nginx_vhost`

**Nivel de Riesgo:** Alto (Configuración Crítica)

| **Atributo**         | **Detalles**                                                                                                       |
| -------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Propósito**        | Desplegar una configuración de Nginx, validando la sintaxis antes de aplicar cambios.                              |
| **Parámetros**       | `$1`: Nombre del sitio, `$2`: Ruta al archivo fuente.                                                              |
| **Dependencias**     | `nginx`, `cp`, `ln`.                                                                                               |
| **Salida/Efecto**    | Crea archivos en `sites-available` y enlaces en `sites-enabled`. Realiza rollback automático si la sintaxis falla. |
| **Estado de Salida** | `0`: Éxito, `1`: Error en sintaxis o origen faltante.                                                              |

**Ejemplo:**

```Bash
deploy_nginx_vhost "piler" "/tmp/piler.conf"
```

## 🔐 Dominio: Seguridad y Secretos

Generación de datos sensibles para la instalación.

### `generate_secure_secret`

**Nivel de Riesgo:** Bajo (Generación)

| **Atributo**         | **Detalles**                                                                          |
| -------------------- | ------------------------------------------------------------------------------------- |
| **Propósito**        | Crear cadenas de texto aleatorias y seguras para contraseñas o llaves criptográficas. |
| **Parámetros**       | `$1`: Longitud (opcional, default 32).                                                |
| **Dependencias**     | `openssl`.                                                                            |
| **Salida/Efecto**    | Imprime una cadena alfanumérica sanitizada (sin caracteres de escape conflictivos).   |
| **Estado de Salida** | `0`: Éxito.                                                                           |

**Ejemplo:**

```Bash
DB_PASS=$(generate_secure_secret 24)
```
