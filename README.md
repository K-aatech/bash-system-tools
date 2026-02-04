# *Bash System Tools* (BST) | K'aatech

![Stable Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?color=blue&label=stable)
![Pre-release Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?include_prereleases&color=orange&label=dev-build)
![Dev Build Status](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml/badge.svg?branch=dev)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)
![License](https://img.shields.io/github/license/K-aatech/bash-system-tools)
[![Documentation](https://img.shields.io/badge/docs-Engineering%20Manuals-lightgrey)](./docs)


Conjunto de herramientas de automatización y auditoría para la gestión profesional de infraestructuras Linux. Estas herramientas están diseñadas siguiendo principios de seguridad, idempotencia y trazabilidad.

---

## 🚀 Instalación y Uso

### Opción A: *Suite* Completa (Recomendado)
Ideal para administradores que usarán múltiples herramientas de la colección.
```bash
git clone https://github.com/K-aatech/bash-system-tools.git
cd bash-system-tools
# Dar permisos de ejecución a todos los scripts y asegurar lectura de librerías
sudo chmod +x */*.sh
sudo ./audit/sys-audit-check.sh
```

### Opción B: *Script* individual
Ideal para auditorías rápidas en un solo servidor.
```bash
# Descarga la versión estable v1.6.0
sudo curl -L -o /usr/local/bin/sys-audit-check.sh https://raw.githubusercontent.com/K-aatech/bash-system-tools/v1.6.0/audit/sys-audit-check.sh
sudo chmod 700 /usr/local/bin/sys-audit-check.sh
```

---

## 🏗️ Arquitectura del *Toolkit*
Este proyecto sigue un diseño modular. Los *scripts* de herramientas (`/audit`, `/hardening`, etc.) dependen de un conjunto de librerías centralizadas en `/lib`.

> [!IMPORTANT]
> Si decides descargar un *script* de forma individual (*Standalone*), este activará automáticamente un **modo de compatibilidad** (*fallback*) para mantener su funcionalidad, aunque se recomienda la suite completa para obtener *logs* estandarizados y soporte de colores.

---

## 🧰 Catálogo de Herramientas

| Herramienta | Categoría | Descripción | Documentación |
| :--- | :--- | :--- | :--- |
| [**`sys-audit-check.sh`**](./audit/sys-audit-check.sh) | `Audit` | Diagnóstico profesional de salud Linux. | [Manual de Ingeniería 📘](./docs/sys-audit-check.md) |  \

<br>

> [!TIP]
> Cada herramienta incluye un sistema de rotación de logs automático en `/var/log/kaatech_report.log` y validación de privilegios de *root*.

---

## 📂 Estructura del *Toolkit*

- **/audit:** *Scripts* de recolección de información sin cambios en el sistema.
- **/hardening:** Aplicación de políticas de seguridad y cierre de brechas.
- **/lib:** Funciones *core* compartidas (*logging*, manejo de errores).
- **/maintenance:** Automatización de tareas rutinarias (*logs*, *backups*, *updates*).

---

## 📦 Requisitos Previos

Antes de ejecutar cualquier *script*, asegúrate de cumplir con:
- **OS:** Ubuntu 22.04+ / Debian 11+ / RHEL 9+
- **Privilegios:** La mayoría de los *scripts* requieren acceso `root` o `sudo`.
- **Dependencias:** `curl`, `wget`, `grep`, `awk`.

---

## 📌 Control de Versiones

Este proyecto sigue el estándar de *[Semantic Versioning (SemVer)](https://semver.org/)*. La automatización de lanzamientos se gestiona mediante ***Release Please***.

- **Versiones Estables (*Main*):** Representan código probado y listo para producción. Se identifican como `vX.Y.Z`.
- **Release Candidates (*Dev*):** Versiones en etapa de pruebas finales. Se identifican con el sufijo `-rc.N` (ej. `v1.7.0-rc.1`).
- **Historial de Cambios:** Consulta nuestro [CHANGELOG.md](./CHANGELOG.md) (generado automáticamente) para conocer las novedades de cada versión.

---

## 🫱🏻‍🫲🏾 Guía de Contribución

¡Las contribuciones son bienvenidas! Para mantener la integridad técnica de la *suite*, seguimos un flujo de trabajo riguroso.

> [!NOTE]
> Antes de empezar, por favor lee nuestra **[Guía Completa de Contribución](./CONTRIBUTING.md)** donde detallamos el flujo de ramas y estándares de código.

**Requisitos rápidos:**
1. **Ramas:** Toda mejora debe nacer de una rama `feat/*` o `fix/*` y dirigirse a `dev`.
2. **Calidad:** Es obligatorio pasar el linter ***ShellCheck*** (incluido en nuestro CI).
3. **Mensajes:** Utilizamos ***Conventional Commits*** (`feat:`, `fix:`, `docs:`, `refactor:`).
4. **Estilo:** Sigue nuestra [Guía de Estilo de Bash](docs/style-guide.md).

---

## 🛡️ *Disclaimer*

Este software se proporciona "tal cual" bajo la Licencia **MIT**. Consulta el archivo [LICENSE](/LICENSE) para más detalles.  \
Para soporte profesional, visita [kaatech.mx](https://kaatech.mx).
