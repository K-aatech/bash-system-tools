# Política de Seguridad

Este repositorio define la base estructural y de gobernanza para proyectos de automatización basados ​​en *Bash*.

La seguridad se considera una preocupación fundamental.

## 1. Alcance

Esta política se aplica a:

- El repositorio de base.
- Automatización, flujos de trabajo y mecanismos de lanzamiento.
- Plantillas y documentación de gobernanza.
- Configuraciones de herramientas incluidas en la base.

Los repositorios derivados deben definir sus propias políticas de seguridad, incluso si están alineados con este documento.

---

## 2. Reportar una vulnerabilidad

Si descubre una vulnerabilidad de seguridad, no abra un informe público.

Este repositorio utiliza ***GitHub Private Vulnerability Reporting***. Para reportar un problema:

1. Diríjase a la pestaña ***Security*** del repositorio.
2. Seleccione ***Advisories*** en la barra lateral izquierda.
3. Haga clic en ***Report a vulnerability*** para enviar los detalles de forma privada a los mantenedores.

Los detalles confidenciales no deben divulgarse públicamente hasta que se disponga de una mitigación.

## 3. Tipos de Problemas de Seguridad

Los problemas de seguridad pueden incluir:

- Configuraciones incorrectas del flujo de trabajo que permiten la escalada de privilegios.
- Omisión de la automatización de versiones.
- Exposición de secretos o credenciales.
- Vulnerabilidades de dependencia.
- Configuración incorrecta de permisos.
- Debilidades estructurales en la aplicación de la gobernanza.

Las inconsistencias en la documentación que podrían debilitar la gobernanza también pueden considerarse problemas de seguridad.

## 4. Proceso de Gestión

Al recibir un informe:

1. Los responsables del mantenimiento acusarán recibo.
2. Se evaluará el riesgo.
3. Se identificarán los componentes afectados.
4. Se definirá un plan de remediación.
5. Se preparará una solución en una rama controlada.
6. La divulgación se realizará después de la mitigación.

El plazo depende de la gravedad y la complejidad.

## 5. Clasificación de Gravedad

Los problemas se pueden clasificar como:

- Bajo: Documentación o debilidades menores en la aplicación.
- Medio: Configuración incorrecta de la automatización sin riesgo directo de privilegios.
- Alto: Compromiso del proceso de lanzamiento, omisión de la gobernanza o riesgo de integridad estructural.
- Crítico: Exposición de credenciales, omisión de la ejecución o riesgo de toma de control del repositorio.

La clasificación debe alinearse con el [Modelo de Seguridad](./docs/security-model.md) estructural del repositorio.

La clasificación de gravedad determina la urgencia de la respuesta.

## 6. Divulgación Coordinada

El proyecto sigue los principios de divulgación responsable:

- No se realizará divulgación pública antes de la mitigación.
- No se publicarán los detalles del *exploit* antes del lanzamiento del parche.
- Actualizar el registro de cambios de forma transparente una vez resuelto.
- Actualización de la versión siguiendo las reglas de *SemVer*.

Los cambios importantes relacionados con la seguridad deben seguir las *Conventional Commits*.

## 7. Seguridad de Dependencias

El repositorio puede depender de actualizaciones automatizadas de dependencias.

Las actualizaciones de seguridad deben:

- Priorizarse.
- No debilitar las reglas de gobernanza.
- Validarse mediante CI antes de la fusión.

Las actualizaciones de dependencias no deben introducir cambios estructurales importantes sin declaración.

## 8. Secretos y Credenciales

Está estrictamente prohibido:

- Hacer *commit* con secretos.
- Almacenar *tokens* en texto plano.
- Incrustar credenciales en flujos de trabajo.
- Deshabilitar el escaneo de secretos.

Si se hace un *commit* de un secreto accidentalmente se debe:

1. Revocar el secreto inmediatamente.
2. Rotar las credenciales.
3. Abrir una *Pull Request* para su corrección.
4. Documentar el incidente internamente.

### 8.1 Escaneo Automatizado de Secretos

El repositorio aplica un control estructural obligatorio en dos niveles:

- **Nivel Local (Preventivo)**: El uso de `pre-commit` con ***TruffleHog*** es obligatorio para todos los colaboradores. Este control bloquea la creación del *commit* si se detectan secretos.
- **Nivel CI (Reactivo)**: Cada *Pull Request* se somete a un escaneo diferencial. Los escaneos programados analizan el historial completo y publican reportes SARIF en el panel de seguridad.

Cualquier intento de evasión (como el uso de `--no-verify`) sin una causa justificada y documentada se considera una infracción de gobernanza y un riesgo de seguridad de nivel **Alto**.

### 8.2 Protocolo de Remediación (Incidente de Fuga)

Si un secreto llega a ser persistido en el historial de *Git*, el daño no se repara borrando la línea y haciendo un nuevo *commit*. Se debe actuar bajo el siguiente protocolo de "Tierra Quemada":

1. **Invalidación Inmediata**: Revocar el *token*, llave o *password* en el servicio proveedor (AWS, GitHub, GCP, etc.). **Este es el paso más crítico.**
2. **Rotación**: Generar nuevas credenciales.
3. **Limpieza del Historial**: Para eliminar el rastro del secreto en todos los *commits* y etiquetas, se recomienda el uso de `git filter-repo` (sustituto moderno de BFG):

    ```bash
    # Ejemplo para eliminar un archivo que contenía secretos en todo el historial
    git filter-repo --path path/to/secret_file --invert-paths
    ```

   - **Reescritura de Etiquetas**: Si el secreto estaba presente en alguna etiqueta, también se deben reescribir:

      ```bash
      git filter-repo --refs refs/tags/* --path path/to/secret_file --invert-paths
      ```

4. **Notificación**: Informar a los mantenedores y colaboradores sobre el incidente mediante el reporte privado e vulnerabilidades mencionado en la Sección 2.
5. **Forzar Actualización**: Tras la limpieza local, será necesario un `git push origin --force` en las ramas afectadas para sobrescribir el historial remoto comprometido.

   > [!CAUTION]
   > El uso de `--force` puede afectar a otros colaboradores. Se recomienda coordinar esta acción para minimizar interrupciones.

6. **Documentación Interna**: Registrar el incidente, las acciones tomadas y las lecciones aprendidas en un documento interno de seguridad.

## 9. Gestión de *Tokens* Automatizados

El repositorio puede utilizar *tokens* de automatización para procesos de *release* u otras operaciones controladas de CI.

Estos *tokens* deben:

- Ser ***Fine-Grained*** cuando la plataforma lo permita.
- Tener alcance mínimo necesario.
- Tener expiración definida.
- Ser rotados periódicamente.
- No incluir permisos administrativos.
- Estar restringidos a cuentas técnicas o de servicio.

La configuración de dichos *tokens* forma parte del modelo de seguridad estructural del proyecto.

El uso indebido, ampliación de privilegios o reutilización fuera del flujo autorizado constituye un incidente de seguridad.

## 10. Protección de ramas y etiquetas

La postura de seguridad requiere:

- Rama principal protegida.
- No forzar *push*.
- Requerir *Pull Request*.
- Modificación de etiquetas restringida.
- Verificaciones de CI forzadas.

Deshabilitar estas protecciones constituye una infracción de gobernanza.

## 11. Seguridad y Cambios Importantes

Si una corrección de seguridad requiere una modificación estructural:

- Puede activar una versión *MAJOR*.
- Debe documentarse explícitamente.
- No debe alterar las expectativas de gobernanza de forma silenciosa.

## 12. Responsabilidad del Mantenedor

Los mantenedores son responsables de:

- Preservar la integridad de la versión.
- Proteger los procesos de automatización.
- Garantizar el control de versiones determinista.
- Prevenir la erosión de la gobernanza.

La seguridad es inseparable de la gobernanza.

## 13. Descargo de responsabilidad

Este repositorio proporciona estándares estructurales y de gobernanza.

Los repositorios derivados son responsables de definir los controles de seguridad adecuados a su riesgo operativo.
