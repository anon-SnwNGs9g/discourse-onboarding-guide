# frozen_string_literal: true

module ::DiscourseOnboardingGuide
  class JsonArrayValidator
    def initialize(opts = {})
      @opts = opts
    end

    def valid_value?(value)
      parsed = JSON.parse(value)
      parsed.is_a?(Array) && parsed.all? { |entry| entry.is_a?(String) && entry.present? }
    rescue JSON::ParserError
      false
    end

    def error_message
      "must be a JSON array of non-empty strings"
    end
  end
end
