class PartidosGrupoController < ApplicationController
  before_action :set_partido, only: %i[edit update destroy registrar_resultado]
  before_action :set_grupos, only: %i[index calendario new create edit update]

  def index
    @grupos = Grupo.ordenados.includes(:selecciones)
    @total_requerido = Grupo::LETRAS.size * Grupo::MAXIMO_EQUIPOS
    @total_registrado = @grupos.sum { |grupo| grupo.selecciones.size }
    @grupos_completos = @grupos.select(&:completo?)
    @grupos_incompletos = @grupos.reject(&:completo?)
  end

  def generar_calendario
    grupos = Grupo.ordenados.includes(:selecciones, :partidos)
    grupos_incompletos = grupos.reject(&:completo?)

    if grupos_incompletos.any?
      letras = grupos_incompletos.map { |grupo| "Grupo #{grupo.letra}" }.join(", ")
      redirect_to partidos_grupo_path,
                  alert: "No se puede generar el calendario. Revisa estos grupos: #{letras}."
      return
    end

    creados = generar_partidos_faltantes(grupos)
    mensaje = if creados.positive?
                "Calendario generado con #{creados} partido(s)."
              else
                "El calendario ya estaba generado."
              end

    redirect_to calendario_partidos_grupo_path, notice: mensaje
  end

  def calendario
    @grupos = Grupo.ordenados.includes(:selecciones)
    @grupo_seleccionado = Grupo.find_by(id: params[:grupo_id]) || @grupos.first
    @partidos = @grupo_seleccionado&.partidos&.includes(:seleccion_local, :seleccion_visitante) || Partido.none
    @tabla_posiciones = @grupo_seleccionado&.tabla_posiciones || Seleccion.none
    @mejores_terceros_ids = Seleccion.mejores_terceros(8).map(&:id)
  end

  def new
    @partido = Partido.new(tipo_partido: "fase_grupos", grupo_id: params[:grupo_id])
    cargar_opciones
  end

  def create
    @partido = Partido.new(partido_params.merge(tipo_partido: "fase_grupos"))

    if @partido.save
      redirect_to partidos_grupo_path, notice: "Partido creado correctamente."
    else
      cargar_opciones
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    cargar_opciones
  end

  def update
    if @partido.update(partido_params)
      redirect_after_update(notice: "Partido actualizado correctamente.")
    else
      cargar_opciones
      render :edit, status: :unprocessable_entity
    end
  end

  def registrar_resultado
    @partido.registrar_resultado!(
      resultado_params[:goles_local].to_i,
      resultado_params[:goles_visitante].to_i
    )

    redirect_after_update(notice: "Marcador registrado correctamente.")
  rescue StandardError => e
    redirect_after_update(alert: "No se pudo registrar el marcador: #{e.message}")
  end

  def destroy
    @partido.destroy!
    redirect_to partidos_grupo_path, notice: "Partido eliminado correctamente.", status: :see_other
  rescue StandardError => e
    redirect_to partidos_grupo_path, alert: "No se pudo eliminar el partido: #{e.message}"
  end

  private

  def set_partido
    @partido = Partido.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to partidos_grupo_path, alert: "Partido no encontrado."
  end

  def set_grupos
    @grupos = Grupo.ordenados
  end

  def cargar_opciones
    @selecciones = Seleccion.order(:nombre)
  end

  def partido_params
    params.require(:partido).permit(
      :numero_partido,
      :grupo_id,
      :seleccion_local_id,
      :seleccion_visitante_id,
      :estado,
      :goles_local,
      :goles_visitante
    )
  end

  def resultado_params
    params.require(:partido).permit(:goles_local, :goles_visitante)
  end

  def redirect_after_update(**message)
    if params[:volver_calendario].present?
      redirect_to calendario_partidos_grupo_path(grupo_id: @partido.grupo_id), message
    else
      redirect_to partidos_grupo_path, message
    end
  end

  def generar_partidos_faltantes(grupos)
    grupos_ordenados = grupos.sort_by(&:letra)

    grupos_ordenados.sum do |grupo|
      selecciones = grupo.selecciones.to_a
      indice_grupo = Grupo::LETRAS.index(grupo.letra)

      selecciones.combination(2).each_with_index.count do |(local, visitante), indice_partido_grupo|
        numero_partido = numero_partido_fase_grupos(indice_grupo, indice_partido_grupo)
        partido_existente = partido_por_emparejamiento(grupo, local, visitante)

        if partido_existente
          partido_existente.update!(numero_partido: numero_partido) if partido_existente.numero_partido != numero_partido
          false
        else
          Partido.create!(
            numero_partido: numero_partido,
            tipo_partido: "fase_grupos",
            grupo: grupo,
            seleccion_local: local,
            seleccion_visitante: visitante
          )
          true
        end
      end
    end
  end

  def numero_partido_fase_grupos(indice_grupo, indice_partido_grupo)
    bloque = indice_partido_grupo / 2
    posicion_en_bloque = indice_partido_grupo % 2

    (bloque * Grupo::LETRAS.size * 2) + (indice_grupo * 2) + posicion_en_bloque + 1
  end

  def partido_por_emparejamiento(grupo, local, visitante)
    grupo.partidos.detect do |partido|
      [partido.seleccion_local_id, partido.seleccion_visitante_id].sort == [local.id, visitante.id].sort
    end
  end
end
