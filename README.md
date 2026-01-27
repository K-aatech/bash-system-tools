# Bash System Tools (BST) | K'aatech

![Linting Status](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml/badge.svg)

Conjunto de herramientas de automatización y auditoría para la gestión profesional de infraestructuras Linux. Estas herramientas están diseñadas siguiendo principios de seguridad, idempotencia y trazabilidad.

---

## 📂 Estructura del Toolkit

- **/audit:** Scripts de recolección de información sin cambios en el sistema.
- **/hardening:** Aplicación de políticas de seguridad y cierre de brechas.
- **/lib:** Funciones core compartidas (logging, manejo de errores).
- **/maintenance:** Automatización de tareas rutinarias (logs, backups, updates).

---

## 🛠 Requisitos Previos

Antes de ejecutar cualquier script, asegúrate de cumplir con:
- **OS:** Ubuntu 22.04+ / Debian 11+ / RHEL 9+
- **Privilegios:** La mayoría de los scripts requieren acceso `root` o `sudo`.
- **Dependencias:** `curl`, `wget`, `grep`, `awk`.

---

## 🚀 Uso Seguro

1. **Clonar el repositorio:**
   ```bash
   git clone [https://github.com/K-aatech/bash-system-tools.git](https://github.com/K-aatech/bash-system-tools.git)
   cd bash-system-tools
   ```

2. **Dar permisos de ejecución:**

    ```bash
    chmod +x ./audit/sys-audit-check.sh
    ```

3. **Ejecución (Modo Seguro):** Recomendamos probar primero en entornos de staging.

    ```bash
    sudo ./audit/sys-audit-check.sh
    ```

## 🤝 Guía de Contribución
Para mantener la calidad de **K'aatech**, todas las contribuciones deben:

1. Pasar el linter de ShellCheck.
2. Seguir el estilo de codificación definido en la [Guía de Estilo](docs/style-guide.md).
3. Usar Conventional Commits para los mensajes de Git.

## 🛡 Disclaimer

Este software se proporciona "tal cual" bajo la Licencia **MIT**. Consulta el archivo [LICENSE](/LICENSE) para más detalles.  \
Para soporte profesional, visita [kaatech.mx](https://kaatech.mx).


