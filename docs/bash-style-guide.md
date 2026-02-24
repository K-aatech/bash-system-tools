# *Bash Engineering Style Guide*

Este documento define los estándares obligatorios de ingeniería para *scripts* de automatización e infraestructura desarrollados en *Bash* y derivados del repositorio `baseline-scripts`.

El cumplimiento de esta guía es obligatorio para garantizar confiabilidad, portabilidad, mantenibilidad y seguridad operativa.

## 1. Requisitos de Ejecución

- ***Shell* mínimo requerido:** Bash >= 4.2
- ***Shebang* obligatorio:**

    ```bash
    #!/usr/bin/env bash
    ```

- **Modo Seguro (Obligatorio):**

    ```bash
    set -euo pipefail
    ```

Significado:

- `-e` → Termina la ejecución ante cualquier error.
- `-u` → Falla ante variables no definidas.
- `-o pipefail` → Detecta fallas en *pipelines*.

Cualquier excepción a esta regla debe estar documentada explícitamente en el encabezado del *script*.

## 2. Estándares de Formato

- **Indentación:** 2 espacios (definido en `.editorconfig`)
- **Final de línea:** LF
- **Espacios en blanco al final:** No permitidos
- **Mezcla de tabs y espacios:** Prohibida

## 3. Convenciones de Nombres

- **Variables globales:** `UPPER_CASE`

    ```bash
    BACKUP_DIR="/var/backups"
    ```

- **Variables locales:** `snake_case`

    ```bash
    local file_path="/tmp/data"
    ```

- **Funciones:** `snake_case`

    ```bash
    check_status() { ... }
    ```

- **Constantes:** `UPPER_CASE`

Evitar nombres de una sola letra salvo en *loops* de alcance reducido.

## 4. Gestión de Dependencias

Todo *script* que dependa de binarios externos debe validarlos antes de ejecutar lógica principal.

Patrón recomendado:

```bash
require_command() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: Missing required command: $cmd" >&2
        exit 1
    }
}
```

Las dependencias deben validarse al inicio del *script*.

## 5. Manejo de Errores

- Código de salida:
  - `0` → éxito
  - `1` → error genérico
  - Códigos personalizados solo si están documentados

- Está prohibido suprimir errores silenciosamente.
- Evitar `|| true` salvo justificación documentada.

## 6. Idempotencia (Obligatoria)

Los *scripts* deben ser seguros de ejecutar múltiples veces sin efectos secundarios indeseados.

Ejemplo correcto:

```bash
grep -qxF "config" /etc/file || echo "config" >> /etc/file`
```

Evitar operaciones que agreguen o sobrescriban contenido sin validación previa.

## 7. Limpieza y Manejo de Señales

Si el *script* genera archivos temporales o realiza modificaciones transitorias, debe implementar limpieza mediante `trap`.

Ejemplo:

```bash
cleanup() {
    rm -f "$temp_file"
}

trap cleanup EXIT`
```

Cuando sea pertinente, manejar señales `INT` y `TERM`.

## 8. Manejo Seguro de Entrada

- Citar siempre las expansiones de variables:

    ```bash
    "$variable"
    ```

- Evitar sustituciones no citadas.
- Controlar `IFS` explícitamente al iterar sobre entrada externa:

    ```bash
    IFS=$'\n\t'
    ```

Todo *script* que acepte argumentos debe validar que los parámetros obligatorios no estén vacíos antes de proceder.

## 9. Estrategia de *Logging*

El uso directo de `echo` está permitido en *scripts* simples. <br>
Ejemplo:
`echo "Error: File not found" >&2`

Para automatizaciones de mayor complejidad se recomienda:

- Niveles de log (`INFO`, `WARN`, `ERROR`)
- Separación entre `stdout` y `stderr`
- Formato consistente

La implementación de *logging* no debe acoplarse a la lógica de negocio.

Los mensajes de error deben redirigirse obligatoriamente a `stderr` (`>&2`) para no interferir con la salida de datos del *script*.

```bash
log_error() {
    echo "[ERROR] $*" >&2
}
```

## 10. Estándares de Documentación

- **Idioma del código:** Inglés (variables, funciones, comentarios técnicos)
- **Idioma de manuales y guías:** Español
- **Mensajes de *commit*:** Inglés bajo estándar ***Conventional Commits***

Cada *script* debe incluir un bloque inicial que describa:

- Propósito
- Entradas
- Salidas
- Dependencias
- Códigos de salida

### Documentación de Funciones

Cada función debe estar precedida por un comentario que explique su contrato:

- **Description**: Qué hace la función.
- **Globals**: Lista de variables globales que lee o modifica (usar - `None` si no aplica).
- **Arguments**: Parámetros que recibe.
- **Outputs**: Qué imprime en `stdout` o `stderr`.
- **Returns**: Significado del código de salida (0 para éxito, etc.).

## 11. *Linting* y Análisis Estático

Todos los *scripts* deben:

- Pasar *ShellCheck*
- Cumplir validaciones de CI
- Integrarse con *Code Scanning* mediante SARIF cuando esté habilitado

Las advertencias deben resolverse o justificarse explícitamente.

## 12. Prácticas Prohibidas

- Usar `#!/bin/bash`
- Omitir `set -euo pipefail`
- Suprimir errores silenciosamente
- *Hardcodear* rutas específicas de entorno sin documentación
- Mezclar *tabs* y espacios
- Usar `echo` para reportar fallas críticas o errores sin redirección a `stderr`.
- Utilizar variables no inicializadas.

## 13. Principios de Diseño

Los *scripts* derivados de este *baseline* deben cumplir:

- Comportamiento determinístico
- Modos de fallo previsibles
- Supuestos externos mínimos
- Separación clara entre configuración y lógica

## 14. Cumplimiento del *Baseline*

Todo repositorio generado desde `baseline-scripts` debe:

- Adoptar esta guía sin modificaciones
- Documentar cualquier desviación
- Mantener compatibilidad con las políticas de CI y gobernanza

Este documento se versiona junto con el repositorio baseline.

## 15. Referencias y Autoridad Técnica

Esta guía se basa en los principios de robustez de la **[Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)**.

En caso de ambigüedad, escenarios no cubiertos por este documento o debates técnicos sobre el estilo, **prevalecerá el estándar definido por Google**. Se recomienda a los desarrolladores consultar dicha guía para profundizar en las razones detrás de estos estándares de seguridad y legibilidad.
