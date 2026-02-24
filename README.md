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

## 🏗️ Estructura y Módulos

El repositorio se organiza por dominios de responsabilidad para facilitar su uso en diferentes escenarios de consultoría y administración:

* **`audit/`**: *Scripts* de inspección y diagnóstico. Generan reportes de estado sin alterar el sistema. Ideales para auditorías iniciales con clientes.
* **`hardening/`**: Herramientas de reforzamiento de seguridad. Aplican políticas de "mínimo privilegio" y cierran brechas en la configuración del SO.
* **`deploy/`**: (Implementaciones) *Scripts* destinados a la instalación, configuración inicial y despliegue de servicios o aplicaciones específicas.
* **`maintenance/`**: Automatización de tareas recurrentes como rotación de *logs*, *backups* y limpieza de recursos.
* **`scripts/`**: Utilidades generales de sistema y herramientas de soporte que asisten al SysAdmin en tareas cotidianas no categorizadas en los módulos anteriores.

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

---
Desarrollado con rigor por el equipo de [**K'aatech**](https://kaatech.mx).
