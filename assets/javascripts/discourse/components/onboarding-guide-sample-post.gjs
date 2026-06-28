import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Post from "discourse/components/post";
import { i18n } from "discourse-i18n";

export default class OnboardingGuideSamplePost extends Component {
  @service currentUser;
  @service site;
  @service store;

  @tracked flagged = false;

  @cached
  get sampleUser() {
    const avatarTemplate =
      this.currentUser?.avatar_template || this.site.system_user_avatar_template;

    return this.store.createRecord("user", {
      id: -1000,
      username: i18n("onboarding_guide.flagging.sample_username"),
      name: i18n("onboarding_guide.flagging.sample_name"),
      avatar_template: avatarTemplate,
      staff: false,
      admin: false,
      moderator: false,
      can_send_private_message_to_user: false,
    });
  }

  @cached
  get sampleTopic() {
    return this.store.createRecord("topic", {
      id: -1000,
      slug: "onboarding-guide-sample-topic",
      title: i18n("onboarding_guide.flagging.sample_topic_title"),
      archetype: "regular",
      posts_count: 1,
      deleted: false,
      deleted_at: null,
      visible: true,
      details: {
        can_delete: false,
        can_edit_staff_notes: false,
        can_permanently_delete: false,
        can_publish_page: false,
        can_recover: false,
        created_by: {
          id: this.sampleUser.id,
        },
      },
    });
  }

  @cached
  get samplePost() {
    const post = this.store.createRecord("post", {
      id: -1000,
      post_number: 1,
      topic: this.sampleTopic,
      topic_id: this.sampleTopic.id,
      cooked: `<p>${i18n("onboarding_guide.flagging.sample_body")}</p>`,
      created_at: new Date(Date.now() - 30 * 60 * 1000),
      user: this.sampleUser,
      user_id: this.sampleUser.id,
      username: this.sampleUser.username,
      name: this.sampleUser.name,
      reply_count: 0,
      version: 1,
      read: true,
      via_email: false,
      wiki: false,
      hidden: false,
      deleted_at: null,
      user_deleted: false,
      can_edit: false,
      can_delete: false,
      can_recover: false,
      can_permanently_delete: false,
      can_see_hidden_post: false,
      can_view_edit_history: false,
      actions_summary: [],
    });

    Object.defineProperty(post, "canFlag", {
      configurable: true,
      get: () => true,
    });

    Object.defineProperty(post, "canBookmark", {
      configurable: true,
      get: () => false,
    });

    return post;
  }

  @action
  flagPost() {
    this.flagged = true;
    this.args.onFlag?.();
  }

  @action
  noop() {}

  <template>
    <div class="onboarding-guide-sample-post">
      <Post
        @post={{this.samplePost}}
        @canCreatePost={{true}}
        @replyToPost={{this.noop}}
        @showFlags={{this.flagPost}}
        @showLogin={{this.noop}}
      />

      {{#if this.flagged}}
        <div class="onboarding-guide-sample-post__flagged-note">
          {{i18n "onboarding_guide.flagging.completed"}}
        </div>
      {{/if}}
    </div>
  </template>
}
