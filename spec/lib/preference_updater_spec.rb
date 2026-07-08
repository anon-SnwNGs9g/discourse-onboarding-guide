# frozen_string_literal: true

RSpec.describe DiscourseOnboardingGuide::PreferenceUpdater do
  fab!(:user)
  fab!(:category) { Fabricate(:category) }
  fab!(:tag) { Fabricate(:tag) }

  before do
    SiteSetting.onboarding_guide_preference_items_json = [
      { summary: "G1", items: [{ type: "category", slug: category.slug, label: "Cat" }] },
      { summary: "G2", items: [{ type: "tag", name: tag.name, label: "Tag" }] },
    ].to_json
  end

  it "updates category notification level" do
    expect {
      described_class.update!(user, [{ type: "category", id: category.id, state: "muted" }])
    }.to change { CategoryUser.count }.by(1)
    expect(
      CategoryUser.find_by(user: user, category: category).notification_level,
    ).to eq(CategoryUser.notification_levels[:muted])
  end

  it "updates tag notification level" do
    expect {
      described_class.update!(user, [{ type: "tag", id: tag.id, state: "tracking" }])
    }.to change { TagUser.count }.by(1)
    expect(TagUser.find_by(user: user, tag: tag).notification_level).to eq(
      TagUser.notification_levels[:tracking],
    )
  end

  it "removes CategoryUser row when state is regular" do
    CategoryUser.create!(
      user: user,
      category: category,
      notification_level: CategoryUser.notification_levels[:watching_first_post],
    )
    expect(CategoryUser.where(user: user, category: category).count).to eq(1)
    described_class.update!(user, [{ type: "category", id: category.id, state: "regular" }])
    expect(CategoryUser.where(user: user, category: category).count).to eq(0)
  end

  it "raises on invalid state" do
    expect {
      described_class.update!(user, [{ type: "category", id: category.id, state: "invalid" }])
    }.to raise_error(Discourse::InvalidParameters)
  end

  it "raises on invalid type" do
    expect {
      described_class.update!(user, [{ type: "group", id: 1, state: "muted" }])
    }.to raise_error(Discourse::InvalidParameters)
  end

  it "raises when item is not in allowed list" do
    other_category = Fabricate(:category)
    expect {
      described_class.update!(user, [{ type: "category", id: other_category.id, state: "muted" }])
    }.to raise_error(Discourse::InvalidParameters)
  end
end
