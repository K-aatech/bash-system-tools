# 📚 Librería: `net-utils.sh`

- [📚 Librería: `net-utils.sh`](#-librería-net-utilssh)
  - [🌐 Dominio: Descubrimiento de Red (Discovery)](#-dominio-descubrimiento-de-red-discovery)
    - [`fetch_network_metadata`](#fetch_network_metadata)
    - [`fetch_dns_metadata`](#fetch_dns_metadata)
  - [⚡ Dominio: Vitalidad y Rendimiento](#-dominio-vitalidad-y-rendimiento)
    - [`verify_internet_connectivity`](#verify_internet_connectivity)
    - [`audit_multi_cloud_latency`](#audit_multi_cloud_latency)
  - [🔌 Dominio: Auditoría de Sockets y Puertos](#-dominio-auditoría-de-sockets-y-puertos)
    - [`audit_listening_sockets`](#audit_listening_sockets)
    - [`verify_port_activity`](#verify_port_activity)
  - [🔐 Dominio: Seguridad Perimetral y TLS](#-dominio-seguridad-perimetral-y-tls)
    - [`apply_nginx_hardening`](#apply_nginx_hardening)
    - [`configure_tls_edge`](#configure_tls_edge)
  - [🏗️ Dominio: Orquestación de Servicios (*Edge*)](#️-dominio-orquestación-de-servicios-edge)
    - [`safe_service_config_apply`](#safe_service_config_apply)

---

## 🌐 Dominio: Descubrimiento de Red (Discovery)

Funciones para la identificación de interfaces y topología local.

### `fetch_network_metadata`

**Nivel de Riesgo:** Bajo (Lectura)

| **Atributo**         | **Detalles**                                                                             |
| -------------------- | ---------------------------------------------------------------------------------------- |
| **Propósito**        | Identificar la interfaz de red principal, IP, máscara y puerta de enlace predeterminada. |
| **Parámetros**       | Ninguno.                                                                                 |
| **Dependencias**     | Binario `ip` (iproute2), `awk`, `timeout`.                                               |
| **Salida/Efecto**    | Exporta variables globales: `KISA_IFACE`, `KISA_PRIMARY_IP`, `KISA_NETMASK`, `KISA_GW`.  |
| **Estado de Salida** | `0`: Éxito (incluso si no detecta red, las variables se inicializan).                    |

**Ejemplo:**

```bash
fetch_network_metadata
echo "IP Detectada: $KISA_PRIMARY_IP"
```

### `fetch_dns_metadata`

**Nivel de Riesgo:** Bajo (Lectura)

| **Atributo**         | **Detalles**                                                      |
| -------------------- | ----------------------------------------------------------------- |
| **Propósito**        | Extraer los servidores DNS configurados en el sistema.            |
| **Parámetros**       | Ninguno.                                                          |
| **Dependencias**     | Archivo `/etc/resolv.conf`, `grep`, `awk`.                        |
| **Salida/Efecto**    | Exporta la variable global `KISA_DNS` con la lista de servidores. |
| **Estado de Salida** | `0`: Éxito.                                                       |

**Ejemplo:**

```Bash
fetch_dns_metadata
log_event "INFO" "DNS configurados: $KISA_DNS"
```

## ⚡ Dominio: Vitalidad y Rendimiento

Pruebas de conectividad y latencia hacia nubes externas (*Fierro-to-Cloud*).

### `verify_internet_connectivity`

**Nivel de Riesgo:** Bajo (Conectividad)

| **Atributo**         | **Detalles**                                                             |
| -------------------- | ------------------------------------------------------------------------ |
| **Propósito**        | Confirmar salida a internet mediante una prueba de eco (Ping) a 8.8.8.8. |
| **Parámetros**       | Ninguno.                                                                 |
| **Dependencias**     | Binario `ping`.                                                          |
| **Estado de Salida** | `0`: Conexión exitosa, `1`: Sin acceso a internet.                       |

**Ejemplo:**

```Bash
if verify_internet_connectivity; then
    log_event "OK" "Continuando con la descarga..."
fi
```

### `audit_multi_cloud_latency`

**Nivel de Riesgo:** Bajo (Informativo)

| **Atributo**         | **Detalles**                                                                     |
| -------------------- | -------------------------------------------------------------------------------- |
| **Propósito**        | Medir la latencia promedio hacia proveedores críticos (AWS, Cloudflare, Google). |
| **Parámetros**       | Ninguno.                                                                         |
| **Dependencias**     | Binario `ping`, `awk`.                                                           |
| **Salida/Efecto**    | Reporta los tiempos de respuesta en milisegundos (ms) vía `log_event`.           |
| **Estado de Salida** | `0`: Éxito.                                                                      |

**Ejemplo:**

```Bash
audit_multi_cloud_latency
```

## 🔌 Dominio: Auditoría de Sockets y Puertos

Inspección de servicios activos y escucha en el stack TCP/UDP local.

### `audit_listening_sockets`

**Nivel de Riesgo:** Bajo (Lectura)

| **Atributo**         | **Detalles**                                                       |
| -------------------- | ------------------------------------------------------------------ |
| **Propósito**        | Listar todos los procesos que están escuchando en puertos TCP/UDP. |
| **Parámetros**       | Ninguno.                                                           |
| **Dependencias**     | Binario `ss` (iproute2), `awk`.                                    |
| **Salida/Efecto**    | Mapeo visual de Protocolo, Puerto y Proceso en consola.            |
| **Estado de Salida** | `0`: Éxito.                                                        |

**Ejemplo:**

```Bash
audit_listening_sockets
```

### `verify_port_activity`

**Nivel de Riesgo:** Bajo (Verificación)

| **Atributo**         | **Detalles**                                                                  |
| -------------------- | ----------------------------------------------------------------------------- |
| **Propósito**        | Validar si uno o varios puertos específicos están activos en el stack local.  |
| **Parámetros**       | `$@`: Lista de puertos (ej. `80 443 25`). Soporta múltiples argumentos.       |
| **Dependencias**     | Binario `ss`.                                                                 |
| **Salida/Efecto**    | Mensaje de confirmación por cada puerto; retorna error si al menos uno falla. |
| **Estado de Salida** | `0`: Todos los puertos activos, `1`: Al menos un puerto inactivo.             |

**Ejemplo:**

```Bash
verify_port_activity 80 443 25 || log_event "WARN" "Revisar servicios de red."
```

## 🔐 Dominio: Seguridad Perimetral y TLS

Hardening de servicios de red y gestión de certificados.

### `apply_nginx_hardening`

**Nivel de Riesgo:** Medio (Configuración)

| **Atributo**         | **Detalles**                                                                                           |
| -------------------- | ------------------------------------------------------------------------------------------------------ |
| **Propósito**        | Inyectar políticas de seguridad en Nginx (HSTS, TLS 1.3, Ciphers fuertes y parámetros Diffie-Hellman). |
| **Parámetros**       | Ninguno.                                                                                               |
| **Dependencias**     | Función `require_root_privileges` (de `sys-utils.sh`). Binarios `nginx`, `openssl`.                    |
| **Salida/Efecto**    | Genera `/etc/nginx/dhparam.pem` y `/etc/nginx/conf.d/kisa-hardening.conf`.                             |
| **Estado de Salida** | `0`: Éxito, `1`: Error (Nginx no encontrado).                                                          |

**Ejemplo:**

```Bash
require_root_privileges
apply_nginx_hardening
```

### `configure_tls_edge`

**Nivel de Riesgo:** Alto (Certificados)

| **Atributo**         | **Detalles**                                                                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Propósito**        | Orquestar la obtención de certificados SSL/TLS. **Modo Autónomo:** Si faltan datos en sesión interactiva, los solicita al usuario.                            |
| **Parámetros**       | `$1`: Dominio, `$2`: Email, `$3`: Modo (certbot/manual), `$4`: Reto (nginx/standalone/dns), `$5`: Staging (true/false). Todos opcionales en modo interactivo. |
| **Dependencias**     | Función `verify_binary_existence` (de `sys-utils.sh`), binario `certbot`.                                                                                     |
| **Salida/Efecto**    | Instalación de certificados en el sistema y configuración de renovación automática.                                                                           |
| **Estado de Salida** | `0`: Éxito, `1`: Fallo en el reto de Certbot o falta de datos críticos.                                                                                       |

**Ejemplo:**

```Bash
configure_tls_edge "mail.midominio.com" "admin@midominio.com" "certbot" "nginx" "false"

# Modo totalmente autónomo (interactivo)
configure_tls_edge
```

## 🏗️ Dominio: Orquestación de Servicios (*Edge*)

### `safe_service_config_apply`

**Nivel de Riesgo:** Medio (Operacional)

| **Atributo**         | **Detalles**                                                                                                                           |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Propósito**        | Aplicar cambios de configuración de forma segura, validando sintaxis antes de recargar/reiniciar el servicio para prevenir *downtime*. |
| **Parámetros**       | `$1`: Nombre del servicio, `$2`: Comando de validación (ej. `nginx -t`), `$3`: Acción (`reload`/`restart`).                            |
| **Dependencias**     | Binario del servicio (`$1`), función `control_service_state`.                                                                          |
| **Salida/Efecto**    | Valida configuración; si es correcta, aplica la acción. Si es incorrecta, aborta la operación y registra el error.                     |
| **Estado de Salida** | `0`: Validación y acción exitosas, `1`: Error de sintaxis o fallo al aplicar acción.                                                   |

**Ejemplo:**

```Bash
safe_service_config_apply "nginx" "nginx -t" "reload"
```
