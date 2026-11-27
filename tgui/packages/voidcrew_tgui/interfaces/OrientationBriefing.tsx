import { useState } from 'react';
import {
  Box,
  Button,
  Icon,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Zone = {
  name: string;
  color: string;
  summary: string;
  rules: string[];
};

type ResearchNode = {
  name: string;
  desc: string;
};

type Data = {
  ship_name: string | null;
  combat_researched: BooleanLike;
  zones: Zone[];
  research_path: ResearchNode[];
};

type TabName = 'welcome' | 'zones' | 'combat';

const TABS: { id: TabName; label: string; icon: string }[] = [
  { id: 'welcome', label: 'Добро пожаловать', icon: 'hand-spock' },
  { id: 'zones', label: 'Зоны', icon: 'circle-half-stroke' },
  { id: 'combat', label: 'Корабельный бой', icon: 'crosshairs' },
];

export const OrientationBriefing = () => {
  const [tab, setTab] = useState<TabName>('welcome');

  return (
    <Window title="Добро пожаловать в Voidcrew" width={600} height={560}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs fluid>
              {TABS.map((entry) => (
                <Tabs.Tab
                  key={entry.id}
                  selected={tab === entry.id}
                  onClick={() => setTab(entry.id)}
                  icon={entry.icon}
                >
                  {entry.label}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {tab === 'welcome' && <WelcomeTab />}
            {tab === 'zones' && <ZonesTab />}
            {tab === 'combat' && <CombatTab />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

/** The reason this window exists at all: the server is being tested on you. */
const WelcomeTab = () => {
  const { act } = useBackend<Data>();

  return (
    <Section title="Сервер в раннем тестировании">
      <NoticeBox>
        Всё будет ломаться. Ожидайте баги, недоделанные функции и раунды, которые плохо заканчиваются не по вашей вине.
      </NoticeBox>
      <Box mb={1}>
        Обо всех поломках сообщайте <b>jackrip</b> в Discord: что вы делали и примерно когда — обычно этого достаточно, чтобы найти проблему в логах. Вики подробно описывает корабли, овермап, задания и всё остальное, что добавляет Voidcrew, — гораздо подробнее, чем это окно.
      </Box>
      <Stack mb={2}>
        <Stack.Item>
          <Button icon="comments" onClick={() => act('open_discord')}>
            Открыть Discord
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button icon="book" onClick={() => act('open_wiki')}>
            Открыть вики
          </Button>
        </Stack.Item>
      </Stack>
      <Box color="label">
        Вы управляете кораблём на овермапе. Берите контракты, добывайте ресурсы, торгуйте и исследуйте; чем дальше вы летите, тем выше оплата и тем хуже шансы. Две другие вкладки рассказывают, куда можно летать и как вооружить корабль.
      </Box>
    </Section>
  );
};

/** What the three overmap bands permit, straight off the defines that enforce it. */
const ZonesTab = () => {
  const { data } = useBackend<Data>();
  const { zones } = data;

  return (
    <Section title="Три кольца">
      <Box mb={2} color="label">
        Ваша консоль управления всегда показывает, в каком кольце вы находитесь. Пересечение границы занимает десять секунд, и его можно отменить до завершения.
      </Box>
      {zones.map((zone) => (
        <Box key={zone.name} mb={2}>
          <Box bold style={{ color: zone.color }}>
            <Icon name="circle" mr={1} />
            {zone.name}
          </Box>
          <Box mb={1}>{zone.summary}</Box>
          <Box ml={2}>
            {zone.rules.map((rule) => (
              <Box key={rule} color="label">
                • {rule}
              </Box>
            ))}
          </Box>
        </Box>
      ))}
      <NoticeBox mt={2}>
        Чем дальше, тем выше риск: метеоры, радиационные бури на планетах, враждебные экипажи и кое-что похуже.
      </NoticeBox>
    </Section>
  );
};

/** Why a new crew should not simply fly outward, and what fixes that. */
const CombatTab = () => {
  const { data } = useBackend<Data>();
  const { research_path, combat_researched, ship_name } = data;

  return (
    <Section title="Корабельное боевое снаряжение">
      <Box mb={2}>
        Щиты, турели, ракеты и интердикторы исследуются на вашем корабле, а не покупаются. Используйте консоль НИОКР, подключённую к исследовательскому серверу корабля; каждый узел открывает плату, которую вы печатаете и устанавливаете.
      </Box>
      {research_path.map((node) => (
        <Box key={node.name} mb={1}>
          <Box bold>{node.name}</Box>
          <Box color="label">{node.desc}</Box>
        </Box>
      ))}
      {combat_researched ? (
        <NoticeBox success mt={2}>
          {ship_name ?? 'Ваш корабль'} — системы шаттлового боя исследованы. Вы можете строить щиты и оружие, когда будете готовы.
        </NoticeBox>
      ) : (
        <NoticeBox danger mt={2}>
          {ship_name ?? 'Ваш корабль'} ещё не исследовал системы шаттлового боя: нет щитов и нечем отвечать. Берите контракты в среднем кольце, зарабатывайте исследовательские очки и не суйтесь во внешнее кольцо, пока не экипируетесь.
        </NoticeBox>
      )}
    </Section>
  );
};
