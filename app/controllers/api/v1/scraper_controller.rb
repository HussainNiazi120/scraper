# frozen_string_literal: true

module Api
  module V1
    # The ScraperController handles the web scraping functionality of the application.
    # It uses the ScrapeService to scrape data from a given URL and returns the scraped data.
    class ScraperController < ActionController::API
      def scrape
        response = ScrapeService.call(scrape_params)
        @messages = response.delete(:messages)

        render json: response.as_json
      rescue SanitizeUrlService::UrlMissingError, SanitizeUrlService::InvalidUrlError,
             ValidateFieldsService::MissingOrInvalidFields => e
        render json: { message: e.message }, status: 422
      rescue FetchHtmlService::WebPageError => e
        render json: { message: e.message }, status: 500
      rescue StandardError
        render json: { message: 'There was an unexpected error!' }, status: 500
      end

      private

      def scrape_params
        params.permit(:url, :commit, fields: {})
      end
    end
  end
end
