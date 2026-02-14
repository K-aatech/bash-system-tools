# Política de Versiones

Este repositorio adopta **Semantic Versioning (SemVer)** y utiliza **Conventional Commits** para garantizar versionado automático, determinista y reproducible mediante `release-please`.

El modelo está diseñado bajo un enfoque **trunk-based** con gobernanza estricta sobre el historial y las etiquetas.

---

## Formato de Versión

Las versiones siguen el esquema:

MAJOR.MINOR.PATCH

Ejemplo:

4.2.0

Las etiquetas se generan automáticamente con el prefijo `v`:

v4.2.0

---

## Derivación de Versiones

El incremento se determina exclusivamente por el tipo de commit fusionado en `main`.

### MAJOR

Se incrementa cuando se introduce un cambio incompatible.

Debe declararse mediante:

- `feat!: descripción`
- o incluir `BREAKING CHANGE:` en el cuerpo del commit

---

### MINOR

Se incrementa cuando se agrega funcionalidad compatible hacia atrás.

Activado por:

- `feat:`

---

### PATCH

Se incrementa cuando se corrigen errores o se realizan mejoras compatibles.

Activado por:

- `fix:`
- `perf:`
- `refactor:`
- `ci:` (cuando aplique)
- `test:` (cuando aplique)

> [!NOTE]
> Los commits `docs:` y `chore:` no generan incremento de versión por sí mismos.

---

## Tipos de Commit Permitidos

Los commits deben seguir el formato:

`type(alcance opcional): descripción breve`

Tipos admitidos:

- feat
- fix
- perf
- refactor
- docs
- ci
- test
- chore

Ejemplos:

`feat(cli): add interactive mode`
`fix: handle empty input validation`
`ci: update workflow permissions`
`docs: clarify installation instructions`

---

## Flujo de Liberación (Trunk-Based)

1. Toda mejora nace en una rama corta `feat/*` o `fix/*`.
2. Se crea un Pull Request hacia `main`.
3. `commitlint` valida la convención.
4. La fusión se realiza exclusivamente mediante *squash merge*.
5. `release-please` evalúa automáticamente el historial.
6. Se genera o actualiza el Pull Request de versión.
7. Al fusionarse el PR de versión:
   - Se actualiza `CHANGELOG.md`.
   - Se crea la etiqueta correspondiente.
   - Se consolida el estado del manifiesto.

> [!NOTE]
> No existen ramas de desarrollo permanentes (`dev`, `release`, etc.).

---

## Restricciones

**No está permitido:**

- Crear etiquetas manualmente.
- Modificar etiquetas existentes.
- Incrementar versiones manualmente.
- Realizar push directo a `main`.

Las etiquetas `vMAJOR.MINOR.PATCH` están protegidas contra eliminación o modificación.

---

## Garantías del Modelo

Este esquema proporciona:

- Historial lineal y auditable.
- Versionado semántico predecible.
- Automatización sin intervención manual.
- Integridad de etiquetas.
- Reducción de error humano.

El sistema de versionado forma parte integral de la gobernanza técnica del repositorio.
