# app/controllers/campeones_controller.rb

# CampehonesController muestra el podio final del torneo:
# campeón, subcampeón y tercer lugar.
#
# Rutas:
#   GET  /campeones       → index (podio completo)
#   GET  /campeones/show  → show  (detalle del campeón)

class CampehonesController < ApplicationController
  before_action :verificar_torneo_completo, only: [:index, :show]

  # ──────────────────────────────────────────
  # GET /campeones
  # Muestra el podio final: campeón, subcampeón, tercer lugar
  # ──────────────────────────────────────────
  def index
    @torneo = Torneo.first || Torneo.create!(nombre: "Mundial 2026")

    @campeon = @torneo.campeon
    @subcampeon = @torneo.subcampeon
    @tercero = @torneo.tercero

    # Si el torneo está completo pero no tiene podio registrado, intentar determinarlo
    if @torneo.finalizado? && @campeon.nil?
      @torneo.determinar_podio!
      @torneo.reload
      @campeon = @torneo.campeon
      @subcampeon = @torneo.subcampeon
      @tercero = @torneo.tercero
    end

    # Información adicional
    @total_partidos = Partido.count
    @total_selecciones = Seleccion.count
  end

  # ──────────────────────────────────────────
  # GET /campeones/show
  # Muestra detalle del campeón y sus estadísticas
  # ──────────────────────────────────────────
  def show
    @torneo = Torneo.first
    @campeon = @torneo&.campeon

    unless @campeon
      redirect_to campeones_url, alert: "❌ El torneo aún no tiene campeón"
      return
    end

    # Estadísticas del campeón
    @estadisticas = @campeon.resumen_estadisticas
    @partidos = @campeon.partidos_finalizados
    @victorias = @campeon.victorias
    @goles_totales = @campeon.goles_favor
  end

  # ──────────────────────────────────────────
  # GET /campeones/podio
  # Muestra el podio de forma más visual
  # ──────────────────────────────────────────
  def podio
    @torneo = Torneo.first

    if @torneo.nil? || !@torneo.finalizado?
      redirect_to campeones_url, alert: "❌ El torneo aún no está completo"
      return
    end

    @campeon = @torneo.campeon      # 🥇
    @subcampeon = @torneo.subcampeon # 🥈
    @tercero = @torneo.tercero       # 🥉
  end

  # ──────────────────────────────────────────
  # GET /campeones/estadisticas
  # Muestra estadísticas del torneo completo
  # ──────────────────────────────────────────
  def estadisticas
    @torneo = Torneo.first

    # Estadísticas generales
    @total_partidos = Partido.count
    @total_goles = Partido.finalizados.sum("goles_local + goles_visitante")
    @promedio_goles_por_partido = @total_partidos.zero? ? 0 : 
                                   (@total_goles.to_f / @total_partidos).round(2)

    # Top goleadores
    @top_goleadores = Seleccion.all
                               .sort_by { |s| -s.goles_favor }
                               .first(10)

    # Top defensas
    @mejores_defensas = Seleccion.all
                                .sort_by { |s| [s.goles_contra, -s.puntos] }
                                .first(10)

    # Equipo con mejor diferencia
    @mejor_diferencia = Seleccion.all
                                .sort_by { |s| -s.diferencia_goles }
                                .first

    # Equipo con peor diferencia
    @peor_diferencia = Seleccion.all
                               .sort_by { |s| s.diferencia_goles }
                               .first
  end

  private

  # ──────────────────────────────────────────
  # Callbacks privados
  # ──────────────────────────────────────────

  # Verifica que el torneo esté completo
  def verificar_torneo_completo
    torneo = Torneo.first

    unless torneo&.finalizado?
      render :en_construccion
    end
  end
end
