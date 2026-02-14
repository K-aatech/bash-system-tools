# *Bash System Tools* (BST) | K'aatech

![Stable Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?exclude_prereleases&color=blue&label=stable)
![CI Status](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml/badge.svg?branch=main)
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
(Reemplazar la ruta y nombre del *script* requerido)
```bash
# Descarga la versión estable
sudo curl -L -o /usr/local/bin/sys-audit-check.sh https://raw.githubusercontent.com/K-aatech/bash-system-tools/main/audit/sys-audit-check.sh
sudo chmod 700 /usr/local/bin/sys-audit-check.sh
```

> [!NOTE]
> Se recomienda utilizar siempre la versión estable más reciente publicada en la sección de Releases.

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

Este proyecto sigue el estándar de **Semantic Versioning (SemVer)** y **Conventional Commits**.

- Las versiones estables se etiquetan como `vMAJOR.MINOR.PATCH`.
- El versionado es automático y gestionado mediante `release-please`.
- El registro de cambios se genera automáticamente en [CHANGELOG.md](./CHANGELOG.md).
- El flujo de desarrollo es *trunk-based*: toda mejora nace de una rama `feat/*` o `fix/*` → PR → validación automática → *merge* en `main` → *release* automático.

Para más detalles, consulte la [Política de Versiones](./docs/versioning.md).

---

## 🫱🏻‍🫲🏾 Guía de Contribución

¡Las contribuciones son bienvenidas! Para mantener la integridad técnica de la *suite*, seguimos un flujo de trabajo riguroso.

> [!NOTE]
> Antes de empezar, por favor lee nuestra **[Guía Completa de Contribución](./CONTRIBUTING.md)** donde detallamos el flujo de ramas y estándares de código.

**Requisitos rápidos:**

1. **Ramas:** Toda mejora debe nacer de una rama `feat/*` o `fix/*` y dirigirse a `main`.
2. **Calidad:** Es obligatorio pasar el linter **ShellCheck** (incluido en nuestro CI).
3. **Mensajes:** Utilizamos **Conventional Commits** (`feat:`, `fix:`, `docs:`, etc.).
4. **Estilo:** Sigue nuestra [Guía de Estilo de Bash](docs/style-guide.md).

---

## 📜 Política de Lanzamiento y Gobernanza

Este proyecto aplica controles formales de gobernanza para garantizar trazabilidad, reproducibilidad e integridad del historial.

---

### Convención de *Commit*

Todos los cambios deben seguir la especificación de ***Conventional Commits***:

- `feat:` nuevas funcionalidades
- `fix:` correcciones de errores
- `docs:` cambios en la documentación
- `refactor:` reestructuración interna sin alterar comportamiento
- `chore:` tareas de mantenimiento
- `ci:` cambios en integración continua
- `perf:` mejoras de rendimiento
- `test:` incorporación o ajuste de pruebas

Los títulos de las solicitudes de incorporación de cambios (*Pull Request* - PR) **deben** cumplir con este formato, ya que la automatización de lanzamientos deriva el control de versiones a los metadatos de los *commits*.

### Estrategia de Fusión

Este repositorio aplica **fusiones exclusivamente mediante *squash merge***.

Cada solicitud de incorporación de cambios se integra como una única confirmación en la rama `main`.
El mensaje de confirmación resultante debe coincidir exactamente con el título del PR y respetar la convención de *Conventional Commits*.

Esto garantiza:

- Historial lineal limpio
- Generación determinista de registros de cambios
- Cálculo preciso de versiones semánticas
- Eliminación de ruido histórico

### Lanzamientos automatizados

Las versiones se gestionan mediante `release-please` utilizando la **estrategia de manifiesto**.

Principios del modelo de versionado:

- El incremento de versión se deriva exclusivamente de *Conventional Commits*.
- El PR de versión se actualiza automáticamente cuando se integran nuevas confirmaciones en `main`.
- El archivo de manifiesto es la única fuente de información veraz sobre el estado de la versión.
- No se permite el etiquetado manual ni incrementos de versión manuales.

Todos los cambios de versión deben originarse en confirmaciones fusionadas que cumplan las convenciones establecidas.

Las etiquetas de versión (`vMAJOR.MINOR.PATCH`) están protegidas contra modificación o eliminación.

---

### Integridad del repositorio

Este proyecto implementa controles técnicos adicionales para proteger la integridad del código:

- Historial lineal obligatorio.
- Validaciones automáticas requeridas antes de cada fusión (*merge*).
- Análisis estático de seguridad (CodeQL).
- Confirmaciones (*commits*) firmadas criptográficamente obligatorias.
- Protección de la rama principal contra *force push* o eliminación.
- Protección de etiquetas de versión (`v*`) como artefactos inmutables.

Estos controles garantizan consistencia, trazabilidad y resistencia ante modificaciones no autorizadas.

---

## 🛡️ Descargo de responsabilidad (*Disclaimer*)

Este software se proporciona "tal cual" bajo la Licencia **MIT**. Consulta el archivo [LICENSE](/LICENSE) para más detalles.  \
Para soporte profesional, visita **[kaatech.mx](https://kaatech.mx)**.
