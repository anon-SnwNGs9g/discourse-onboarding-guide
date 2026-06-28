# frozen_string_literal: true

module ::DiscourseOnboardingGuide
  class AssignmentManager
    class << self
      def assign_new_user!(user)
        assign!(user)
      end

      def assign_group_user!(user, group)
        return unless target_group_ids.include?(group.id)

        assign!(user)
      end

      def assign!(user)
        return if !SiteSetting.onboarding_guide_enabled || !user.human? || user.staged?

        user.upsert_custom_fields(
          DiscourseOnboardingGuide::ASSIGNED_VERSION_FIELD => [assigned_version(user), current_version].max,
        )
        user.save_custom_fields
      end

      def assigned_version(user)
        user.custom_fields[DiscourseOnboardingGuide::ASSIGNED_VERSION_FIELD].to_i
      end

      def current_version
        SiteSetting.onboarding_guide_version.to_i
      end

      def target_group_ids
        SiteSetting.onboarding_guide_target_groups_map
      end
    end
  end
end
