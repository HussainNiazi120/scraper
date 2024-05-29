class ScrapService < ApplicationService
    require 'open-uri'
    require 'nokogiri'
    class UrlMissingError < StandardError; end
    class InvalidUrl < StandardError; end
    class MissingOrInvalidFields < StandardError; end
    class ConnectionError < StandardError; end
  
    def initialize(params)
        @url = params[:url]
        @fields = params[:fields]
        @meta_tags = @fields.delete(:meta) if @fields.present? && @fields[:meta].present?
    end

    def call
        raise UrlMissingError if @url.blank?
        raise InvalidUrl unless @url =~ URI::DEFAULT_PARSER.make_regexp

        # remove all fields that have blank key or value
        @fields = @fields&.select { |k, v| k.present? && v.present? }

        raise MissingOrInvalidFields unless @fields.present?

        # check if url exists in redis cache store and return it if it does
        cache_key = Digest::MD5.hexdigest(@url)
        if Rails.cache.exist?(cache_key)
            html = Rails.cache.read(cache_key)
        else
            html = URI.open(@url).read
            Rails.cache.write(cache_key, html, expires_in: 1.hour)
        end
        page = Nokogiri::HTML(html)

        response = Hash.new
        @fields.each do |field|
            response[field[0]] = page.css(field[1]).text.present? ? page.css(field[1]).text : nil
        end

        # if meta tags are requested, add them to the response
        if @meta_tags
            response[:meta] = Hash.new
            @meta_tags.each do |tag|
                response[:meta][tag] = page.css("meta[name='#{tag}']").first&.[]('content')
            end
        end

        response
    rescue UrlMissingError
        raise UrlMissingError
    rescue InvalidUrl
        raise InvalidUrl
    rescue MissingOrInvalidFields
        raise MissingOrInvalidFields
    rescue => e
        raise ConnectionError, e.message
    end
end