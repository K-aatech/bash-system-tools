# Arquitectura de Integración Continua (CI)

Este documento define la arquitectura de automatización del repositorio `baseline-scripts`.

La CI no es un complemento; es el mecanismo de ejecución de la gobernanza técnica.

## 1. Principios de Diseño

La arquitectura CI se rige por los siguientes principios:

- Automatización obligatoria
- Validación temprana
- Determinismo
- Reproducibilidad
- Mínimo privilegio
- Separación de responsabilidades

La CI convierte reglas declarativas en controles ejecutables.

## 2. Objetivos de la CI

La arquitectura de integración continua debe garantizar:

1. Cumplimiento de *Conventional Commits*.
2. Versionado automático determinista.
3. Generación automática de *changelog*.
4. Validación estructural del repositorio.
5. Análisis estático de *scripts*.
6. Integridad de dependencias.
7. Prevención de debilitamiento de gobernanza.

Si una validación falla, el *Pull Request* no debe poder fusionarse.

## 3. Componentes Principales

La arquitectura CI se compone de los siguientes bloques:

### 3.1 Validación de *Commits*

Se ejecuta en el *workflow* `linting.yml` mediante `commitlint` con configuración basada en [Conventional Commits](https://www.conventionalcommits.org/).
Responsable de:

- Validar formato según *Conventional Commits*.
- Bloquear *commits* no conformes.
- Mantener coherencia con el modelo de versionado.

Impacto directo en derivación automática de versión.

### 3.2 Versionado Automatizado

Gestionado por `release-please`.

Responsable de:

- Analizar historial de *commits*.
- Determinar incremento *MAJOR* / *MINOR* / *PATCH*.
- Generar *Pull Request* de versión.
- Crear etiquetas `vX.Y.Z`.
- Actualizar `CHANGELOG.md`.

No se permite creación manual de etiquetas ni manipulación manual del número de versión.

#### 3.2.1 Automatización de *Releases* y Uso de *Token* Dedicado

Para garantizar que el *Pull Request* generado por la automatización:

- Ejecute validación de *commits*.
- Ejecute análisis estático.
- Cumpla las mismas reglas de gobernanza que cualquier otro *Pull Request*.

Podrá utilizarse un *Personal Access Token (PAT)* con alcance restringido para ejecutar el flujo de *release*.

Esta decisión responde a restricciones de activación de workflows asociadas al `GITHUB_TOKEN`, que impiden su activación completa cuando el PR es generado por automatización.

El *token* debe:

- Cumplir las restricciones definidas en el [Modelo de Seguridad](./security-model.md).
- Tener permisos mínimos necesarios.
- Estar restringido exclusivamente al flujo de liberación.
- Ser almacenado como secreto del repositorio.

La arquitectura CI considera este *token* una excepción controlada, auditada y limitada al proceso de versionado automático.

### 3.3 Análisis Estático

Análisis automatizado para garantizar la calidad del código:

- **ShellCheck (`shellcheck.yml`)**: Valida la lógica y sintaxis de *scripts* `.sh`. Los hallazgos de severidad 'error' y 'warning' bloquean el *pipeline*.
- **Bash Style Guide**: Los *scripts* deben alinearse manualmente con la [guía de estilo interna](./bash-style-guide.md), siendo *ShellCheck* el principal mecanismo de refuerzo de estas reglas.
- **Format & Schema (`linting.yml`)**: Validación de sintaxis para `YAML`, `JSON` y consistencia de documentación en `Markdown`.

Cuando es posible, los resultados se publican en formato **SARIF** para integrarse con el panel de *Security Code Scanning* de *GitHub*.

### 3.4 Estándares de Formato (*Linting*)

Garantiza que la documentación y configuraciones sean legibles y válidas:

- **`linting.yml`**: Ejecuta validaciones de `Markdown`, `YAML` y `JSON`. Previene errores de sintaxis en la infraestructura de *GitHub Actions*.

### 3.5 Validación Estructural y de Seguridad

Asegura que la base del repositorio no sea degradada:

- **TruffleHog (`secret-scanning.yml`)**: Impide la persistencia de secretos.
- **Validación Estructural**: (Pendiente de *script custom*) Garantiza la presencia de artefactos normativos y archivos obligatorios.

La eliminación de artefactos normativos constituye una falla crítica.

### 3.6 Dependencias

Se deben validar:

- Actualizaciones automáticas.
- Compatibilidad con gobernanza.
- No introducción de cambios incompatibles sin declaración explícita.

## 4. Flujo de Ejecución (PR vs *Main*)

### 4.1 En *Pull Request*

Debe ejecutarse:

- Validación de *commits*.
- *Linting* y análisis estático.
- Validación estructural.
- Validación de configuración.

El PR solo puede fusionarse si todas las validaciones pasan.

### 4.2 En `main`

Debe ejecutarse:

- Evaluación de versionado.
- Generación de PR de *release*.
- Publicación de etiqueta tras aprobación.

## 5. Matriz de Trazabilidad Técnica

Esta tabla vincula los principios de gobernanza con los archivos de ejecución reales:

| Componente                 | Archivo Workflow      | Nivel de Control       |
| :------------------------- | :-------------------- | :--------------------- |
| **Conventional Commits**   | `linting.yml`         | Bloqueante (CI)        |
| **Linting (MD/YAML/JSON)** | `linting.yml`         | Informativo/Bloqueante |
| **Shell Analysis**         | `shellcheck.yml`      | Bloqueante (CI)        |
| **Secret Scanning**        | `secret-scanning.yml` | Crítico (SARIF)        |
| **Versionamiento**         | `release-please.yml`  | Automatizado (Main)    |

## 6. Permisos y Seguridad

Los *workflows* deben:

- Utilizar permisos mínimos necesarios.
  - Declarar explícitamente el bloque `permissions:` en cada *workflow*.
  - Prohibir el uso de permisos implícitos por defecto.
- Evitar *tokens* con privilegios excesivos.
- No exponer secretos en *logs*.
- Usar versiones fijas o controladas de acciones externas.

La arquitectura CI forma parte del modelo de seguridad estructural.

## 7. CI como Control de Gobernanza

La CI no solo valida código.

También protege:

- Integridad del modelo *trunk-based*.
- Determinismo de *releases*.
- Coherencia de documentación normativa.
- Cumplimiento del contrato estructural.

Si una regla no está automatizada, no está completamente protegida.

---

## 8. Evolución de la Arquitectura

Cambios en la arquitectura CI que:

- Alteren reglas obligatorias
- Debiliten validaciones
- Modifiquen el modelo de versionado
- Permitan *bypass* de controles

Deben declararse como `BREAKING CHANGE` cuando afecten el contrato estructural.

## 9. Repositorios Derivados

Los repositorios creados a partir de este *baseline* deben:

- Implementar una arquitectura CI equivalente o superior.
- Mantener validación de *commits*.
- Mantener versionado automático.
- No debilitar controles obligatorios.

La CI es parte integral del *baseline*.

## 10. Declaración Final

La arquitectura de integración continua es el mecanismo técnico que ejecuta la gobernanza.

Sin CI obligatoria:

- El versionado deja de ser determinista.
- La estructura deja de ser verificable.
- La seguridad pierde automatización.
- La gobernanza se vuelve opcional.

En este *baseline*, la gobernanza no es opcional.
