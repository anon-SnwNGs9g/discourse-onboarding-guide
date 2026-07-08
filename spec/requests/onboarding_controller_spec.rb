# frozen_string_literal: true

RSpec.describe DiscourseOnboardingGuide::OnboardingController, type: :request do
  fab!(:user)
  fab!(:group) { Fabricate(:group, name: "opt-in-group") }
  fab!(:tutorial_category) { Fabricate(:category, slug: "tutorial") }
  fab!(:category) { Fabricate(:category, slug: "announcements") }
  fab!(:tag) { Fabricate(:tag, name: "quiet-tag") }

  before do
    enable_current_plugin
    SiteSetting.onboarding_guide_enabled = true
    SiteSetting.onboarding_guide_version = 3
    SiteSetting.onboarding_guide_target_groups = group.id.to_s
    SiteSetting.onboarding_guide_tutorial_category_slug = tutorial_category.slug
    SiteSetting.onboarding_guide_preference_items_json =
      [
        {
          summary: "Group 1",
          items: [
            { type: "category", slug: category.slug, label: "Announcements" },
          ],
        },
        {
          summary: "Group 2",
          items: [
            { type: "tag", name: tag.name, label: "Quiet tag" },
          ],
        },
      ].to_json
  end

  it "returns grouped preference items" do
    sign_in(user)
    get "/onboarding-guide/preference-items.json"

    expect(response.status).to eq(200)
    items = response.parsed_body["items"]
    expect(items.size).to eq(2)
    expect(items[0]["summary"]).to eq("Group 1")
    expect(items[0]["items"].size).to eq(1)
    expect(items[0]["items"][0]["label"]).to eq("Announcements")
    expect(items[1]["summary"]).to eq("Group 2")
    expect(items[1]["items"].size).to eq(1)
    expect(items[1]["items"][0]["label"]).to eq("Quiet tag")
  end

  it "assigns new users and exposes required state" do
    DiscourseOnboardingGuide::AssignmentManager.assign_new_user!(user)

    sign_in(user)
    get "/onboarding-guide/preference-items.json"

    expect(response.status).to eq(200)
  end

  it "assigns when joining a configured group" do
    DiscourseEvent.trigger(:user_added_to_group, user, group, automatic: false)

    expect(user.custom_fields[DiscourseOnboardingGuide::ASSIGNED_VERSION_FIELD].to_i).to eq(3)
  end

  it "updates preferences and completes the flow" do
    DiscourseOnboardingGuide::AssignmentManager.assign_new_user!(user)
    sign_in(user)

    post "/onboarding-guide/preferences", params: {
      items: [
        { id: category.id, type: "category", state: "muted" },
        { id: tag.id, type: "tag", state: "tracking" },
      ],
    }
    expect(response.status).to eq(200)
    expect(CategoryUser.find_by(user: user, category: category).notification_level).to eq(
      CategoryUser.notification_levels[:muted],
    )
    expect(TagUser.find_by(user: user, tag: tag).notification_level).to eq(
      TagUser.notification_levels[:tracking],
    )

    post "/onboarding-guide/progress", params: {
      progress: {
        pledges: true,
        flagging: true,
        username: true,
        preferences: true,
        tutorials: true,
        current_step: "tutorials",
      },
    }
    expect(response.status).to eq(200)

    post "/onboarding-guide/complete", params: { version: 3 }
    expect(response.status).to eq(200)
    expect(user.reload.custom_fields[DiscourseOnboardingGuide::COMPLETED_VERSION_FIELD].to_i).to eq(3)
  end

  it "rejects completion with mismatched version" do
    DiscourseOnboardingGuide::AssignmentManager.assign_new_user!(user)
    sign_in(user)

    post "/onboarding-guide/progress", params: {
      progress: { pledges: true, flagging: true, username: true, preferences: true, tutorials: true, current_step: "tutorials", version: 3 },
    }
    expect(response.status).to eq(200)

    post "/onboarding-guide/complete", params: { version: 99 }
    expect(response.status).to eq(422)
  end

  it "rejects completion when progress is incomplete" do
    DiscourseOnboardingGuide::AssignmentManager.assign_new_user!(user)
    sign_in(user)

    post "/onboarding-guide/progress", params: {
      progress: { pledges: true, current_step: "pledges", version: 3 },
    }
    expect(response.status).to eq(200)

    post "/onboarding-guide/complete", params: { version: 3 }
    expect(response.status).to eq(422)
  end

  it "rejects preference update with invalid item type" do
    DiscourseOnboardingGuide::AssignmentManager.assign_new_user!(user)
    sign_in(user)

    post "/onboarding-guide/preferences", params: {
      items: [{ id: 1, type: "invalid_type", state: "muted" }],
    }
    expect(response.status).to eq(422)
  end

  it "rejects preference update with invalid state" do
    DiscourseOnboardingGuide::AssignmentManager.assign_new_user!(user)
    sign_in(user)

    post "/onboarding-guide/preferences", params: {
      items: [{ id: category.id, type: "category", state: "super_duper" }],
    }
    expect(response.status).to eq(422)
  end

  it "handles corrupted progress JSON gracefully" do
    DiscourseOnboardingGuide::AssignmentManager.assign_new_user!(user)
    user.upsert_custom_fields(DiscourseOnboardingGuide::PROGRESS_FIELD => "corrupted")
    user.save_custom_fields
    sign_in(user)

    post "/onboarding-guide/progress", params: {
      progress: { pledges: true, version: 3 },
    }
    expect(response.status).to eq(200)
  end
end
