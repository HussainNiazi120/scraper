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
      rescue StandardError => e
        handle_error(e)
      end

      private

      def scrape_params
        params.permit(:url, :commit, fields: {})
      end

      # rubocop:disable Metrics/MethodLength
      def handle_error(error)
        case error
        when SanitizeUrlService::UrlMissingError, SanitizeUrlService::InvalidUrlError,
             ValidateFieldsService::MissingOrInvalidFields
          render json: { message: error.message }, status: 422
        when FetchHtmlService::ForbiddenError
          render json: { message: error.message }, status: 403
        when FetchHtmlService::WebPageError
          render json: { message: error.message }, status: 500
        else
          render json: { message: 'There was an unexpected error!' }, status: 500
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
