class Grupo < ApplicationRecord
  
  LETRAS = ("A".."L").to_a.freeze
  MAXIMO_EQUIPOS = 4

  has_many :equipos, dependent: :destroy
  has_many :partidos, dependent: :destroy

  validates :letra,
            presence: true,
            uniqueness: true,
            inclusion: { in: LETRAS }

  before_validation :normalizar_letra

  def posiciones
    equipos.order(
      puntos: :desc,
      diferencia_goles: :desc,
      goles_favor: :desc
    )
  end

  def clasificados_directos
    posiciones.limit(2)
  end

  def completo?
    equipos.count == MAXIMO_EQUIPOS
  end

  def tiene_espacio?
    equipos.count < MAXIMO_EQUIPOS
  end

  def self.ordenados
    order(:letra)
  end

  private

  def normalizar_letra
    self.letra = letra.to_s.strip.upcase
  end
end