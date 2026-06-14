# app/services/actualizar_estadisticas_seleccion.rb

# Servicio encargado de recalcular TODAS las estadísticas de una selección
# basándose en todos sus partidos finalizados.
#
# Cumple con SRP: solo recalcula estadísticas, no guarda (excepto al final).
# Es útil cuando:
#   - Se necesita sincronizar estadísticas después de cambios en partidos
#   - Se corrigen datos incorrectos
#   - Se reinicia el sistema
#
# Ejemplo:
#   service = ActualizarEstadisticasSeleccion.new(seleccion)
#   service.recalcular!  # Actualiza y guarda la selección
class ActualizarEstadisticasSeleccion
  def initialize(seleccion)
    @seleccion = seleccion
  end

  # Recalcula todas las estadísticas desde cero y guarda cambios
  def recalcular!
    calcular_estadisticas
    @seleccion.save!
  end

  # Recalcula pero retorna un hash sin guardar cambios (útil para validación)
  def calcular
    calcular_estadisticas
    estadisticas_actuales
  end

  private

  # Realiza el cálculo de todos los valores
  def calcular_estadisticas
    # Reinicia todo a cero
    @seleccion.puntos           = 0
    @seleccion.goles_favor      = 0
    @seleccion.goles_contra     = 0
    @seleccion.diferencia_goles = 0

    # Obtiene solo partidos finalizados (tanto fase grupos como eliminación)
    partidos_finalizados.each { |partido| procesar_partido(partido) }

    # Recalcula la diferencia
    @seleccion.diferencia_goles = @seleccion.goles_favor - @seleccion.goles_contra
  end

  # Obtiene todos los partidos de esta selección que ya finalizaron
  def partidos_finalizados
    Partido.where(estado: "finalizado")
           .where("seleccion_local_id = ? OR seleccion_visitante_id = ?",
                  @seleccion.id, @seleccion.id)
           .order(created_at: :asc)
  end

  # Procesa un partido individual y actualiza puntos y goles
  #
  # En fase de grupos: suma 3 puntos por victoria, 1 por empate
  # En eliminación: suma 3 puntos si ganó, 0 si perdió
  # (en eliminación no hay empates porque se resuelven con penales)
  def procesar_partido(partido)
    # Determina si esta selección fue local o visitante
    es_local = partido.seleccion_local_id == @seleccion.id

    # Obtiene los goles a favor y en contra
    if es_local
      goles_hechos    = partido.goles_local
      goles_recibidos = partido.goles_visitante
    else
      goles_hechos    = partido.goles_visitante
      goles_recibidos = partido.goles_local
    end

    # Acumula los goles
    @seleccion.goles_favor  += goles_hechos
    @seleccion.goles_contra += goles_recibidos

    # Suma puntos según el resultado
    case
    when goles_hechos > goles_recibidos
      @seleccion.puntos += 3  # Victoria
    when goles_hechos == goles_recibidos
      @seleccion.puntos += 1  # Empate (solo en fase grupos)
    # else: derrota, no suma puntos
    end
  end

  # Retorna un hash con las estadísticas actuales
  def estadisticas_actuales
    {
      puntos: @seleccion.puntos,
      goles_favor: @seleccion.goles_favor,
      goles_contra: @seleccion.goles_contra,
      diferencia_goles: @seleccion.diferencia_goles
    }
  end
end
