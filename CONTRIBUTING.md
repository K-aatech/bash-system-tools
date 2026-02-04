# Guía de Contribución - ***Bash System Tools***

Gracias por interesarte en mejorar esta *suite*. Para mantener la estabilidad de las herramientas en entornos de producción, seguimos estas reglas:

## 🏗️ Flujo de Trabajo (*Git Workflow*)

Para garantizar la estabilidad, seguimos un modelo de promoción de código por capas:

1. **Fork & Branch:** Crea una rama con un nombre descriptivo (ej: `feat/add-zfs-audit`).
2. **Desarrollo:** Realiza tus cambios asegurando que los *scripts* sean idempotentes.
3. ***Commits*:** Usa el estándar de [Conventional Commits](https://www.conventionalcommits.org/).
4. ***Pull Request*:** Envía tu PR exclusivamente a la rama **`dev`**.
5. **Validación:** El PR disparará automáticamente un análisis con **ShellCheck**. Si el linter falla, el PR no será revisado hasta que se corrija.

| Fase            | Acción                 | Comando / Herramienta                                  | Rama                  |
|-----------------|------------------------|--------------------------------------------------------|-----------------------|
| **Desarrollo**  | Crear funcionalidad    | `git checkout -b feat/nombre`                          | `feat/*`              |
| **Calidad**     | Linter Automático      | `linting.yml` (ShellCheck)                             | PR a `dev`            |
| **Integración** | Consolidar en Dev      | **Squash Merge**                                       | `dev`                 |
| **Pre-Release** | Tag de Prueba (Manual) | `git tag vX.Y.Z-rc.N && git push --tags`               | `dev` o `release/*`   |
| **Promoción**   | Paso a Producción      | PR de `dev` o `release/*` a `main` (**Merge Commit**)  | `main`                |
| ***Release***   | Publicación Oficial    | ***Release Please*** (Aprobar el PR generado)          | `main`                |

### 🧪 Manejo de *Release Candidates* (RC)
Si el desarrollo en `dev` continúa mientras se prueba una versión:
1. Se crea una rama de estabilización: `release/vX.Y.Z`.
2. Las correcciones encontradas en las pruebas se hacen sobre esa rama y se integran luego a `dev`.
3. Al aprobarse, esa rama es la que se promociona a `main`.

## 🚀 Ciclo de Lanzamiento

1. Las mejoras se consolidan en `dev`.
2. Se generan etiquetas `vX.Y.Z-rc.N` para pruebas de integración.
3. Una vez validado, se realiza un *Merge* de `dev` a `main`.
4. El sistema generará automáticamente un "Release PR". Al aceptarlo, se publicará la nueva versión estable.

## 💻 Estándares de Código
- Usa `[[ ]]` en lugar de `[ ]` para condiciones.
- Todas las variables deben estar entre comillas `"$VARIABLE"`.
- Usa `local` para variables dentro de funciones.
- No olvides documentar las nuevas funciones en `/docs`.
