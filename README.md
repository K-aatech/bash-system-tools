# *Bash System Tools* (BST) | K'aatech

![Stable Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?exclude_prereleases&color=blue&label=stable)
![Pre-release Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?include_prereleases&color=orange&label=dev-build)
![Dev Build Status](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml/badge.svg?branch=dev)
![Platform](https://img.shields.io/badge/platform-Linux-steelblue)
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
# Descarga la versión estable v1.7.0
sudo curl -L -o /usr/local/bin/sys-audit-check.sh https://raw.githubusercontent.com/K-aatech/bash-system-tools/v1.7.0/audit/sys-audit-check.sh
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

Este proyecto sigue el estándar de ***[Semantic Versioning (SemVer)](https://semver.org/)*** y ***Conventional Commits***. La automatización de lanzamientos se gestiona mediante ***Release Please***.

- **Versiones Estables (*Main*):** Código probado y listo para producción, etiquetado como `vX.Y.Z`.
- ***Release Candidates* (Dev / RC):** Versiones de prueba finales, etiquetadas con sufijo `-rc.N` (ej. `v1.7.0-rc.1`), generadas manualmente según sea necesario.
- **Registro de Cambios:** Consulta el [CHANGELOG.md](./CHANGELOG.md) generado automáticamente.
- **Flujo *Trunk-Based*:** Toda mejora nace de una rama `feat/*` o `fix/*` → PR → validación por `commitlint` → *merge* en `main` → *release* automático.
- **Referencia:** Consulta nuestra [Política de Versiones](./docs/versioning.md) para todos los detalles del flujo *trunk-based*, convenciones de *commit* y generación de versiones.

---

## 🫱🏻‍🫲🏾 Guía de Contribución

¡Las contribuciones son bienvenidas! Para mantener la integridad técnica de la *suite*, seguimos un flujo de trabajo riguroso.

> [!NOTE]
> Antes de empezar, por favor lee nuestra **[Guía Completa de Contribución](./CONTRIBUTING.md)** donde detallamos el flujo de ramas y estándares de código.

**Requisitos rápidos:**
1. **Ramas:** Toda mejora debe nacer de una rama `feat/*` o `fix/*` y dirigirse a `dev`.
2. **Calidad:** Es obligatorio pasar el linter ***ShellCheck*** (incluido en nuestro CI).
3. **Mensajes:** Utilizamos ***Conventional Commits*** (`feat:`, `fix:`, `docs:`, `refactor:`).
4. **Estilo:** Sigue nuestra **[Guía de Estilo de *Bash*](docs/style-guide.md).**

---

## 📜 Política de Lanzamiento y Gobernanza

Este repositorio sigue un estricto modelo de gobernanza para garantizar un control de versiones predecible, trazable y con lanzamientos automatizados.

### Convención de *Commit*

Todos los cambios deben seguir la especificación de ***Conventional Commits***:

- `feat:` para nuevas funcionalidades
- `fix:` para correcciones de errores
- `docs:` para cambios en la documentación
- `refactor:` para reestructuración interna
- `chore:` para tareas de mantenimiento

Los títulos de las solicitudes de incorporación de cambios (*Pull Request* - PR) **deben** cumplir con este formato, ya que la automatización de lanzamientos deriva el control de versiones a los metadatos de los *commits*.

### Estrategia de Fusión

Este repositorio aplica **fusiones solo por *squash***.

Cada solicitud de incorporación de cambios se fusiona como una única confirmación *squash* en `main`.
El mensaje de confirmación resultante debe coincidir con el título de la solicitud de incorporación de cambios y seguir los *Conventional Commits*.

Esto garantiza:

- Historial lineal limpio
- Generación determinista de registros de cambios
- Cálculo preciso de versiones semánticas

### Lanzamientos automatizados

Las versiones se gestionan mediante `release-please` utilizando la **estrategia de manifiesto**.

- El control de versiones se deriva de los *Conventional Commits*.
- El PR de la versión se actualiza automáticamente cuando se incluyen nuevas confirmaciones en `main`.
- `.release-please-manifest.json` es la única fuente de información veraz sobre el estado de la versión.

No se permite el etiquetado manual ni los incrementos de versión manuales.

Todos los incrementos de versión deben provenir de confirmaciones fusionadas que cumplan con las convenciones.

---

## 🛡️ Descargo de responsabilidad (*Disclaimer*)

Este software se proporciona "tal cual" bajo la Licencia **MIT**. Consulta el archivo [LICENSE](/LICENSE) para más detalles.  \
Para soporte profesional, visita **[kaatech.mx](https://kaatech.mx)**.
