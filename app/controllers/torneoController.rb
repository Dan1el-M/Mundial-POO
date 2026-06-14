# app/controllers/torneos_controller.rb

class TorneoController < ApplicationController

  before_action :establecer_torneo, only: %i[show edit update destroy
                                              avanzar_etapa podio]

  # GET /torneos
  # Lista todos los torneos registrados.
  def index
    @torneos = Torneo.order(created_at: :desc)
  end

  # GET /torneos/:id
  # Muestra el estado actual del torneo: etapa, grupos y podio si aplica.
  def show
    @grupos  = @torneo.grupos.order(:letra)
    @podio   = { campeon: @torneo.campeon,
                 subcampeon: @torneo.subcampeon,
                 tercero: @torneo.tercero }
  end

  # GET /torneos/new
  def new
    @torneo = Torneo.new
  end

  # POST /torneos
  def create
    @torneo = Torneo.new(torneo_params)

    if @torneo.save
      redirect_to @torneo, notice: "Torneo creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /torneos/:id/edit
  # Solo permite editar el nombre — la etapa se gestiona con avanzar_etapa.
  def edit; end

  # PATCH/PUT /torneos/:id
  def update
    if @torneo.update(torneo_params)
      redirect_to @torneo, notice: "Torneo actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /torneos/:id
  def destroy
    @torneo.destroy!
    redirect_to torneos_path, notice: "Torneo eliminado.", status: :see_other
  end

  # POST /torneos/:id/avanzar_etapa
  # Intenta avanzar a la siguiente etapa del torneo.
  # Solo tiene efecto si todos los partidos de la etapa actual están finalizados.
  def avanzar_etapa
    servicio = SiguienteRonda.new(@torneo)
    resultado = servicio.avanzar

    if resultado[:ok]
      redirect_to @torneo,
                  notice: " Partidos generados para: #{resultado[:etapa].humanize}."
    else
      redirect_to @torneo,
                  alert: " #{resultado[:error]}"
    end
  end

  # GET /torneos/:id/podio
  # Muestra el podio final del torneo (campeón, subcampeón y tercer lugar).
  def podio
    # Si el podio no está determinado aún, intenta calcularlo.
    @torneo.determinar_podio! unless @torneo.finalizado?

    @campeon    = @torneo.campeon
    @subcampeon = @torneo.subcampeon
    @tercero    = @torneo.tercero
  end

  private

  # ──────────────────────────────────────────
  # Callbacks privados
  # ──────────────────────────────────────────

  def establecer_torneo
    @torneo = Torneo.find(params[:id])
  end

  # Solo se permite modificar el nombre desde el formulario.
  # La etapa_actual se gestiona exclusivamente mediante avanzar_etapa.
  # El podio se calcula automáticamente con determinar_podio!.
  def torneo_params
    params.require(:torneo).permit(:nombre)
  end

  # Verifica si los partidos de tercer lugar y final ya finalizaron,
  # para decidir si se puede calcular el podio.
  def podio_listo?
    @torneo.partidos_de_eliminacion
           .where(numero_partido: [103, 104])
           .all?(&:finalizado?)
  end
end