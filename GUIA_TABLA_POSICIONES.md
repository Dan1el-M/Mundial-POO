# Guía: Sistema de Cálculo de Tablas de Posiciones

## Resumen de lo implementado

Se ha creado un sistema completo y robusto para calcular y gestionar las tablas de posiciones de la Copa Mundial 2026.

---

## 📊 Obtener Tabla de Posiciones de un Grupo

```ruby
# Opción 1: Desde el modelo Grupo
grupo = Grupo.find_by(letra: "A")
tabla = grupo.tabla_posiciones
# => [Seleccion, Seleccion, Seleccion, Seleccion] (ordenadas por puntos, diferencia, goles)

# Opción 2: Alias más legible
tabla = grupo.posiciones

# Opción 3: Con scope directo
tabla = Seleccion.tabla_de_grupo(grupo.id)
```

---

## 🏆 Clasificados de un Grupo

```ruby
grupo = Grupo.find_by(letra: "B")

# Primero y segundo lugar (clasifican automáticamente a 16avos)
clasificados = grupo.clasificados_directos
# => [primer_lugar, segundo_lugar]

# Tercer lugar (podría clasificar como mejor tercero)
tercero = grupo.tercero
# => Seleccion

# Cuarto lugar (NO clasifica)
cuarto = grupo.cuarto
# => Seleccion
```

---

## 📝 Registrar Resultados de Partidos

### Opción 1: Registrar con goles solo

```ruby
partido = Partido.find(1)

# Registra goles y finaliza automáticamente el partido
# Actualiza automáticamente puntos, goles y diferencia en ambas selecciones
partido.registrar_resultado!(
  goles_local: 2,
  goles_visitante: 1
)
```

### Opción 2: Con penales (eliminación directa)

```ruby
partido = Partido.find(2)

# Registra goles regulares y penales
partido.registrar_resultado!(
  goles_local: 1,
  goles_visitante: 1,
  goles_penales_local: 4,
  goles_penales_visitante: 2
)
```

### Opción 3: Registrar en pasos (recomendado)

```ruby
partido = Partido.find(3)

# Paso 1: Registrar goles en tiempo regular
partido.registrar_goles_regulares!(2, 2)

# Paso 2: Después, registrar los penales
partido.registrar_penales!(5, 3)
```

---

## 🤖 Estadísticas Automáticas

### Sistema automático de actualización

Cuando registras un resultado en fase de grupos:

```ruby
partido.registrar_resultado!(2, 1)
```

Se ejecutan automáticamente:
1. ✅ Se calcula el ganador
2. ✅ Se actualizan los puntos de ambas selecciones (3, 1 o 0)
3. ✅ Se actualizan goles a favor y en contra
4. ✅ Se recalcula la diferencia de goles
5. ✅ Se recalcula la tabla de posiciones del grupo
6. ✅ Se actualiza la posición de cada equipo

### Recalcular estadísticas manualmente

Si algo se corrompió o necesitas sincronizar:

```ruby
# Recalcular una selección individual
service = ActualizarEstadisticasSeleccion.new(seleccion)
service.recalcular!

# Recalcular TODAS las selecciones de un grupo
grupo = Grupo.find_by(letra: "A")
grupo.recalcular_todas_las_estadisticas!
```

---

## 👥 Consultas sobre Selecciones

```ruby
seleccion = Seleccion.find_by(acronimo: "MEX")

# Posición en su grupo
posicion = seleccion.posicion_en_grupo
# => 1 (primer lugar)

# Verificar si clasificó
if seleccion.clasificado_directo?
  # Primer o segundo lugar
end

if seleccion.es_tercero?
  # Tercer lugar (podría ser mejor tercero)
end

# Estadísticas de juego
puts seleccion.victorias
puts seleccion.empates
puts seleccion.derrotas
puts seleccion.partidos_finalizados.count

# Todos los partidos
partidos = seleccion.partidos_ordenados
pendientes = seleccion.partidos_pendientes
jugados = seleccion.partidos_finalizados

# Resumen completo
resumen = seleccion.resumen_estadisticas
# => {
#      nombre: "Mexico",
#      acronimo: "MEX",
#      grupo: "A",
#      posicion: 1,
#      puntos: 7,
#      victorias: 2,
#      empates: 1,
#      derrotas: 0,
#      goles_favor: 5,
#      goles_contra: 2,
#      diferencia_goles: 3,
#      partidos_jugados: 3
#    }
```

---

## 🎯 Determinar Clasificados a Fase de Eliminación Directa

```ruby
# Servicio que determina todos los clasificados
clasificados = DeterminarClasificados.obtener

# Retorna un hash con:
# {
#   primeros: [12 equipos],
#   segundos: [12 equipos],
#   terceros_clasificados: [8 mejores terceros],
#   total_clasificados: [32 equipos]
# }

# Acceso directo
primeros = clasificados[:primeros]
segundos = clasificados[:segundos]
terceros = clasificados[:terceros_clasificados]
todos = clasificados[:total_clasificados]
```

### Verificar progreso de fase de grupos

```ruby
service = DeterminarClasificados.new

# Verifica si fase de grupos está completa
if service.fase_grupos_completa?
  # Podemos pasar a eliminación
end

# Progreso actual
progreso = service.progreso_fase_grupos
# => 0.75 (75% de partidos finalizados)

# Estadísticas
puts service.partidos_fase_grupos_finalizados    # 36
puts service.total_partidos_fase_grupos         # 48
```

---

## 🏅 Mejores Terceros Lugares

```ruby
# Obtener los 8 mejores terceros de todos los grupos
# Ordenados automáticamente por: puntos → diferencia → goles a favor
mejores_terceros = Seleccion.mejores_terceros(8)

# Si solo necesitas algunos
top_3_terceros = Seleccion.mejores_terceros(3)
# => [tercero_A, tercero_D, tercero_G]
```

---

## 🔄 Flujo Completo: Fase de Grupos

```ruby
# 1. Crear grupos y selecciones (ya hecho en seeds)
grupo_a = Grupo.find_by(letra: "A")

# 2. Registrar un partido
partido = Partido.create!(
  numero_partido: 1,
  seleccion_local: Seleccion.find_by(acronimo: "MEX"),
  seleccion_visitante: Seleccion.find_by(acronimo: "JAP"),
  grupo: grupo_a,
  tipo_partido: "fase_grupos",
  estado: "programado"
)

# 3. Registrar resultado (actualiza TODO automáticamente)
partido.registrar_resultado!(2, 1)

# 4. Ver tabla actualizada
tabla = grupo_a.tabla_posiciones
tabla.each_with_index do |equipo, index|
  puts "#{index+1}. #{equipo.nombre} - #{equipo.puntos}pts (#{equipo.goles_favor}:#{equipo.goles_contra})"
end

# 5. Cuando todos los partidos estén listos, determinar clasificados
if DeterminarClasificados.new.fase_grupos_completa?
  clasificados = DeterminarClasificados.obtener
  puts "16 equipos clasificados a eliminación directa"
end
```

---

## ⚠️ Validaciones Automáticas

Todas estas validaciones se ejecutan automáticamente:

```ruby
# ❌ No se puede crear un partido entre un equipo y sí mismo
partido = Partido.new(
  seleccion_local_id: 1,
  seleccion_visitante_id: 1  # Error!
)
partido.save  # => false

# ✅ Goles deben ser números enteros no negativos
partido.registrar_resultado!(-1, 2)  # Error!

# ✅ Los estados solo pueden ser: programado, en_juego, finalizado
partido.estado = "cancelado"  # Error!

# ✅ Los tipos solo pueden ser: fase_grupos, eliminacion_directa
partido.tipo_partido = "otra"  # Error!
```

---

## 📋 Criterios de Desempate (FIFA)

Cuando dos o más equipos tienen los mismos puntos, se ordena por:

1. **Diferencia de goles** (goles a favor - goles en contra)
2. **Goles a favor** (total de goles anotados)
3. **Menor antigüedad** (implícito: si aún hay empate, se consulta con FIFA)

```ruby
tabla = Grupo.find_by(letra: "A").tabla_posiciones
# Automáticamente ordenada por: puntos DESC, diferencia DESC, goles_favor DESC
```

---

## 🔧 Métodos Útiles Adicionales

```ruby
seleccion = Seleccion.find_by(acronimo: "ARG")

# Todos los partidos
todos = seleccion.todos_los_partidos

# Solo como local
como_local = seleccion.partidos_como_local

# Solo como visitante
como_visitante = seleccion.partidos_como_visitante

# Cambiar a otro grupo
seleccion.cambiar_grupo(Grupo.find_by(letra: "B"))

# Reiniciar estadísticas a cero
seleccion.reiniciar_estadisticas!

# String legible
puts seleccion  # "ARG - Argentina (Grupo A)"
```

---

## 📊 Scopes Disponibles

```ruby
# Partidos
Partido.finalizados
Partido.programados
Partido.en_juego
Partido.fase_grupos
Partido.eliminacion_directa

# Selecciones
Seleccion.tabla_de_grupo(grupo_id)
Seleccion.mejores_terceros(8)

# Grupos
Grupo.ordenados
```

---

## 🚀 Ejemplo Completo Paso a Paso

```ruby
# Crear un partido y registrar su resultado
grupo = Grupo.find_by(letra: "A")

mexico = Seleccion.find_by(acronimo: "MEX")
japon = Seleccion.find_by(acronimo: "JAP")

# 1. Verificar estadísticas antes
puts "Antes:"
puts mexico.resumen_estadisticas
puts japon.resumen_estadisticas

# 2. Crear partido
partido = Partido.create!(
  numero_partido: 1,
  seleccion_local: mexico,
  seleccion_visitante: japon,
  grupo: grupo,
  tipo_partido: "fase_grupos"
)

# 3. Registrar resultado
partido.registrar_resultado!(2, 1)

# 4. Ver cambios automáticos
puts "\nDespués:"
puts mexico.resumen_estadisticas
puts japon.resumen_estadisticas

# 5. Ver tabla del grupo
puts "\nTabla del Grupo #{grupo.letra}:"
grupo.tabla_posiciones.each_with_index do |equipo, i|
  puts "#{i+1}. #{equipo.nombre} - #{equipo.puntos}pts"
end
```

---

## 📚 Referencias Rápidas

| Acción | Código |
|--------|--------|
| Obtener tabla de grupo | `Grupo.find(1).tabla_posiciones` |
| Registrar resultado | `partido.registrar_resultado!(2, 1)` |
| Recalcular estadísticas | `ActualizarEstadisticas Seleccion.new(sel).recalcular!` |
| Determinar clasificados | `DeterminarClasificados.obtener` |
| Ver posición de equipo | `seleccion.posicion_en_grupo` |
| Mejores terceros | `Seleccion.mejores_terceros(8)` |
| Resumen de selección | `seleccion.resumen_estadisticas` |

