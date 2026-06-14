class Seleccion < ApplicationRecord

  # ──────────────────────────────────────────
  # Asociaciones
  # ──────────────────────────────────────────
  belongs_to :grupo

  has_many :partidos_como_local,
           class_name:  "Partido",
           foreign_key: :seleccion_local_id,
           dependent:   :restrict_with_error,
           inverse_of: :seleccion_local

  has_many :partidos_como_visitante,
           class_name:  "Partido",
           foreign_key: :seleccion_visitante_id,
           dependent:   :restrict_with_error,
           inverse_of: :seleccion_visitante

  # ──────────────────────────────────────────
  # Validaciones
  # ──────────────────────────────────────────

  validates :nombre,
            presence:   true,
            uniqueness: { case_sensitive: false },
            length:     { maximum: 100 }

  validates :acronimo,
            presence:   true,
            uniqueness: { case_sensitive: false },
            length:     { maximum: 3 },
            format:     { with: /\A[A-Z]{2,3}\z/, message: "debe ser 2 o 3 letras mayúsculas" }

  validates :puntos,
            :goles_favor,
            :goles_contra,
            :diferencia_goles,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }

  validates :grupo, presence: true

  # ──────────────────────────────────────────
  # Callbacks
  # ──────────────────────────────────────────

  # Genera el acrónimo automáticamente si no fue asignado manualmente
  before_validation :generar_acronimo, on: %i[create update]

  before_save :calcular_diferencia_goles

  # ──────────────────────────────────────────
  # Scopes
  # ──────────────────────────────────────────

  # Todas las selecciones de un grupo ordenadas por tabla FIFA
  # (puntos → diferencia de goles → goles a favor)
  scope :tabla_de_grupo, ->(grupo_id) {
    where(grupo_id: grupo_id)
      .order(puntos: :desc, diferencia_goles: :desc, goles_favor: :desc)
  }

  #scope :clasificados, -> { joins(:grupo).where(grupos: { clasificado: true }) }

  # ──────────────────────────────────────────
  # Métodos públicos 
  # ──────────────────────────────────────────

  def registrar_resultado_grupo(goles_hechos, goles_recibidos)
    self.goles_favor  += goles_hechos
    self.goles_contra += goles_recibidos

    if goles_hechos > goles_recibidos
      self.puntos += 3       # victoria
    elsif goles_hechos == goles_recibidos
      self.puntos += 1       # empate
    end
    # derrota: no suma puntos

    save!
  end

  def reiniciar_estadisticas!
    update!(
      puntos:           0,
      goles_favor:      0,
      goles_contra:     0,
      diferencia_goles: 0
    )
  end

  def todos_los_partidos
    Partido.where(
      "seleccion_local_id = :id OR seleccion_visitante_id = :id",
      id: id
    )
  end

  def posicion_en_grupo
    Seleccion.tabla_de_grupo(grupo_id).pluck(:id).index(id).to_i + 1
  end

  # Verifica si esta selección clasificó a la fase de eliminación directa
  # (primer o segundo lugar de su grupo)
  def clasificado_directo?
    posicion_en_grupo <= 2
  end

  # Verifica si es el tercer lugar (podría clasificar como mejor tercero)
  def es_tercero?
    posicion_en_grupo == 3
  end

  # Retorna todos los partidos de esta selección en orden cronológico
  def partidos_ordenados
    todos_los_partidos.order(created_at: :asc)
  end

  # Retorna los partidos finalizados (jugados)
  def partidos_finalizados
    todos_los_partidos.where(estado: "finalizado").order(created_at: :asc)
  end

  # Retorna los partidos pendientes (no jugados)
  def partidos_pendientes
    todos_los_partidos.where(estado: %w[programado en_juego])
  end

  # Cuenta el número de victorias de esta selección
  def victorias
    partidos_finalizados.count do |partido|
      es_local = partido.seleccion_local_id == id
      es_local ? (partido.goles_local > partido.goles_visitante) :
               (partido.goles_visitante > partido.goles_local)
    end
  end

  # Cuenta el número de empates de esta selección
  def empates
    partidos_finalizados.count do |partido|
      partido.goles_local == partido.goles_visitante
    end
  end

  # Cuenta el número de derrotas de esta selección
  def derrotas
    partidos_finalizados.count - victorias - empates
  end

  # Representación legible para logs y vistas
  def to_s
    "#{acronimo} - #{nombre} (Grupo #{grupo&.letra})"
  end

  # Hash con resumen de estadísticas
  def resumen_estadisticas
    {
      nombre: nombre,
      acronimo: acronimo,
      grupo: grupo&.letra,
      posicion: posicion_en_grupo,
      puntos: puntos,
      victorias: victorias,
      empates: empates,
      derrotas: derrotas,
      goles_favor: goles_favor,
      goles_contra: goles_contra,
      diferencia_goles: diferencia_goles,
      partidos_jugados: partidos_finalizados.count
    }
  end

  # ──────────────────────────────────────────
  # Métodos de clase
  # ──────────────────────────────────────────

  def self.mejores_terceros(cantidad = 8)
    Grupo.all.map { |g| tabla_de_grupo(g.id).offset(2).first }
         .compact
         .sort_by { |s| [-s.puntos, -s.diferencia_goles, -s.goles_favor] }
         .first(cantidad)
  end

  private

  # ──────────────────────────────────────────
  # Callbacks privados
  # ──────────────────────────────────────────
  def generar_acronimo
    return if acronimo.present?

    self.acronimo = construir_acronimo(nombre)
  end


  def construir_acronimo(nombre_pais)
    return "" if nombre_pais.blank?

    # Palabras que no aportan al acrónimo (artículos y preposiciones comunes)
    palabras_vacias = %w[de del la las los el y e the of and]

    # Separa, normaliza y filtra las palabras del nombre
    palabras_relevantes = nombre_pais
      .split
      .reject { |palabra| palabras_vacias.include?(palabra.downcase) }

    base = if palabras_relevantes.length >= 2
             palabras_relevantes.first(3).map { |p| p[0] }.join.upcase
           else
             
             nombre_pais.gsub(/\s+/, "").first(3).upcase
           end

    resolver_colision(base)
  end

  def resolver_colision(base)
    candidato = base
    contador  = 2

    # Excluye el registro actual para que una edición no colisione consigo mismo
    scope = Seleccion.where.not(id: id.presence || 0)

    while scope.exists?(acronimo: candidato)
      # Recorta la base a 2 letras para que quepa el número en 3 caracteres
      candidato = "#{base.first(2)}#{contador}"
      contador += 1
    end

    candidato
  end

  def calcular_diferencia_goles
    self.diferencia_goles = goles_favor - goles_contra
  end
end