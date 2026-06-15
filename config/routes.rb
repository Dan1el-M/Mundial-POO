Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "selecciones#index"

  resources :grupos do
    member do
      get :tabla
      get :partidos, as: :partidos_del
    end
  end

  resources :selecciones do
    member do
      get :partidos
    end
  end

  get "partidos_grupo", to: "partidos_grupo#index", as: :partidos_grupo
  post "partidos_grupo/generar_calendario",
       to: "partidos_grupo#generar_calendario",
       as: :generar_calendario_partidos_grupo
  get "partidos_grupo/calendario",
      to: "partidos_grupo#calendario",
      as: :calendario_partidos_grupo

  resources :partidos_grupo, except: %i[index show] do
    member do
      patch :registrar_resultado
    end
  end

  resources :partidos do
    member do
      patch :registrar_resultado
    end
  end

  resources :selecciones, only: %i[index show] do
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

  resources :eliminacion_directa, only: [:index]

  get 'validacion_fase_eliminatoria', to: 'eliminacion_directa#index', as: :validacion_fase_eliminatoria
  
  get "eliminacion_directa/:etapa",
      to: "eliminacion_directa#show",
      as: :etapa_eliminacion_directa

  get '/fase_eliminatoria', to: 'eliminacion_directa#fase_eliminatoria', as: :fase_eliminatoria
  patch 'eliminacion_directa/fase_eliminatoria/actualizar_resultados',
        to: 'eliminacion_directa#actualizar_resultados',
        as: :actualizar_resultados_fase_eliminatoria
  patch "eliminacion_directa/:id/registrar_resultado",
        to: "eliminacion_directa#registrar_resultado",
        as: :registrar_resultado_eliminacion_directa

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
