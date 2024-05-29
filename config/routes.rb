# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  root 'scraper#index'
  post 'scraper/scrape', to: 'scraper#scrape', as: :scrape
end
