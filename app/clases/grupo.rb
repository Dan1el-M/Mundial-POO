# == Schema Information
#
# Table name: grupos
#
#  id          :integer  not null, primary key
#  letra       :string   not null
#  created_at  :datetime not null
#  updated_at  :datetime not null

class Grupo < ApplicationRecord
  LETRAS = ("A".."L").to_a.freeze
  MAXIMO_EQUIPOS = 4

  # ──────────────────────────────────────────
  # Asociaciones
  # ──────────────────────────────────────────

  has_many :selecciones, dependent: :destroy
  has_many :partidos, dependent: :destroy

  # ──────────────────────────────────────────
  # Validaciones
  # ──────────────────────────────────────────

  validates :letra,
            presence: true,
            uniqueness: true,
            inclusion: { in: LETRAS }

  # ──────────────────────────────────────────
  # Callbacks
  # ──────────────────────────────────────────

  before_validation :normalizar_letra

  # ──────────────────────────────────────────
  # Scopes
  # ──────────────────────────────────────────

  scope :ordenados, -> { order(:letra) }

  # ──────────────────────────────────────────
  # Métodos públicos: Tabla de posiciones
  # ──────────────────────────────────────────

  # Retorna la tabla de posiciones actual del grupo,
  # ordenada por criterios FIFA (puntos → diferencia → goles favor)
  #
  # @return [Array<Seleccion>] selecciones ordenadas
  def tabla_posiciones
    selecciones.order(
      puntos: :desc,
      diferencia_goles: :desc,
      goles_favor: :desc
    )
  end

  # Alias más legible para tabla_posiciones
  def posiciones
    tabla_posiciones
  end

  # Retorna los 2 primeros clasificados del grupo (directo a 16avos)
  #
  # @return [Array<Seleccion>] los primero y segundo lugar
  def clasificados_directos
    tabla_posiciones.limit(2)
  end

  # Retorna el tercer lugar del grupo (podría clasificar como mejor tercero)
  #
  # @return [Seleccion, nil] la selección en tercer lugar
  def tercero
    tabla_posiciones.offset(2).first
  end

  # Retorna el cuarto lugar del grupo (último, no clasifica)
  #
  # @return [Seleccion, nil] la selección en cuarto lugar
  def cuarto
    tabla_posiciones.offset(3).first
  end

  # ──────────────────────────────────────────
  # Métodos públicos: Control de grupo
  # ──────────────────────────────────────────

  # Verifica si el grupo tiene los 4 equipos completados
  #
  # @return [Boolean]
  def completo?
    selecciones.count == MAXIMO_EQUIPOS
  end

  # Verifica si hay espacio para agregar más equipos
  #
  # @return [Boolean]
  def tiene_espacio?
    selecciones.count < MAXIMO_EQUIPOS
  end

  # Recalcula las estadísticas de TODAS las selecciones del grupo
  # basándose en todos los partidos finalizados.
  #
  # Útil cuando se necesita sincronizar después de cambios en partidos.
  def recalcular_todas_las_estadisticas!
    selecciones.each do |seleccion|
      service = ActualizarEstadisticasSeleccion.new(seleccion)
      service.recalcular!
    end
  end

  # ──────────────────────────────────────────
  # Representación
  # ──────────────────────────────────────────

  def to_s
    "Grupo #{letra}"
  end

  # ──────────────────────────────────────────
  # Private
  # ──────────────────────────────────────────

  private

  def normalizar_letra
    self.letra = letra.to_s.strip.upcase
  end
end