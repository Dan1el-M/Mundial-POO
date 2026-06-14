# app/services/calcular_ganador_partido.rb

# Servicio responsable de calcular el ganador de un partido.
# Cumple con SRP: solo maneja la lógica de ganador, no la persistencia.
class CalcularGanadorPartido
  def initialize(partido)
    @partido = partido
  end

  # Devuelve la selección ganadora según el marcador.
  # Esto solamente consulta el resultado.
  # No guarda cambios ni avanza equipos.
  def calcular_ganador
    return nil unless @partido.finalizado?

    # Si hay diferencia en goles normales, hay ganador directo
    if goles_regulares_definitivos?
      ganador_goles_regulares
    # En eliminación directa con empate, se decide por penales
    elsif @partido.eliminacion_directa?
      ganador_por_penales
    end
  end

  private

  # Verifica si hay un ganador definitivo en goles regulares
  def goles_regulares_definitivos?
    @partido.goles_local > @partido.goles_visitante ||
      @partido.goles_visitante > @partido.goles_local
  end

  # Devuelve el ganador según goles en tiempo regular
  def ganador_goles_regulares
    if @partido.goles_local > @partido.goles_visitante
      @partido.seleccion_local
    else
      @partido.seleccion_visitante
    end
  end

  # Determina el ganador según la tanda de penales.
  # Solo aplica en partidos de eliminación directa.
  def ganador_por_penales
    # Validar que ambas tandas de penales tengan datos
    return nil if @partido.goles_penales_local.nil? ||
                  @partido.goles_penales_visitante.nil?

    if @partido.goles_penales_local > @partido.goles_penales_visitante
      @partido.seleccion_local
    elsif @partido.goles_penales_visitante > @partido.goles_penales_local
      @partido.seleccion_visitante
    end
  end
end
