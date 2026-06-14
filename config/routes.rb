Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "tournament#standings"

  resources :teams, except: :show
  resources :groups
  resources :group_matches, except: :show
  resources :knockout_matches, only: %i[index edit update]

  resources :torneos do
    member do
      post :avanzar_etapa
      get  :podio
    end
  end
end
