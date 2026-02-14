# Guía de Estilo de Ingeniería | K'aatech

![Stable Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?exclude_prereleases&color=blue&label=stable)
![CI Status](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml/badge.svg?branch=main)
![Platform](https://img.shields.io/badge/platform-Linux-steelblue)
![License](https://img.shields.io/github/license/K-aatech/bash-system-tools)

Este documento define los estándares de codificación para todos los scripts de automatización e infraestructura. El cumplimiento de estas reglas es obligatorio para garantizar la confiabilidad en entornos de producción.

## 1. Estándares de Bash
- **Shebang:** Usar siempre `#!/usr/bin/env bash`.
- **Modo Seguro:** Todo script debe iniciar con `set -euo pipefail` para detener la ejecución ante errores.
- **Indentación:** 4 espacios (configurado en `.editorconfig`).
- **Naming:**
  - Variables globales: `UPPER_CASE` (ej. `BACKUP_DIR`).
  - Variables locales y funciones: `snake_case` (ej. `local check_status`).

    > [!NOTE]
    > Utilice: "${VAR:=val}" para variables globales en bibliotecas para evitar colisiones de solo lectura durante el abastecimiento.

## 2. Pilares de Infraestructura (Obligatorios)

### A. Idempotencia
El script debe ser seguro de ejecutar múltiples veces.
- *Ejemplo:* Antes de añadir una línea a un archivo, verificar si ya existe usando `grep`.
  - *Mal:* `echo "config" >> /etc/file`
  - *Bien:* `grep -qxF "config" /etc/file || echo "config" >> /etc/file`

### B. Manejo de Errores y *Logging*
Está prohibido el uso de `echo` directo para mensajes de estado. Se debe invocar la función `log_event` de la librería *core*.
- **Niveles soportados:** `INFO`, `OK`, `WARN`, `CRIT`.
- **Flujos de salida:**
  - `INFO` / `OK` → Enviados a `stdout`.
  - `WARN` / `CRIT` → Enviados a `stderr` mediante redirección (`>&2`).
- **Ejemplo de uso:** `log_event "CRIT" "Permisos insuficientes en /etc/shadow"`

### C. Limpieza (Cleanup)
Si el script genera archivos temporales, debe usar la instrucción `trap` para asegurar que se borren incluso si el script falla o es interrumpido (`Ctrl+C`).

## 3. Documentación y Código
- **Idioma del Código:** Variables, funciones y comentarios técnicos en **Inglés**.
- **Idioma de Documentación:** Manuales y guías en **Español**.
- **Mensajes de Commit:** Siguiendo el estándar ***Conventional Commits*** en **Inglés**.
  - Se debe explicar el "por qué" de comandos complejos o flags específicas de herramientas de red/sistema.
