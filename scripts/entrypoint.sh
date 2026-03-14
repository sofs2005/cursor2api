#!/bin/sh
set -eu

CONFIG_FILE="/app/config.yaml"

# If vision env vars are provided, generate config.yaml at runtime.
# This keeps secrets out of git and makes Railway configuration easy.
if [ "${VISION_API_KEY:-}" != "" ] || [ "${VISION_BASE_URL:-}" != "" ] || [ "${VISION_MODEL:-}" != "" ] || [ "${VISION_MODE:-}" != "" ]; then
  PORT_VAL="${PORT:-3010}"
  TIMEOUT_VAL="${TIMEOUT:-120}"
  ENABLE_THINKING_VAL="${ENABLE_THINKING:-true}"
  VISION_ENABLED_VAL="${VISION_ENABLED:-true}"
  VISION_MODE_VAL="${VISION_MODE:-api}"
  VISION_BASE_URL_VAL="${VISION_BASE_URL:-https://api.openai.com/v1/chat/completions}"
  VISION_API_KEY_VAL="${VISION_API_KEY:-}"
  VISION_MODEL_VAL="${VISION_MODEL:-gpt-4o-mini}"

  cat > "$CONFIG_FILE" <<EOF
port: ${PORT_VAL}
timeout: ${TIMEOUT_VAL}
enable_thinking: ${ENABLE_THINKING_VAL}
vision:
  enabled: ${VISION_ENABLED_VAL}
  mode: ${VISION_MODE_VAL}
  providers:
    - name: vision
      base_url: ${VISION_BASE_URL_VAL}
      api_key: ${VISION_API_KEY_VAL}
      model: ${VISION_MODEL_VAL}
EOF
fi

exec "$@"
