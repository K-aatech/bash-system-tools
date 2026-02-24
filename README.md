# *Baseline Scripts* 🛡️

[![Linting & Standards](https://github.com/K-aatech/baseline-scripts/actions/workflows/linting.yml/badge.svg)](https://github.com/K-aatech/baseline-scripts/actions/workflows/linting.yml)
[![Secret Scanning (TruffleHog)](https://github.com/K-aatech/baseline-scripts/actions/workflows/secret-scanning.yml/badge.svg)](https://github.com/K-aatech/baseline-scripts/actions/workflows/secret-scanning.yml)
[![CodeQL](https://github.com/K-aatech/baseline-scripts/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/K-aatech/baseline-scripts/actions/workflows/github-code-scanning/codeql)
![License](https://img.shields.io/github/license/K-aatech/baseline-scripts)

Este es un **Repositorio Template** diseñado para ser la base de cualquier proyecto de automatización. Su objetivo es eliminar la fatiga de configuración inicial, garantizando que cada *script* nazca en un entorno con estándares de calidad y seguridad empresarial.

## 💎 Filosofía: *Security by Design & Default*

Este repositorio no solo "soporta" seguridad; la impone.

- **Zero Leak Tolerance**: Escaneo de secretos obligatorio en cada *commit* local y validación profunda en CI.
- **Inmutabilidad**: Todas las *GitHub Actions* están pineadas mediante **Commit SHA** para prevenir ataques de cadena de suministro.
- **Calidad Automatizada**: Uso estricto de **Conventional Commits** y validación de sintaxis en tiempo real.
- **Governanza Rigurosa**: Reglas claras de contribución y revisión para mantener la integridad del código.
- **Privacidad Respetada**: Validaciones locales para proteger la confidencialidad de los datos y secretos.
- **Actualizaciones Proactivas**: Integración de *Dependabot* para mantener dependencias y acciones siempre actualizadas.
- **Seguridad Integral**: Cobertura de seguridad que va desde el desarrollo local hasta la producción, sin puntos ciegos.
- **Facilidad de Uso**: Configuración única y herramientas preinstaladas para que los desarrolladores se enfoquen en el código, no en la configuración.
- **Cultura de Seguridad**: Fomentar una mentalidad de seguridad en cada contribución, haciendo que la seguridad sea parte del ADN del proyecto.

## 🔍 Herramientas Incluidas

El ecosistema de calidad se basa en herramientas líderes que operan en dos niveles: preventivo (Local) y reactivo (CI).

| Herramienta | Función | Implementación |
| :--- | :--- | :--- |
| **TruffleHog** | Detección de secretos y llaves | Local (*Hook*) + CI (*Workflow*) |
| **ShellCheck** | Análisis estático de *scripts* Shell | Local (*Hook*) + CI (*Workflow*) |
| **Conventional Commits** | Estándar de mensajes de *commit* | Local (*Hook*) + CI (*Workflow*) |
| **Pre-commit** | Orquestador de validaciones locales | *Hooks* de *Git* |
| **MarkdownLint** | Estilo de documentación | Local (*Hook*) + CI (*Workflow*) |
| **Linter (YAML/JSON)** | Validación de sintaxis y esquemas | Local (*Hook*) + CI (*Workflow*) |
| **Dependabot** | Actualización de dependencias | Automatizado semanal |

## 🚀 Instalación y Uso Rápido

### 1. Preparar el Entorno

Este repositorio requiere herramientas específicas instaladas en su máquina (*Python, TruffleHog, ShellCheck*).

👉 **Siga la guía obligatoria aquí:** [**Guía de Configuración del Entorno (Setup Checklist)**](./docs/setup-checklist.md)

### 2. Inicializar el Proyecto

Una vez cumplidos los requisitos previos:

1. Haga clic en **"Use this template"** en *GitHub*.
2. Clone su nuevo repositorio y vincule los controles de calidad:

```bash
git clone https://github.com/K-aatech/baseline-scripts.git
cd baseline-scripts
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

## 🛠️ Capacidades de Normalización

El repositorio incluye configuraciones predefinidas para garantizar la consistencia en cualquier editor:

- **`.editorconfig`**: Normalización de fines de línea, indentación y codificación.
- **`.vscode/settings.json`**: Configuración optimizada para *VS Code* y extensiones recomendadas para validación en tiempo real (ver [.vscode/extensions.json](.vscode/extensions.json)).
- **Convenciones**: Validación de **Conventional Commits** para un historial legible.

## 🫱🏻‍🫲🏾 Contribución y Gobernanza

- **CODEOWNERS**: Revisión obligatoria para cambios en infraestructura de CI.
- ***Templates***: Uso obligatorio de formularios estructurados para *bugs* y *features*.
- **Estatutos**: Consulte [CONTRIBUTING.md](./CONTRIBUTING.md) para conocer las reglas de contribución y el flujo de trabajo.

---

Arquitecto del Proyecto: [@albertochungvz](https://github.com/albertochungvz)
