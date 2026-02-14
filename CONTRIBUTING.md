# Guía de Contribución - ***Bash System Tools***

Gracias por interesarte en mejorar esta *suite*. Para mantener la estabilidad de las herramientas en entornos de producción, seguimos estas reglas:

## 🏗️ Flujo de Trabajo (*Trunk-Based*)

Este repositorio opera bajo un modelo ***trunk-based development***.

1. Crear rama corta desde `main`:
   - `feat/*`
   - `fix/*`
   - `chore/*`
   - `docs/*`

2. Enviar *Pull Request* hacia `main`.
3. El PR debe pasar:
   - *ShellCheck*
   - Validación de permisos ejecutables
   - Validación de *Conventional Commits*
4. La fusión se realiza exclusivamente mediante ***Squash Merge***.

> [!NOTE]
> No existen ramas `dev`, `release`, ni ciclos manuales de RC.

| Fase            | Acción                 | Comando / Herramienta                                  | Rama                  |
|-----------------|------------------------|--------------------------------------------------------|-----------------------|
| **Desarrollo**  | Crear funcionalidad    | `git checkout -b feat/nombre`                          | `feat/*`              |
| **Calidad**     | Linter Automático      | `linting.yml` (ShellCheck), commitlint, governance     | PR a `main`           |
| **Integración** | Consolidar en `main`   | **Squash Merge**                                       | `main`                |
| ***Release***   | Publicación Oficial    | ***Release Please*** (Aprobar el PR generado)          | `main`                |

## ⚠️ Activación del *Pre-commit Hook*

Después de clonar el repositorio, ejecutar:

```bash
git config core.hooksPath .githooks
```

Esto activa las validaciones locales obligatorias.

El hook es parte del modelo de gobernanza.
No activarlo puede resultar en fallos de CI y bloqueo del PR.

---

## 💻 Estándares de Código
- Usa `[[ ]]` en lugar de `[ ]` para condiciones.
- Todas las variables deben estar entre comillas `"$VARIABLE"`.
- Usa `local` para variables dentro de funciones.
- No olvides documentar las nuevas funciones en `/docs`.
