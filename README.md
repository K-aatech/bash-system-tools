# *Bash System Tools* (BST) | K'aatech

**Herramientas de grado empresarial para la gestión, seguridad y automatización de sistemas Linux.**

[![ShellCheck](https://github.com/K-aatech/bash-system-tools/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/K-aatech/bash-system-tools/actions/workflows/shellcheck.yml)
[![Linting & Standards](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml/badge.svg)](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml)
[![Secret Scanning (TruffleHog)](https://github.com/K-aatech/bash-system-tools/actions/workflows/secret-scanning.yml/badge.svg)](https://github.com/K-aatech/bash-system-tools/actions/workflows/secret-scanning.yml)
[![CodeQL](https://github.com/K-aatech/bash-system-tools/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/K-aatech/bash-system-tools/actions/workflows/github-code-scanning/codeql)

[![Quality](https://img.shields.io/badge/quality-K'aatech%20Baseline%20v1.3.0-60c1ec)](./docs/governance-baseline.md)
![Bash Version](https://img.shields.io/badge/bash-%3E%3D4.2-blue)
![License](https://img.shields.io/github/license/K-aatech/bash-system-tools)
![Stable Version](https://img.shields.io/github/v/release/K-aatech/bash-system-tools?exclude_prereleases&color=blue&label=stable)

## 📋 Descripción General

`bash-system-tools` es una *suite* de automatización diseñada para resolver desafíos operativos reales en entornos de misión crítica. Este repositorio no solo contiene *scripts*; representa un compromiso con la **Ingeniería de Software aplicada a Bash**, garantizando que cada herramienta sea segura, predecible y profesional.

A diferencia de *scripts* convencionales, estas herramientas están construidas sobre un **Contrato de Gobernanza Técnica**, lo que garantiza:

* **Determinismo:** Comportamiento predecible en diversas distribuciones.
* **Seguridad por Diseño:** Fallo seguro (`set -euo pipefail`) y escaneo activo de secretos.
* **Gobernanza:** Código auditado y validado mediante análisis estático automatizado.
* **Portabilidad:** Dependencias mínimas y cumplimiento de estándares *POSIX/Bash*.
* **Configuración Adaptativa:** Soporte nativo para inyección de variables vía entorno (ENV) y archivos `.env` para facilitar la integración en *pipelines* de CI/CD.

## 🚀 Inicio Rápido (Auditoría de Salud)

Para ejecutar una auditoría completa de salud del sistema con el estándar de K'aatech:

```bash
# Clonar y acceder
git clone https://github.com/K-aatech/bash-system-tools.git
cd bash-system-tools

# Ejecutar auditoría (requiere privilegios de Root para auditoría de seguridad)
sudo ./audit/system-health-audit.sh
```

### ¿Qué se audita?

* **Identidad del *Host*:** *Namespace* KISA_ (*Hostname*, *Kernel*, *Distro*, *Uptime*).
* **Seguridad:** Matriz de permisos críticos, *reboots* pendientes y cumplimiento de *Hardening*.
* **Rendimiento:** Carga de CPU, I/O Wait, procesos Zombis y monitoreo térmico por adaptador.
* **Red:** Contexto local, conectividad y latencia *multi-cloud* (*"Fierro-to-Cloud"*).
* **Virtualización:** Salud y estado de contenedores *Docker* (detección dinámica).

### Hardening Automatizado (Mail Piler)

Ahora puede automatizar el despliegue de seguridad definiendo su identidad previamente:

```Bash
# Definir identidad y ejecutar (Sin prompts)
sudo PILER_FQDN="piler.dominio.com" PILER_ADMIN_EMAIL="admin@dominio.com" ./hardening/piler-hardening.sh
```

## 🏗️ Estructura y Módulos

El repositorio se organiza por dominios de responsabilidad, utilizando una **Arquitectura de Librerías Inteligentes** (`lib/`) que soportan ejecución programática e interactiva:

* **`audit/`**: *Scripts* de inspección y diagnóstico. Generan reportes de estado sin alterar el sistema.
* **`hardening/`**: Herramientas de reforzamiento de seguridad.
  * **`piler-hardening.sh`**: **(v0.2.0)** Endurecimiento perimetral para Mail Piler. Implementa la nueva arquitectura de **SSL Snippets** y resolución automática de identidad. [Ver Manual de Operaciones](./docs/operations/piler-hardening-manual.md).
* **`deploy/`**: *Scripts* destinados a la instalación y configuración inicial.
* **`maintenance/`**: Automatización de tareas recurrentes (backups, limpieza, rotación).
* **`lib/`**: El núcleo de inteligencia (KISA Framework).
  * **Identity Resolver**: Gestión inteligente de variables de configuración con jerarquía de prioridad (ENV > `.env` > Interactivo).
  * **Orquestación Segura (`safe_*`)**: Módulos que garantizan la integridad de los servicios (Nginx/Systemd) validando la sintaxis antes de aplicar cambios para prevenir *downtime*. Ahora incluye `link_ssl_snippet` para vincular certificados a Vhosts de Nginx de forma no intrusiva con rollback automático.
  * **Autonomía Inteligente**: Funciones capaces de detectar si faltan parámetros y solicitarlos interactivamente solo si hay una terminal activa.

## 📚 Documentación y Gobernanza

Hemos organizado nuestro conocimiento bajo estándares de **Ingeniería SRE** para facilitar la consulta rápida y la profundidad técnica:

| Categoría       | Ubicación                                | Contenido                                                                    |
| :-------------- | :--------------------------------------- | :--------------------------------------------------------------------------- |
| **Operaciones** | [`docs/operations/`](./docs/operations/) | Manuales de Ingeniería (SRE) para la ejecución segura de scripts operativos. |
| **Referencia**  | [`docs/reference/`](./docs/reference/)   | Documentación técnica de la API de librerías y módulos `KISA_`.              |
| **Gobernanza**  | [`docs/`](./docs/)                       | Guías de estilo, baseline de seguridad y políticas de contribución.          |

## 🤝 Para SysAdmins y Colaboradores

Este proyecto es de código abierto para fomentar la transparencia y la mejora continua a través de la comunidad.

* **Para SysAdmins:** Cada herramienta incluye documentación técnica interna. Siéntete libre de usar y adaptar estas herramientas en tus flujos de trabajo.
* **Para Colaboradores:** Valoramos las contribuciones que respeten nuestra gobernanza. Consulta las [Directrices de Contribución](./CONTRIBUTING.md) para conocer nuestro flujo *Trunk-based*.

> [!NOTE]
> **Calidad:** Todas las herramientas pasan por validaciones estáticas con *ShellCheck* antes de ser publicadas.

## ⚖️ Estándares de Ingeniería

Para nuestros clientes y socios, este repositorio sirve como evidencia de rigor técnico y prueba de nuestro compromiso con la excelencia:

* **Versionado Semántico:** Publicaciones claras y deterministas mediante `release-please`.
* **Calidad de Código:** Cumplimiento estricto del [Bash Engineering Style Guide](./docs/bash-style-guide.md).
* **Transparencia:** Historial de cambios auditable basado en *Conventional Commits*.

Este repositorio es una implementación de **Ingeniería de Sistemas en *Bash***:

* **Namespace KISA:** Estandarización de atributos de infraestructura para evitar colisiones globales.
* **Gestión de Identidad Centralizada:** Uso de `resolve_identity_value` para garantizar que los *scripts* operen con datos consistentes, ya sea en despliegues manuales o automatizados.
* **Separación de Datos y Presentación:** Los módulos de descubrimiento (`fetch_`) están desacoplados de los módulos de reporte (`render_`), facilitando la futura integración con *Dashboards* o APIs.
* **Resiliencia Operativa:**
  * Uso de `set -euo pipefail` e `IFS` seguro para evitar fallos silenciosos en entornos productivos.
  * Uso de `safe_service_config_apply` para garantizar que ningún error tipográfico afecte la disponibilidad de los servicios en producción.
* **Interactividad Segura:** Uso de `request_input` para la captura de datos sensibles (*passwords*) sin eco en terminal ni rastro en el historial de Bash (`.bash_history`).
* **Validación Pre-flight:** Verificación elástica de binarios y estados de servicio antes de iniciar cualquier lógica mutante.

---

Desarrollado con rigor por el equipo de [**K'aatech**](https://kaatech.mx).
