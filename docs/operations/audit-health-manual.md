# Engineering Manual: system-health-audit.sh

## Metadata

- **Script Name:** system-health-audit.sh
- **Version:** 0.1.1
- **Author / Owner:** K'aatech Engineering Team
- **Last Review Date:** 2026-03-14
- **Operational Classification:**
  - [x] Read-only
  - [x] Idempotent
  - [ ] Mutating
  - [ ] Potentially Destructive
- **Environment Scope:**
  - [x] Development
  - [x] Staging
  - [x] Production

---

## 1. Propósito

Proporcionar una visión integral y en tiempo real del estado de salud del sistema y la infraestructura.
Este *script* existe para garantizar que el nodo cumple con el **Governance Baseline**, mitigando riesgos de degradación de *hardware*, saturación de recursos y desviaciones de seguridad en permisos críticos.

---

## 2. Arquitectura y Lógica

- **Patrón Principal:** Monitoreo y Validación (*Audit-only*).
- **Flujo de Ejecución:**
  1. *Bootstrap* e inyección de dependencias (`logging`, `sys-utils`, `net-utils`).
  2. Validación de privilegios de *Root* y binarios requeridos.
  3. Ejecución secuencial de sondas (Térmica, CPU, RAM, Disco, Zombis).
  4. Auditoría de red y latencia *multi-cloud* (vía `net-utils`).
  5. Generación de reporte final basado en niveles de *log* (`OK`, `WARN`, `CRIT`).

Es **seguro ejecutarlo múltiples veces** (Idempotente) ya que no modifica el estado del sistema, salvo por la generación de *logs* y rotación de los mismos.

---

## 3. Parámetros y Configuración

| Parámetro        | Valor por defecto              | Requerido | Descripción                             |
| ---------------- | ------------------------------ | --------- | --------------------------------------- |
| THRESHOLD_DISK   | 90                             | No        | % máximo de uso de disco antes de WARN. |
| THRESHOLD_RAM    | 80                             | No        | % máximo de uso de RAM antes de WARN.   |
| THRESHOLD_TEMP   | 75                             | No        | Temperatura Celsius máxima permitida.   |
| THRESHOLD_IOWAIT | 5.0                            | No        | % de espera de I/O máximo permitido.    |
| LOG_FILE         | ./logs/system-health-audit.log | No        | Ruta del archivo de persistencia.       |

---

## 4. Dependencias

- **Bash** >= 4.2
- **Core:** `awk`, `sed`, `grep`, `df`, `free`, `uptime`, `vmstat`, `ps`, `ss`, `ping`.
- **Opcionales:** `sensors` (Lm-sensors), `bc`.

El script utiliza `verify_binary_existence` para validar las dependencias core antes de iniciar la Fase 1.

---

## 5. Instalación y Uso

```bash
## 5. Instalación y Uso

El script permite la personalización de umbrales de alerta mediante la inyección de variables de entorno al momento de la ejecución. Si no se proveen, se utilizarán los valores por defecto definidos en la Sección 3.

```bash
# 1. Otorgar permisos de ejecución
chmod +x audit/system-health-audit.sh

# 2. Ejecución estándar (Usa valores por defecto)
sudo ./audit/system-health-audit.sh

# 3. Ejecución con inyección de variables (Personalización de umbrales)
# Ejemplo: Alerta de RAM al 95% y Disco al 85%
sudo THRESHOLD_RAM=95 THRESHOLD_DISK=85 ./audit/system-health-audit.sh

# 4. Ejecución con ruta de log personalizada
sudo LOG_FILE="/var/log/kisa-audit.log" ./audit/system-health-audit.sh
```

## 6. Seguridad y Riesgos

- **¿Requiere *root*?** Sí, para acceder a métricas de *hardware* y *sockets* protegidos.
- **¿Modifica archivos?** No, solo lectura y escritura de su propio *log*  (*Audit-only*).
- **¿Interactúa con red?** Sí, realiza *pings* a *endpoints* de *Cloud* (AWS, GCP, Azure) para medir latencia.

## 7. Manejo de Errores

- **Exit 0:** Éxito (aunque existan WARN o CRIT en el sistema auditado).
- **Exit 1:** Error fatal (Falta de privilegios, dependencias core ausentes o librerías corruptas).
- No implementa *rollback* porque es una operación de solo lectura.

## 8. Logging y Trazabilidad

- **Ubicación:** Definida en `LOG_FILE` (predeterminado `./logs/system-health-audit.log`).

- **Detalle:** Incluye marcas de tiempo y niveles de severidad KISA.

- Los *logs* son rotados automáticamente mediante la integración con `logging.sh`.

## 9. Plan de Recuperación (*Rollback*)

Al ser un *script* de lectura, el fallo solo implica la ausencia de datos. Si el *script* se interrumpe, basta con eliminar el archivo de *log* parcial si se desea una ejecución limpia.

## 10. Consideraciones de *Performance*

- **CPU:** Impacto despreciable (<1%).
- **I/O:** Mínimo, limitado a lecturas de `/proc` y escritura de logs.
- **Red:** Genera una ráfaga pequeña de paquetes ICMP durante la fase de latencia.

## 11. Historial de Cambios Relevantes

- **v0.1.1 (2026-03-14):** Revisión a instrucciones de Instalación y Uso.
- **v0.1.0 (2026-03-09):** Refactorización completa para alineación con Suite v1.2.1. Integración de `logging.sh`, `sys-utils.sh` y `net-utils.sh`. Adopción de estándar de documentación Shdoc.
