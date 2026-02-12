# Política de Versiones

Este repositorio sigue el **Versionado Semántico (SemVer)** e implementa ***Conventional Commits*** para garantizar versiones deterministas y automatizadas mediante `release-please`.

---

## Estrategia de Versionado Semántico

Formato de versión:

MAYOR.MENOR.PATCH

Ejemplo:

4.2.0

### MAYOR

Se incrementa cuando:
- Se introduce un cambio incompatible con versiones anteriores.
- Se eliminan o modifican indicadores de CLI.
- Se rompe intencionalmente la compatibilidad con versiones anteriores.

Debe declararse usando:

`feat!: descripción`

o

`BREAKING CHANGE: descripción`

---

### MENOR
Se incrementa cuando:
- Se añade nueva funcionalidad compatible con versiones anteriores.

Activado por:

`feat: descripción`

---

### PATCH
Se incrementa cuando:
- Se corrige un error.
- Se mejora rendimiento.
- Se realizan ajustes internos de CI/CD o infraestructura.
- Se refactoriza sin romper compatibilidad.

Activado por:

`fix:`
`perf:`
`refactor:`
`ci:`

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

Los *commits* **deben** seguir este formato:

`type(alcance opcional): descripción breve`

Ejemplos:

`feat(cli): Add interactive mode`
`fix: Handle empty input validation`
`ci: Update version workflow`
`docs: Clarify installation steps`

---

## Generación de *CHANGELOG*

`release-please` genera automáticamente el registro de cambios agrupado por secciones:

- 🚀 Features
- 🐛 Bug Fixes
- ⚡ Performance
- ♻️ Refactoring
- ⚙️ CI/CD & Infra
- 📚 Documentation
- 🧪 Tests

> [!NOTE]
> Las confirmaciones tipo `chore` se ocultan del *changelog*.


---

## Flujo de trabajo trunk-based

1. Todas las mejoras se desarrollan en ramas `feat/*` o `fix/*`.
2. Se crean PR hacia `main`.
3. `commitlint` valida la convención.
4. `release-please` genera automáticamente la PR de *release*, etiquetas y actualización del *changelog*.
5. Los *merges* en `main` generan las versiones estables.
6. *Release Candidates* (RC) son manuales y opcionales; se etiquetan solo cuando se necesite *pre-release*.


> [!CAUTION]
> **No se permite la actualización manual de versiones.**

---

## Principios de gobernanza

- Todos los commits deben pasar `commitlint`.
- No se permiten push directo a `main`.
- Los lanzamientos son totalmente automatizados y deterministas.
