# *Bash System Tools* (BST) | K'aatech

**Herramientas de grado empresarial para la gestión, seguridad y automatización de sistemas Linux.**

[![Linting & Standards](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml/badge.svg)](https://github.com/K-aatech/bash-system-tools/actions/workflows/linting.yml)
[![Secret Scanning (TruffleHog)](https://github.com/K-aatech/bash-system-tools/actions/workflows/secret-scanning.yml/badge.svg)](https://github.com/K-aatech/bash-system-tools/actions/workflows/secret-scanning.yml)
[![CodeQL](https://github.com/K-aatech/bash-system-tools/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/K-aatech/bash-system-tools/actions/workflows/github-code-scanning/codeql)
[![Quality](https://img.shields.io/badge/quality-K'aatech%20Baseline%20v1.1.0-60c1ec)](./docs/governance-baseline.md)
![Bash Version](https://img.shields.io/badge/bash-%3E%3D4.2-blue)
![License](https://img.shields.io/github/license/K-aatech/bash-system-tools)

## 📋 Descripción General

`bash-system-tools` es una *suite* de automatización diseñada para resolver desafíos operativos reales en entornos de misión crítica. Este repositorio no solo contiene *scripts*; representa un compromiso con la **Ingeniería de Software aplicada a Bash**, garantizando que cada herramienta sea segura, predecible y profesional.

A diferencia de *scripts* convencionales, estas herramientas están construidas sobre un **Contrato de Gobernanza Técnica**, lo que garantiza:

* **Determinismo:** Comportamiento predecible en diversas distribuciones.
* **Seguridad por Diseño:** Fallo seguro (`set -euo pipefail`) y escaneo activo de secretos.
* **Gobernanza:** Código auditado y validado mediante análisis estático automatizado.
* **Portabilidad:** Dependencias mínimas y cumplimiento de estándares *POSIX/Bash*.

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
* **Seguridad:** Matriz de permisos críticos (`/etc/shadow`, `sudoers`) y *reboots* pendientes.
* **Rendimiento:** Carga de CPU, I/O Wait, procesos Zombis y monitoreo térmico por adaptador.
* **Red:** Contexto local, conectividad a* internet y latencia *multi-cloud* (*"Fierro-to-Cloud"*).
* **Virtualización:** Salud y estado de contenedores *Docker* (detección dinámica).

## 🏗️ Estructura y Módulos

El repositorio se organiza por dominios de responsabilidad para facilitar su uso en diferentes escenarios de consultoría y administración, utilizando una **Arquitectura de Librerías Desacopladas** (`lib/`) para alimentar las herramientas operativas:

* **`audit/`**: *Scripts* de inspección y diagnóstico. Generan reportes de estado sin alterar el sistema. Ideales para auditorías iniciales con clientes.
  * **`system-health-audit.sh`**: Nuestra herramienta insignia. Realiza una auditoría integral en **6 Fases Estructuradas** (*Governance, Security, Performance, Storage, Network, y Virtualization*).
* **`hardening/`**: Herramientas de reforzamiento de seguridad. Aplican políticas de "mínimo privilegio" y cierran brechas en la configuración del SO.
* **`deploy/`**: (Implementaciones) *Scripts* destinados a la instalación, configuración inicial y despliegue de servicios o aplicaciones específicas.
* **`maintenance/`**: Automatización de tareas recurrentes como rotación de *logs*, *backups* y limpieza de recursos.
* **`scripts/`**: Utilidades generales de sistema y herramientas de soporte que asisten al SysAdmin en tareas cotidianas no categorizadas en los módulos anteriores.
* **`lib/`**: El núcleo de inteligencia del *framework*.
  * **Modelos *Data-Only***: Librerías especializadas (`sys-utils`, `net-utils`) que extraen metadatos del sistema sin generar ruido en los flujos de salida, permitiendo su reutilización en otros *scripts*.
  * ***Logging Engine***: Sistema de registro atómico con rotación determinista y soporte visual para terminales modernas.

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
* **Separación de Datos y Presentación:** Los módulos de descubrimiento (`fetch_`) están desacoplados de los módulos de reporte (`render_`), facilitando la futura integración con *Dashboards* o APIs.
* **Resiliencia Operativa:** Uso de `set -euo pipefail` e `IFS` seguro para evitar fallos silenciosos en entornos productivos.

---
Desarrollado con rigor por el equipo de [**K'aatech**](https://kaatech.mx).
