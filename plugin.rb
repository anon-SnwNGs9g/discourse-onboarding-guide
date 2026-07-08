# frozen_string_literal: true

# name: discourse-onboarding-guide
# about: Guided onboarding flow for newly registered users and opt-in group members.
# version: 0.1
# authors: kull
# url: https://github.com/anon-SnwNGs9g/discourse-onboarding-guide
# required_version: 2.7.0

enabled_site_setting :onboarding_guide_enabled

register_asset "stylesheets/onboarding-guide.scss"

module ::DiscourseOnboardingGuide
  PLUGIN_NAME = "discourse-onboarding-guide"

  ASSIGNED_VERSION_FIELD = "onboarding_guide_assigned_version"
  COMPLETED_VERSION_FIELD = "onboarding_guide_completed_version"
  PROGRESS_FIELD = "onboarding_guide_progress"
end

require_relative "lib/discourse_onboarding_guide/json_array_validator"
require_relative "lib/discourse_onboarding_guide/preference_items_validator"
require_relative "lib/discourse_onboarding_guide/assignment_manager"
require_relative "lib/discourse_onboarding_guide/preference_updater"
require_relative "lib/discourse_onboarding_guide/state_resolver"
require_relative "lib/discourse_onboarding_guide/tutorial_category_validator"
require_relative "lib/discourse_onboarding_guide/mandatory_setting_validator"

after_initialize do
  require_relative "app/controllers/discourse_onboarding_guide/onboarding_controller"

  [
    [DiscourseOnboardingGuide::ASSIGNED_VERSION_FIELD, :integer, 10],
    [DiscourseOnboardingGuide::COMPLETED_VERSION_FIELD, :integer, 10],
    [DiscourseOnboardingGuide::PROGRESS_FIELD, :json, nil],
  ].each do |field, type, max_length|
    register_editable_user_custom_field field
    register_user_custom_field_type(
      field,
      type,
      **(max_length ? { max_length: max_length } : {}),
    )
    DiscoursePluginRegistry.serialized_current_user_fields << field
  end

  add_to_serializer(:current_user, :onboarding_guide_required) do
    DiscourseOnboardingGuide::StateResolver.required_for?(object)
  end

  on(:user_created) do |user|
    next unless SiteSetting.onboarding_guide_enabled
    next if !user.human? || user.staged?

    DiscourseOnboardingGuide::AssignmentManager.assign_new_user!(user)
  end

  on(:user_added_to_group) do |user, group, automatic:|
    next unless SiteSetting.onboarding_guide_enabled
    next if automatic

    DiscourseOnboardingGuide::AssignmentManager.assign_group_user!(user, group)
  end

  Discourse::Application.routes.append do
    get "/onboarding-guide/preference-items" => "discourse_onboarding_guide/onboarding#preference_items"
    post "/onboarding-guide/progress" => "discourse_onboarding_guide/onboarding#progress"
    post "/onboarding-guide/preferences" => "discourse_onboarding_guide/onboarding#preferences"
    post "/onboarding-guide/complete" => "discourse_onboarding_guide/onboarding#complete"
  end
end
