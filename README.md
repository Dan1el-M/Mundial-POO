# Mundial-POO

Sistema de gestión del Mundial FIFA 2026 desarrollado con **Ruby on Rails 7.1.6** y **SQLite**. La aplicación cubre la fase de grupos, clasificación a eliminación directa, registro de resultados, avance automático del bracket y visualización del podio final.

## Funcionalidades principales

- CRUD de grupos (`A` a `L`)
- Registro y edición de selecciones con estadísticas acumuladas
- Registro de partidos de fase de grupos con actualización automática de:
  - puntos
  - goles a favor
  - goles en contra
  - diferencia de goles
- Tabla de posiciones por grupo
- Clasificación automática de:
  - primero y segundo de cada grupo
  - los 8 mejores terceros lugares
- Generación del bracket de eliminación directa
- Avance automático entre rondas:
  - dieciseisavos
  - octavos
  - cuartos
  - semifinales
  - tercer lugar
  - final
- Visualización de campeón, subcampeón y tercer lugar

## Arquitectura aplicada

La aplicación sigue el patrón **MVC** de Rails y separa la lógica de negocio compleja en **Service Objects**:

- `GroupStandingService`: ordena la tabla de posiciones de un grupo
- `ThirdPlacesRankingService`: calcula los mejores terceros
- `KnockoutBracketService`: genera la llave de 32 clasificados
- `MatchResultUpdater`: recalcula estadísticas de grupo al registrar o editar resultados
- `RoundAdvancer`: crea la siguiente ronda al completarse la actual

## Requisitos

- Ruby `4.0.5`
- Bundler
- SQLite 3

## Instalación

Desde la raíz del proyecto:

```powershell
bundle install
ruby bin\rails db:migrate
ruby bin\rails db:seed
```

También puedes usar:

```powershell
ruby bin\setup
```

## Ejecución

Para levantar el servidor:

```powershell
ruby bin\rails server
```

Luego abre:

```text
http://localhost:3000
```

## Flujo de uso recomendado

1. Revisar o completar los grupos en `Groups`
2. Revisar o completar las selecciones en `Teams`
3. Registrar resultados en `Group Matches`
4. Consultar tablas en `Standings`
5. Abrir `Qualified` y generar la llave de eliminación directa
6. Registrar resultados en `Knockout`
7. Consultar el podio final en `Champion`

## Rutas principales

- `/` → dashboard de posiciones
- `/groups` → gestión de grupos
- `/teams` → gestión de selecciones
- `/group_matches` → fase de grupos
- `/tournament/qualified` → clasificados
- `/knockout_matches` → eliminación directa
- `/tournament/champion` → campeón, subcampeón y tercer lugar

## Seeds incluidas

El archivo `db/seeds.rb` crea:

- los 12 grupos (`A`..`L`)
- 48 selecciones distribuidas en grupos de 4

## Pruebas

Para ejecutar las pruebas:

```powershell
ruby bin\rails test
```

## Notas técnicas

- Los logs y las bases SQLite locales de desarrollo están excluidos del control de versiones.
- La fase de grupos recalcula estadísticas desde resultados persistidos para que editar un partido no corrompa la tabla.
- La eliminación directa resuelve empates con penales y avanza automáticamente los ganadores.
