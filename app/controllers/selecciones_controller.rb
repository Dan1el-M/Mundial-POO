class SeleccionesController < ApplicationController
  before_action :set_seleccion, only: %i[show edit update destroy]

  # GET /selecciones
  # Lista todas las selecciones agrupadas por grupo
  def index
    @selecciones_por_grupo = Grupo.all.each_with_object({}) do |grupo, hash|
      hash[grupo] = Seleccion.tabla_de_grupo(grupo.id)
    end
  end

  # GET /selecciones/:id
  # Detalle de una selección y sus partidos
  def show
    @partidos = @seleccion.todos_los_partidos.order(created_at: :desc)
  end

  # GET /selecciones/:id/partidos
  # Lista los partidos de una seleccion.
  def partidos
    set_seleccion
    @partidos = @seleccion.todos_los_partidos.order(created_at: :desc)
  end

  # GET /selecciones/new
  def new
    @seleccion = Seleccion.new
    @grupos    = Grupo.all.order(:letra)
  end

  # POST /selecciones
  def create
    @seleccion = Seleccion.new(seleccion_params)

    if @seleccion.save
      redirect_to @seleccion,
                  notice: "Selección '#{@seleccion.nombre}' (#{@seleccion.acronimo}) registrada correctamente."
    else
      @grupos = Grupo.all.order(:letra)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /selecciones/:id/edit
  def edit
    @grupos = Grupo.all.order(:letra)
  end

  # PATCH/PUT /selecciones/:id
  # Permite actualizar el nombre, acrónimo y/o reasignar el grupo
  def update
    # Si el usuario limpió el acrónimo en el form, se regenera desde el nombre
    if seleccion_params[:acronimo].blank?
      @seleccion.acronimo = nil
    end

    if @seleccion.update(seleccion_params)
      redirect_to @seleccion,
                  notice: "Selección '#{@seleccion.nombre}' (#{@seleccion.acronimo}) actualizada correctamente."
    else
      @grupos = Grupo.all.order(:letra)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /selecciones/:id
  # Elimina la selección del sistema
  def destroy
    nombre = @seleccion.nombre
    @seleccion.destroy
    redirect_to selecciones_url,
                notice: "Selección '#{nombre}' eliminada correctamente.",
                status: :see_other
  end

  private

  # Busca la selección por id; redirige con alerta si no existe
  def set_seleccion
    @seleccion = Seleccion.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to selecciones_url, alert: "Selección no encontrada."
  end

  # Permite cambiar nombre, acrónimo y grupo desde el formulario.
  # El acrónimo es opcional: si se deja vacío, se autogenera en el modelo.
  # Las estadísticas se actualizan únicamente a través de los partidos.
  def seleccion_params
    params.require(:seleccion).permit(:nombre, :acronimo, :grupo_id)
  end
end
