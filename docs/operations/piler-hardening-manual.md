# Engineering Manual: piler-hardening.sh

## Metadata

- **Script Name:** piler-hardening.sh
- **Version:** 0.1.0
- **Author / Owner:** K'aatech Engineering Team
- **Last Review Date:** 2026-03-10
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

- **Validación Elástica:** No depende de rutas estáticas. Verifica la existencia del binario `piler` en el `$PATH` y valida el estado operativo de los servicios `piler.service`, `piler-smtp.service` y `pilersearch.service`.
- **Delegación Inteligente:** Utiliza la librería `net-utils.sh` para la gestión autónoma de TLS. El *script* es capaz de detectar si falta información (FQDN, Email) y solicitarla interactivamente.
- **Protección de Disponibilidad:** Implementa el patrón *Pre-flight Validation* antes de cualquier recarga de servicio.

## 3. Parámetros y Configuración

| Parámetro | Valor por defecto            | Requerido | Descripción                                    |
| --------- | ---------------------------- | --------- | ---------------------------------------------- |
| LOG_FILE  | `./logs/piler-hardening.log` | No        | Ruta del archivo de persistencia de auditoría. |

> [!NOTE]
> Los parámetros de TLS (FQDN, Email, Challenge) son gestionados internamente por la función `configure_tls_edge` de forma interactiva.*

## 4. Dependencias

- **Librerías KISA:** `logging.sh`, `sys-utils.sh`, `net-utils.sh`.
- **Servicios:** `nginx`, `systemd`.
- **Binarios:** `piler`, `openssl`, `certbot` (opcional para modo automático).

## 5. Instalación y Uso

```bash
# Otorgar permisos de ejecución
chmod +x hardening/piler-hardening.sh

# Ejecución estándar (Modo Interactivo)
sudo ./hardening/piler-hardening.sh
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

- **v0.1.0 (2026-03-10):** *Refactor* completo. Integración con `net-utils.sh` v1.2.1. Implementación de validación elástica de servicios y orquestación segura de *Nginx*.
