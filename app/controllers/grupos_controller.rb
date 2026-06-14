class GruposController < ApplicationController
  before_action :set_grupo, only: %i[show edit update destroy tabla partidos]

  def index
    @grupos = Grupo.ordenados.includes(:selecciones)
    @total_grupos = Grupo.count
    @grupos_completos = @grupos.count(&:completo?)

    respond_to do |format|
      format.html
      format.json { render json: @grupos.map { |grupo| grupo_json(grupo) } }
    end
  end

  def show
    @tabla_posiciones = @grupo.tabla_posiciones
    @selecciones = @grupo.selecciones.order(:nombre)
    @total_selecciones = @selecciones.count
    @partidos = @grupo.partidos.order(:numero_partido)
    @partidos_finalizados = @grupo.partidos.finalizados.count
    @partidos_pendientes = @grupo.partidos.where(estado: %w[programado en_juego]).count
    @grupos = Grupo.ordenados
  end

  def new
    @grupo = Grupo.new
    set_letras_disponibles
  end

  def create
    @grupo = Grupo.new(grupo_params)

    if @grupo.save
      respond_to do |format|
        format.html { redirect_to @grupo, notice: "Grupo #{@grupo.letra} creado correctamente." }
        format.json do
          render json: { message: "Grupo agregado correctamente.", letra: @grupo.letra, letter: @grupo.letra },
                 status: :created
        end
      end
    else
      set_letras_disponibles
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { message: @grupo.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    set_letras_disponibles(except_id: @grupo.id)
  end

  def update
    if @grupo.update(grupo_params)
      redirect_to @grupo, notice: "Grupo #{@grupo.letra} actualizado correctamente."
    else
      set_letras_disponibles(except_id: @grupo.id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    letra = @grupo.letra

    if @grupo.destroy
      redirect_to grupos_url, notice: "Grupo #{letra} eliminado correctamente.", status: :see_other
    else
      redirect_to @grupo, alert: @grupo.errors.full_messages.to_sentence
    end
  end

  def tabla
    @tabla_posiciones = @grupo.tabla_posiciones

    respond_to do |format|
      format.html { render :tabla, layout: false }
      format.json { render json: tabla_json_format }
    end
  end

  def partidos
    @partidos = @grupo.partidos.order(:numero_partido)

    respond_to do |format|
      format.html { render :partidos, layout: false }
      format.json { render json: @partidos }
    end
  end

  private

  def set_grupo
    @grupo = Grupo.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to grupos_url, alert: "Grupo no encontrado."
  end

  def set_letras_disponibles(except_id: nil)
    scope = except_id.present? ? Grupo.where.not(id: except_id) : Grupo.all
    @letras_disponibles = Grupo::LETRAS - scope.pluck(:letra)
  end

  def grupo_params
    params.require(:grupo).permit(:letra)
  end

  def tabla_json_format
    @tabla_posiciones.map do |seleccion|
      {
        id: seleccion.id,
        nombre: seleccion.nombre,
        acronimo: seleccion.acronimo,
        posicion: seleccion.posicion_en_grupo,
        puntos: seleccion.puntos,
        victorias: seleccion.victorias,
        empates: seleccion.empates,
        derrotas: seleccion.derrotas,
        goles_favor: seleccion.goles_favor,
        goles_contra: seleccion.goles_contra,
        diferencia_goles: seleccion.diferencia_goles
      }
    end
  end

  def grupo_json(grupo)
    selecciones = grupo.selecciones.order(:nombre).map do |seleccion|
      {
        id: seleccion.id,
        nombre: seleccion.nombre,
        name: seleccion.nombre,
        acronimo: seleccion.acronimo,
        acronym: seleccion.acronimo
      }
    end

    {
      id: grupo.id,
      letra: grupo.letra,
      letter: grupo.letra,
      selecciones: selecciones,
      teams: selecciones
    }
  end
end
