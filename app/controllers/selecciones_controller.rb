class SeleccionesController < ApplicationController
  before_action :set_seleccion, only: %i[show edit update destroy]
  before_action :set_grupos, only: %i[index new create edit update]

  PER_PAGE = 10

  def index
    preparar_index
  end

  def show
    @partidos = @seleccion.todos_los_partidos.order(created_at: :desc)
  end

  def partidos
    set_seleccion
    @partidos = @seleccion.todos_los_partidos.order(created_at: :desc)
  end

  def new
    @seleccion = Seleccion.new
  end

  def create
    @seleccion = Seleccion.new(seleccion_params)

    if @seleccion.save
      redirect_to selecciones_path,
                  notice: "Seleccion '#{@seleccion.nombre}' (#{@seleccion.acronimo}) registrada correctamente."
    else
      preparar_index
      @validation_errors = errores_en_espanol(@seleccion)
      flash.now[:alert] = @validation_errors.join(". ")
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @seleccion.acronimo = nil if seleccion_params[:acronimo].blank?

    if @seleccion.update(seleccion_params)
      redirect_to selecciones_path,
                  notice: "Seleccion '#{@seleccion.nombre}' (#{@seleccion.acronimo}) actualizada correctamente."
    else
      redirect_to selecciones_path,
                  alert: @seleccion.errors.full_messages.to_sentence
    end
  end

  def destroy
    nombre = @seleccion.nombre

    if @seleccion.destroy
      redirect_to selecciones_url,
                  notice: "Seleccion '#{nombre}' eliminada correctamente.",
                  status: :see_other
    else
      redirect_to selecciones_url,
                  alert: @seleccion.errors.full_messages.to_sentence,
                  status: :see_other
    end
  end

  private

  def preparar_index
    @seleccion ||= Seleccion.new
    @grupos = Grupo.ordenados.includes(:selecciones)
    @letras_disponibles = Grupo::LETRAS - @grupos.pluck(:letra)
    @pagina_actual = params[:page].to_i.positive? ? params[:page].to_i : 1

    scope = Seleccion.includes(:grupo).order(:nombre)
    letra_filtro = params[:grupo_letra].presence || params[:group_letter].presence

    if letra_filtro.present? && letra_filtro != "all"
      scope = scope.joins(:grupo).where(grupos: { letra: letra_filtro })
    end

    @total_selecciones = scope.count
    @total_paginas = (@total_selecciones / PER_PAGE.to_f).ceil
    @total_paginas = 1 if @total_paginas.zero?
    @pagina_actual = @total_paginas if @pagina_actual > @total_paginas
    @selecciones = scope.offset((@pagina_actual - 1) * PER_PAGE).limit(PER_PAGE)

    @selecciones_por_grupo = @grupos.each_with_object({}) do |grupo, hash|
      hash[grupo] = Seleccion.tabla_de_grupo(grupo.id)
    end
  end

  def set_seleccion
    @seleccion = Seleccion.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to selecciones_url, alert: "Seleccion no encontrada."
  end

  def set_grupos
    @grupos = Grupo.ordenados
  end

  def seleccion_params
    params.require(:seleccion).permit(
      :nombre,
      :acronimo,
      :grupo_id,
      :puntos,
      :goles_favor,
      :goles_contra,
      :diferencia_goles
    )
  end

  def errores_en_espanol(seleccion)
    seleccion.errors.full_messages.map do |msg|
      case msg
      when /can't be blank/i
        "#{msg.split.first.humanize} no puede estar vacio"
      when /has already been taken/i
        "#{msg.split.first.humanize} ya esta en uso"
      else
        msg
      end
    end.uniq
  end
end
