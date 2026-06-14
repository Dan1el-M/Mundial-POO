# == Schema Information
#
# Table name: partidos
#
#  id                        :integer  not null, primary key
#  numero_partido            :integer  not null
#  estado                    :string   default("programado"), not null
#  tipo_partido              :string   not null
#  seleccion_local_id        :integer  not null, foreign key
#  seleccion_visitante_id    :integer  not null, foreign key
#  ganador_id                :integer  foreign key
#  goles_local               :integer
#  goles_visitante           :integer
#  goles_penales_local       :integer
#  goles_penales_visitante   :integer
#  grupo_id                  :integer  foreign key
#  created_at                :datetime not null
#  updated_at                :datetime not null

class Partido < ApplicationRecord
  # ──────────────────────────────────────────
  # Asociaciones
  # ──────────────────────────────────────────

  belongs_to :torneo, optional: true
  belongs_to :seleccion_local,
             class_name: "Seleccion"
  belongs_to :seleccion_visitante,
             class_name: "Seleccion"
  belongs_to :ganador,
             class_name: "Seleccion",
             optional: true
  belongs_to :grupo, optional: true

  # ──────────────────────────────────────────
  # Validaciones
  # ──────────────────────────────────────────

  validates :numero_partido,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validates :estado,
            presence: true,
            inclusion: { in: %w[programado en_juego finalizado] }

  validates :tipo_partido,
            presence: true,
            inclusion: { in: %w[fase_grupos eliminacion_directa] }

  validates :goles_local,
            :goles_visitante,
            :goles_penales_local,
            :goles_penales_visitante,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            },
            allow_nil: true

  validate :selecciones_deben_ser_diferentes

  # ──────────────────────────────────────────
  # Callbacks
  # ──────────────────────────────────────────

  # Cuando el partido se finaliza, actualiza estadísticas de ambas selecciones
  after_save :actualizar_estadisticas_si_finalizado

  # ──────────────────────────────────────────
  # Scopes
  # ──────────────────────────────────────────

  scope :finalizados, -> { where(estado: "finalizado") }
  scope :programados, -> { where(estado: "programado") }
  scope :en_juego, -> { where(estado: "en_juego") }
  scope :fase_grupos, -> { where(tipo_partido: "fase_grupos") }
  scope :eliminacion_directa, -> { where(tipo_partido: "eliminacion_directa") }

  # ──────────────────────────────────────────
  # Consultas
  # ──────────────────────────────────────────

  # Devuelve true cuando el partido ya finalizó
  def finalizado?
    estado == "finalizado"
  end

  # Devuelve true cuando es un partido de fase de grupos
  def fase_grupos?
    tipo_partido == "fase_grupos"
  end

  # Devuelve true cuando es un partido eliminatorio
  def eliminacion_directa?
    tipo_partido == "eliminacion_directa"
  end

  # Devuelve true cuando los goles normales son iguales
  def empate?
    goles_local.present? &&
      goles_visitante.present? &&
      goles_local == goles_visitante
  end

  # ──────────────────────────────────────────
  # Métodos públicos: Registro de resultados
  # ──────────────────────────────────────────

  # Registra el resultado de un partido y lo marca como finalizado.
  # Actualiza automáticamente las estadísticas de ambas selecciones.
  #
  # En fase de grupos: solo usa goles_local y goles_visitante
  # En eliminación directa: además de goles regulares, puede incluir penales
  #
  # @param goles_local [Integer] goles del equipo local
  # @param goles_visitante [Integer] goles del equipo visitante
  # @param goles_penales_local [Integer, nil] goles de penales local (solo eliminación)
  # @param goles_penales_visitante [Integer, nil] goles de penales visitante (solo eliminación)
  def registrar_resultado!(goles_local, goles_visitante, 
                           goles_penales_local = nil, goles_penales_visitante = nil)
    self.goles_local = goles_local
    self.goles_visitante = goles_visitante
    self.goles_penales_local = goles_penales_local
    self.goles_penales_visitante = goles_penales_visitante
    self.estado = "finalizado"
    self.ganador = calcular_ganador
    
    save!
  end

  # Registra solo los goles de tiempo regular (sin penales)
  # Útil cuando aún no se sabe si habrá penales
  #
  # @param goles_local [Integer]
  # @param goles_visitante [Integer]
  def registrar_goles_regulares!(goles_local, goles_visitante)
    self.goles_local = goles_local
    self.goles_visitante = goles_visitante
    self.estado = "finalizado"
    save!
  end

  # Registra solo los goles de penales (después de empate en eliminación)
  #
  # @param goles_penales_local [Integer]
  # @param goles_penales_visitante [Integer]
  def registrar_penales!(goles_penales_local, goles_penales_visitante)
    self.goles_penales_local = goles_penales_local
    self.goles_penales_visitante = goles_penales_visitante
    self.ganador = calcular_ganador
    save!
  end

  # ──────────────────────────────────────────
  # Métodos públicos: Cálculo de ganador
  # ──────────────────────────────────────────

  # Devuelve la selección ganadora según el marcador.
  # Solo consulta el resultado sin guardar cambios.
  # Delega el cálculo al servicio CalcularGanadorPartido (SRP).
  #
  # @return [Seleccion, nil]
  def calcular_ganador
    calculator = CalcularGanadorPartido.new(self)
    calculator.calcular_ganador
  end

  # ──────────────────────────────────────────
  # Métodos públicos: Info del partido
  # ──────────────────────────────────────────

  # Retorna un hash con los datos del partido
  def resumen
    {
      numero: numero_partido,
      local: seleccion_local.nombre,
      visitante: seleccion_visitante.nombre,
      goles_local: goles_local,
      goles_visitante: goles_visitante,
      ganador: ganador&.nombre,
      estado: estado,
      tipo: tipo_partido
    }
  end

  # ──────────────────────────────────────────
  # Private
  # ──────────────────────────────────────────

  private

  # Callback: Cuando un partido se finaliza, recalcula las estadísticas
  # de ambas selecciones (solo en fase de grupos)
  def actualizar_estadisticas_si_finalizado
    return unless finalizado? && fase_grupos?

    # Recalcula todo desde cero para ambas selecciones
    [seleccion_local, seleccion_visitante].each do |seleccion|
      service = ActualizarEstadisticasSeleccion.new(seleccion)
      service.recalcular!
    end

    # Recalcula la tabla del grupo
    grupo.recalcular_todas_las_estadisticas! if grupo.present?
  end

  # Valida que las selecciones sean diferentes
  def selecciones_deben_ser_diferentes
    return if seleccion_local_id.blank? || seleccion_visitante_id.blank?
    return unless seleccion_local_id == seleccion_visitante_id

    errors.add(:seleccion_visitante,
               "debe ser diferente de la selección local")
  end
end