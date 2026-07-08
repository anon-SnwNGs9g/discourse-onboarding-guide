import Component from "@glimmer/component";
import { fn, get } from "@ember/helper";
import { on } from "@ember/modifier";
import { modifier } from "ember-modifier";
import HomeLogo from "discourse/components/header/home-logo";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import OnboardingGuidePledges from "./onboarding-guide-pledges";
import OnboardingGuideFlagging from "./onboarding-guide-flagging";
import OnboardingGuideUsername from "./onboarding-guide-username";
import OnboardingGuidePreferences from "./onboarding-guide-preferences";
import OnboardingGuideTutorials from "./onboarding-guide-tutorials";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { eq } from "discourse/truth-helpers";
import { AUTO_GROUPS } from "discourse/lib/constants";
import { i18n } from "discourse-i18n";
import { sanitize } from "discourse/lib/text";
import bodyClass from "discourse/helpers/body-class";
const setHtml = modifier((element, [html, onLinkClick]) => {
  element.innerHTML = sanitize(html);

  const handler = (e) => {
    const link = e.target.closest("a");
    if (link) {
      e.preventDefault();
      onLinkClick();
    }
  };

  element.addEventListener("click", handler);
  return () => element.removeEventListener("click", handler);
});

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
  @service site;
  @service siteSettings;

  @tracked state = null;
  @tracked guideOpen = false;
  @tracked activeStep = "pledges";
  @tracked selectedPreferences = {};
  @tracked pledgeInputs = {};
  @tracked sampleFlagClicked = false;
  @tracked pmSidebarOpen = false;
  @tracked pmMoreOpen = false;
  @tracked pmGroupsOpen = false;
  @tracked pmMessageClicked = false;
  @tracked forceOpen = false;
  @tracked overlay = null; // { title, url } or null

  constructor() {
    super(...arguments);
    this.loadState();
  }

  get showBubble() {
    return !this.guideOpen && this.currentUser && (this.state?.required || this.forceOpen);
  }

  get showGuide() {
    return this.guideOpen;
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

  get currentStepNumber() {
    return this.currentStepIndex + 1;
  }

  get canCloseForNow() {
    return this.activeStep !== "pledges" || this.state?.progress?.pledges;
  }

  get clickableSteps() {
    if (!this.state?.progress) return [this.steps[0]];
    const firstUncompleted = this.steps.find(
      (step) => !this.state.progress[step],
    );
    return firstUncompleted
      ? this.steps.slice(0, this.steps.indexOf(firstUncompleted) + 1)
      : this.steps;
  }

  get currentStepLabel() {
    return this.stepLabel(this.activeStep);
  }

  get siteCategory() {
    return this.site.categories?.find((c) => c.slug === this.state?.tutorial_category?.slug);
  }

  get flatPreferenceItems() {
    return (this.state?.preference_items || []).flatMap((g) => g.items);
  }

  get moderatorsGroupName() {
    return this.site.groups?.find((g) => g.id === AUTO_GROUPS.moderators.id)?.name || "moderators";
  }

  @action
  preferenceItemCategory(item) {
    if (item.type !== "category") return null;
    return this.site.categories?.find((c) => c.slug === item.key);
  }

  get canContinue() {
    if (this.state?.progress?.[this.activeStep]) {
      return true;
    }
    switch (this.activeStep) {
      case "pledges":
        return (this.state?.pledges || []).every(
          (pledge, index) => this.pledgeInputs[index] === pledge
        );
      case "flagging":
        return this.sampleFlagClicked && this.pmMessageClicked;
      default:
        return true;
    }
  }

  get continueHint() {
    if (!this.canContinue) {
      if (this.activeStep === "flagging") {
        return i18n("onboarding_guide.flagging.continue_hint");
      }
      if (this.activeStep === "pledges") {
        return i18n("onboarding_guide.pledges.helper");
      }
    }
  }

  get isLastStep() {
    return this.currentStepIndex === this.steps.length - 1;
  }

  get isFirstStep() {
    return this.currentStepIndex <= 0;
  }

  async loadState() {
    if (!this.currentUser || !this.siteSettings.onboarding_guide_enabled) {
      return;
    }

    try {
      const prefData = await ajax("/onboarding-guide/preference-items");
      const progress = this.parseProgress();
      const catSlug = this.siteSettings.onboarding_guide_tutorial_category_slug;
      const cat = catSlug
        ? this.site.categories?.find((c) => c.slug === catSlug)
        : null;

      this.state = {
        required: this.currentUser.onboarding_guide_required,
        current_version: this.siteSettings.onboarding_guide_version,
        completed_version: parseInt(
          this.currentUser.custom_fields?.onboarding_guide_completed_version || "0",
        ),
        assigned:
          parseInt(
            this.currentUser.custom_fields?.onboarding_guide_assigned_version || "0",
          ) > 0,
        progress,
        pledges: this.parsePledges(),
        tutorial_category: cat
          ? {
              id: cat.id,
              name: cat.name,
              slug: cat.slug,
              url: `/c/${cat.slug}/${cat.id}`,
            }
          : null,
        preference_items: prefData.items,
      };

      this.activeStep =
        progress.current_step ||
        this.steps.find((step) => !progress[step]) ||
        "pledges";

      this.selectedPreferences = Object.fromEntries(
        this.flatPreferenceItems.map((item) => [
          this.preferenceKey(item),
          item.state,
        ])
      );

      if (sessionStorage.getItem("discourse-onboarding-guide-force-open") === "1") {
        sessionStorage.removeItem("discourse-onboarding-guide-force-open");
        this.forceOpen = true;
        this.guideOpen = true;
        this.activeStep = this.steps[0];
      } else if (
        this.state.required &&
        this.state.completed_version < this.state.current_version &&
        sessionStorage.getItem(STORAGE_KEY) !== "1"
      ) {
        this.guideOpen = true;
      } else {
        this.guideOpen =
          this.state.required && sessionStorage.getItem(STORAGE_KEY) !== "1";
      }
    } catch (error) {
      popupAjaxError(error);
    }
  }

  parseProgress() {
    try {
      const raw = this.currentUser.custom_fields?.onboarding_guide_progress;
      const parsed = typeof raw === "object" ? raw : JSON.parse(raw || "{}");
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
        return {};
      }
      if (
        parseInt(parsed.version, 10) !==
        this.siteSettings.onboarding_guide_version
      ) {
        return {};
      }
      return Object.fromEntries(
        Object.entries(parsed).filter(([k]) =>
          [...this.steps, "current_step", "version"].includes(k),
        ),
      );
    } catch {
      return {};
    }
  }

  parsePledges() {
    try {
      return JSON.parse(this.siteSettings.onboarding_guide_pledges_json);
    } catch {
      return [];
    }
  }

  @action
  stepLabel(step) {
    return i18n(`onboarding_guide.steps.${step}`);
  }

  @action
  preferenceKey(item) {
    return `${item.type}:${item.id}`;
  }

  @action
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
  markPmMessageClicked() {
    this.pmMessageClicked = true;
  }

  @action
  togglePmSidebar() {
    this.pmSidebarOpen = !this.pmSidebarOpen;
    if (!this.pmSidebarOpen) {
      this.pmMoreOpen = false;
      this.pmGroupsOpen = false;
    }
  }

  @action
  togglePmMore() {
    if (!this.pmSidebarOpen) {
      return;
    }

    this.pmMoreOpen = !this.pmMoreOpen;
    if (!this.pmMoreOpen) {
      this.pmGroupsOpen = false;
    }
  }

  @action
  openPmGroups() {
    this.pmSidebarOpen = true;
    this.pmMoreOpen = false;
    this.pmGroupsOpen = true;
  }

  @action
  closeForNow() {
    this.guideOpen = false;
    this.forceOpen = false;
    sessionStorage.setItem(STORAGE_KEY, "1");
  }

  @action
  reopen() {
    this.guideOpen = true;
    sessionStorage.removeItem(STORAGE_KEY);
  }

  @action
  async openOverlay(title, url, event) {
    event?.preventDefault();
    try {
      const html = await ajax(url, { dataType: "html" });
      const doc = new DOMParser().parseFromString(html, "text/html");
      const container =
        doc.querySelector(".container") ||
        doc.querySelector(".contents") ||
        doc.querySelector("#main-outlet") ||
        doc.querySelector("body");
      if (container) {
        container.querySelectorAll("nav, ul.nav, ul.nav-pills, .nav-stacked, .faq-tabs")
          .forEach((el) => el.remove());
      }
      this.overlay = { title, html: container?.innerHTML || "" };
    } catch {
      this.openUrl(url);
    }
  }

  @action
  closeOverlay() {
    this.overlay = null;
  }

  @action
  openUrl(url, event) {
    event?.preventDefault();
    event?.stopPropagation();
    this.guideOpen = false;
    sessionStorage.setItem(STORAGE_KEY, "1");
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
      version: this.state.current_version,
      [this.activeStep]: true,
    };

    try {
      if (this.activeStep === "preferences") {
        await ajax("/onboarding-guide/preferences", {
          method: "POST",
          data: {
            items: this.flatPreferenceItems.map((item) => ({
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
        this.guideOpen = false;
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

  @action
  async previous() {
    if (this.isFirstStep) {
      return;
    }

    const previousStep = this.steps[this.currentStepIndex - 1];
    const progress = {
      ...(this.state.progress || {}),
      version: this.state.current_version,
      current_step: previousStep,
    };
    try {
      await ajax("/onboarding-guide/progress", {
        method: "POST",
        data: { progress },
      });

      this.state = { ...this.state, progress };
      this.activeStep = previousStep;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  isStepClickable(step) {
    return this.clickableSteps.includes(step);
  }

  @action
  jumpToStep(step) {
    if (!this.clickableSteps.includes(step) || step === this.activeStep) {
      return;
    }
    this.activeStep = step;
  }

  @action
  preferenceItemUrl(item) {
    return item.type === "category"
      ? `/c/${item.key}/${item.id}`
      : `/tag/${item.key}`;
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
      {{bodyClass "onboarding-guide-active"}}
      <div class="onboarding-guide-page">
        <div class="onboarding-guide-page__header">
          <div class="onboarding-guide-page__header-left">
            <HomeLogo @minimized={{true}} />
            <h2 class="onboarding-guide-page__title">{{i18n "onboarding_guide.title"}}</h2>
          </div>
          <button
            type="button"
            class="btn btn-default"
            {{on "click" this.closeForNow}}
          >
            {{dIcon "times"}}
          </button>
        </div>

        <div class="onboarding-guide-page__body">
          <div class="onboarding-guide-page__step-heading">
            <span class="onboarding-guide-page__step-number">{{this.currentStepNumber}}/{{this.steps.length}}</span>
            <span class="onboarding-guide-page__step-label">{{this.currentStepLabel}}</span>
          </div>
          <div class="onboarding-guide-progress">
            {{#each this.steps as |step|}}
              <div
                class="onboarding-guide-progress__item
                  {{if (eq step this.activeStep) "is-active"}}
                  {{if (get this.state.progress step) "is-completed"}}
                  {{if (this.isStepClickable step) "is-clickable"}}"
                role={{if (this.isStepClickable step) "button"}}
                {{on "click" (fn this.jumpToStep step)}}
              >
                <div
                  class="onboarding-guide-progress__dot"
                  title={{this.stepLabel step}}
                  aria-label={{this.stepLabel step}}
                >
                  {{#if (get this.state.progress step)}}
                    {{dIcon "check"}}
                  {{/if}}
                </div>
              </div>
            {{/each}}
          </div>

          {{#if (eq this.activeStep "pledges")}}
            <OnboardingGuidePledges
              @pledges={{this.state.pledges}}
              @pledgeInputs={{this.pledgeInputs}}
              @updatePledge={{this.updatePledge}}
              @openOverlay={{this.openOverlay}}
            />
          {{else if (eq this.activeStep "flagging")}}
            <OnboardingGuideFlagging
              @sampleFlagClicked={{this.sampleFlagClicked}}
              @pmSidebarOpen={{this.pmSidebarOpen}}
              @pmMoreOpen={{this.pmMoreOpen}}
              @pmGroupsOpen={{this.pmGroupsOpen}}
              @pmMessageClicked={{this.pmMessageClicked}}
              @moderatorsGroupName={{this.moderatorsGroupName}}
              @markSampleFlagged={{this.markSampleFlagged}}
              @markPmMessageClicked={{this.markPmMessageClicked}}
              @togglePmSidebar={{this.togglePmSidebar}}
              @togglePmMore={{this.togglePmMore}}
              @openPmGroups={{this.openPmGroups}}
              @openUrl={{this.openUrl}}
            />
          {{else if (eq this.activeStep "username")}}
            <OnboardingGuideUsername @openUrl={{this.openUrl}} />
          {{else if (eq this.activeStep "preferences")}}
            <OnboardingGuidePreferences
              @preferenceItems={{this.state.preference_items}}
              @preferenceItemCategory={{this.preferenceItemCategory}}
              @preferenceItemUrl={{this.preferenceItemUrl}}
              @selectedState={{this.selectedState}}
              @choosePreference={{this.choosePreference}}
              @notificationStates={{this.notificationStates}}
              @openUrl={{this.openUrl}}
            />
          {{else}}
            <OnboardingGuideTutorials
              @title={{this.siteSettings.title}}
              @tutorialCategory={{this.state.tutorial_category}}
              @siteCategory={{this.siteCategory}}
              @openUrl={{this.openUrl}}
            />
          {{/if}}
        </div>

        <div class="onboarding-guide-page__footer">
          <div class="onboarding-guide-footer__left">
            {{#if this.canCloseForNow}}
              <button
                type="button"
                class="btn btn-default"
                {{on "click" this.closeForNow}}
              >
                {{i18n "onboarding_guide.close_for_now"}}
              </button>
            {{/if}}
          </div>
          <div class="onboarding-guide-footer__right">
            {{#if this.continueHint}}
              <span class="onboarding-guide-footer__hint">
                {{this.continueHint}}
              </span>
            {{/if}}
            <button
              type="button"
              class="btn btn-default"
              disabled={{this.isFirstStep}}
              {{on "click" this.previous}}
            >
              {{i18n "onboarding_guide.previous"}}
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
        </div>
      </div>


      {{#if this.overlay}}
        <div class="onboarding-guide-overlay">
          <div class="onboarding-guide-overlay__header">
            <button
              type="button"
              class="btn btn-default"
              {{on "click" this.closeOverlay}}
            >
              {{dIcon "chevron-left"}}
              {{i18n "onboarding_guide.previous"}}
            </button>
            <h3 class="onboarding-guide-overlay__title">{{this.overlay.title}}</h3>
            <button
              type="button"
              class="btn btn-default"
              {{on "click" this.closeOverlay}}
            >
              {{dIcon "times"}}
            </button>
          </div>
          <div class="onboarding-guide-overlay__body" {{setHtml this.overlay.html this.closeOverlay}}></div>
        </div>
      {{/if}}
    {{/if}}
  </template>
}
