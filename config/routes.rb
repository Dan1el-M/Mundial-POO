Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "tournament#standings"

  # Recursos en inglés (legado)
  resources :teams, except: :show
  resources :groups
  resources :group_matches, except: :show
  resources :knockout_matches, only: %i[index edit update]

  # Recursos en español (nuevo)
  resources :grupos do
    member do
      get :tabla      # GET /grupos/:id/tabla
      get :partidos   # GET /grupos/:id/partidos
    end
  end

  resources :selecciones do
    member do
      get :partidos   # GET /selecciones/:id/partidos
    end
  end

  resources :partidos do
    member do
      patch :registrar_resultado  # PATCH /partidos/:id/registrar_resultado
    end
  end

  # Posiciones y clasificados
  resources :posiciones, only: %i[index show] do
    collection do
      get :general    # GET /posiciones/general
    end
  end

  resources :clasificados, only: %i[index show] do
    collection do
      get :por_grupo  # GET /clasificados/por_grupo
      get :resumen    # GET /clasificados/resumen
    end
    member do
      get :detalles   # GET /clasificados/:id/detalles
    end
  end

  # Eliminación directa
  resources :eliminacion_directa, only: [:index] do
    member do
      get :show               # GET /eliminacion-directa/:etapa
      patch :registrar_resultado  # PATCH /eliminacion-directa/:id/resultado
    end
  end

  # Campeones y podio
  resources :campeones, only: [:index] do
    collection do
      get :show             # GET /campeones/show
      get :podio            # GET /campeones/podio
      get :estadisticas     # GET /campeones/estadisticas
    end
  end

  # Torneos
  resources :torneos do
    member do
      post :avanzar_etapa
      get  :podio
    end
  end
end
