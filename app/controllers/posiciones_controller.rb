# app/controllers/posiciones_controller.rb

# PosicionesController muestra las tablas de posiciones de los grupos
# en fase de grupos.
#
# Rutas:
#   GET  /posiciones        → index   (todas las tablas)
#   GET  /posiciones/:id    → show    (tabla de un grupo)

class PosicionesController < ApplicationController
  # ──────────────────────────────────────────
  # GET /posiciones
  # Muestra todas las tablas de posiciones de los 12 grupos
  # ──────────────────────────────────────────
  def index
    @grupos = Grupo.ordenados
    @tablas = {}

    @grupos.each do |grupo|
      @tablas[grupo.letra] = grupo.tabla_posiciones
    end

    # Información general
    @partidos_totales = Partido.fase_grupos.count
    @partidos_finalizados = Partido.fase_grupos.finalizados.count
    @progreso = @partidos_totales.zero? ? 0 : 
                (@partidos_finalizados.to_f / @partidos_totales * 100).round(1)
  end

  # ──────────────────────────────────────────
  # GET /posiciones/:id
  # Muestra la tabla de posiciones de un grupo específico
  # ──────────────────────────────────────────
  def show
    @grupo = Grupo.find_by(letra: params[:id].upcase)

    unless @grupo
      redirect_to posiciones_url, alert: "❌ Grupo no encontrado"
      return
    end

    @tabla_posiciones = @grupo.tabla_posiciones
    @selecciones = @grupo.selecciones

    # Detalles de partidos del grupo
    @partidos = @grupo.partidos.order(:numero_partido)
    @partidos_finalizados = @grupo.partidos.finalizados.count
    @partidos_pendientes = @grupo.partidos.where(estado: %w[programado en_juego]).count
  end

  # ──────────────────────────────────────────
  # GET /posiciones/general
  # Muestra un resumen general de todas las tablas
  # ──────────────────────────────────────────
  def general
    @grupos = Grupo.ordenados
    @tablas_resumen = {}

    @grupos.each do |grupo|
      tabla = grupo.tabla_posiciones
      @tablas_resumen[grupo.letra] = {
        primero: tabla.first,
        segundo: tabla.second,
        tercero: tabla.third,
        cuarto: tabla.fourth
      }
    end

    # Estadísticas generales
    @total_selecciones = Seleccion.count
    @total_partidos = Partido.fase_grupos.count
    @partidos_finalizados = Partido.fase_grupos.finalizados.count
    @partidos_pendientes = Partido.fase_grupos.where(estado: %w[programado en_juego]).count
  end
end
