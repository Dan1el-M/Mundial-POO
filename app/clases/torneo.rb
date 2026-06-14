# app/models/torneo.rb

class Torneo < ApplicationRecord

  # ──────────────────────────────────────────
  # Constantes
  # ──────────────────────────────────────────

  # Flujo de etapas en orden cronológico.
  ETAPAS = %w[
    fase_grupos
    dieciseisavos
    octavos
    cuartos
    semifinal
    tercer_lugar
    final
  ].freeze

  TOTAL_GRUPOS      = 12
  EQUIPOS_POR_GRUPO = 4
  TOTAL_SELECCIONES = 48

  # ──────────────────────────────────────────
  # Asociaciones
  # ──────────────────────────────────────────

  has_many :grupos,   dependent: :destroy
  has_many :partidos, dependent: :destroy

  # FK manuales — opcionales hasta que el torneo concluya.
  belongs_to :campeon,    class_name: "Seleccion", optional: true,
                          foreign_key: :campeon_id
  belongs_to :subcampeon, class_name: "Seleccion", optional: true,
                          foreign_key: :subcampeon_id
  belongs_to :tercero,    class_name: "Seleccion", optional: true,
                          foreign_key: :tercero_id

  # ──────────────────────────────────────────
  # Validaciones
  # ──────────────────────────────────────────

  validates :nombre,
            presence:   true,
            uniqueness: { case_sensitive: false }

  validates :etapa_actual,
            presence:  true,
            inclusion: { in: ETAPAS }

  # ──────────────────────────────────────────
  # Callbacks
  # ──────────────────────────────────────────

  before_validation :asignar_etapa_inicial, on: :create

  # ──────────────────────────────────────────
  # Consultas de estado
  # ──────────────────────────────────────────

  # Devuelve true si el torneo está en la fase de grupos.
  def en_fase_grupos?
    etapa_actual == "fase_grupos"
  end

  # Devuelve true si el torneo ya tiene un campeón definido.
  def finalizado?
    campeon_id.present?
  end

  # ──────────────────────────────────────────
  # Métodos de fase de grupos
  # ──────────────────────────────────────────

  # Tabla de posiciones de un grupo, ordenada por criterios FIFA.
  # Delega al modelo Grupo para obtener la tabla.
  #
  # @param grupo [Grupo] objeto del grupo
  # @return [Array<Seleccion>] selecciones ordenadas
  def tabla_grupo(grupo)
    grupo.tabla_posiciones
  end

  # Las 32 selecciones clasificadas a la fase de eliminación directa.
  # Delega al servicio DeterminarClasificados para consistencia.
  #
  # @return [Array<Seleccion>] 32 equipos clasificados
  def selecciones_clasificadas
    DeterminarClasificados.obtener[:total_clasificados]
  end

  # Los 24 clasificados (primeros + segundos de cada grupo).
  # Conveniencia para acceso directo.
  #
  # @return [Array<Seleccion>] 24 equipos
  def clasificados_por_primeros_y_segundos
    clasificados = DeterminarClasificados.obtener
    clasificados[:primeros] + clasificados[:segundos]
  end

  # Los 8 mejores terceros lugares entre todos los grupos.
  # Conveniencia para acceso directo.
  #
  # @return [Array<Seleccion>] hasta 8 equipos
  def mejores_terceros
    DeterminarClasificados.obtener[:terceros_clasificados]
  end

  # Verifica si la fase de grupos está lista para pasar a eliminación directa.
  # Usa el servicio para verificación consistente.
  #
  # @return [Boolean]
  def fase_grupos_lista?
    DeterminarClasificados.new.fase_grupos_completa?
  end

  # ──────────────────────────────────────────
  # Avance de etapas
  # ──────────────────────────────────────────

  # Avanza a la siguiente etapa si todos los partidos actuales finalizaron.
  # Devuelve true si se avanzó, false si no.
  def avanzar_etapa_si_es_posible
    return false unless todos_los_partidos_finalizados?

    siguiente = etapa_siguiente
    return false if siguiente.nil?

    update!(etapa_actual: siguiente)
    true
  end

  # Establece campeón, subcampeón y tercer lugar al concluir el torneo.
  # Solo actúa cuando los partidos de final y tercer_lugar están finalizados.
  def determinar_podio!
    partido_final        = partidos_de_eliminacion
                           .find_by(numero_partido: numero_partido_final)
    partido_tercer_lugar = partidos_de_eliminacion
                           .find_by(numero_partido: numero_partido_tercer_lugar)

    return unless partido_final&.finalizado? && partido_tercer_lugar&.finalizado?

    update!(
      campeon_id:    partido_final.ganador_id,
      subcampeon_id: perdedor_de(partido_final)&.id,
      tercero_id:    partido_tercer_lugar.ganador_id
    )
  end

  # ──────────────────────────────────────────
  # Consultas de partidos
  # ──────────────────────────────────────────

  # Partidos de fase de grupos (usualmente 72 para 48 equipos)
  #
  # @return [ActiveRecord::Relation]
  def partidos_de_fase_grupos
    partidos.fase_grupos
  end

  # Partidos de eliminación directa (dieciseisavos a final)
  #
  # @return [ActiveRecord::Relation]
  def partidos_de_eliminacion
    partidos.eliminacion_directa
  end

  # Partidos pendientes en la etapa actual
  #
  # @return [ActiveRecord::Relation]
  def partidos_pendientes
    partidos_en_etapa_actual.where(estado: %w[programado en_juego])
  end

  # Partidos finalizados en la etapa actual
  #
  # @return [ActiveRecord::Relation]
  def partidos_finalizados_en_etapa
    partidos_en_etapa_actual.finalizados
  end

  # ──────────────────────────────────────────
  # Representación
  # ──────────────────────────────────────────

  def to_s
    "#{nombre} — Etapa actual: #{etapa_actual}"
  end

  private

  # ──────────────────────────────────────────
  # Callbacks privados
  # ──────────────────────────────────────────

  def asignar_etapa_inicial
    self.etapa_actual ||= "fase_grupos"
  end

  # ──────────────────────────────────────────
  # Auxiliares privados
  # ──────────────────────────────────────────

  # Verifica que todos los partidos de la etapa actual estén finalizados.
  # En fase de grupos verifica TODOS los partidos de grupos.
  # En eliminación verifica solo los de esa ronda.
  def todos_los_partidos_finalizados?
    pendientes = partidos_pendientes.count
    pendientes.zero?
  end

  # Partidos que corresponden a la etapa actual.
  # En fase de grupos: todos los partidos de fase_grupos.
  # En eliminación: solo los del rango de números de esa ronda.
  def partidos_en_etapa_actual
    if etapa_actual == "fase_grupos"
      partidos_de_fase_grupos
    else
      partidos_de_eliminacion.where(
        numero_partido: rango_numeros_para(etapa_actual)
      )
    end
  end

  # Rango de números de partido por ronda de eliminación directa.
  # El Mundial 2026 tiene 104 partidos en total:
  #   Partidos  1-72  → fase de grupos    (12 grupos × 6 partidos)
  #   Partidos 73-88  → dieciseisavos    (16 partidos)
  #   Partidos 89-96  → octavos           ( 8 partidos)
  #   Partidos 97-100 → cuartos           ( 4 partidos)
  #   Partidos 101-102→ semifinales       ( 2 partidos)
  #   Partido  103    → tercer lugar      ( 1 partido )
  #   Partido  104    → final             ( 1 partido )
  #
  # NOTA: Coordinar con el compañero que genera los partidos.
  def rango_numeros_para(etapa)
    {
      "dieciseisavos" => (73..88),
      "octavos"       => (89..96),
      "cuartos"       => (97..100),
      "semifinal"     => (101..102),
      "tercer_lugar"  => (103..103),
      "final"         => (104..104)
    }.fetch(etapa, (0..0))
  end

  # Siguiente etapa en el flujo. Nil si ya se llegó a la final.
  def etapa_siguiente
    indice = ETAPAS.index(etapa_actual)
    return nil if indice.nil? || indice == ETAPAS.length - 1

    ETAPAS[indice + 1]
  end

  # Selección que perdió el partido (la que no es el ganador).
  # Usado para determinar subcampeón.
  def perdedor_de(partido)
    return nil if partido.ganador_id.blank?

    if partido.ganador_id == partido.seleccion_local_id
      partido.seleccion_visitante
    else
      partido.seleccion_local
    end
  end

  # Número de partido para la final (104).
  def numero_partido_final
    104
  end

  # Número de partido para tercer lugar (103).
  def numero_partido_tercer_lugar
    103
  end
end