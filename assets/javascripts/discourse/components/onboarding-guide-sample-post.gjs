import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { i18n } from "discourse-i18n";
import dIcon from "discourse/ui-kit/helpers/d-icon";

export default class OnboardingGuideSamplePost extends Component {
  @tracked flagged = false;
  @tracked menuOpen = false;

  get avatarLetter() {
    return i18n("onboarding_guide.flagging.sample_username")
      .trim()
      .charAt(0)
      .toUpperCase();
  }

  @action
  toggleMenu() {
    this.menuOpen = !this.menuOpen;
  }

  @action
  flagPost() {
    this.menuOpen = false;
    this.flagged = true;
    this.args.onFlag?.();
  }

  @action
  noop(event) {
    event?.preventDefault?.();
  }

  <template>
    <article class="onboarding-guide-sample-post" aria-label={{i18n "onboarding_guide.flagging.sample_username"}}>
      <div class="onboarding-guide-sample-post__header">
        <div class="onboarding-guide-sample-post__avatar">{{this.avatarLetter}}</div>
        <div class="onboarding-guide-sample-post__meta">
          <div class="onboarding-guide-sample-post__username">
            {{i18n "onboarding_guide.flagging.sample_username"}}
          </div>
        </div>
      </div>

      <div class="onboarding-guide-sample-post__body">
        <p>{{i18n "onboarding_guide.flagging.sample_body"}}</p>
      </div>

      <div class="onboarding-guide-sample-post__footer">
        <button
          type="button"
          class="btn-flat onboarding-guide-sample-post__action"
          {{on "click" this.noop}}
          aria-label={{i18n "onboarding_guide.flagging.like_label"}}
        >
          {{dIcon "heart"}}
        </button>

        {{#if this.menuOpen}}
          <button
            type="button"
            class="btn-flat onboarding-guide-sample-post__action"
            {{on "click" this.noop}}
            aria-label={{i18n "onboarding_guide.flagging.link_label"}}
          >
            {{dIcon "link"}}
          </button>

          <button
            type="button"
            class="btn-flat onboarding-guide-sample-post__action"
            {{on "click" this.flagPost}}
            aria-label={{i18n "onboarding_guide.flagging.flag_label"}}
          >
            {{dIcon "flag"}}
          </button>

          <button
            type="button"
            class="btn-flat onboarding-guide-sample-post__action"
            {{on "click" this.noop}}
            aria-label={{i18n "onboarding_guide.flagging.bookmark_label"}}
          >
            {{dIcon "bookmark"}}
          </button>
        {{else}}
          <button
            type="button"
            class="btn-flat onboarding-guide-sample-post__action"
            {{on "click" this.toggleMenu}}
            aria-label={{i18n "show_more"}}
          >
            {{dIcon "ellipsis"}}
          </button>
        {{/if}}

        <button
          type="button"
          class="btn-flat onboarding-guide-sample-post__action"
          {{on "click" this.noop}}
          aria-label={{i18n "onboarding_guide.flagging.reply_label"}}
        >
          {{dIcon "reply"}}
        </button>
      </div>

      {{#if this.flagged}}
        <div class="onboarding-guide-sample-post__flagged-note">
          {{i18n "onboarding_guide.flagging.completed"}}
        </div>
      {{/if}}
    </article>
  </template>
}
