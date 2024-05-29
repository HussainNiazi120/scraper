class ScrapperController < ApplicationController
    rescue_from ScrapService::UrlMissingError, with: :handle_url_missing
    rescue_from ScrapService::InvalidUrl, with: :handle_invalid_url
    rescue_from ScrapService::MissingOrInvalidFields, with: :handle_missing_or_invalid_fields
    rescue_from ScrapService::ConnectionError, with: :handle_nokogiri_error

    def index
    end

    def scrap
        @response = ScrapService.call(scrap_params)

        respond_to do |format|
            format.turbo_stream
            format.json { render json: @response }
        end
    end

    private

    def scrap_params
        params.permit(:url, :commit, fields: {})
    end

    def handle_url_missing
        @error = { code: 422, message: 'URL is missing' }
        render_error
    end

    def handle_invalid_url
        @error = { code: 422, message: 'URL is invalid' }
        render_error
    end

    def handle_missing_or_invalid_fields
        @error = { code: 422, message: 'Fields are missing or invalid' }
        render_error
    end

    def handle_nokogiri_error(message)
        @error = { code: 500, message: message }
        render_error
    end

    def render_error
        respond_to do |format|
            format.turbo_stream { render turbo_stream: turbo_stream.replace('formErrors', partial: 'form_errors') }
            format.json { render json: @error, status: @error[:code] }
        end
    end
end