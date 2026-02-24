# 🛡️ Seguridad: Preguntas Frecuentes (FAQ)

## 1. *TruffleHog* bloqueó mi *commit*, pero no es un secreto real

Esto es un **Falso Positivo** (ej. un ID de prueba que parece una *API Key*).

- **Solución**:

    1. Identifique el archivo en el reporte de la terminal.
    2. Añada la ruta a la sección `exclude_paths` en el archivo `.trufflehog.yaml` en la raíz del proyecto.
    3. Si es un *string* específico en un archivo que **no** debe ser ignorado por completo, consulte la documentación de [TruffleHog](https://github.com/trufflesecurity/trufflehog) para exclusiones granulares.

> [!WARNING]
> Nunca ignore archivos como `.env`, `secrets.yaml` o carpetas de configuración sensible.

## 2. El proceso de *commit* se queda congelado

Habitualmente ocurre por el **Agente GPG** (Firmado de *Commits*). El proceso espera la frase de paso (*passphrase*) y el *prompt* no logra saltar a primer plano.

- **Solución Rápida**: Ejecute `echo "test" | gpg --clearsign` en su terminal para forzar la apertura del *prompt* de la contraseña.
- **Solución Permanente**: Asegúrese de tener configurado un `pinentry` adecuado para su sistema operativo (ej. `pinentry-mac` o `pinentry-gnome`).

## 3. ¿Cómo reporto un secreto filtrado de verdad?

Si un secreto real llegó al historial (incluso si no se ha hecho `push` a `main`):

1. **Invalidación Inmediata**: Rote la credencial (anúlela en el servicio origen). **Borrar el commit no invalida el secreto**.
2. **Notificación**: Informe al responsable de seguridad o al CODEOWNER del repositorio.
3. **Saneamiento**: El historial deberá ser limpiado profundamente usando `git filter-repo` o `bfg-repo-cleaner`.

> [!CAUTION]
> Una vez que un secreto toca el servidor de *GitHub*, se considera comprometido permanentemente.
> Nunca confíe en que eliminar un *commit* revertirá la exposición.
