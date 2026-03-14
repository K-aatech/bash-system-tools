# Engineering Manual: piler-hardening.sh

## Metadata

- **Script Name:** piler-hardening.sh
- **Version:** 0.2.0
- **Author / Owner:** K'aatech Engineering Team
- **Last Review Date:** 2026-03-14
- **Operational Classification:**
  - [ ] Read-only
  - [x] Idempotent
  - [x] Mutating
  - [ ] Potentially Destructive
- **Environment Scope:**
  - [x] Development
  - [x] Staging
  - [x] Production

## 1. Propósito

Automatizar el endurecimiento (*hardening*) de seguridad post-instalación para Mail Piler.

Este *script* mitiga riesgos de interceptación de tráfico (MitM) y ataques de degradación de protocolo mediante la configuración estricta de TLS 1.3, cabeceras HSTS y la gestión automatizada de certificados vía *Certbot*.

## 2. Arquitectura y Lógica

- **Resolución de Identidad Multinivel:** Implementa el patrón *Identity Resolver*. El *script* busca el *FQDN* y *Email* administrativo en el siguiente orden:
  1. Variables de entorno exportadas
  2. Archivo de configuración `.env`
  3. *Prompt* interactivo (*fallback*).
- **Gobernanza No Intrusiva (*Snippets*):** A diferencia de versiones anteriores, el TLS no se inyecta directamente en el bloque de servidor. Se genera un *snippet* independiente y se vincula mediante una directiva `include` controlada, facilitando auditorías y reversión de cambios.
- **Validación Elástica:** No depende de rutas estáticas. Verifica la existencia del binario `piler` en el `$PATH` y valida el estado operativo de los servicios `piler.service`, `piler-smtp.service` y `pilersearch.service`.
- **Delegación Inteligente:** Utiliza la librería `net-utils.sh` para la gestión autónoma de TLS. El *script* es capaz de detectar si falta información (FQDN, Email) y solicitarla interactivamente.
- **Protección de Disponibilidad:** Implementa el patrón *Pre-flight Validation* antes de cualquier recarga de servicio.

## 3. Parámetros y Configuración

| Parámetro       | Variable de Entorno | Requerido | Descripción                                                      |
| :-------------- | :------------------ | :-------- | :--------------------------------------------------------------- |
| **LOG_FILE**    | `LOG_FILE`          | No        | Ruta del archivo de persistencia de auditoría.                   |
| **FQDN**        | `PILER_FQDN`        | Sí *      | Nombre de dominio totalmente calificado para el certificado TLS. |
| **Admin Email** | `PILER_ADMIN_EMAIL` | Sí *      | Correo para notificaciones de seguridad de Let's Encrypt.        |

> [!TIP]
> **Automatización vía `.env`**: El script busca un archivo `.env` en la raíz del proyecto. Ejemplo de contenido:
>
> ```env
> PILER_FQDN=piler.dominio.com
> PILER_ADMIN_EMAIL=admin@dominio.com
> ```
>
> \* *Si no se proveen mediante ENV o .env, el script pasará a modo interactivo para solicitarlos.*

## 4. Dependencias

- **Librerías KISA:** `logging.sh`, `sys-utils.sh`, `net-utils.sh`.
- **Servicios:** `nginx`, `systemd`.
- **Binarios:** `piler`, `openssl`, `certbot` (opcional para modo automático).

## 5. Instalación y Uso

```bash
# Otorgar permisos de ejecución
chmod +x hardening/piler-hardening.sh

# Opción A: Ejecución estándar (Modo Interactivo)
sudo ./hardening/piler-hardening.sh

# Opción B: Automatización mediante inyección de variables (Modo CI/CD)
sudo PILER_FQDN="mail.kisa.com" PILER_ADMIN_EMAIL="ops@kisa.com" ./hardening/piler-hardening.sh

# Opción C: Uso de archivo .env
# El script cargará automáticamente las variables si el archivo existe en la ruta relativa.
```

## 6. Seguridad y Riesgos

- **¿Requiere root?** Sí (valida privilegios mediante `require_root_privileges`).
- **¿Modifica archivos?** Sí, inyecta configuraciones en `/etc/nginx/conf.d/` y genera parámetros DH.
- **Impacto en Red:** Valida la visibilidad de los puertos 80, 443 y 25. Gestiona el intercambio de retos de red (`HTTP-01`) con los servidores de *Let's Encrypt* a través de *Nginx*. No modifica reglas de *Firewall*/*Iptables*.

## 7. Manejo de Errores

El *script* utiliza el código de salida `1` para fallos críticos. Gracias a la función `safe_service_config_apply`, si una configuración de *Nginx* es inválida, el *script* aborta **antes** de afectar el servicio en ejecución, garantizando 0% de *downtime* accidental por errores de sintaxis.

## 8. Logging y Trazabilidad

- Los eventos se registran en tiempo real con niveles `INFO`, `OK`, `WARN` y `CRIT`.
- Se incluye la verificación de renovación automática de *Certbot* en los *logs* finales.

## 9. Plan de Recuperación (Rollback)

En caso de fallo crítico en la aplicación de certificados:

1.Revisar los *logs* en `./logs/piler-hardening.log`.
2.La configuración previa de *Nginx* se mantiene intacta si la validación falló.
3.Para revertir cambios manuales en *Nginx*: `rm /etc/nginx/conf.d/kisa-hardening.conf && systemctl reload nginx`.

## 10. Historial de Cambios Relevantes

- **v0.2.0 (2026-03-14):** Implementación de *Identity Resolver* con soporte para `.env`. Migración a arquitectura de *SSL Snippets* y vinculación automática de Vhosts mediante `link_ssl_snippet`.
- **v0.1.0 (2026-03-10):** *Refactor* completo. Integración con `net-utils.sh` v1.2.1. Implementación de validación elástica de servicios y orquestación segura de *Nginx*.
