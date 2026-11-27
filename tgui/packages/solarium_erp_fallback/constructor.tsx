// VOIDCREW EDIT: SOLARIUM - public layout when the ERP asset package is absent.
import {
  getRandomization,
  PreferenceList,
} from 'tgui/interfaces/PreferencesMenu/CharacterPreferences/MainPage';
import type { ServerData } from 'tgui/interfaces/PreferencesMenu/types';

export function CategoryPreferences(props: {
  characterPreferences: object;
  contextualPreferences: Record<string, unknown>;
  nonContextualPreferences: Record<string, unknown>;
  serverData: ServerData | undefined;
  randomBodyEnabled: boolean;
}) {
  return (
    <>
      {[props.contextualPreferences, props.nonContextualPreferences].map(
        (preferences, index) => (
          <PreferenceList
            key={index}
            preferences={preferences}
            randomizations={getRandomization(preferences, props.serverData, props.randomBodyEnabled)}
            maxHeight="auto"
          />
        ),
      )}
    </>
  );
}
