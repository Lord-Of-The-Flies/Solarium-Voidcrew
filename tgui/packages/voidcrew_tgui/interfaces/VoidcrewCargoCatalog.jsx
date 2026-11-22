/**
 * Voidcrew Cargo Catalog
 * A copy of TG's CargoCatalog with fixed price display.
 * The only change is using explicit inline styles for price visibility.
 */

import { sortBy } from 'es-toolkit';
import { filter } from 'es-toolkit/compat';
import { useMemo, useState } from 'react';
import {
  BlockQuote,
  Button,
  Icon,
  ImageButton,
  Input,
  Modal,
  Section,
  Stack,
  Tabs,
  Tooltip,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';

import { useBackend, useSharedState } from '../../tgui/backend';

// Shuttle state constants (must match DM defines)
const CARGO_SHUTTLE_AWAY = 0;

const CATEGORY_LABELS = {
  Armory: 'Арсенал',
  'Canisters & Materials': 'Баллоны и материалы',
  'Costumes & Toys': 'Костюмы и игрушки',
  Emergency: 'Аварийное снаряжение',
  'Engine Construction': 'Строительство двигателей',
  Engineering: 'Инженерия',
  'Food & Hydroponics': 'Еда и гидропоника',
  Goods: 'Товары',
  Imports: 'Импорт',
  Livestock: 'Животные',
  Medical: 'Медицина',
  'Miscellaneous Supplies': 'Разное снабжение',
  Outsourced: 'Аутсорсинг',
  Science: 'Наука',
  Security: 'Охрана',
  Service: 'Сервис',
  'Ship Combat': 'Корабельный бой',
  'Vending Restocks': 'Пополнение автоматов',
};

const categoryLabel = (name) => CATEGORY_LABELS[name] || name;

// Inline search function to avoid import issues
function searchForSupplies(supplies, search) {
  const lowerSearch = search.toLowerCase();
  const flatMapped = supplies.flatMap((category) => category.packs || []);
  const filtered = filter(
    flatMapped,
    (pack) =>
      pack.name?.toLowerCase().includes(lowerSearch) ||
      pack.desc?.toLowerCase().includes(lowerSearch),
  );
  return filtered.slice(0, 25);
}

// Inline SearchBar component
function SearchBar(props) {
  const {
    expensive,
    onSearch,
    placeholder = 'Поиск...',
    query = '',
  } = props;

  return (
    <Stack fill>
      <Stack.Item align="center">
        <Icon name="search" />
      </Stack.Item>
      <Stack.Item grow>
        <Input
          expensive={expensive}
          fluid
          onChange={onSearch}
          placeholder={placeholder}
          value={query}
        />
      </Stack.Item>
    </Stack>
  );
}

export function VoidcrewCargoCatalog(props) {
  const { data } = useBackend();
  const { express } = props;

  // `data` is a fresh object on every backend push, so Object.values() here would hand
  // back a new array ~every second and invalidate the packs memo below - re-sorting and
  // re-rendering the whole catalog on every tick. `data.supplies` itself is static data,
  // so it keeps a stable reference across partial updates; key the memo on that.
  const supplies = useMemo(() => Object.values(data.supplies || {}), [
    data.supplies,
  ]);
  const [showContents, setShowContents] = useState('');
  const [searchText, setSearchText] = useSharedState('search_text', '');
  const [activeSupplyName, setActiveSupplyName] = useSharedState(
    'supply',
    supplies[0]?.name,
  );

  const packs = useMemo(() => {
    let fetched;

    if (activeSupplyName === 'search_results') {
      fetched = searchForSupplies(supplies, searchText);
    } else {
      fetched = supplies.find(
        (supply) => supply.name === activeSupplyName,
      )?.packs;
    }

    if (!fetched) return [];

    fetched = sortBy(fetched, [(pack) => pack.name]);

    return fetched;
  }, [activeSupplyName, supplies, searchText]);

  return (
    <>
      {!!showContents && (
        <CatalogPackInfo
          packs={packs}
          name={showContents}
          closeContents={setShowContents}
        />
      )}
      <Stack fill g={0}>
        <Stack.Item grow mr={-0.33}>
          <Section fill>
            <CatalogTabs
              express={express}
              activeSupplyName={activeSupplyName}
              categories={supplies}
              searchText={searchText}
              setActiveSupplyName={setActiveSupplyName}
              setSearchText={setSearchText}
            />
          </Section>
        </Stack.Item>
        <Stack.Divider />
        <Stack.Item grow={express ? 2 : 3}>
          <Section fill scrollable>
            <CatalogList packs={packs} openContents={setShowContents} />
          </Section>
        </Stack.Item>
      </Stack>
    </>
  );
}

function CatalogTabs(props) {
  const { act, data } = useBackend();
  const {
    activeSupplyName,
    categories,
    searchText,
    setActiveSupplyName,
    setSearchText,
    express,
  } = props;
  const { self_paid } = data;

  const sorted = useMemo(
    () => sortBy(categories, [(supply) => supply.name]),
    [categories],
  );

  return (
    <Stack fill vertical>
      <Stack.Item>
        <SearchBar
          expensive
          query={searchText}
          onSearch={(value) => {
            if (value === searchText) {
              return;
            }

            if (value.length) {
              setActiveSupplyName('search_results');
            } else if (activeSupplyName === 'search_results') {
              setActiveSupplyName(sorted[0]?.name);
            }
            setSearchText(value);
          }}
        />
      </Stack.Item>
      <Stack.Item grow p={1} m={-1} mt={1} overflowY="auto">
        <Tabs vertical>
          <Tabs.Tab
            key="search_results"
            selected={activeSupplyName === 'search_results'}
            style={{ display: 'none' }}
          />

          {sorted.map((supply) => (
            <Tabs.Tab
              className="candystripe"
              color={supply.name === activeSupplyName ? 'green' : undefined}
              key={supply.name}
              selected={supply.name === activeSupplyName}
              onClick={() => {
                setActiveSupplyName(supply.name);
                setSearchText('');
              }}
            >
              <Stack justify="space-between">
                <span>{categoryLabel(supply.name)}</span>
                <span> {supply.packs?.length || 0}</span>
              </Stack>
            </Tabs.Tab>
          ))}
        </Tabs>
      </Stack.Item>
      <Stack.Item>
        {!express && (
          <Button
            fluid
            color={self_paid ? 'caution' : 'transparent'}
            icon={self_paid ? 'check-square-o' : 'square-o'}
            onClick={() => act('toggleprivate')}
            tooltip="Покупать товары на собственные средства."
            tooltipPosition="top"
          >
            Купить за свои средства
          </Button>
        )}
      </Stack.Item>
    </Stack>
  );
}

function CatalogList(props) {
  const { act, data } = useBackend();
  const {
    amount_by_name = {},
    max_order = 20,
    self_paid,
    app_cost,
    shuttle_state = CARGO_SHUTTLE_AWAY,
  } = data;
  const { packs = [], openContents } = props;
  // Once the shuttle is called the cart is a dispatched manifest - no more additions
  const cartLocked = shuttle_state !== CARGO_SHUTTLE_AWAY;

  return (
    <>
      {packs.map((pack) => {
        let color = '';
        const cost = pack.cost || 0;
        const digits = cost > 0 ? Math.floor(Math.log10(cost) + 1) : 1;
        if (self_paid) {
          color = 'yellow';
        } else if (digits >= 5 && digits <= 6) {
          color = 'orange';
        } else if (digits > 6) {
          color = 'bad';
        }

        const privateBuy = (self_paid && !pack.goody) || app_cost;
        const tooltipIcon = (content, icon, iconColor) => (
          <Stack.Item>
            <Tooltip content={content}>
              <Icon color={iconColor} name={icon} />
            </Tooltip>
          </Stack.Item>
        );

        return (
          <ImageButton
            key={pack.id}
            fluid
            dmIcon={pack.first_item_icon}
            dmIconState={pack.first_item_icon_state}
            imageSize={32}
            color={color}
            disabled={
              cartLocked || (amount_by_name[pack.name] || 0) >= max_order
            }
            buttonsAlt={
              <Button
                color="transparent"
                icon="info"
                onClick={() => openContents(pack.name)}
              />
            }
            onClick={() =>
              act('add', {
                id: pack.id,
              })
            }
          >
            <Stack fill textAlign="right">
              <Stack.Item grow textAlign="left">
                {pack.name}
              </Stack.Item>
              {/* No 'Restricted' lock marker: ship crates never arrive locked. */}
              {(!!pack.small_item || !!pack.contraband) && (
                <Stack.Item>
                  <Stack reverse>
                    {!!pack.small_item &&
                      tooltipIcon('Малый предмет', 'compress-alt', 'purple')}
                    {!!pack.contraband &&
                      tooltipIcon('Контрабанда', 'pastafarianism', 'bad')}
                  </Stack>
                </Stack.Item>
              )}
              {/* FIXED: Price display with explicit inline styles for visibility */}
              <Stack.Item
                align="center"
                width={6}
                style={{
                  color: '#FFD700',
                  fontWeight: 'bold',
                  fontSize: '0.9em',
                  textAlign: 'right',
                  paddingRight: '4px',
                }}
              >
                {formatMoney(cost)} кр
                {!!privateBuy && (
                  <div style={{ fontSize: '0.8em', opacity: 0.7 }}>
                    ({formatMoney(Math.round(cost * 1.1))} кр. свои)
                  </div>
                )}
              </Stack.Item>
            </Stack>
          </ImageButton>
        );
      })}
    </>
  );
}

function CatalogPackInfo(props) {
  const { name, packs, closeContents } = props;
  const pack = packs.find((p) => p.name === name);
  const contains = pack?.contains;

  return (
    <Modal p={1} width="50vw" height="50vh">
      <Stack fill vertical>
        <Stack.Item>
          <Section
            fill
            title={name}
            buttons={
              <Button
                icon="close"
                color="bad"
                onClick={() => closeContents('')}
              />
            }
          >
            <BlockQuote>{pack?.desc || 'Описание отсутствует.'}</BlockQuote>
          </Section>
        </Stack.Item>
        <Stack.Item m={0} grow>
          <Section fill scrollable>
            {contains && contains.length > 0 ? (
              contains.map((item) => (
                <ImageButton
                  key={item.name}
                  fluid
                  dmIcon={item.icon}
                  dmIconState={item.icon_state}
                  buttonsAlt={
                    !!item.amount && (
                      <Stack.Item backgroundColor="rgba(255, 255, 255, 0.1)">
                        x{item.amount}
                      </Stack.Item>
                    )
                  }
                  imageSize={32}
                >
                  <Stack fill>
                    <Stack.Item textAlign="left">{item.name}</Stack.Item>
                  </Stack>
                </ImageButton>
              ))
            ) : (
              <Stack fill vertical align="center" justify="center">
                <Stack.Item>
                  <Icon name="triangle-exclamation" size={6} color="orange" />
                </Stack.Item>
                <Stack.Item mt={2} color="label" textAlign="center">
                  {`Мы не можем найти информацию даже о примерном содержимом этого заказа.`}
                </Stack.Item>
              </Stack>
            )}
          </Section>
        </Stack.Item>
      </Stack>
    </Modal>
  );
}
