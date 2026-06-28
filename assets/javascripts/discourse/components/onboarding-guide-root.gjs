import Component from "@glimmer/component";
import { concat, fn, get } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import OnboardingGuideSamplePost from "./onboarding-guide-sample-post";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const STORAGE_KEY = "discourse-onboarding-guide-dismissed-session";
const STEPS = ["pledges", "flagging", "username", "preferences", "tutorials"];
const NOTIFICATION_STATES = [
  "regular",
  "tracking",
  "watching_first_post",
  "muted",
];

export default class OnboardingGuideRoot extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked state = null;
  @tracked showModal = false;
  @tracked activeStep = "pledges";
  @tracked selectedPreferences = {};
  @tracked pledgeInputs = {};
  @tracked sampleFlagClicked = false;

  constructor() {
    super(...arguments);
    this.loadState();
  }

  get shouldRender() {
    return this.currentUser && this.state?.required;
  }

  get showBubble() {
    return this.shouldRender && !this.showModal;
  }

  get showGuide() {
    return this.shouldRender && this.showModal;
  }

  get steps() {
    return STEPS;
  }

  get notificationStates() {
    return NOTIFICATION_STATES;
  }

  get currentStepIndex() {
    return this.steps.indexOf(this.activeStep);
  }

  get currentStepLabel() {
    return this.stepLabel(this.activeStep);
  }

  get canContinue() {
    switch (this.activeStep) {
      case "pledges":
        return (this.state?.pledges || []).every(
          (pledge, index) => this.pledgeInputs[index] === pledge
        );
      case "flagging":
        return this.sampleFlagClicked;
      default:
        return true;
    }
  }

  get isLastStep() {
    return this.currentStepIndex === this.steps.length - 1;
  }

  async loadState() {
    if (!this.currentUser || !this.siteSettings.onboarding_guide_enabled) {
      return;
    }

    try {
      this.state = await ajax("/onboarding-guide/state.json");
      this.activeStep =
        this.state.progress?.current_step ||
        this.steps.find((step) => !this.state.progress?.[step]) ||
        "pledges";
      this.selectedPreferences = Object.fromEntries(
        (this.state.preference_items || []).map((item) => [
          this.preferenceKey(item),
          item.state,
        ])
      );
      this.showModal =
        this.state.required && sessionStorage.getItem(STORAGE_KEY) !== "1";
    } catch (error) {
      popupAjaxError(error);
    }
  }

  stepLabel(step) {
    return i18n(`onboarding_guide.steps.${step}`);
  }

  preferenceKey(item) {
    return `${item.type}:${item.id}`;
  }

  selectedState(item) {
    return this.selectedPreferences[this.preferenceKey(item)];
  }

  @action
  updatePledge(index, event) {
    this.pledgeInputs = { ...this.pledgeInputs, [index]: event.target.value };
  }

  @action
  markSampleFlagged() {
    this.sampleFlagClicked = true;
  }

  @action
  closeForNow() {
    this.showModal = false;
    sessionStorage.setItem(STORAGE_KEY, "1");
  }

  @action
  reopen() {
    this.showModal = true;
    sessionStorage.removeItem(STORAGE_KEY);
  }

  @action
  openUrl(url) {
    window.location.href = url;
  }

  @action
  choosePreference(item, state) {
    this.selectedPreferences = {
      ...this.selectedPreferences,
      [this.preferenceKey(item)]: state,
    };
  }

  @action
  async continue() {
    if (!this.canContinue) {
      return;
    }

    const progress = {
      ...(this.state.progress || {}),
      [this.activeStep]: true,
    };

    try {
      if (this.activeStep === "preferences") {
        await ajax("/onboarding-guide/preferences", {
          method: "POST",
          data: {
            items: (this.state.preference_items || []).map((item) => ({
              id: item.id,
              type: item.type,
              state: this.selectedState(item) || "regular",
            })),
          },
        });
      }

      if (this.isLastStep) {
        progress.current_step = this.activeStep;
        await ajax("/onboarding-guide/progress", {
          method: "POST",
          data: { progress },
        });
        await ajax("/onboarding-guide/complete", {
          method: "POST",
          data: { version: this.state.current_version },
        });

        this.state = { ...this.state, required: false, progress };
        this.showModal = false;
        sessionStorage.removeItem(STORAGE_KEY);
        return;
      }

      const nextStep = this.steps[this.currentStepIndex + 1];
      progress.current_step = nextStep;
      await ajax("/onboarding-guide/progress", {
        method: "POST",
        data: { progress },
      });

      this.state = { ...this.state, progress };
      this.activeStep = nextStep;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    {{#if this.showBubble}}
      <button
        type="button"
        class="onboarding-guide-bubble"
        {{on "click" this.reopen}}
      >
        {{i18n "onboarding_guide.reopen"}}
      </button>
    {{/if}}

    {{#if this.showGuide}}
      <DModal
        @title={{this.currentStepLabel}}
        @closeModal={{this.closeForNow}}
        class="onboarding-guide-modal"
      >
        <:body>
          <div class="onboarding-guide-progress">
            {{#each this.steps as |step|}}
              <span class={{if (eq step this.activeStep) "is-active" ""}}>
                {{this.stepLabel step}}
              </span>
            {{/each}}
          </div>

          {{#if (eq this.activeStep "pledges")}}
            <div class="onboarding-guide-links">
              <a href="/guidelines" target="_blank" rel="noopener noreferrer">
                {{i18n "onboarding_guide.pledges.guidelines"}}
              </a>
              <a href="/tos" target="_blank" rel="noopener noreferrer">
                {{i18n "onboarding_guide.pledges.tos"}}
              </a>
            </div>
            <p>{{i18n "onboarding_guide.pledges.helper"}}</p>
            {{#each this.state.pledges as |pledge index|}}
              <label class="onboarding-guide-field">
                <span>{{pledge}}</span>
                <input
                  type="text"
                  value={{get this.pledgeInputs index}}
                  {{on "input" (fn this.updatePledge index)}}
                />
              </label>
            {{/each}}
          {{else if (eq this.activeStep "flagging")}}
            <p>{{i18n "onboarding_guide.flagging.helper"}}</p>
            <OnboardingGuideSamplePost @onFlag={{this.markSampleFlagged}} />
            <div class="onboarding-guide-flagging-alt">
              <p>
                {{i18n
                  "onboarding_guide.flagging.pm_helper"
                  groupName=this.state.moderators_group_name
                }}
              </p>
              <ol class="onboarding-guide-flagging-steps">
                <li>{{i18n "onboarding_guide.flagging.pm_step_one"}}</li>
                <li>{{i18n "onboarding_guide.flagging.pm_step_two"}}</li>
                <li>
                  {{i18n
                    "onboarding_guide.flagging.pm_step_three"
                    groupName=this.state.moderators_group_name
                  }}
                </li>
              </ol>

              <div class="onboarding-guide-message-demo">
                <div class="onboarding-guide-message-demo__row">
                  <span class="onboarding-guide-message-demo__label">
                    {{i18n "onboarding_guide.flagging.pm_to_label"}}
                  </span>
                  <span class="onboarding-guide-message-demo__value">
                    @{{this.state.moderators_group_name}}
                  </span>
                </div>
                <div class="onboarding-guide-message-demo__row">
                  <span class="onboarding-guide-message-demo__label">
                    {{i18n "onboarding_guide.flagging.pm_title_label"}}
                  </span>
                  <span class="onboarding-guide-message-demo__value">
                    {{i18n "onboarding_guide.flagging.pm_title_example"}}
                  </span>
                </div>
                <div class="onboarding-guide-message-demo__body">
                  {{i18n "onboarding_guide.flagging.pm_body_example"}}
                </div>
              </div>
            </div>
          {{else if (eq this.activeStep "username")}}
            <p>{{i18n "onboarding_guide.username.helper"}}</p>
            <DButton
              @label="onboarding_guide.username.open_preferences"
              @action={{fn this.openUrl "/my/preferences/account"}}
            />
          {{else if (eq this.activeStep "preferences")}}
            <p>{{i18n "onboarding_guide.preferences.helper"}}</p>
            {{#each this.state.preference_items as |item|}}
              <div class="onboarding-guide-preference-item">
                <div class="onboarding-guide-preference-label">{{item.label}}</div>
                <div class="onboarding-guide-preference-options">
                  {{#each this.notificationStates as |state|}}
                    <button
                      type="button"
                      class={{if (eq (this.selectedState item) state) "is-selected" ""}}
                      {{on "click" (fn this.choosePreference item state)}}
                    >
                      {{i18n (concat "onboarding_guide.preferences." state)}}
                    </button>
                  {{/each}}
                </div>
              </div>
            {{/each}}
          {{else}}
            <p>{{i18n "onboarding_guide.tutorials.helper"}}</p>
            {{#if this.state.tutorial_category}}
              <DButton
                @label="onboarding_guide.tutorials.open_category"
                @action={{fn this.openUrl this.state.tutorial_category.url}}
              />
            {{/if}}
            <ul class="onboarding-guide-topics">
              {{#each this.state.tutorial_topics as |topic|}}
                <li><a href={{topic.url}}>{{topic.title}}</a></li>
              {{/each}}
            </ul>
          {{/if}}
        </:body>

        <:footer>
          <div class="onboarding-guide-footer">
            <button
              type="button"
              class="btn btn-default"
              {{on "click" this.closeForNow}}
            >
              {{i18n "onboarding_guide.close_for_now"}}
            </button>
            <button
              type="button"
              class="btn btn-primary"
              disabled={{if this.canContinue false true}}
              {{on "click" this.continue}}
            >
              {{#if this.isLastStep}}
                {{i18n "onboarding_guide.finish"}}
              {{else}}
                {{i18n "onboarding_guide.next"}}
              {{/if}}
            </button>
          </div>
        </:footer>
      </DModal>
    {{/if}}
  </template>
}
