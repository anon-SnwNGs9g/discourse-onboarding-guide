# frozen_string_literal: true

# name: discourse-onboarding-guide
# about: Guided onboarding flow for newly registered users and opt-in group members.
# version: 0.1
# authors: kull
# url: https://github.com/anon-SnwNGs9g/discourse-onboarding-guide
# required_version: 2.7.0

enabled_site_setting :onboarding_guide_enabled

module ::DiscourseOnboardingGuide
  PLUGIN_NAME = "discourse-onboarding-guide"

  ASSIGNED_VERSION_FIELD = "onboarding_guide_assigned_version"
  COMPLETED_VERSION_FIELD = "onboarding_guide_completed_version"
  PROGRESS_FIELD = "onboarding_guide_progress"
end
