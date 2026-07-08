# frozen_string_literal: true

module ::DiscourseOnboardingGuide
  class MandatorySettingValidator
    def initialize(opts = {})
      @opts = opts
    end

    def valid_value?(value)
      return true if ActiveModel::Type::Boolean.new.cast(value)

      Group.where(id: SiteSetting.onboarding_guide_target_groups_map).all? { |g| !g.automatic && g.public_exit }
    end

    def error_message
      I18n.t("site_settings.errors.onboarding_guide_mandatory_automatic_group")
    end
  end
end
