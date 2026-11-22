import { useState } from 'react';
import {
  Box,
  Button,
  Icon,
  Input,
  NoticeBox,
  Section,
  Stack,
  Table,
  Tabs,
  TextArea,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CrewMember = {
  name: string;
  job: string;
  ref: string;
  is_captain: BooleanLike;
  is_online: BooleanLike;
  can_take_command: BooleanLike;
};

type AvailablePlayer = {
  name: string;
  ckey: string;
  job: string;
};

type PendingInvite = {
  ckey: string;
  time: number;
};

type CrewApplication = {
  ref: string;
  name: string;
  ckey: string;
  message: string;
  /// Seconds this application has been waiting
  waiting: number;
};

type Data = {
  ship_destroyed: BooleanLike;
  ship_name: string;
  memo: string;
  joining_allowed: BooleanLike;
  join_password: string;
  can_set_password: BooleanLike;
  crew_only_airlocks: BooleanLike;
  is_captain: BooleanLike;
  crew: CrewMember[];
  available_players: AvailablePlayer[];
  pending_invites: PendingInvite[];
  applications: CrewApplication[];
  can_invite: BooleanLike;
  can_rename: BooleanLike;
  command_offer_pending: BooleanLike;
};

export const CaptainManagement = () => {
  const { data } = useBackend<Data>();
  const { ship_destroyed, ship_name, is_captain } = data;
  const [currentTab, setCurrentTab] = useState<
    'crew' | 'invites' | 'applications' | 'settings'
  >('crew');

  if (ship_destroyed) {
    return (
      <Window width={500} height={500} title="Управление кораблём">
        <Window.Content>
          <NoticeBox danger>Корабль больше не существует!</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  if (!is_captain) {
    return (
      <Window width={500} height={500} title="Управление кораблём">
        <Window.Content>
          <NoticeBox danger>Вы больше не капитан!</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={500} height={550} title={`Управление кораблём — ${ship_name}`}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                selected={currentTab === 'crew'}
                onClick={() => setCurrentTab('crew')}
                icon="users"
              >
                Экипаж ({data.crew.length})
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'invites'}
                onClick={() => setCurrentTab('invites')}
                icon="envelope"
              >
                Приглашения ({data.pending_invites.length})
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'applications'}
                onClick={() => setCurrentTab('applications')}
                icon="clipboard-list"
              >
                Заявки ({data.applications.length})
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'settings'}
                onClick={() => setCurrentTab('settings')}
                icon="cog"
              > Настройки </Tabs.Tab>
            </Tabs>
          </Stack.Item>

          <Stack.Item grow>
            {currentTab === 'crew' && <CrewTab />}
            {currentTab === 'invites' && <InvitesTab />}
            {currentTab === 'applications' && <ApplicationsTab />}
            {currentTab === 'settings' && <SettingsTab />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const CrewTab = () => {
  const { act, data } = useBackend<Data>();
  const { crew, command_offer_pending } = data;

  return (
    <Section title="Список экипажа">
      {crew.length === 0 ? (
        <NoticeBox info>Экипаж не найден.</NoticeBox>
      ) : (
        <Table>
          <Table.Row header>
            <Table.Cell>Имя</Table.Cell>
            <Table.Cell>Роль</Table.Cell>
            <Table.Cell>Статус</Table.Cell>
            <Table.Cell>Действия</Table.Cell>
          </Table.Row>
          {crew.map((member) => (
            <Table.Row key={member.ref} className="candystripe">
              <Table.Cell bold={!!member.is_captain}>
                {member.name}
                {!!member.is_captain && (
                  <Box inline color="gold" ml={1}>
                    <Icon name="crown" />
                  </Box>
                )}
              </Table.Cell>
              <Table.Cell>{member.job}</Table.Cell>
              <Table.Cell color={member.is_online ? 'good' : 'grey'}>
                <Icon name={member.is_online ? 'circle' : 'circle-xmark'} />
                {member.is_online ? ' В сети' : ' Не в сети'}
              </Table.Cell>
              <Table.Cell>
                {!member.is_captain && (
                  <>
                    <Button
                      icon="user-minus"
                      color="bad"
                      compact
                      onClick={() => act('kick_crew', { ref: member.ref })}
                      tooltip="Убрать из экипажа"
                    > Выгнать </Button>
                    <Button
                      icon="crown"
                      color="caution"
                      compact
                      disabled={
                        !member.can_take_command || !!command_offer_pending
                      }
                      onClick={() =>
                        act('transfer_command', { ref: member.ref })
                      }
                      tooltip={
                        command_offer_pending
                          ? 'Предложение командования уже ждёт ответа'
                          : member.can_take_command
                            ? 'Предложить им командование кораблём. У них есть 30 секунд на ответ; если примут, вы перестанете быть капитаном.'
                            : 'Они должны быть живы и в сети, чтобы принять командование'
                      }
                    > Передать командование </Button>
                  </>
                )}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

const InvitesTab = () => {
  const { act, data } = useBackend<Data>();
  const { available_players, pending_invites, can_invite } = data;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Ожидающие приглашения">
          {pending_invites.length === 0 ? (
            <NoticeBox info>Нет ожидающих приглашений.</NoticeBox>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Игрок</Table.Cell>
                <Table.Cell>Действия</Table.Cell>
              </Table.Row>
              {pending_invites.map((invite) => (
                <Table.Row key={invite.ckey} className="candystripe">
                  <Table.Cell>{invite.ckey}</Table.Cell>
                  <Table.Cell>
                    <Button
                      icon="times"
                      color="bad"
                      compact
                      onClick={() =>
                        act('cancel_invite', { ckey: invite.ckey })
                      }
                    > Отменить </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section title="Доступные игроки" fill scrollable>
          {available_players.length === 0 ? (
            <NoticeBox info>Нет игроков, доступных для приглашения.</NoticeBox>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Имя</Table.Cell>
                <Table.Cell>Роль</Table.Cell>
                <Table.Cell>Действия</Table.Cell>
              </Table.Row>
              {available_players.map((player) => (
                <Table.Row key={player.ckey} className="candystripe">
                  <Table.Cell>{player.name}</Table.Cell>
                  <Table.Cell color="label">{player.job}</Table.Cell>
                  <Table.Cell>
                    <Button
                      icon="envelope"
                      color="good"
                      compact
                      disabled={!can_invite}
                      onClick={() =>
                        act('invite_player', { ckey: player.ckey })
                      }
                      tooltip={
                        can_invite
                          ? 'Отправить приглашение в экипаж'
                          : 'Подождите перед отправкой следующего приглашения'
                      }
                    > Пригласить </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const ApplicationsTab = () => {
  const { act, data } = useBackend<Data>();
  const { applications } = data;

  return (
    <Section title="Заявки на присоединение" fill scrollable>
      {applications.length === 0 ? (
        <NoticeBox info>
          Никто не подавал заявку. Игроки видят кнопку «Подать заявку» на вашем корабле в лобби, когда на нём стоит пароль; одобрение позволяет игроку войти без пароля. Заявки истекают через десять минут.
        </NoticeBox>
      ) : (
        <Stack vertical>
          {applications.map((application) => (
            <Stack.Item key={application.ref}>
              <Section>
                <Stack align="center">
                  <Stack.Item grow>
                    <Box bold>{application.name}</Box>
                    <Box color="label" fontSize="11px">
                      ckey: {application.ckey} — ожидание {application.waiting} с
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="check"
                      color="good"
                      onClick={() =>
                        act('approve_application', { ref: application.ref })
                      }
                    > Одобрить </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="times"
                      color="bad"
                      tooltip="Запросит необязательную причину для ответа"
                      onClick={() =>
                        act('deny_application', { ref: application.ref })
                      }
                    > Отклонить </Button>
                  </Stack.Item>
                </Stack>
                <Box mt={1} italic>
                  &quot;{application.message}&quot;
                </Box>
              </Section>
            </Stack.Item>
          ))}
        </Stack>
      )}
    </Section>
  );
};

const SettingsTab = () => {
  const { act, data } = useBackend<Data>();
  const {
    ship_name,
    memo,
    joining_allowed,
    join_password,
    can_set_password,
    crew_only_airlocks,
    can_rename,
  } = data;
  const [newName, setNewName] = useState(ship_name ?? '');
  const [newMemo, setNewMemo] = useState(memo ?? '');
  const [newPassword, setNewPassword] = useState(join_password ?? '');

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Название корабля">
          <Stack>
            <Stack.Item grow>
              <Input
                fluid
                value={newName}
                maxLength={42}
                onChange={(value) => setNewName(value ?? '')}
                placeholder="Введите название корабля..."
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="save"
                color="good"
                disabled={!newName || newName.length < 2 || !can_rename}
                tooltip={!can_rename ? 'Переименование на перезарядке' : ''}
                onClick={() => act('rename_ship', { name: newName })}
              > Сохранить </Button>
            </Stack.Item>
          </Stack>
          <Box mt={1} fontSize="11px" color="label">
            Название корабля должно быть от 2 до 42 символов. Переименование доступно раз в 5 минут.
          </Box>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Присоединение через криокапсулы">
          <Stack align="center">
            <Stack.Item grow>
              <Box>
                Разрешить игрокам присоединяться к вашему кораблю через криокапсулы в меню лобби.
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon={joining_allowed ? 'door-open' : 'door-closed'}
                color={joining_allowed ? 'good' : 'bad'}
                onClick={() => act('toggle_joining')}
              >
                {joining_allowed ? 'Включено' : 'Выключено'}
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Пароль для присоединения">
          {can_set_password ? (
            <>
              <Box mb={1} color="label" fontSize="11px">
                Игроки, присоединяющиеся из лобби, должны ввести этот пароль либо быть одобрены или приглашены. Смена пароля сбрасывает весь сохранённый доступ и одобрения. Оставьте поле пустым и сохраните, чтобы снять блокировку.
              </Box>
              <Stack>
                <Stack.Item grow>
                  <Input
                    fluid
                    value={newPassword}
                    maxLength={24}
                    onChange={(value) => setNewPassword(value ?? '')}
                    placeholder="Без пароля — может присоединиться любой"
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon={newPassword ? 'lock' : 'lock-open'}
                    color="good"
                    onClick={() =>
                      act('set_password', { password: newPassword })
                    }
                  >
                    {newPassword ? 'Установить пароль' : 'Очистить'}
                  </Button>
                </Stack.Item>
              </Stack>
              <Box mt={1}>
                <Button
                  icon="user-lock"
                  color="caution"
                  disabled={!join_password}
                  onClick={() => act('reset_join_access')}
                  tooltip="Сбросить весь сохранённый доступ и одобрения, не меняя пароль. Чтобы вернуться, игрокам придётся ввести пароль или снова получить одобрение либо приглашение. Экипаж, уже находящийся на борту, остаётся в списке."
                >
                  Сбросить доступ к присоединению
                </Button>
              </Box>
            </>
          ) : (
            <Box color="label">
              Корабли, выданные флотом, открыты для всех, и на них нельзя поставить пароль.
            </Box>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Шлюзы только для экипажа">
          {can_set_password ? (
            <Stack align="center">
              <Stack.Item grow>
                <Box color="label" fontSize="11px">
                  Пока это включено, шлюзы и ветродвери на корабле открываются только для вашего экипажа. Всем остальным будет отказано у двери. Ломы, емаги и перерезанные провода по-прежнему работают как раньше.
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={crew_only_airlocks ? 'lock' : 'lock-open'}
                  color={crew_only_airlocks ? 'good' : 'bad'}
                  onClick={() => act('toggle_crew_lock')}
                >
                  {crew_only_airlocks ? 'Только экипаж' : 'Открыто для всех'}
                </Button>
              </Stack.Item>
            </Stack>
          ) : (
            <Box color="label">
              Корабли, выданные флотом, открыты для всех, и их шлюзы нельзя привязать к экипажу.
            </Box>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section title="Заметка о корабле" fill>
          <Box mb={1} color="label" fontSize="11px">
            Эта заметка показывается игрокам при выборе вашего корабля в лобби и после появления.
          </Box>
          <TextArea
            fluid
            height="100px"
            value={newMemo}
            maxLength={500}
            onChange={(value) => setNewMemo(value ?? '')}
            placeholder="Введите сообщение для новых членов экипажа..."
          />
          <Box mt={1}>
            <Stack align="center">
              <Stack.Item grow>
                <Box color="label" fontSize="11px">
                  {(newMemo ?? '').length}/500 символов
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="save"
                  color="good"
                  onClick={() => act('set_memo', { memo: newMemo })}
                >
                  Сохранить заметку
                </Button>
              </Stack.Item>
            </Stack>
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
