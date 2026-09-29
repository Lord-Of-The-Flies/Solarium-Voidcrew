#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request


def api(path):
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
    if not token:
        print("GH_TOKEN/GITHUB_TOKEN не задан", file=sys.stderr)
        sys.exit(1)
    request = urllib.request.Request(
        "https://api.github.com" + path,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "User-Agent": "Solarium-Voidcrew-Changelog",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        print(f"API {path}: HTTP {error.code}", file=sys.stderr)
        sys.exit(1)


def api_paginated(path, per_page=100):
    results = []
    page = 1
    while True:
        items = api(f"{path}?per_page={per_page}&page={page}")
        if not items:
            break
        results.extend(items)
        if len(items) < per_page:
            break
        page += 1
    return results


def main():
    repo = os.environ.get("GITHUB_REPOSITORY", "")
    pr_input = os.environ.get("PR_NUMBER", "").strip()
    if not repo or not pr_input:
        print("нужны GITHUB_REPOSITORY и PR_NUMBER", file=sys.stderr)
        sys.exit(1)
    try:
        pr_number = int(pr_input)
    except ValueError:
        print(f"PR_NUMBER не число: {pr_input}", file=sys.stderr)
        sys.exit(1)

    pr = api(f"/repos/{repo}/pulls/{pr_number}")
    commits = api_paginated(f"/repos/{repo}/pulls/{pr_number}/commits")

    lines = [
        f"## Изменения в PR #{pr_number}: {pr['title']}",
        "",
        f"- Всего коммитов: {len(commits)}",
        "",
    ]

    for commit in commits:
        message = commit["commit"]["message"]
        subject, _, body = message.partition("\n")
        subject = " ".join(subject.split()).strip()
        sha = commit.get("sha", "")
        sha_short = sha[:7]
        author = (commit.get("author") or {}).get("login") or (
            (commit.get("commit") or {}).get("author") or {}
        ).get("name") or "?"
        body = body.strip()

        lines.append(f"- {subject} - @{author} - `{sha_short}`")
        if body:
            lines.extend(
                [
                    "",
                    "  <details>",
                    "  <summary>Описание</summary>",
                    "",
                    "  ```",
                ]
            )
            for body_line in body.splitlines():
                lines.append(f"  {body_line}")
            lines.extend(["  ```", "", "  </details>", ""])
        else:
            lines.extend(
                [
                    "",
                    "  <details>",
                    "  <summary>Описание</summary>",
                    "",
                    "  Описания нет.",
                    "",
                    "  </details>",
                    "",
                ]
            )
        lines.append("")

    comment = "\n".join(lines).strip() + "\n"

    body_path = "/tmp/pr_changelog.md"
    with open(body_path, "w", encoding="utf-8") as file_out:
        file_out.write(comment)
    print(comment)

    if os.environ.get("UPDATE_PR_DESCRIPTION", "true").lower() == "true":
        result = subprocess.run(
            ["gh", "pr", "edit", str(pr_number), "--repo", repo, "--body-file", body_path],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print(result.stderr, file=sys.stderr)
            sys.exit(1)
        print(f"Описание ПРа #{pr_number} обновлено.")


if __name__ == "__main__":
    main()