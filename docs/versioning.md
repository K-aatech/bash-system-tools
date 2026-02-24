# Política de Versionado

Este repositorio adopta ***Semantic Versioning (SemVer 2.0.0)*** y utiliza ***Conventional Commits*** como mecanismo determinista para la generación automática de versiones mediante `release-please`.

El modelo está diseñado bajo un enfoque ***trunk-based*** con historial lineal, automatización obligatoria y gobernanza estricta sobre etiquetas y publicaciones.

## 1. Esquema de Versión

Las versiones siguen el formato:

> **MAJOR.MINOR.PATCH** <br>
> Ejemplo: <br>
> **1.0.0**

Las etiquetas se generan automáticamente con el prefijo `v`:

`v1.0.0`

No se permite la creación manual de etiquetas.

## 2. Fuente de Verdad del Versionado

El número de versión se determina exclusivamente por el historial de *commits* fusionados en la rama `main`.

No existen archivos de versión editables manualmente como fuente primaria.

El incremento de versión es calculado automáticamente por `release-please` con base en el tipo de *commit*.

## 3. Reglas de Incremento

### 3.1 MAJOR

Se incrementa cuando se introduce un cambio incompatible.

Debe declararse mediante:

- `feat!: descripción`
- o incluir `BREAKING CHANGE:` en el cuerpo del *commit*

**En el contexto del *baseline*, se considera cambio incompatible:**

- Modificación obligatoria de la estructura mínima del repositorio.
- Cambios en reglas de gobernanza que afecten compatibilidad con repos derivados.
- Eliminación o endurecimiento de validaciones obligatorias de CI.
- Cambios en la política de versionado.
- Alteración del contrato estructural definido en `docs/`.

### 3.2 MINOR

Se incrementa cuando se agrega funcionalidad compatible hacia atrás.

Activado por:

- `feat:`

Ejemplos:

- Incorporación de nuevas plantillas opcionales.
- Mejora no disruptiva de documentación.
- Nuevas validaciones no obligatorias.

## 3.3 PATCH

Se incrementa cuando se corrigen errores o se realizan mejoras internas compatibles.

Activado por:

- `fix:`
- `perf:`
- `refactor:`
- `ci:` (cuando no altera gobernanza estructural)
- `test:`

> [!NOTE]
> `docs:` y `chore:` no generan incremento de versión por sí mismos.

## 4. Tipos de *Commit* Permitidos

Formato obligatorio:

`type(scope opcional): descripción breve`

Tipos admitidos:

- `feat`
- `fix`
- `docs`
- `style`
- `refactor`
- `perf`
- `test`
- `build`
- `ci`
- `chore`
- `revert`

Todos los mensajes deben cumplir con el estándar **Conventional Commits** y son auditados en dos momentos críticos:

1. **Validación Preventiva (Local)**:
   Al intentar realizar un *commit*, el *hook* `conventional-pre-commit` (gestionado por `pre-commit`) valida el mensaje antes de que se cree el registro en *Git*.

2. **Validación de Integridad (CI)**:
   El *workflow* especializado `commitlint.yml` audita el historial de la *Pull Request* en la nube. Esto garantiza que el estándar se mantenga incluso si se realizan ediciones en la interfaz de *GitHub* o mediante fusiones.

    > [!TIP]
    > Si el *linter* local falla, el *commit* será rechazado. Esto previene ciclos de "*fix commit message*" innecesarios en la CI.

Consulte el [Setup Checklist](./setup-checklist.md) para habilitar la validación local.

### 4.1 Ámbitos Sugeridos (*Scopes*)

Para mejorar la trazabilidad, se recomienda el uso de *scopes* que vinculen el cambio con la estructura del repositorio. Aunque el sistema permite cualquier texto en minúsculas, los ámbitos estandarizados son:

| Ámbito        | Descripción                                      | Carpeta Relacionada |
| :------------ | :----------------------------------------------- | :------------------ |
| `audit`       | Lógica de cumplimiento y scripts de auditoría.   | `audit/`            |
| `hardening`   | Scripts de endurecimiento y seguridad.           | `hardening/`        |
| `maintenance` | Tareas de limpieza o scripts de soporte.         | `maintenance/`      |
| `scripts`     | Herramientas generales de automatización.        | `scripts/`          |
| `lib`         | Funciones compartidas y bibliotecas.             | `lib/`              |
| `docs`        | Cambios exclusivos en documentación.             | `docs/`             |
| `setup`       | Configuración de entorno y guías de inicio.      | -                   |
| `governance`  | Modificaciones en políticas y reglas del repo.   | -                   |
| `ci`          | Workflows, *hooks* y automatización de procesos. | `.github/`          |

**Ejemplo:** `feat(hardening): add kernel parameter validation script`

## 5. Flujo de Liberación (*Trunk-Based*)

1. Toda modificación se desarrolla en una rama corta (`feat/*`, `fix/*`, etc.).
2. Se crea un *Pull Request* hacia `main`.
3. `commitlint` valida el formato del *commit*.
4. La fusión se realiza exclusivamente mediante ***squash merge***.
5. `release-please` evalúa automáticamente el historial.
6. Se genera o actualiza el *Pull Request* de versión.
7. Al fusionarse el PR de versión (gestionado por un *Token* de automatización para permitir la ejecución de checks cruzados):
    - Se actualiza `CHANGELOG.md`.
    - Se crea la etiqueta correspondiente.
    - Se consolida el manifiesto de versión.

No existen ramas permanentes de desarrollo (`dev`, `release`, etc.).

## 6. Restricciones Operativas

No está permitido:

- Crear etiquetas manualmente.
- Modificar o eliminar etiquetas existentes.
- Incrementar versiones manualmente.
- Realizar *push* directo a `main`.
- Publicar *releases* fuera del flujo automatizado.

Las etiquetas `vMAJOR.MINOR.PATCH` deben estar protegidas contra modificación o eliminación.

## 7. Integridad y Reproducibilidad

El modelo garantiza:

- Historial lineal y auditable.
- Versionado determinista.
- Automatización sin intervención manual.
Integridad criptográfica de etiquetas (cuando la plataforma - lo permita).
- Eliminación de ambigüedad humana en *releases*.

Cada versión publicada representa un estado:

- Técnicamente válido
- Estructuralmente coherente
- Gobernado por las políticas activas del repositorio

## 8. Versionado del *Baseline* vs Repos Derivados

Este documento rige el versionado del repositorio `baseline-scripts`.

Los repositorios generados a partir del baseline pueden:

- Adoptar esta política sin cambios.
- Extenderla.
- Endurecerla.

Pero cualquier desviación debe documentarse explícitamente.

## 9. Cumplimiento Obligatorio

El sistema de versionado forma parte integral de la gobernanza técnica del repositorio.

Cualquier cambio que altere esta política debe:

- Realizarse mediante *Pull Request*.
- Declararse explícitamente como cambio incompatible si aplica.
- Seguir *Conventional Commits*.
- Ser aprobado bajo el modelo de revisión establecido.
