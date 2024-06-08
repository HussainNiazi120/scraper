# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  root 'home_page#index'

  post 'scraper/scrape', to: 'home_page#scrape', as: :scrape

  namespace :api do
    namespace :v1 do
      post 'scraper/scrape', to: 'scraper#scrape', as: :scrape
    end
  end
end
