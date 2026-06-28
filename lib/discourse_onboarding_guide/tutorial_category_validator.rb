# frozen_string_literal: true

module ::DiscourseOnboardingGuide
  class TutorialCategoryValidator
    def initialize(opts = {})
      @opts = opts
    end

    def valid_value?(slug)
      slug.blank? || Category.find_by(slug: slug).present?
    end

    def error_message
      "must be a slug of an existing category"
    end
  end
end
