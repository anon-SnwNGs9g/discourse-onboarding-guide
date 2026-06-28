# frozen_string_literal: true

module ::DiscourseOnboardingGuide
  class PreferenceItemsValidator
    VALID_TYPES = %w[category tag].freeze

    def initialize(opts = {})
      @opts = opts
    end

    def valid_value?(value)
      parsed = JSON.parse(value)
      return false unless parsed.is_a?(Array) && parsed.size <= 10

      parsed.all? do |entry|
        entry.is_a?(Hash) &&
          VALID_TYPES.include?(entry["type"]) &&
          (
            (entry["type"] == "category" && entry["slug"].is_a?(String) && entry["slug"].present?) ||
              (entry["type"] == "tag" && entry["name"].is_a?(String) && entry["name"].present?)
          ) &&
          (!entry.key?("label") || entry["label"].is_a?(String))
      end
    rescue JSON::ParserError
      false
    end

    def error_message
      "must be a JSON array with up to 10 category/tag entries"
    end
  end
end
