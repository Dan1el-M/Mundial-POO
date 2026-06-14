# app/controllers/partidos_controller.rb

class PartidosController < ApplicationController
  before_action :establecer_partido, only: %i[show edit update destroy registrar_resultado]

  # GET /partidos
  # Lista todos los partidos, separados por tipo
  def index
    @partidos_grupos      = Partido.where(tipo_partido: "fase_grupos").order(:numero_partido)
    @partidos_eliminacion = Partido.where(tipo_partido: "eliminacion_directa").order(:numero_partido)
  end

  # GET /partidos/:id
  def show; end

  # GET /partidos/new
  def new
    @partido    = Partido.new
    @selecciones = Seleccion.order(:nombre)
    @grupos      = Grupo.order(:letra)
    @torneos     = Torneo.order(:nombre)
  end

  # POST /partidos
  def create
    @partido = Partido.new(partido_params)

    if @partido.save
      redirect_to @partido, notice: "Partido ##{@partido.numero_partido} creado exitosamente."
    else
      @selecciones = Seleccion.order(:nombre)
      @grupos      = Grupo.order(:letra)
      @torneos     = Torneo.order(:nombre)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /partidos/:id/edit
  def edit
    @selecciones = Seleccion.order(:nombre)
    @grupos      = Grupo.order(:letra)
    @torneos     = Torneo.order(:nombre)
  end

  # PATCH/PUT /partidos/:id
  # Solo permite editar datos estructurales del partido (no el resultado)
  def update
    if @partido.update(partido_params)
      redirect_to @partido, notice: "Partido ##{@partido.numero_partido} actualizado exitosamente."
    else
      @selecciones = Seleccion.order(:nombre)
      @grupos      = Grupo.order(:letra)
      @torneos     = Torneo.order(:nombre)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /partidos/:id
  def destroy
    numero = @partido.numero_partido
    @partido.destroy!
    redirect_to partidos_url, notice: "Partido ##{numero} eliminado.", status: :see_other
  end

  # PATCH /partidos/:id/registrar_resultado
  # Registra el marcador de un partido y determina el ganador.
  # Solo aplica si el partido está en estado "programado" o "en_juego".
  def registrar_resultado
    if @partido.finalizado?
      redirect_to @partido, alert: "El partido ya está finalizado y no puede modificarse."
      return
    end

    if @partido.update(resultado_params.merge(estado: "finalizado"))
      ganador = @partido.calcular_ganador
      @partido.update!(ganador: ganador) if ganador.present?

      # Si es de fase de grupos, actualiza estadísticas de ambas selecciones
      if @partido.fase_grupos?
        @partido.seleccion_local.registrar_resultado_grupo(
          @partido.goles_local,
          @partido.goles_visitante
        )
        @partido.seleccion_visitante.registrar_resultado_grupo(
          @partido.goles_visitante,
          @partido.goles_local
        )
      end

      redirect_to @partido, notice: "Resultado registrado correctamente."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  # ──────────────────────────────────────────
  # Callbacks privados
  # ──────────────────────────────────────────

  def establecer_partido
    @partido = Partido.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to partidos_url, alert: "Partido no encontrado."
  end

  # Parámetros permitidos para crear/editar la estructura del partido.
  # Los goles y el ganador se manejan exclusivamente desde registrar_resultado.
  def partido_params
    params.require(:partido).permit(
      :numero_partido,
      :estado,
      :tipo_partido,
      :torneo_id,
      :grupo_id,
      :seleccion_local_id,
      :seleccion_visitante_id
    )
  end

  # Parámetros permitidos solo para registrar el resultado de un partido.
  def resultado_params
    params.require(:partido).permit(
      :goles_local,
      :goles_visitante,
      :goles_penales_local,
      :goles_penales_visitante
    )
  end
end