# Governance Baseline

Este documento define el contrato estructural y normativo del repositorio `baseline-scripts`.

Su propósito es garantizar:

- Consistencia organizacional
- Reproducibilidad técnica
- Gobernanza verificable
- Estándares mínimos obligatorios
- Compatibilidad con repositorios derivados

**Este documento es normativo. No es informativo.**

## 1. Alcances

El *baseline* establece:

- Estructura mínima del repositorio
- Estándares obligatorios de ingeniería
- Políticas de versionado
- Reglas de colaboración
- Requisitos de automatización
- Controles de integridad estructural

Todos los repositorios derivados deben cumplir estas reglas salvo desviación documentada explícitamente.

## 2. Estructura Mínima Obligatoria

El repositorio debe contener como mínimo:

- `.editorconfig`
- Configuración operativa de `shellcheck`
- Configuración operativa de `trufflehog`
- Configuración operativa de `commitlint`
- configuración operativa de `dependabot`
- Configuración operativa de `release-please`
- Política de versionado (`docs/versioning.md`)
- Guía de estilo (`docs/bash-style-guide.md`)
- Plantillas oficiales (`docs/templates/`)
- Configuración de automatización de dependencias
- Documentación de gobernanza

### 2.1 Estructura de Directorios Estándar

Además de los artefactos mínimos obligatorios, el repositorio adopta la siguiente estructura base:

```bash
.
├── audit/
├── hardening/
├── maintenance/
├── scripts/
├── test/
│   ├── unit/
│   │   ├── example-test.sh        (ejecutable)
│   │   └── another-test.sh        (ejecutable)
│   └── lib/
│       └── test-helpers.sh        (no ejecutable)
├── lib/
├── docs/
│ ├── templates/
│ └── *.md
└── .github/workflows/
```

---

#### Reglas

- `scripts/`
    Contiene únicamente *scripts* ejecutables distribuidos como artefacto principal del repositorio.

- `lib/`
    Contiene módulos reutilizables que pueden ser importados (`source`) por *scripts* productivos o pruebas.
    No debe contener artefactos ejecutables distribuidos directamente al usuario final.

- `test/`
    Contiene pruebas automatizadas.
    Puede incluir subdirectorios internos para utilidades (`helpers/`, `fixtures/`, etc.) siempre que no contengan artefactos productivos.

- `docs/`
    Contiene documentación normativa y técnica.

- `.github/workflows/`
    Contiene exclusivamente automatizaciones CI/CD.

#### Reglas de Ejecutabilidad y Permisos

El repositorio implementa una auditoría estricta de permisos para garantizar la operatividad y la seguridad:

1. **Scripts Operativos**: Los archivos en `scripts/`, `audit/`, `hardening/`, `maintenance/` y `test/unit/` deben ser ejecutables (`chmod +x`). Esto garantiza que las herramientas sean funcionales tras el despliegue.
2. **Bibliotecas y Documentos**: Los archivos en `lib/`, `test/lib/` y `docs/` tienen prohibido el *bit* de ejecución. Esto asegura que los módulos solo se carguen mediante `source`, mitigando vectores de ejecución accidental.

> [!NOTE]
> El sistema de *pre-commit* intentará auto-remediar estos permisos localmente, pero la CI rechazará cualquier *commit* que no cumpla con este estándar.

#### Auditoría de Integridad

En entornos donde el sistema de archivos no soporta permisos POSIX nativos, la "Fuente de Verdad" para la auditoría de seguridad y *bits* de ejecución será el **Índice de Git** (`git ls-files --stage`), no los atributos del disco local.

---

La introducción de nuevas carpetas de primer nivel debe justificarse técnicamente.

Los contenidos de `test/` no forman parte del artefacto distribuible del baseline.

La modificación de la topología de primer nivel definida en esta sección constituye una ruptura del contrato estructural y requiere declaración explícita de `BREAKING CHANGE` conforme a SemVer.

### 2.2 Automatización Local (Escudo Preventivo)

El repositorio implementa el *framework* `pre-commit` para garantizar el cumplimiento de estándares antes de la persistencia de datos en el historial.

Su propósito es:

- **Prevención de Fugas**: Bloqueo obligatorio de secretos mediante *TruffleHog*.
- **Calidad de Origen**: Validación de sintaxis (*ShellCheck*) y formato (*Linters*) en tiempo real.
- **Reducción de Ruido en CI**: Asegurar que los *Pull Requests* lleguen en estado de cumplimiento.

**El uso de los *hooks* locales definidos es obligatorio para todos los colaboradores.** La evasión de estos controles (vía `--no-verify`) sin justificación técnica se considera una violación de la gobernanza.

Se permite la exclusión de archivos generados automáticamente (ej. `CHANGELOG.md`) de las reglas de formato de *Markdown* para garantizar la compatibilidad con los sistemas de versionado automático.

#### 2.2.1 Ejecución Manual del Validaciones

Aunque la mayoría de los controles son automáticos, los desarrolladores pueden (y deben) ejecutar las validaciones manualmente durante el desarrollo:

##### Validación de Estructura y Permisos

```bash
./scripts/validate-structure.sh
```

| Nivel   | Color | Significado                       | Acción Requerida                   |
| ------- | ----- | --------------------------------- | ---------------------------------- |
| INFO    | Azul  | Inicio de auditoría y progreso.   | Ninguna (Informativo).             |
| WARN    | Ámbar | Alertas no críticas u omisiones.  | Revisar que sea intencional.       |
| ERROR   | Rojo  | Violación de contrato o permisos. | **Obligatoria**. Corregir pronto.  |
| SUCCESS | Verde | Cumplimiento total del contrato.  | Ninguna. Listo para el despliegue. |

> [!NOTE]
> Este *script* es invocado automáticamente por el sistema de Integración Continua (CI). Un fallo en este validador causará el rechazo inmediato del *Pull Request*.

##### Validación Completa de *Hooks* (Estilo, *Lint* y Seguridad)

Para ejecutar todos los controles de *pre-commit* (*ShellCheck*, *TruffleHog*, *MarkdownLint*, etc.) sobre todos los archivos sin necesidad de crear un *commit*:

```bash
pre-commit run --all-files
```

> [!TIP]
> Si solo deseas probar un hook específico (por ejemplo, solo ShellCheck) en los archivos modificados, puedes usar: pre-commit run shellcheck

### 2.3 Configuración de Entorno (Recomendada)

El repositorio puede incluir configuraciones específicas de herramientas de desarrollo, tales como:

- `.vscode/settings.json`
- `.vscode/extensions.json`

Estas configuraciones tienen como objetivo:

- Mejorar la experiencia de desarrollo
- Homogeneizar estándares locales
- Reducir fricción operativa

Dichos archivos son opcionales y no forman parte de la estructura mínima obligatoria.

Su modificación o eliminación no constituye un cambio incompatible ni requiere incremento MAJOR.

El procedimiento de configuración de estas herramientas está centralizado en el [Setup Checklist](./setup-checklist.md), el cual debe seguirse estrictamente para garantizar la paridad entre el entorno local y la CI.

## 3. Modelo de Desarrollo

Se adopta un modelo:

- *Trunk-based*
- Historial lineal
- Sin ramas permanentes adicionales
- *Pull Requests* obligatorios
- *Squash merge* obligatorio

Está prohibido:

- Push directo a `main`
- Reescritura del historial público
- Creación manual de *tags* de versión

## 4. Automatización Obligatoria

El *baseline* debe garantizar:

- Validación de *commits*
- Versionado automático
- Generación automática de *changelog*
- Integridad de etiquetas

Cuando CI esté habilitado, debe:

- Validar estructura mínima
- Ejecutar análisis estático
- Publicar resultados de seguridad (cuando aplique)

La implementación técnica de estas validaciones, así como la matriz de herramientas utilizadas, se detalla en el documento de [Arquitectura de Integración Continua (CI)](./ci-architecture.md).

## 5. Control de Calidad

Todos los *scripts* derivados deben:

- Cumplir la [Bash Style Guide](bash-style-guide.md)
- Pasar análisis con *ShellCheck*
- Implementar manejo de errores explícito
- Ser idempotentes cuando aplique

Los desvíos deben justificarse técnicamente.

## 6. Contrato de Compatibilidad

Se considera ruptura del contrato estructural cuando:

- Se eliminan documentos normativos obligatorios
- Se altera el modelo de versionado
- Se debilitan restricciones de gobernanza
- Se introduce ambigüedad en reglas automáticas
- Se altera la topología base de directorios de primer nivel definida en la sección 2.1 sin declaración de `BREAKING CHANGE`

## 7. Protección de Integridad

El repositorio debe configurar:

- Protección de rama `main`
- Requerimiento de *Pull Request*
- Prohibición de *force-push*
- Restricción de eliminación de *tags*

Cuando la plataforma lo permita, se recomienda:

- Firmado de *commits*
- Firmado de *tags*
- Revisión obligatoria por al menos un mantenedor

## 8. Repositorios Derivados

Los repositorios creados a partir de este baseline:

- Heredan este contrato
- Deben mantener compatibilidad estructural
- Pueden extender, pero no debilitar, las reglas obligatorias

Si un repositorio derivado modifica esta gobernanza, debe documentarlo explícitamente.

## 9. Evolución del *Baseline*

Las modificaciones al *baseline* deben:

- Realizarse mediante *Pull Request*
- Cumplir *Conventional Commits*
- Declarar BREAKING CHANGE cuando aplique
- Mantener coherencia con *SemVer*

El *baseline* se versiona como cualquier otro proyecto, pero su impacto es organizacional.

## 10. Principios Rectores

Este *baseline* se rige por los siguientes principios:

- Determinismo
- Automatización por defecto
- Eliminación de intervención manual en *releases*
- Transparencia del historial
- Reproducibilidad técnica
- Mínima ambigüedad operativa

## 11. Cumplimiento

El incumplimiento de este contrato puede resultar en:

- Rechazo de *Pull Request*
- Bloqueo de *release*
- Revisión estructural obligatoria

Este documento forma parte integral de la gobernanza técnica del repositorio.
