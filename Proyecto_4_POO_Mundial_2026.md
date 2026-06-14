# Proyecto 4 de POO: Sistema de Gestión de la Copa Mundial FIFA 2026

El propósito de este proyecto es diseñar e implementar un sistema completo de gestión de la Copa Mundial de la FIFA México-USA-Canadá 2026, mediante una aplicación web desarrollada con Ruby on Rails.

El sistema permitirá gestionar las fases y etapas de la Copa Mundial de la FIFA 2026, considerando que el torneo contará con 48 selecciones, distribuidas en 12 grupos de 4 equipos. En la fase de grupos, cada selección disputará tres partidos y clasificarán a la fase de eliminación directa los dos primeros lugares de cada grupo.

El sistema podrá registrar selecciones, gestionar partidos, calcular posiciones en la fase de grupos y administrar la fase de eliminación directa hasta determinar el campeón del torneo.

## Requerimientos del sistema

El sistema debe permitir:

1. Registrar selecciones participantes, incluyendo:
   - Nombre del país.
   - Grupo asignado.
   - Puntos.
   - Goles a favor.
   - Goles en contra.
   - Diferencia de goles.

2. Crear y administrar (CRUD) los 12 grupos del torneo, identificados de la A a la L.

3. Registrar los resultados de los partidos de fase de grupos.

4. Calcular automáticamente la tabla de posiciones de cada grupo, tomando en cuenta:
   - Puntos.
   - Diferencia de goles.
   - Goles a favor.

5. Determinar los clasificados a la fase de eliminación directa:
   - Primer y segundo lugar de cada grupo.
   - Ocho mejores terceros lugares.

6. Gestionar la fase de eliminación directa:
   - Dieciseisavos de final.
   - Octavos de final.
   - Cuartos de final.
   - Semifinales.
   - Partido por tercer lugar.
   - Final.

7. Registrar los resultados de cada partido de eliminación directa (incluya los goles adicionales, en caso de que el partido se vaya a penales).

8. Avanzar automáticamente al equipo ganador a la siguiente ronda, una vez todos los partidos de la primera fase hayan sido completados.

9. Mostrar el campeón, subcampeón y tercer lugar del Mundial.

## Consideraciones y aspectos técnicos

1. El manejo de los datos queda a criterio de los estudiantes. Podría generarse desde un archivo TXT, un JSON, SQLite o incluso una base de datos relacional, como PostgreSQL.

2. La arquitectura lógica utilizada queda también a discreción de los estudiantes; no obstante, se espera que cumplan con las buenas prácticas de la POO y los principios SOLID.

- El proyecto debe ser desarrollado en Ruby mediante el framework Ruby on Rails. Puede utilizar la versión que desee; no obstante, se recomienda la versión 7.1 por ser una de las versiones recientes más estables y fáciles de usar por sus características.
- Debe generar una interfaz gráfica.
- El código debe ser modular, comentado y estructurado.

## Aspectos administrativos

- La tarea vale un 15% de la nota del curso.
- La tarea se hará en grupos de 4 personas como máximo.
- **Fecha de entrega:** martes 30 de julio de 2025. No se aceptan tareas entregadas después de esa fecha.
- **IMPORTANTE:** En caso de desearlo, podría realizar la revisión del proyecto antes de la fecha límite de entrega. Si desean trabajarlo de esta manera, deben contactar al profesor para coordinar la fecha y hora ideal para todos(as).
- Los grupos deberán subir el código y la documentación de sus respectivas tareas a un repositorio en GitHub, de manera que el profesor pueda ver las contribuciones que las diferentes personas hacen al proyecto. La idea es que, apenas empiecen a desarrollar la tarea, suban las contribuciones al repositorio y no esperen a tener todo el código listo para subirlo.
- En el TEC Digital deberán subir un documento con las siguientes secciones:
  - Portada.
  - Índice.
  - Enlace de GitHub.
  - Pasos de instalación del programa.
  - Manual de usuario.
  - Arquitectura lógica utilizada:
    - Explicación del funcionamiento.
    - Diagrama de clases del sistema implementado.
- Todos los miembros del grupo deberán participar en la revisión, ya que, de lo contrario, no se les asignará el puntaje correspondiente. La nota de la revisión es individual; el resto de la nota es grupal.
- El código entregado debe ser 100% original. En caso de probarse algún tipo de fraude en la elaboración de la tarea, se aplicarán todas las medidas correspondientes según el reglamento del TEC, incluyendo una carta al expediente.

## Evaluación

| Aspecto por evaluar | Porcentaje |
|---|---:|
| Documentación | 10% |
| Registro de equipo | 25% |
| Fase de grupo y registro de puntajes | 30% |
| Fase de eliminación directa | 25% |
| Flujo lógico, interfaz y arquitectura SOLID | 10% |
