# frozen_string_literal: true

module ::DiscourseOnboardingGuide
  class OnboardingController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    def show
      render_json_dump(StateResolver.state_for(current_user))
    end

    def progress
      current_user.upsert_custom_fields(
        DiscourseOnboardingGuide::PROGRESS_FIELD => progress_params.to_h.to_json,
      )
      current_user.save_custom_fields

      render json: success_json
    end

    def preferences
      PreferenceUpdater.update!(current_user, preference_items_params)
      render json: success_json
    end

    def complete
      raise Discourse::InvalidParameters.new(:version) if params[:version].to_i != StateResolver.current_version

      progress = StateResolver.progress_for(current_user)
      unless StateResolver::STEP_KEYS.all? { |step| progress[step] == true }
        return render_json_error(I18n.t("invalid_params"), status: 422)
      end

      current_user.upsert_custom_fields(
        DiscourseOnboardingGuide::COMPLETED_VERSION_FIELD => StateResolver.current_version,
      )
      current_user.save_custom_fields

      render json: success_json
    end

    private

    def progress_params
      raw_progress = params.require(:progress).permit(*StateResolver::STEP_KEYS, :current_step, :version)
      boolean_type = ActiveModel::Type::Boolean.new

      raw_progress.to_h.tap do |progress|
        StateResolver::STEP_KEYS.each do |step|
          next unless progress.key?(step)

          progress[step] = boolean_type.cast(progress[step])
        end
      end
    end

    def preference_items_params
      raw_items = params.require(:items)
      raw_items = raw_items.to_unsafe_h.values if raw_items.is_a?(ActionController::Parameters)

      Array.wrap(raw_items).map do |item|
        item = item.to_unsafe_h if item.is_a?(ActionController::Parameters)
        ActionController::Parameters.new(item).permit(:id, :type, :state).to_h.symbolize_keys
      end
    end
  end
end
