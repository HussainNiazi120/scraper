Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "scrapper#index"
  post 'scrapper/scrap', to: 'scrapper#scrap', as: 'scrap'
end
