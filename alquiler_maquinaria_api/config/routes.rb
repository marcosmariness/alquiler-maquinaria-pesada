Rails.application.routes.draw do
  resources :articulos, only: [:index, :create, :update, :destroy]
  resources :reservas, only: [:index, :create, :destroy]
  post '/login', to: 'sesiones#create'
end
