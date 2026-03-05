# Engineering Manual: install-piler.sh

## Metadata

- **Script Name:** install-piler.sh
- **Version:** 0.2.0
- **Author / Owner:** Engineering Team / K'aatech
- **Last Review Date:** 2026-03-05
- **Operational Classification:**
  - [ ] Read-only
  - [ ] Idempotent
  - [x] Mutating
  - [x] Potentially Destructive (Modifica bases de datos y archivos de sistema)
- **Environment Scope:**
  - [ ] Development
  - [x] Staging
  - [x] Production

---

## 1. Propósito

Automatizar el despliegue de **Mail Piler** (*Open Source Email Archiving*) bajo estándares de seguridad y resiliencia. El *script* resuelve la complejidad de la compilación manual y la interconexión de componentes (Manticore, MariaDB, Nginx, PHP 8.3).

**Riesgos que mitiga:**

- Desalineación de rutas de activos entre versiones de fuente.
- Exposición de secretos en el historial de procesos (`ps aux`).
- Inconsistencia horaria en auditorías legales (*Timezone mismatch*).

---

## 2. Arquitectura y Lógica

El *script* sigue un patrón de **Compilación Nativa e Integración Atómica**:

1. **Fase de Gobernanza:** Captura de metadatos y validación de privilegios.
2. **Fase de Infraestructura:** Registro de repositorios oficiales (Manticore) e instalación de dependencias.
3. **Fase de Datos:** Aprovisionamiento de base de datos con contraseñas generadas dinámicamente.
4. **Fase de Construcción:** Compilación desde código fuente de *GitHub* para garantizar integridad de binarios.
5. **Fase de Localización:** Implementación de **Timezone Híbrido** (Sistema en UTC / App en Local TZ).

- **Privilegios:** Requiere `root`.
- **Modificación de estado:** Instala paquetes, crea usuarios de sistema, modifica `/etc/` y aprovisiona bases de datos.

---

## 3. Parámetros y Configuración

| Parámetro        | Valor por defecto        | Requerido | Descripción                                                  |
| ---------------- | ------------------------ | --------- | ------------------------------------------------------------ |
| PILER_HOSTNAME   | N/A                      | Sí        | FQDN para el acceso web y configuración de Nginx.            |
| MYSQL_ROOT_PASS  | N/A                      | Sí        | Contraseña de root de MariaDB para aprovisionamiento.        |
| PILER_USER       | piler                    | No        | Usuario de sistema y de base de datos.                       |
| DISPLAY_TZ       | Autodetectado (o UTC)    | No        | Zona horaria para la interfaz web (ej. America/Mexico_City). |
| MYSQL_PILER_PASS | Auto-generado (24 chars) | No        | Contraseña de la BD para la aplicación.                      |

---

## 4. Dependencias

- **bash >= 4.2**
- **PHP 8.3 FPM** (con extensiones mysqli, zip, ldap, gd, curl, xml).
- **Manticore Search** (Repositorio oficial).
- **MariaDB Server** >= 10.6.
- **Herramientas de compilación:** build-essential, libmariadb-dev, libssl-dev.

---

## 5. Instalación y Uso

```bash
# Otorgar permisos
chmod +x deploy/install-piler.sh

# Ejecución estándar (interactiva)
sudo ./deploy/install-piler.sh
```

## 6. Seguridad y Riesgos

- **Manejo de Secretos:** Las contraseñas se capturan mediante `read -s` para evitar el eco en la terminal y no se guardan en archivos temporales planos.
- ***Root*:** Necesario para la gestión de `systemd` y la instalación en `/usr/libexec/piler`.
- ***Encryption*:** Genera una llave de cifrado única de 56 bytes en `/etc/piler/piler.key` con permisos `600`.

## 7. Manejo de Errores

- **Fallo Seguro:** Implementa `set -euo pipefail`. Cualquier error detiene la ejecución inmediatamente.
- ***Logging*:** Los errores de compilación detallados se desvían a `/var/log/piler_build.log` para no saturar la salida estándar.

## 8. *Logging* y Trazabilidad

- **Evento de *Script*:** Salida estándar formateada por el *Logging Engine* de KISA.
- ***Build Log*:** `/var/log/piler_build.log` (contiene la salida de `./configure` y `make`).
- ***App Logs*:** Visibles vía `journalctl -u piler`.

## 9. Plan de Recuperación (*Rollback*)

El *script* no implementa *rollback* automático de binarios instalados. En caso de fallo:

1. Revisar `/var/log/piler_build.log` para identificar la dependencia faltante.
2. Eliminar el directorio temporal `${WORKING_DIR}` para reintentar la compilación limpia.
3. Para revertir la DB: `DROP DATABASE piler; DROP USER piler@localhost;`.

## 10. Limpieza

- **Temporales:** Usa un `trap` para eliminar el esquema SQL temporal en `/tmp/`.
- **Build Artifacts:** Se recomienda mantener `/tmp/piler_build` solo durante la instalación y eliminarlo manualmente tras validar el funcionamiento.

## 11. Consideraciones de *Performance*

- **Compilación:** Puede consumir el 100% de la CPU durante el proceso de `make` (5-10 minutos dependiendo de los *cores*).
- **Almacenamiento:** Requiere al menos 1GB libre en `/var` para la compilación y los índices iniciales.

## 12. Historial de Cambios Relevantes

- **v0.1.0:** Versión inicial basada en *Gist*.
- **v0.2.0:** Refactorización modular KISA, soporte PHP 8.3, corrección de mapeo de activos y lógica de *Timezone* híbrida.
