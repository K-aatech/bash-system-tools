# Política de Versiones

Este repositorio sigue el Versionado Semántico (SemVer) e implementa **Commits Convencionales** para garantizar versiones deterministas y automatizadas mediante `release-please`.

---

## Estrategia de Versionado Semántico

Formato de versión:

MAYOR.MENOR.PATCH

Ejemplo:

4.2.0

### MAYOR

Se incrementa cuando:
- Se introduce un cambio importante.
- Se modifican o eliminan los indicadores de la CLI.
- Se rompe intencionalmente la compatibilidad con versiones anteriores.

Debe declararse usando:

feat!: descripción

o

BREAKING CHANGE: descripción

---

### MENOR
Se incrementa cuando:
- Se añade una nueva característica.
- Se introduce una nueva funcionalidad de forma compatible con versiones anteriores.

Activado por:

feat: descripción

---

### PATCH
Se incrementa cuando:
- Se corrige un error.
- Se mejora el rendimiento.
- La refactorización interna se realiza sin comprometer la compatibilidad.
- Se realizan ajustes de integración continua (CI) o de infraestructura.

Activado por:

fix:
perf:
refactor:
ci:

---

## Tipos de *commits*

Se permiten y aplican los siguientes tipos de *commits*:

- feat
- fix
- perf
- refactor
- docs
- ci
- test
- chore

Los *commits* deben seguir este formato:

type(alcance opcional): descripción breve

Ejemplos:

feat(cli): añadir modo interactivo
fix: gestionar la validación de entrada vacía
ci: actualizar el flujo de trabajo de la versión
docs: aclarar los pasos de instalación

---

## Generación del registro de cambios

Las entradas del registro de cambios se generan automáticamente mediante `release-please`.

Las secciones se agrupan de la siguiente manera:

- 🚀 Features
- 🐛 Bug Fixes
- ⚡ Performance
- ♻️ Refactoring
- ⚙️ CI/CD & Infra
- 📚 Documentation
- 🧪 Tests

Las confirmaciones de mantenimiento (`chore`) se ocultan del registro de cambios.

---

## Proceso de lanzamiento

1. Los cambios se fusionan en `main`.
2. `release-please` evalúa las confirmaciones.
3. Se genera automáticamente una solicitud de versión.
4. Tras la fusión, se crea una etiqueta de versión.
5. `CHANGELOG.md` se actualiza automáticamente.

> [!CAUTION]
> **No se permite la actualización manual de versiones.**

---

## Principios de gobernanza

- Todas las confirmaciones deben pasar la validación de `commitlint`.
- La combinación y la fusión deben conservar el formato convencional de las confirmaciones.
- Se prohíben las subidas directas a `main`.
- Los lanzamientos son totalmente automatizados y deterministas.
