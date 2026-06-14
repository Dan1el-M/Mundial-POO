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
  # Recibe un objeto Grupo.
  def tabla_grupo(grupo)
    Seleccion.tabla_de_grupo(grupo.id)
  end

  # Los dos primeros de cada uno de los 12 grupos → 24 selecciones.
  def clasificados_por_primeros_y_segundos
    grupos.flat_map(&:clasificados_directos)
  end

  # Los ocho mejores terceros lugares entre todos los grupos.
  def mejores_terceros
    Seleccion.mejores_terceros(8)
  end

  # Las 32 selecciones clasificadas a la fase de eliminación directa.
  def selecciones_clasificadas
    clasificados_por_primeros_y_segundos + mejores_terceros
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

  def partidos_de_fase_grupos
    partidos.where(tipo_partido: "fase_grupos")
  end

  def partidos_de_eliminacion
    partidos.where(tipo_partido: "eliminacion_directa")
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

  # True si ningún partido de la etapa actual sigue pendiente.
  def todos_los_partidos_finalizados?
    partidos_en_etapa_actual.all?(&:finalizado?)
  end

  # Partidos que corresponden a la etapa actual.
  # En fase de grupos filtra por tipo_partido.
  # En eliminación directa filtra por numero_partido según el rango de la ronda.
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
  #   Partidos  1-48 → fase de grupos (48 equipos × 3 partidos / 2 = 72? No:
  #     12 grupos × 6 partidos c/u = 72 partidos de grupos)
  #   Partidos 73-88 → dieciseisavos (16 partidos)
  #   Partidos 89-96 → octavos       ( 8 partidos)
  #   Partidos 97-100→ cuartos       ( 4 partidos)
  #   Partidos 101-102→ semifinales  ( 2 partidos)
  #   Partido  103   → tercer lugar  ( 1 partido )
  #   Partido  104   → final         ( 1 partido )
  #
  # NOTA: ajustar estos rangos con el compañero que cree los partidos.
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
  def perdedor_de(partido)
    return nil if partido.ganador_id.blank?

    if partido.ganador_id == partido.seleccion_local_id
      partido.seleccion_visitante
    else
      partido.seleccion_local
    end
  end

  def numero_partido_final
    104
  end

  def numero_partido_tercer_lugar
    103
  end
end