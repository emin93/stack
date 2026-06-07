#!/usr/bin/env bash
# Sync currently-loaded LM Studio models into an opencode config fragment.
#
# LM Studio is the source of truth: the model list, tool-call support, and
# context length are all read from the running server (/api/v0/models), so you
# never hand-edit opencode.json. The output is written OUTSIDE the dotfiles repo
# (default ~/.cache/opencode/lmstudio.json) and fed to opencode via
# OPENCODE_CONFIG, which opencode merges on top of the global config. That keeps
# the stow-symlinked ~/.config/opencode/opencode.json clean (no git churn).
#
# Usage: run it directly, or let the `opencode` shell wrapper run it on launch.
set -euo pipefail

LMSTUDIO_API="${LMSTUDIO_API:-http://127.0.0.1:1234}"
OUT="${OPENCODE_LMSTUDIO_CONFIG:-$HOME/.cache/opencode/lmstudio.json}"
mkdir -p "$(dirname "$OUT")"

# Fetch loaded models. If LM Studio is unreachable, write an empty provider and
# exit 0 so launching opencode is never blocked by the local server being down.
models_json="$(curl -fsS --max-time 2 "$LMSTUDIO_API/api/v0/models" 2>/dev/null || true)"
if [ -z "$models_json" ]; then
  printf '{"$schema":"https://opencode.ai/config.json","provider":{}}\n' >"$OUT"
  exit 0
fi

# Build the lmstudio provider from the loaded (non-embedding) models. Context
# comes from loaded_context_length (the value LM Studio is actually serving).
printf '%s' "$models_json" | jq --arg baseURL "$LMSTUDIO_API/v1" '{
  "$schema": "https://opencode.ai/config.json",
  provider: {
    "lmstudio-local": {
      npm: "@ai-sdk/openai-compatible",
      name: "LM Studio (local)",
      options: { baseURL: $baseURL },
      models: (
        [ .data[]
          | select(.state == "loaded" and .type != "embeddings")
          | { key: .id, value: {
              name: .id,
              tool_call: (((.capabilities // []) | index("tool_use")) != null),
              limit: { context: (.loaded_context_length // .max_context_length), output: 8192 }
            } }
        ] | from_entries
      )
    }
  }
}' >"$OUT"
