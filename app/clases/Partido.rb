# app/models/partido.rb

# esto creo que es lo que decia cesaer de que todos heredaban de algho, y es que todos los modelos heredan de ApplicationRecord, que a su vez hereda de ActiveRecord::Base
class Partido < ApplicationRecord
  # ==========================================================
  # Atributos:
  # ==========================================================
   # No necesitas declarar explícitamente:
  # - numero_partido
  # - estado
  # - tipo_partido
  # - goles_local
  # - goles_visitante
  # - goles_penales_local
  # - goles_penales_visitante
  #se jala de la DB, no es necesario declararlos aquí. revisar despues la tabla bien
  belongs_to :torneo, optional: true  # El partido pertenece a un torneo.
  belongs_to :grupo, optional: true  #grupos opcionales, partidos finales no pertenecen a un grupo
  belongs_to :seleccion_local,
             class_name: "Seleccion" #recibe un objeto seleccion
  belongs_to :seleccion_visitante,
             class_name: "Seleccion" #recibe un objeto seleccion
  belongs_to :ganador,
             class_name: "Seleccion",
             optional: true # al crease queda vacio, se llena al finalizar el partido con  un put

  # ==========================================================
  # VALIDACIONES
  # ==========================================================

  # El número del partido debe existir y ser mayor que cero.
  validates :numero_partido, #de donde sacamos el numero del partido? no es ninguno de los atributos definidos arriba
            presence: true, #esto que es?
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  # Solo permite los estados definidos por el sistema.
  validates :estado, #esteb atributo dodne esta y por que no en la parte de arriba?
            presence: true,
            inclusion: {
              in: %w[programado en_juego finalizado]
            }

  # Solo permite los tipos definidos.
  validates :tipo_partido, #solo existen estas 2? donde se pide este dato? no es ninguno de los atributos definidos arriba
            presence: true,
            inclusion: {
              in: %w[fase_grupos eliminacion_directa]
            }

  # Los goles deben ser enteros positivos o cero.
  # Pueden estar vacíos antes de jugarse el partido.
  validates :goles_local, #donde se obtienen estos datos? no deberian de ser un atributo de la clase?
            :goles_visitante,
            :goles_penales_local,
            :goles_penales_visitante,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            },
            allow_nil: true

  # Ejecuta una validación propia de este modelo.
  validate :selecciones_deben_ser_diferentes

  # Devuelve true cuando el partido ya finalizó.
  def finalizado? #De donde se obtiene el estado del partido? de la tabla de la DB
    estado == "finalizado"
  end

  # Devuelve true cuando es un partido de fase de grupos.
  def fase_grupos? #De donde se obtiene el tipo del partido? e la tabla de la DB
    tipo_partido == "fase_grupos"
  end

  # Devuelve true cuando es un partido eliminatorio.
  def eliminacion_directa? #De donde se obtiene el tipo del partido? e la tabla de la DB
    tipo_partido == "eliminacion_directa"
  end

  # Devuelve true cuando los goles normales son iguales.
  def empate? #goles_local y goles_visitante no son atributos definidos arriba, de donde se obtienen estos datos?e la tabla de la DB
    goles_local.present? &&
      goles_visitante.present? &&
      goles_local == goles_visitante
  end

  # Devuelve la selección ganadora según el marcador.
  #
  # Este método solamente consulta el resultado.
  # No guarda cambios ni avanza equipos.
  # Delega el cálculo al servicio CalcularGanadorPartido (SRP).
  def calcular_ganador
    calculator = CalcularGanadorPartido.new(self)
    calculator.calcular_ganador
  end

  private

  # Evita que una selección juegue contra sí misma.
  def selecciones_deben_ser_diferentes
    return if seleccion_local_id.blank? ||
              seleccion_visitante_id.blank?

    return unless seleccion_local_id == seleccion_visitante_id

    errors.add(
      :seleccion_visitante,
      "debe ser diferente de la selección local"
    )
  end
end