Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "posiciones#index"

  resources :teams, except: :show
  resources :groups
  resources :group_matches, except: :show do
    collection do
      post :generate_calendar
      get :calendar
    end
  end
  resources :knockout_matches, only: %i[index edit update]
  # Recursos principales en espanol
  resources :grupos do
    member do
      get :tabla
      get :partidos
    end
  end

  resources :selecciones do
    member do
      get :partidos
    end
  end

  resources :partidos do
    member do
      patch :registrar_resultado
    end
  end

  resources :posiciones, only: %i[index show] do
    collection do
      get :general
    end
  end

  resources :clasificados, only: %i[index show] do
    collection do
      get :por_grupo
      get :resumen
    end

    member do
      get :detalles
    end
  end

  # Eliminacion directa
  resources :eliminacion_directa, only: [:index]
  get "eliminacion_directa/:etapa",
      to: "eliminacion_directa#show",
      as: :etapa_eliminacion_directa
  patch "eliminacion_directa/:id/registrar_resultado",
        to: "eliminacion_directa#registrar_resultado",
        as: :registrar_resultado_eliminacion_directa

  # Campeones y podio
  resources :campeones, only: %i[index show] do
    collection do
      get :podio
      get :estadisticas
    end
  end

  resources :torneos do
    member do
      post :avanzar_etapa
      get :podio
    end
  end
end
