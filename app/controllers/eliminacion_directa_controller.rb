# app/controllers/eliminacion_directa_controller.rb

# EliminacionDirectaController gestiona todos los partidos de la fase
# de eliminación directa: dieciseisavos, octavos, cuartos, semifinales,
# tercer lugar y final.
#
# Rutas:
#   GET  /eliminacion-directa              → index        (todos los partidos)
#   GET  /eliminacion-directa/:etapa       → show         (partidos de una etapa)
#   PATCH /eliminacion-directa/:id/resultado → registrar_resultado

class EliminacionDirectaController < ApplicationController
  before_action :set_etapa, only: [:show, :registrar_resultado]
  before_action :verificar_fase_grupos_completa, only: [:index, :show]

  # ──────────────────────────────────────────
  # GET /eliminacion-directa
  # Muestra un resumen de todas las etapas de eliminación directa
  # ──────────────────────────────────────────
  def index
    @etapas = {
      dieciseisavos: { nombre: "Dieciseisavos de Final", rango: (73..88) },
      octavos:       { nombre: "Octavos de Final", rango: (89..96) },
      cuartos:       { nombre: "Cuartos de Final", rango: (97..100) },
      semifinal:     { nombre: "Semifinales", rango: (101..102) },
      tercer_lugar:  { nombre: "Tercer Lugar", rango: (103..103) },
      final:         { nombre: "Final", rango: (104..104) }
    }

    @resumen_etapas = {}

    @etapas.each do |etapa_key, etapa_data|
      partidos = Partido.eliminacion_directa
                        .where(numero_partido: etapa_data[:rango])
                        .order(:numero_partido)
      
      @resumen_etapas[etapa_key] = {
        nombre: etapa_data[:nombre],
        total: partidos.count,
        finalizados: partidos.finalizados.count,
        pendientes: partidos.where(estado: %w[programado en_juego]).count,
        partidos: partidos
      }
    end

    # Progreso general
    @total_partidos = Partido.eliminacion_directa.count
    @partidos_finalizados = Partido.eliminacion_directa.finalizados.count
    @progreso = @total_partidos.zero? ? 0 : 
                (@partidos_finalizados.to_f / @total_partidos * 100).round(1)
  end

  # ──────────────────────────────────────────
  # GET /eliminacion-directa/:etapa
  # Muestra los partidos de una etapa específica
  # ──────────────────────────────────────────
  def show
    @etapa_nombre = etapa_nombre_legible(@etapa)
    @rango = rango_numeros_para(@etapa)
    
    @partidos = Partido.eliminacion_directa
                       .where(numero_partido: @rango)
                       .order(:numero_partido)

    @total = @partidos.count
    @finalizados = @partidos.finalizados.count
    @pendientes = @partidos.where(estado: %w[programado en_juego]).count
  end

  # ──────────────────────────────────────────
  # PATCH /eliminacion-directa/:id/resultado
  # Registra el resultado de un partido y actualiza el ganador
  # ──────────────────────────────────────────
  def registrar_resultado
    @partido = Partido.find(params[:id])

    # Validar que sea un partido de eliminación directa
    unless @partido.eliminacion_directa?
      redirect_to eliminacion_directa_url, 
                  alert: "❌ Este no es un partido de eliminación directa"
      return
    end

    # Procesar el resultado
    goles_local = params[:goles_local].to_i
    goles_visitante = params[:goles_visitante].to_i
    goles_penales_local = params[:goles_penales_local]&.to_i
    goles_penales_visitante = params[:goles_penales_visitante]&.to_i

    begin
      @partido.registrar_resultado!(
        goles_local,
        goles_visitante,
        goles_penales_local,
        goles_penales_visitante
      )

      ganador = @partido.ganador
      mensaje = "✅ Resultado registrado. Ganador: #{ganador&.nombre || 'Pendiente'}"

      redirect_to eliminacion_directa_url(etapa: params[:etapa]),
                  notice: mensaje
    rescue StandardError => e
      redirect_to eliminacion_directa_url(etapa: params[:etapa]),
                  alert: "❌ Error al registrar resultado: #{e.message}"
    end
  end

  private

  # ──────────────────────────────────────────
  # Callbacks privados
  # ──────────────────────────────────────────

  # Obtiene la etapa desde parámetros y valida
  def set_etapa
    @etapa = params[:etapa]&.to_sym
    
    etapas_validas = [:dieciseisavos, :octavos, :cuartos, :semifinal, :tercer_lugar, :final]
    
    unless etapas_validas.include?(@etapa)
      redirect_to eliminacion_directa_url, alert: "❌ Etapa inválida"
    end
  end

  # Verifica que la fase de grupos esté completa
  def verificar_fase_grupos_completa
    unless DeterminarClasificados.new.fase_grupos_completa?
      redirect_to clasificados_url, 
                  alert: "⚠️ La fase de grupos no está completa aún"
    end
  end

  # ──────────────────────────────────────────
  # Helpers privados
  # ──────────────────────────────────────────

  # Devuelve el nombre legible de una etapa
  def etapa_nombre_legible(etapa)
    {
      dieciseisavos: "Dieciseisavos de Final",
      octavos: "Octavos de Final",
      cuartos: "Cuartos de Final",
      semifinal: "Semifinales",
      tercer_lugar: "Tercer Lugar",
      final: "Final"
    }[etapa]
  end

  # Devuelve el rango de números de partidos para una etapa
  def rango_numeros_para(etapa)
    {
      dieciseisavos: (73..88),
      octavos: (89..96),
      cuartos: (97..100),
      semifinal: (101..102),
      tercer_lugar: (103..103),
      final: (104..104)
    }[etapa] || (0..0)
  end
end
