#!/usr/bin/env bash
set -uo pipefail

log() { printf '[upstream-merge] %s\n' "$*"; }
die() { log "ERROR: $*"; exit 1; }

UPSTREAM="${UPSTREAM_REPO:-voidcrew/Voidcrew}"
MIRROR_REPO="${GITHUB_REPOSITORY:-SOLARIUM-Collective/Solarium-Voidcrew}"
BASE_BRANCH="${BASE_BRANCH:-stream_update}"
MERGE_LABEL="${UPSTREAM_MERGE_LABEL:-}"
BRANCH="upstream-merge"
REMOTE_BASE="origin/${BASE_BRANCH}"

TOKEN="${UPSTREAM_MIRROR_PAT:-${GITHUB_TOKEN:-}}"
[ -n "$TOKEN" ] || die "нет токена (UPSTREAM_MIRROR_PAT или GITHUB_TOKEN)"
export GH_TOKEN="$TOKEN"

if [ -n "$MERGE_LABEL" ]; then
  gh label create "$MERGE_LABEL" --force --color "1F883D" >/dev/null 2>&1 || true
fi

git config --global user.name  "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"

if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "https://github.com/${UPSTREAM}.git"
else
  git remote set-url upstream "https://github.com/${UPSTREAM}.git"
fi
git fetch --no-tags upstream master --quiet || die "не удалось загрузить upstream/master"
git fetch --prune origin '+refs/heads/*:refs/remotes/origin/*' --quiet || die "не удалось загрузить origin"
git rev-parse --verify "${REMOTE_BASE}" >/dev/null 2>&1 || die "ветка '${BASE_BRANCH}' не найдена на origin"

if git merge-base --is-ancestor upstream/master "${REMOTE_BASE}" 2>/dev/null; then
  log "upstream/master уже полностью влит в ${BASE_BRANCH}, обновлений нет"
  echo "## Обновление из апстрима" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
  echo "- Статус: обновлений нет (upstream/master уже влит в ${BASE_BRANCH})" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
  exit 0
fi

if git rev-parse --verify "refs/remotes/origin/${BRANCH}" >/dev/null 2>&1; then
  if git merge-base --is-ancestor "refs/remotes/origin/${BRANCH}" "${REMOTE_BASE}" 2>/dev/null; then
    log "ветка ${BRANCH} уже влита в базу — удаляю её, чтобы создать свежую"
    git push origin "refs/heads/${BRANCH}" --delete --quiet || log "не удалось удалить ветку ${BRANCH}"
  else
    log "ветка ${BRANCH} уже существует и не влита (открытый ПР/ручная правка). Повторно не трогаю."
    echo "## Обновление из апстрима" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
    echo "- Статус: ветка ${BRANCH} уже есть и не влита в ${BASE_BRANCH}, ждёт ручного разрешения/мержа." >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
    echo "- Ветка: ${BRANCH}" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
    exit 0
  fi
fi

prev_merge="$(git merge-base "${REMOTE_BASE}" upstream/master)"
git checkout -B "$BRANCH" "$REMOTE_BASE" --quiet || die "не могу создать ветку ${BRANCH}"

if git merge --no-edit upstream/master >/tmp/upstream_merge.log 2>&1; then
  if [ "$(git rev-parse HEAD)" = "$(git rev-parse "$REMOTE_BASE")" ]; then
    log "upstream/master: изменений относительно базы нет"
    echo "## Обновление из апстрима" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
    echo "- Статус: upstream/master уже влит в ${BASE_BRANCH} (без новых изменений)" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
    git push origin "refs/heads/${BRANCH}" --delete --quiet 2>/dev/null || true
    exit 0
  fi
  CLEAN=1
  log "слияние прошло чисто"
else
  CLEAN=0
  log "КОНФЛИКТЫ при слиянии upstream/master"

  conflicted="$(git diff --name-only --diff-filter=U 2>/dev/null || true)"
  conflicted="${conflicted:-}"
  [ -z "$conflicted" ] && conflicted="(не удалось получить список — смотри diff)"

  git add -A || die "не могу добавить конфликтные файлы"
  git commit -m "Merge upstream/master into ${BASE_BRANCH} (маркеры конфликтов оставлены для ручного разрешения)" \
    --quiet || die "не могу закоммитить состояние слияния"

  printf '%s\n' "$conflicted" > /tmp/upstream_conflicts.txt
fi

git push -u origin "refs/heads/${BRANCH}" --quiet || die "не могу запушить ${BRANCH}"

now_iso="$(date -u +%Y-%m-%dT%H:%MZ)"

commit_count="$(git rev-list --count "${prev_merge}..upstream/master" 2>/dev/null || echo 0)"
commits_log="$(git log "${prev_merge}..upstream/master" --format='- %h %s - %an' 2>/dev/null | head -n 200)"

if [ "$CLEAN" -eq 1 ]; then
  title="Обновление из апстрима (merge) ${now_iso}"
  status_line="- Статус: чистое слияние, готово к мержу."
else
  title="Обновление из апстрима (merge) ${now_iso} — конфликты, нужно разрешить вручную"
  status_line="- Статус: **конфликты**, нужно разрешить вручную (см. ниже)."
fi

body="Автоматический merge **upstream/master → \`${BASE_BRANCH}\`** (на ${now_iso}).

${status_line}
- Привезено коммитов от ${prev_merge:0:10} до upstream/master: ${commit_count}
- Ветка: \`${BRANCH}\`

<details>
<summary>Коммиты (${commit_count})</summary>

```
${commits_log}
```

</details>
"

if [ "$CLEAN" -ne 1 ]; then
  body="${body}

## Конфликтные файлы

\`\`\`
$(cat /tmp/upstream_conflicts.txt)
\`\`\`

**Как разрешить:**

1. \`git fetch origin\`
2. \`git switch ${BRANCH}\`
3. Разрешить конфликты (убрать маркеры \`<<<<<<< / ======= / >>>>>>>\`)
4. \`git add\` разрешённые файлы и \`git commit\`
5. \`git push origin ${BRANCH}\`

После пуша ПР обновится и станет готов к мержу.
"
fi

existing_pr="$(gh pr list --repo "${MIRROR_REPO}" --state open --head "${BRANCH}" --json number --jq '.[0].number // empty')"
if [ -n "$existing_pr" ]; then
  log "ПР #${existing_pr} для ветки ${BRANCH} уже существует, обновляю заголовок/описание"
  gh pr edit "$existing_pr" --repo "${MIRROR_REPO}" --title "$title" --body "$body" >/dev/null || log "не удалось обновить ПР #${existing_pr}"
else
  pr_args=( --repo "$MIRROR_REPO" --base "$BASE_BRANCH" --head "$BRANCH" --title "$title" --body "$body" )
  [ -n "$MERGE_LABEL" ] && pr_args+=( --label "$MERGE_LABEL" )
  if gh pr create "${pr_args[@]}" >/dev/null; then
    log "готово: открыт ПР '$title'"
  else
    log "не удалось открыть ПР (ветка ${BRANCH} сохранена)"
  fi
fi

git checkout -q "$BASE_BRANCH" 2>/dev/null || true

{
  echo "## Обновление из апстрима"
  echo "${status_line}"
  echo "- Коммитов привезено: ${commit_count}"
  echo "- Ветка: ${BRANCH}"
  echo "- Цель: ${BASE_BRANCH}"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"