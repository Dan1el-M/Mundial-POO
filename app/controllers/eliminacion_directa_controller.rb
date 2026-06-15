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
  before_action :set_etapa, only: [:show]
  before_action :verificar_fase_grupos_completa, only: [:show, :fase_eliminatoria]

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

    @fase_grupos_completa = DeterminarClasificados.new.fase_grupos_completa?
    @partidos_fase_grupos = Partido.fase_grupos
    @partidos_fase_grupos_totales = @partidos_fase_grupos.count
    @partidos_fase_grupos_finalizados = @partidos_fase_grupos.finalizados.count
    @progreso_fase_grupos = @partidos_fase_grupos_totales.zero? ? 0 :
                            (@partidos_fase_grupos_finalizados.to_f / @partidos_fase_grupos_totales * 100).round(1)

    @grupos_info = Grupo.ordenados.each_with_object({}) do |grupo, hash|
      partidos = grupo.partidos.fase_grupos
      finalizados = partidos.finalizados.count
      completado = partidos.count == 6 && finalizados == 6

      hash[grupo.letra] = {
        status: completado ? "Finalizado" : "Pendiente"
      }
    end

    render template: "fase_de_grupos/validacion_fase_eliminatoria"
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
      @partido.torneo&.determinar_podio!

      mensaje = "Resultado registrado. Ganador: #{ganador&.nombre || 'Pendiente'}"
      mensaje += ". Podio definido." if @partido.torneo&.finalizado?

      redirect_to etapa_eliminacion_directa_url(etapa: etapa_para(@partido)),
                  notice: mensaje
    rescue StandardError => e
      redirect_to eliminacion_directa_url,
                  alert: "Error al registrar resultado: #{e.message}"
    end
  end

  # Pantalla de visualización de la fase eliminatoria (llaves)
  def fase_eliminatoria
    @torneo = Torneo.actual
    @clasificados = DeterminarClasificados.obtener
    @fase_grupos_completa = @torneo.fase_grupos_lista?
    @clasificados_count = @clasificados[:total_clasificados].count
    @etapas_etiquetas = ETAPAS_DE_ELIMINACION
    @partidos_por_etapa = build_partidos_por_etapa
    @resultados_disponibles = resultados_finales_disponibles?

    if @fase_grupos_completa && @partidos_por_etapa[:dieciseisavos].empty? && @clasificados_count == 32
      generar_dieciseisavos_iniciales
      flash.now[:notice] = "Se generaron los partidos de Dieciseisavos automáticamente."
      @partidos_por_etapa = build_partidos_por_etapa
    end

    if @fase_grupos_completa && @partidos_por_etapa[:dieciseisavos].any?
      generar_siguiente_ronda_automatico
      @partidos_por_etapa = build_partidos_por_etapa
      @resultados_disponibles = resultados_finales_disponibles?
    end

    if @torneo.podio_listo? && !@torneo.finalizado?
      @torneo.determinar_podio!
    end

    @podio_ready = @torneo.podio_listo?
    @podio = {
      campeon: @torneo.campeon,
      subcampeon: @torneo.subcampeon,
      tercero: @torneo.tercero
    }

    render template: "fase_de_grupos/fase_eliminatoria"
  end

  def actualizar_resultados
    @torneo = Torneo.actual
    resultados = params.fetch(:resultados, {}).permit!
    guardados = 0
    errores = []

    resultados.each do |partido_id, partido_params|
      partido = Partido.find_by(id: partido_id)
      next unless partido&.eliminacion_directa?

      if partido.finalizado?
        errores << "Partido #{partido.numero_partido}: ya finalizado, no se puede editar."
        next
      end

      goles_local_value = partido_params[:goles_local]
      goles_visitante_value = partido_params[:goles_visitante]
      goles_local = goles_local_value.present? ? goles_local_value.to_i : nil
      goles_visitante = goles_visitante_value.present? ? goles_visitante_value.to_i : nil
      penales_local = partido_params[:goles_penales_local].presence
      penales_visitante = partido_params[:goles_penales_visitante].presence

      if goles_local.nil? || goles_visitante.nil?
        errores << "Partido #{partido.numero_partido}: complete ambos goles."
        next
      end

      if goles_local == goles_visitante
        if penales_local.blank? || penales_visitante.blank?
          errores << "Partido #{partido.numero_partido}: empate, complete penales."
          next
        end
      else
        penales_local = nil
        penales_visitante = nil
      end

      begin
        partido.registrar_resultado!(
          goles_local,
          goles_visitante,
          penales_local&.to_i,
          penales_visitante&.to_i
        )
        guardados += 1
      rescue StandardError => e
        errores << "Partido #{partido.numero_partido}: #{e.message}"
      end
    end

    mensaje = "#{guardados} resultados guardados."
    if errores.any?
      mensaje += " Errores: #{errores.join(' ')}"
      redirect_to fase_eliminatoria_path, alert: mensaje
      return
    end

    avance = SiguienteRonda.new(@torneo).avanzar
    if avance[:ok]
      mensaje += " Partidos de #{avance[:etapa].humanize} generados automáticamente."
      redirect_to fase_eliminatoria_path, notice: mensaje
    else
      mensaje += " #{avance[:error]}"
      redirect_to fase_eliminatoria_path, notice: mensaje
    end
  end

  helper_method :partido_estado_label, :partido_estado_class, :partido_score_text

  private

  ETAPAS_DE_ELIMINACION = {
    dieciseisavos: "Dieciseisavos",
    octavos: "Octavos",
    cuartos: "Cuartos de Final",
    semifinal: "Semifinal",
    final: "Final",
    tercer_lugar: "Tercer Lugar"
  }.freeze

  def build_partidos_por_etapa
    ETAPAS_DE_ELIMINACION.each_with_object({}) do |(etapa, _label), hash|
      rango = SiguienteRonda::RANGOS[etapa.to_s]
      hash[etapa] = Partido.eliminacion_directa
                         .where(numero_partido: rango)
                         .order(:numero_partido)
    end
  end

  def resultados_finales_disponibles?
    partidos = Partido.eliminacion_directa

    partidos.count == 32 && partidos.where.not(estado: "finalizado").none?
  end

  def generar_dieciseisavos_iniciales
    seleccionadas = @clasificados[:total_clasificados]
    return if seleccionadas.size != 32

    seleccionadas.each_slice(2).with_index do |(local, visitante), index|
      numero_partido = 73 + index
      partido = Partido.find_or_initialize_by(
        numero_partido: numero_partido,
        tipo_partido: "eliminacion_directa",
        torneo_id: @torneo.id
      )

      partido.assign_attributes(
        estado: "programado",
        seleccion_local: local,
        seleccion_visitante: visitante,
        ganador: nil,
        goles_local: nil,
        goles_visitante: nil,
        goles_penales_local: nil,
        goles_penales_visitante: nil
      )
      partido.save! if partido.changed?
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Error generando dieciseisavos: #{e.message}")
  end

  def generar_siguiente_ronda_automatico
    servicio = SiguienteRonda.new(@torneo)
    resultado = servicio.avanzar

    return unless resultado[:ok]

    flash.now[:notice] ||= ""
    flash.now[:notice] += " " unless flash.now[:notice].blank?
    flash.now[:notice] += "Partidos de #{resultado[:etapa].humanize} generados automáticamente."
  end

  def partido_estado_label(partido)
    case partido.estado
    when "finalizado" then "FINALIZADO"
    when "en_juego" then "EN VIVO"
    else "PROGRAMADO"
    end
  end

  def partido_estado_class(partido)
    case partido.estado
    when "finalizado" then "bg-green-500"
    when "en_juego" then "bg-yellow-400"
    else "bg-outline-variant"
    end
  end

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

  def etapa_para(partido)
    case partido.numero_partido
    when 73..88 then :dieciseisavos
    when 89..96 then :octavos
    when 97..100 then :cuartos
    when 101..102 then :semifinal
    when 103 then :tercer_lugar
    when 104 then :final
    else :dieciseisavos
    end
  end
end
