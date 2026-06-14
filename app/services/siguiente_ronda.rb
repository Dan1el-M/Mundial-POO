# app/services/siguiente_ronda.rb

# Servicio encargado de generar los partidos de la siguiente ronda
# en la fase de eliminación directa.
#
# Toma los ganadores de la ronda actual y crea los partidos de la
# ronda siguiente, respetando el bracket del torneo.
#
# Rangos de número de partido por etapa:
#   Dieciseisavos : 73–88   (16 partidos → 32 clasificados)
#   Octavos       : 89–96   (8 partidos)
#   Cuartos       : 97–100  (4 partidos)
#   Semifinal     : 101–102 (2 partidos)
#   Tercer lugar  : 103     (1 partido  — perdedores de semifinal)
#   Final         : 104     (1 partido  — ganadores de semifinal)
#
# Uso:
#   servicio = SiguienteRonda.new(torneo)
#   resultado = servicio.avanzar
#   # => { ok: true, etapa: "octavos", partidos_creados: [...] }
#   # => { ok: false, error: "..." }

class SiguienteRonda
  SIGUIENTE_ETAPA = {
    "dieciseisavos" => "octavos",
    "octavos"       => "cuartos",
    "cuartos"       => "semifinal",
    "semifinal"     => "final"
  }.freeze

  RANGOS = {
    "dieciseisavos" => (73..88),
    "octavos"       => (89..96),
    "cuartos"       => (97..100),
    "semifinal"     => (101..102),
    "tercer_lugar"  => (103..103),
    "final"         => (104..104)
  }.freeze

  PRIMER_NUMERO = {
    "octavos"      => 89,
    "cuartos"      => 97,
    "semifinal"    => 101,
    "tercer_lugar" => 103,
    "final"        => 104
  }.freeze

  def initialize(torneo)
    @torneo = torneo
  end

  def avanzar
    etapa_actual = determinar_etapa_actual

    return { ok: false, error: "No hay etapa de eliminación en curso." } if etapa_actual.nil?
    return { ok: false, error: "El torneo ya está finalizado." }         if etapa_actual == "final"

    partidos_etapa = partidos_de_etapa(etapa_actual)

    unless todos_finalizados?(partidos_etapa)
      pendientes = partidos_etapa.reject(&:finalizado?).count
      return {
        ok: false,
        error: "Faltan #{pendientes} partido(s) por finalizar en #{etapa_actual.humanize}."
      }
    end

    ganadores = obtener_ganadores(partidos_etapa)

    if etapa_actual == "semifinal"
      return generar_final_y_tercer_lugar(ganadores, partidos_etapa)
    end

    etapa_siguiente = SIGUIENTE_ETAPA[etapa_actual]
    return { ok: false, error: "No se encontró etapa siguiente para '#{etapa_actual}'." } if etapa_siguiente.nil?

    if partidos_de_etapa(etapa_siguiente).exists?
      return { ok: false, error: "Los partidos de #{etapa_siguiente.humanize} ya fueron generados." }
    end

    partidos_creados = generar_partidos_bracket(ganadores, etapa_siguiente)

    { ok: true, etapa: etapa_siguiente, partidos_creados: partidos_creados }
  end

  private

  def determinar_etapa_actual
    orden_etapas = %w[dieciseisavos octavos cuartos semifinal]

    etapa_en_curso = orden_etapas.find do |etapa|
      partidos = partidos_de_etapa(etapa)
      partidos.exists? && !todos_finalizados?(partidos)
    end

    etapa_en_curso || orden_etapas.reverse.find { |etapa| partidos_de_etapa(etapa).exists? }
  end

  def partidos_de_etapa(etapa)
    rango = RANGOS[etapa]
    return Partido.none if rango.nil?

    Partido.where(
      tipo_partido: "eliminacion_directa",
      numero_partido: rango
    ).order(:numero_partido)
  end

  def todos_finalizados?(partidos)
    partidos.all?(&:finalizado?)
  end

  def obtener_ganadores(partidos)
    partidos.map do |partido|
      partido.ganador || CalcularGanadorPartido.new(partido).calcular_ganador
    end.compact
  end

  def obtener_perdedores(partidos)
    partidos.map do |partido|
      ganador = partido.ganador || CalcularGanadorPartido.new(partido).calcular_ganador
      next nil if ganador.nil?

      partido.seleccion_local_id == ganador.id ? partido.seleccion_visitante : partido.seleccion_local
    end.compact
  end

  def generar_partidos_bracket(ganadores, etapa_siguiente)
    numero_inicial = PRIMER_NUMERO[etapa_siguiente]
    partidos_creados = []

    ganadores.each_slice(2).with_index do |(local, visitante), indice|
      next if local.nil? || visitante.nil?

      partido = Partido.create!(
        numero_partido:         numero_inicial + indice,
        tipo_partido:           "eliminacion_directa",
        estado:                 "programado",
        torneo_id:              @torneo.id,
        seleccion_local_id:     local.id,
        seleccion_visitante_id: visitante.id
      )

      partidos_creados << partido
    end

    partidos_creados
  end

  def generar_final_y_tercer_lugar(ganadores, partidos_semifinal)
    perdedores = obtener_perdedores(partidos_semifinal)

    partidos_creados = []

    if perdedores.length == 2
      tercer_lugar = Partido.find_or_initialize_by(numero_partido: 103)
      tercer_lugar.assign_attributes(
        tipo_partido:           "eliminacion_directa",
        estado:                 "programado",
        torneo_id:              @torneo.id,
        seleccion_local_id:     perdedores[0].id,
        seleccion_visitante_id: perdedores[1].id
      )
      tercer_lugar.save!
      partidos_creados << tercer_lugar
    else
      return { ok: false, error: "No se pudieron determinar los perdedores de semifinales." }
    end

    if ganadores.length == 2
      final = Partido.find_or_initialize_by(numero_partido: 104)
      final.assign_attributes(
        tipo_partido:           "eliminacion_directa",
        estado:                 "programado",
        torneo_id:              @torneo.id,
        seleccion_local_id:     ganadores[0].id,
        seleccion_visitante_id: ganadores[1].id
      )
      final.save!
      partidos_creados << final
    else
      return { ok: false, error: "No se pudieron determinar los ganadores de semifinales." }
    end

    { ok: true, etapa: "final_y_tercer_lugar", partidos_creados: partidos_creados }
  end
 
end