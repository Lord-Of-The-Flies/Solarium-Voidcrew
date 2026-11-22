import {
  AnimatedNumber,
  Box,
  Button,
  Input,
  LabeledList,
  ProgressBar,
  RestrictedInput,
  Section,
  Stack,
  Table,
  Tabs,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import { useBackend, useSharedState } from '../../tgui/backend';
import { Window } from '../../tgui/layouts';
import { VoidcrewCargoCatalog } from './VoidcrewCargoCatalog';

// Shuttle state constants (must match DM defines)
const CARGO_SHUTTLE_AWAY = 0;
const CARGO_SHUTTLE_ARRIVING = 1;
const CARGO_SHUTTLE_DOCKED = 2;
const CARGO_SHUTTLE_DEPARTING = 3;

const SHUTTLE_STATUS_LABELS = {
  Away: 'Вне станции',
  Arriving: 'Прибывает',
  Docked: 'Пристыкован',
  Departing: 'Отправляется',
};

export const VoidcrewCargo = () => {
  return (
    <Window width={800} height={750}>
      <Window.Content scrollable>
        <VoidcrewCargoContent />
      </Window.Content>
    </Window>
  );
};

export const VoidcrewCargoContent = () => {
  const { data } = useBackend();
  const [tab, setTab] = useSharedState('tab', 'catalog');
  const { cart = [], supplies = {}, history = [] } = data;
  const cart_length = cart.reduce((total, entry) => total + entry.amount, 0);
  const hasSupplies = Object.keys(supplies).length > 0;

  return (
    <Box>
      <VoidcrewCargoStatus />
      <Section fitted>
        <Tabs>
          <Tabs.Tab
            icon="list"
            selected={tab === 'catalog'}
            onClick={() => setTab('catalog')}
          > Каталог </Tabs.Tab>
          <Tabs.Tab
            icon="shopping-cart"
            textColor={tab !== 'cart' && cart_length > 0 && 'yellow'}
            selected={tab === 'cart'}
            onClick={() => setTab('cart')}
          >
            Корзина ({cart_length})
          </Tabs.Tab>
          <Tabs.Tab
            icon="history"
            selected={tab === 'history'}
            onClick={() => setTab('history')}
          >
            История ({history.length})
          </Tabs.Tab>
        </Tabs>
      </Section>
      {tab === 'catalog' &&
        (hasSupplies ? (
          <Section fill height="550px">
            <VoidcrewCargoCatalog express />
          </Section>
        ) : (
          <Section>
            <Box color="bad">
              Нет доступных товаров. Убедитесь, что грузовая система инициализирована.
            </Box>
          </Section>
        ))}
      {tab === 'cart' && <VoidcrewCargoCart />}
      {tab === 'history' && <VoidcrewCargoHistory />}
    </Box>
  );
};

const VoidcrewCargoStatus = () => {
  const { act, data } = useBackend();
  const {
    shuttle_state = CARGO_SHUTTLE_AWAY,
    shuttle_status = 'Вне станции',
    shuttle_timer = 0,
    can_call_shuttle,
    shuttle_error,
    points,
    loan,
  } = data;

  // Determine button text and state
  const getButtonText = () => {
    switch (shuttle_state) {
      case CARGO_SHUTTLE_AWAY:
        return 'Вызвать шаттл';
      case CARGO_SHUTTLE_ARRIVING:
        return `Прибывает...`;
      case CARGO_SHUTTLE_DOCKED:
        return 'Отправить';
      case CARGO_SHUTTLE_DEPARTING:
        return `Отправляется...`;
      default:
        return 'Грузовой шаттл';
    }
  };

  const getButtonColor = () => {
    switch (shuttle_state) {
      case CARGO_SHUTTLE_DOCKED:
        return 'green';
      case CARGO_SHUTTLE_ARRIVING:
      case CARGO_SHUTTLE_DEPARTING:
        return 'yellow';
      default:
        return 'blue';
    }
  };

  const isButtonDisabled = () => {
    // Disabled during transit or if can't call
    if (
      shuttle_state === CARGO_SHUTTLE_ARRIVING ||
      shuttle_state === CARGO_SHUTTLE_DEPARTING
    ) {
      return true;
    }
    if (shuttle_state === CARGO_SHUTTLE_AWAY && !can_call_shuttle) {
      return true;
    }
    return false;
  };

  return (
    <Section>
      <Box position="absolute" right={1} bold>
        {(!!points && (
          <>
            <AnimatedNumber
              value={points}
              format={(value) => formatMoney(value)}
            />
            {' кредитов'}
          </>
        )) || <AnimatedNumber value="Нет кредитов" />}
      </Box>
      <LabeledList>
        <LabeledList.Item label="Плательщик">
          {data.account_name || 'Привязанный банковский счёт'}
        </LabeledList.Item>
        <LabeledList.Item label="Грузовой шаттл">
          <Button
            color={getButtonColor()}
            disabled={isButtonDisabled()}
            tooltip={
              isButtonDisabled() && shuttle_state === CARGO_SHUTTLE_AWAY
                ? shuttle_error || 'Невозможно вызвать шаттл'
                : null
            }
            content={getButtonText()}
            onClick={() => act('send')}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Статус">
          {SHUTTLE_STATUS_LABELS[shuttle_status] || shuttle_status}
        </LabeledList.Item>
        {shuttle_state === CARGO_SHUTTLE_ARRIVING && (
          <LabeledList.Item label="Таймер">
            <ProgressBar
              value={shuttle_timer}
              maxValue={30}
              ranges={{
                good: [20, 30],
                average: [10, 20],
                bad: [0, 10],
              }}
            >
              {shuttle_timer} с осталось
            </ProgressBar>
          </LabeledList.Item>
        )}
        {shuttle_state === CARGO_SHUTTLE_DEPARTING && (
          <LabeledList.Item label="Таймер">
            <ProgressBar
              value={shuttle_timer}
              maxValue={5}
              ranges={{
                good: [3, 5],
                average: [2, 3],
                bad: [0, 2],
              }}
            >
              {shuttle_timer} с осталось
            </ProgressBar>
          </LabeledList.Item>
        )}
        {!!shuttle_error && shuttle_state === CARGO_SHUTTLE_AWAY && (
          <LabeledList.Item label="Примечание" color="bad">
            {shuttle_error}
          </LabeledList.Item>
        )}
      </LabeledList>
      {!!loan && (
        <Box
          mt={2}
          p={1}
          backgroundColor={
            loan.accepted
              ? 'rgba(100, 200, 100, 0.1)'
              : 'rgba(255, 200, 0, 0.1)'
          }
        >
          <Box bold color={loan.accepted ? 'good' : 'yellow'} mb={1}>
            {loan.accepted
              ? `Заём принят от ${loan.sender}`
              : `Предложение займа на шаттл от ${loan.sender}`}
          </Box>
          <Box mb={1}>{loan.announcement}</Box>
          {loan.bonus_credits > 0 && (
            <Box color="good" mb={1}>
              Бонус: {formatMoney(loan.bonus_credits)} кредитов
              {loan.accepted && ' (зачислено)'}
            </Box>
          )}
          {loan.accepted ? (
            <Box color="good" italic>
              Вызовите грузовой шаттл, чтобы получить товары по займу.
            </Box>
          ) : (
            <Stack>
              <Stack.Item>
                <Button
                  color="green"
                  icon="check"
                  content="Принять заём"
                  onClick={() => act('accept_loan')}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  color="red"
                  icon="times"
                  content="Отклонить"
                  onClick={() => act('decline_loan')}
                />
              </Stack.Item>
            </Stack>
          )}
        </Box>
      )}
    </Section>
  );
};

const VoidcrewCargoCartButtons = () => {
  const { act, data } = useBackend();
  const { cart = [], shuttle_state = CARGO_SHUTTLE_AWAY } = data;
  const total = cart.reduce((total, entry) => total + entry.cost, 0);
  // The cart is the dispatched shipment's manifest once the shuttle is called
  const cartLocked = shuttle_state !== CARGO_SHUTTLE_AWAY;
  return (
    <>
      <Box inline mx={1}>
        {cart.length === 0 && 'Корзина пуста'}
        {cart.length === 1 && '1 товар'}
        {cart.length >= 2 && cart.length + ' товаров'}{' '}
        {total > 0 && `(${formatMoney(total)} cr)`}
      </Box>
      {!cartLocked && (
        <Button
          icon="times"
          color="transparent"
          content="Очистить"
          onClick={() => act('clear')}
        />
      )}
    </>
  );
};

const VoidcrewCargoCart = () => {
  const { act, data } = useBackend();
  const { cart = [], shuttle_state = CARGO_SHUTTLE_AWAY } = data;
  const shuttleDocked = shuttle_state === CARGO_SHUTTLE_DOCKED;
  const cartLocked = shuttle_state !== CARGO_SHUTTLE_AWAY;
  return (
    <Section fill>
      <Section>
        <Stack>
          <Stack.Item mt="4px">Текущая корзина</Stack.Item>
          <Stack.Item ml="200px" mt="3px">
            Количество
          </Stack.Item>
          <Stack.Item ml="72px">
            <VoidcrewCargoCartButtons />
          </Stack.Item>
        </Stack>
      </Section>
      {cart.length === 0 && <Box color="label">В корзине ничего нет</Box>}
      {cart.length > 0 && (
        <Table>
          {cart.map((entry) => (
            <Table.Row key={entry.id} className="candystripe">
              <Table.Cell collapsing color="label" inline width="210px">
                #{entry.id}&nbsp;{entry.object}
              </Table.Cell>
              <Table.Cell inline ml="65px" width="40px">
                {(!cartLocked && !!entry.can_be_cancelled && (
                  <RestrictedInput
                    width="40px"
                    minValue={0}
                    maxValue={50}
                    value={entry.amount}
                    onEnter={(e, value) =>
                      act('modify', {
                        order_name: entry.object,
                        amount: value,
                      })
                    }
                  />
                )) || <Input width="40px" value={entry.amount} disabled />}
              </Table.Cell>
              <Table.Cell inline ml="5px" width="10px">
                {!cartLocked && !!entry.can_be_cancelled && (
                  <Button
                    icon="plus"
                    onClick={() =>
                      act('add_by_name', { order_name: entry.object })
                    }
                  />
                )}
              </Table.Cell>
              <Table.Cell inline ml="15px" width="10px">
                {!cartLocked && !!entry.can_be_cancelled && (
                  <Button
                    icon="minus"
                    onClick={() => act('remove', { order_name: entry.object })}
                  />
                )}
              </Table.Cell>
              <Table.Cell collapsing textAlign="right" inline ml="50px">
                {formatMoney(entry.cost)} {entry.cost_type === 'cr' ? 'кр' : entry.cost_type}
              </Table.Cell>
              <Table.Cell inline mt="20px" />
            </Table.Row>
          ))}
        </Table>
      )}
      {cart.length > 0 && shuttle_state === CARGO_SHUTTLE_AWAY && (
        <Box mt={2}>
          <Box opacity={0.5}>
            Добавьте товары в корзину, затем вызовите грузовой шаттл для заказа.
          </Box>
        </Box>
      )}
      {cart.length > 0 && shuttle_state === CARGO_SHUTTLE_ARRIVING && (
        <Box mt={2}>
          <Box color="yellow">
            Заказ отправлен — корзина заблокирована до прибытия шаттла.
          </Box>
        </Box>
      )}
      {!!shuttleDocked && (
        <Box mt={2}>
          <Box color="good">
            Грузовой шаттл пристыкован! Поднимитесь на борт, чтобы забрать товары, затем отправьте его обратно, чтобы продать экспорт.
          </Box>
        </Box>
      )}
    </Section>
  );
};

const VoidcrewCargoHistory = () => {
  const { data } = useBackend();
  const { history = [] } = data;

  return (
    <Section fill title="История транзакций">
      {history.length === 0 && (
        <Box color="label">Транзакций пока нет.</Box>
      )}
      {history.length > 0 && (
        <Table>
          <Table.Row header>
            <Table.Cell>Время</Table.Cell>
            <Table.Cell>Тип</Table.Cell>
            <Table.Cell>Товар</Table.Cell>
            <Table.Cell>Кол-во</Table.Cell>
            <Table.Cell textAlign="right">Стоимость</Table.Cell>
          </Table.Row>
          {history.map((entry, index) => (
            <Table.Row key={index} className="candystripe">
              <Table.Cell color="label">{entry.time}</Table.Cell>
              <Table.Cell color={entry.type === 'buy' ? 'bad' : 'good'}>
                {entry.type === 'buy' ? 'Покупка' : 'Продажа'}
              </Table.Cell>
              <Table.Cell>{entry.name}</Table.Cell>
              <Table.Cell>{entry.amount}</Table.Cell>
              <Table.Cell textAlign="right">
                <Box color={entry.type === 'buy' ? 'bad' : 'good'}>
                  {entry.type === 'buy' ? '-' : '+'}
                  {formatMoney(entry.value)} кр
                </Box>
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};
