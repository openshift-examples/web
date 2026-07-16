---
name: git-coauthor
description: >-
  Use when committing changes made with AI assistance. Adds the AI agent as a
  co-author to the git commit using the GitHub Co-authored-by trailer convention.
  Trigger phrases: "commit with co-author", "add AI as co-author", "commit changes".
---

# Git Commit with AI Co-author

Every commit that contains AI-assisted changes should credit the AI agent as a
co-author using the [GitHub co-author trailer convention](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors).

## Co-author identity

Use your own agent identity for the trailer. Known identities:

| Agent | Trailer |
|---|---|
| Bob (IBM) | `Co-authored-by: Bob <bob@ibm.com>` |
| Claude (Anthropic) | `Co-authored-by: Claude <claude@anthropic.com>` |
| GPT-4 (OpenAI) | `Co-authored-by: GPT-4 <gpt4@openai.com>` |
| Gemini (Google) | `Co-authored-by: Gemini <gemini@google.com>` |

If your identity is not listed, use `Co-authored-by: <AgentName> <agentname@provider.com>`.

## Commit message format

The trailer **must** be separated from the subject/body by a blank line:

```
<subject line>

<optional body paragraphs>

Co-authored-by: <AgentName> <identity@provider.com>
```

## Steps

1. Stage the relevant files:

   ```shell
   git add <files>
   # or: git add .
   ```

2. Commit with the co-author trailer. Use `-m` twice — first for the subject,
   second for the trailer (git appends them with a blank line between):

   ```shell
   git commit -m "<subject>" -m "Co-authored-by: <AgentName> <identity@provider.com>"
   ```

   If a longer body is also needed:

   ```shell
   git commit -m "<subject>" -m "<body paragraph>" -m "Co-authored-by: <AgentName> <identity@provider.com>"
   ```

3. Verify the trailer was recorded:

   ```shell
   git log -1 --format="%B"
   ```
