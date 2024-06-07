# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  root 'home_page#index'

  namespace :api do
    namespace :v1 do
      post 'scraper/scrape', to: 'scraper#scrape', as: :scrape
    end
  end
end
