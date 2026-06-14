# app/controllers/clasificados_controller.rb

# ClasificadosController determina y muestra los 32 equipos clasificados
# a la fase de eliminación directa.
#
# Criterios:
#   - 2 primeros de cada grupo (24 equipos)
#   - 8 mejores terceros lugares (8 equipos)
#
# Rutas:
#   GET  /clasificados     → index   (lista de clasificados)
#   GET  /clasificados/:id → show    (detalle de un equipo clasificado)

class ClasificadosController < ApplicationController
  before_action :set_clasificados_data

  # ──────────────────────────────────────────
  # GET /clasificados
  # Muestra todos los 32 equipos clasificados a la fase de eliminación
  # ──────────────────────────────────────────
  def index
    @fase_grupos_completa = DeterminarClasificados.new.fase_grupos_completa?

    unless @fase_grupos_completa
      @progreso = DeterminarClasificados.new.progreso_fase_grupos
      render :en_progreso
      return
    end

    @total_clasificados = @clasificados[:total_clasificados].count
  end

  # ──────────────────────────────────────────
  # GET /clasificados/:id
  # Muestra detalle de un equipo clasificado
  # ──────────────────────────────────────────
  def show
    @seleccion = Seleccion.find(params[:id])

    # Verificar si está en los clasificados
    clasificados_ids = @clasificados[:total_clasificados].map(&:id)
    unless clasificados_ids.include?(@seleccion.id)
      redirect_to clasificados_url, 
                  alert: "❌ #{@seleccion.nombre} no está clasificado"
      return
    end

    # Información detallada del equipo
    @grupo = @seleccion.grupo
    @tabla_grupo = @grupo.tabla_posiciones
    @posicion = @seleccion.posicion_en_grupo
    @clasificado_como = determinar_clasificacion(@seleccion)
    @partidos = @seleccion.partidos_finalizados
  end

  # ──────────────────────────────────────────
  # GET /clasificados/por-grupo
  # Muestra los clasificados organizados por grupo
  # ──────────────────────────────────────────
  def por_grupo
    @fase_grupos_completa = DeterminarClasificados.new.fase_grupos_completa?

    unless @fase_grupos_completa
      @progreso = DeterminarClasificados.new.progreso_fase_grupos
      render :en_progreso
      return
    end

    @clasificados_por_grupo = {}

    Grupo.ordenados.each do |grupo|
      clasificados = grupo.clasificados_directos
      @clasificados_por_grupo[grupo.letra] = {
        primero: clasificados.first,
        segundo: clasificados.second
      }
    end

    @mejores_terceros = @clasificados[:terceros_clasificados]
  end

  # ──────────────────────────────────────────
  # GET /clasificados/resumen
  # Resumen estadístico de clasificados
  # ──────────────────────────────────────────
  def resumen
    @fase_grupos_completa = DeterminarClasificados.new.fase_grupos_completa?

    unless @fase_grupos_completa
      render :en_progreso
      return
    end

    @total_clasificados = @clasificados[:total_clasificados].count
    @primeros_lugar = @clasificados[:primeros].count
    @segundos_lugar = @clasificados[:segundos].count
    @mejores_terceros = @clasificados[:terceros_clasificados].count

    # Top 5 equipos por puntos
    @top_equipos = @clasificados[:total_clasificados]
                    .sort_by { |s| [-s.puntos, -s.diferencia_goles, -s.goles_favor] }
                    .first(5)
  end

  private

  # ──────────────────────────────────────────
  # Callbacks privados
  # ──────────────────────────────────────────

  # Obtiene todos los clasificados desde el servicio
  def set_clasificados_data
    @clasificados = DeterminarClasificados.obtener
  end

  # ──────────────────────────────────────────
  # Helpers privados
  # ──────────────────────────────────────────

  # Determina cómo se clasificó el equipo (primero, segundo o tercero)
  def determinar_clasificacion(seleccion)
    posicion = seleccion.posicion_en_grupo

    case posicion
    when 1
      "🥇 Primer lugar del Grupo #{seleccion.grupo.letra}"
    when 2
      "🥈 Segundo lugar del Grupo #{seleccion.grupo.letra}"
    when 3
      "🥉 Tercer lugar - Mejor tercero"
    else
      "No clasificado"
    end
  end
end
