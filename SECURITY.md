# Política de Seguridad

Este repositorio mantiene prácticas activas de seguridad orientadas a la integridad del código, la trazabilidad de versiones y la protección de la cadena de suministro.

---

## Versiones Soportadas

Se mantiene activamente la versión estable más reciente.

Las correcciones de seguridad se aplican directamente sobre la rama principal (`main`) y se incluyen en la siguiente versión liberada.

---

## Reporte de Vulnerabilidades

Si detecta una posible vulnerabilidad de seguridad:

1. Utilice la funcionalidad **GitHub Security Advisories** para realizar un reporte privado.
2. En caso de no estar disponible, contacte directamente al mantenedor.

Se solicita no divulgar públicamente detalles de vulnerabilidades hasta que exista una corrección disponible.

---

## Automatización de *Releases* e Integridad

Las versiones se generan automáticamente mediante un proceso controlado de automatización.

Características del proceso:

- Versionado semántico (`vMAJOR.MINOR.PATCH`).
- Generación automática de *changelog* basada en *Conventional Commits*.
- Protección explícita de etiquetas (`v*`) contra eliminación o modificación.
- Historial lineal obligatorio.
- Validaciones automáticas requeridas antes de cada *merge*.
- Firmado obligatorio de *commits*.

Las etiquetas de versión son consideradas artefactos inmutables.

---

## Control de Integridad del Código

Se aplican las siguientes políticas obligatorias:

- *Pull Request* obligatorio antes de *merge*.
- Resolución de conversaciones requerida.
- Validaciones de CI obligatorias.
- Análisis estático de seguridad (CodeQL).
- Resultados de calidad de código requeridos.
- Firmado criptográfico de *commits*.
- Bloqueo de *force-push* y eliminación de rama principal.

---

## Política de *Tokens* y Automatización

La automatización de *releases* utiliza un *Personal Access Token* (PAT) de alcance restringido.

Política de rotación:

- Renovación obligatoria al menos cada 12 meses.
- Rotación inmediata ante cambios de permisos.
- Rotación inmediata ante sospecha de compromiso.

La fecha de expiración del token se gestiona de manera preventiva para evitar interrupciones del proceso de automatización.

---

## Divulgación Responsable

Se promueve la divulgación responsable y coordinada de vulnerabilidades.

Las actualizaciones de seguridad se publican como parte de las versiones regulares del proyecto o, en caso necesario, mediante una versión correctiva específica.
