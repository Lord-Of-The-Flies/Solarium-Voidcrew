import type {
  FeatureChoiced,
  FeatureChoicedServerData,
  FeatureValueProps,
} from '../../base';
import { FeatureDropdownInput } from '../../dropdowns';

// Base game and ERP species features that are not covered by the skyrat/bubber
// feature packs (they use `feature_horns`, `feature_snout`, ... instead of the
// upstream `feature_lizard_*` keys). Without these the preferences menu renders
// "Feature X is not recognized" for every selected non-human species.

const choicedFeature = (
  name: string,
): FeatureChoiced => ({
  name,
  component: (
    props: FeatureValueProps<string, string, FeatureChoicedServerData>,
  ) => {
    return <FeatureDropdownInput buttons {...props} />;
  },
});

export const hairstyle_name = choicedFeature('Hairstyle');
export const facial_style_name = choicedFeature('Facial hair');

export const feature_ethcolor = choicedFeature('Ethereal color');

export const feature_lizard_body_markings = choicedFeature('Body markings');
export const feature_lizard_frills = choicedFeature('Frills');
export const feature_lizard_horns = choicedFeature('Horns');
export const feature_lizard_snout = choicedFeature('Snout');

export const feature_moth_wings = choicedFeature('Moth wings');
export const feature_mushperson_cap = choicedFeature('Cap');
export const feature_pod_hair = choicedFeature('Pod hair');

export const feature_halo = choicedFeature('Halo');
