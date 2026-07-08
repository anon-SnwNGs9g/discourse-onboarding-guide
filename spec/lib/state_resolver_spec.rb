# frozen_string_literal: true

RSpec.describe DiscourseOnboardingGuide::StateResolver do
  fab!(:user)

  before do
    SiteSetting.onboarding_guide_enabled = true
    SiteSetting.onboarding_guide_version = 5
  end

  describe ".progress_for" do
    it "returns empty hash for missing custom field" do
      result = described_class.progress_for(user)
      expect(result).to eq({})
    end

    it "returns empty hash for corrupted JSON" do
      user.upsert_custom_fields(
        DiscourseOnboardingGuide::PROGRESS_FIELD => "not-json",
      )
      user.save_custom_fields
      result = described_class.progress_for(user)
      expect(result).to eq({})
    end

    it "returns empty hash when version does not match" do
      user.upsert_custom_fields(
        DiscourseOnboardingGuide::PROGRESS_FIELD => { pledges: true, version: 3 }.to_json,
      )
      user.save_custom_fields
      result = described_class.progress_for(user)
      expect(result).to eq({})
    end

    it "parses valid progress and coerces booleans" do
      user.upsert_custom_fields(
        DiscourseOnboardingGuide::PROGRESS_FIELD => {
          pledges: true,
          flagging: false,
          current_step: "username",
          version: 5,
        }.to_json,
      )
      user.save_custom_fields
      result = described_class.progress_for(user)
      expect(result["pledges"]).to be true
      expect(result["flagging"]).to be false
      expect(result["current_step"]).to eq("username")
    end

    it "strips keys outside the expected set" do
      user.upsert_custom_fields(
        DiscourseOnboardingGuide::PROGRESS_FIELD => {
          pledges: true,
          stray_key: "nope",
          version: 5,
        }.to_json,
      )
      user.save_custom_fields
      result = described_class.progress_for(user)
      expect(result).not_to have_key("stray_key")
    end
  end

  describe ".required_for?" do
    it "returns true when enabled, assigned, and version not completed" do
      described_class.assign!(user)
      expect(described_class.required_for?(user)).to be true
    end

    it "returns false when plugin is disabled" do
      SiteSetting.onboarding_guide_enabled = false
      described_class.assign!(user)
      expect(described_class.required_for?(user)).to be false
    end

    it "returns false when user is not assigned" do
      expect(described_class.required_for?(user)).to be false
    end

    it "returns false when user already completed" do
      described_class.assign!(user)
      user.upsert_custom_fields(
        DiscourseOnboardingGuide::COMPLETED_VERSION_FIELD => 5,
      )
      user.save_custom_fields
      expect(described_class.required_for?(user)).to be false
    end
  end
end
