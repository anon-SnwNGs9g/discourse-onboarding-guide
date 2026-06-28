import { withPluginApi } from "discourse/lib/plugin-api";
import OnboardingGuideRoot from "../components/onboarding-guide-root";
import OnboardingGuideProfileButton from "../components/onboarding-guide-profile-button";

export default {
  name: "onboarding-guide",

  initialize() {
    withPluginApi("1.34.0", (api) => {
      api.renderInOutlet("above-site-header", OnboardingGuideRoot);
      api.renderInOutlet("user-profile-controls", OnboardingGuideProfileButton);
    });
  },
};
