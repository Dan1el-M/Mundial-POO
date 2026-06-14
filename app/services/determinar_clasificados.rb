# app/services/determinar_clasificados.rb

# Servicio encargado de determinar los 16 equipos que clasifican
# a la fase de eliminación directa en el formato de 48 equipos.
#
# Criterios:
#   1. Los 2 primeros de cada uno de los 12 grupos (24 equipos)
#   2. Los 8 mejores terceros lugares de todos los grupos (8 equipos)
#   Total: 32 equipos en 16avos de final
#
# Los cuartos lugares NO clasifican.

class DeterminarClasificados
  # Retorna un hash con todos los clasificados organizados
  def self.obtener
    new.obtener
  end

  def obtener
    {
      primeros: primeros_lugares,
      segundos: segundos_lugares,
      terceros_clasificados: mejores_terceros,
      total_clasificados: total_clasificados
    }
  end

  # Retorna el primer lugar de cada grupo (12 equipos)
  def primeros_lugares
    Grupo.ordenados.map { |grupo| grupo.tabla_posiciones.first }
         .compact
  end

  # Retorna el segundo lugar de cada grupo (12 equipos)
  def segundos_lugares
    Grupo.ordenados.map { |grupo| grupo.tabla_posiciones.offset(1).first }
         .compact
  end

  # Retorna los 8 mejores terceros lugares de todos los grupos
  # Ordenados por: puntos → diferencia goles → goles a favor
  def mejores_terceros
    terceros = Grupo.ordenados.map { |grupo| grupo.tercero }
                    .compact

    terceros.sort_by { |s| [-s.puntos, -s.diferencia_goles, -s.goles_favor] }
            .first(8)
  end

  # Retorna TODOS los clasificados (32 equipos) en un solo array ordenado
  def total_clasificados
    (primeros_lugares + segundos_lugares + mejores_terceros).uniq
  end

  # Verifica si la fase de grupos está completa
  # (todos los grupos tienen 4 equipos con estadísticas)
  def fase_grupos_completa?
    grupos = Grupo.all
    grupos.all?(&:completo?) && partidos_fase_grupos_finalizados?
  end

  # Retorna el número de partidos finalizados de fase de grupos
  def partidos_fase_grupos_finalizados
    Partido.fase_grupos.finalizados.count
  end

  # Total de partidos esperados en fase de grupos (12 grupos × 6 partidos/grupo)
  def total_partidos_fase_grupos
    12 * 6  # Cada grupo: 4 equipos × 3 partidos por equipo ÷ 2 = 6 partidos
  end

  # Progreso de la fase de grupos (0.0 a 1.0)
  def progreso_fase_grupos
    total = total_partidos_fase_grupos
    return 1.0 if total.zero?

    partidos_finalizados = partidos_fase_grupos_finalizados
    (partidos_finalizados.to_f / total).round(2)
  end

  # ──────────────────────────────────────────
  # Private
  # ──────────────────────────────────────────

  private

  # Verifica que todos los partidos de fase de grupos estén finalizados
  def partidos_fase_grupos_finalizados?
    Partido.fase_grupos.count == Partido.fase_grupos.finalizados.count
  end
end
