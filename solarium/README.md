## Подключение

В корне основного репозитория (Solarium-Voidcrew) поочереди выполнить команды:

```sh
git submodule update --init Astramilitarum
git submodule update --init Horusheresy
```

Сборка с подключённым модулем или выбрать в отладке один из вариантов заготовленных:

```sh
tools/build/build.sh dm -DASTRAMILITARUM -DHORUSHERESY
```

Без флагов билд скомпилируется без модулей как обычно

<!-- VOIDCREW EDIT: SOLARIUM - ERP integration documentation. -->
Подключение ERP и конструктор персонажа описаны в [ERP.md](ERP.md).
