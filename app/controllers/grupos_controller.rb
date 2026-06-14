# app/controllers/grupos_controller.rb

# GruposController maneja el CRUD de los 12 grupos de la Copa Mundial.
# Cada grupo contiene 4 selecciones que juegan entre sí en fase de grupos.
#
# Rutas:
#   GET    /grupos              → index   (lista todos los grupos)
#   GET    /grupos/:id          → show    (detalle del grupo + tabla)
#   GET    /grupos/new          → new     (formulario crear)
#   POST   /grupos              → create  (guardar nuevo grupo)
#   GET    /grupos/:id/edit     → edit    (formulario editar)
#   PATCH  /grupos/:id          → update  (guardar cambios)
#   DELETE /grupos/:id          → destroy (eliminar grupo)

class GruposController < ApplicationController
  before_action :set_grupo, only: %i[show edit update destroy]

  # ──────────────────────────────────────────
  # GET /grupos
  # Muestra todos los 12 grupos de la Copa Mundial
  # ──────────────────────────────────────────
  def index
    @grupos = Grupo.ordenados
    @total_grupos = Grupo.count
    @grupos_completos = Grupo.all.count { |g| g.completo? }
  end

  # ──────────────────────────────────────────
  # GET /grupos/:id
  # Detalle de un grupo con su tabla de posiciones y selecciones
  # ──────────────────────────────────────────
  def show
    @tabla_posiciones = @grupo.tabla_posiciones
    @selecciones = @grupo.selecciones
    @total_selecciones = @grupo.selecciones.count

    # Información de partidos del grupo
    @partidos = @grupo.partidos.order(:numero_partido)
    @partidos_finalizados = @grupo.partidos.finalizados.count
    @partidos_pendientes = @grupo.partidos.where(estado: %w[programado en_juego]).count
  end

  # ──────────────────────────────────────────
  # GET /grupos/new
  # Formulario para crear un nuevo grupo
  # ──────────────────────────────────────────
  def new
    @grupo = Grupo.new
    @letras_disponibles = Grupo::LETRAS - Grupo.pluck(:letra)
  end

  # ──────────────────────────────────────────
  # POST /grupos
  # Crea un nuevo grupo
  # ──────────────────────────────────────────
  def create
    @grupo = Grupo.new(grupo_params)

    if @grupo.save
      redirect_to @grupo,
                  notice: "✅ Grupo #{@grupo.letra} creado correctamente."
    else
      @letras_disponibles = Grupo::LETRAS - Grupo.pluck(:letra)
      render :new, status: :unprocessable_entity
    end
  end

  # ──────────────────────────────────────────
  # GET /grupos/:id/edit
  # Formulario para editar un grupo (principalmente para cambiar letra)
  # ──────────────────────────────────────────
  def edit
    @letras_disponibles = Grupo::LETRAS - Grupo.where.not(id: @grupo.id).pluck(:letra)
  end

  # ──────────────────────────────────────────
  # PATCH/PUT /grupos/:id
  # Actualiza un grupo
  # ──────────────────────────────────────────
  def update
    if @grupo.update(grupo_params)
      redirect_to @grupo,
                  notice: "✅ Grupo #{@grupo.letra} actualizado correctamente."
    else
      @letras_disponibles = Grupo::LETRAS - Grupo.where.not(id: @grupo.id).pluck(:letra)
      render :edit, status: :unprocessable_entity
    end
  end

  # ──────────────────────────────────────────
  # DELETE /grupos/:id
  # Elimina un grupo y todas sus selecciones y partidos
  # ──────────────────────────────────────────
  def destroy
    letra = @grupo.letra
    @grupo.destroy!

    redirect_to grupos_url,
                notice: "✅ Grupo #{letra} eliminado correctamente."
  rescue StandardError => e
    redirect_to @grupo,
                alert: "❌ Error al eliminar el grupo: #{e.message}"
  end

  # ──────────────────────────────────────────
  # Acciones adicionales
  # ──────────────────────────────────────────

  # GET /grupos/:id/tabla
  # Muestra solo la tabla de posiciones del grupo (útil para API/AJAX)
  def tabla
    set_grupo
    @tabla_posiciones = @grupo.tabla_posiciones

    respond_to do |format|
      format.html { render :tabla, layout: false }
      format.json { render json: tabla_json_format }
    end
  end

  # GET /grupos/:id/partidos
  # Lista todos los partidos del grupo
  def partidos
    set_grupo
    @partidos = @grupo.partidos.order(:numero_partido)

    respond_to do |format|
      format.html { render :partidos, layout: false }
      format.json { render json: @partidos }
    end
  end

  private

  # ──────────────────────────────────────────
  # Callbacks privados
  # ──────────────────────────────────────────

  # Encuentra el grupo por ID
  def set_grupo
    @grupo = Grupo.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to grupos_url, alert: "❌ Grupo no encontrado."
  end

  # ──────────────────────────────────────────
  # Strong Parameters
  # ──────────────────────────────────────────

  # Parámetros permitidos para crear/actualizar un grupo
  def grupo_params
    params.require(:grupo).permit(:letra)
  end

  # ──────────────────────────────────────────
  # Helpers privados
  # ──────────────────────────────────────────

  # Formatea la tabla de posiciones para JSON
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
end
