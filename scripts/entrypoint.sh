#!/bin/sh
set -eu

CONFIG_FILE="/app/config.yaml"

# 确保日志目录存在（上游 v2.7.x 日志查看器需要）
mkdir -p /app/logs

# 如果提供了任何环境变量，在运行时生成 config.yaml
# Railway 等平台通过环境变量注入配置，无需把密钥写进仓库
if [ "${VISION_API_KEY:-}" != "" ] || [ "${VISION_BASE_URL:-}" != "" ] || \
   [ "${VISION_MODEL:-}" != "" ] || [ "${VISION_MODE:-}" != "" ] || \
   [ "${API_KEY:-}" != "" ] || [ "${AUTH_TOKENS:-}" != "" ]; then

  PORT_VAL="${PORT:-3010}"
  TIMEOUT_VAL="${TIMEOUT:-120}"
  ENABLE_THINKING_VAL="${ENABLE_THINKING:-false}"
  VISION_ENABLED_VAL="${VISION_ENABLED:-true}"
  VISION_MODE_VAL="${VISION_MODE:-api}"
  VISION_BASE_URL_VAL="${VISION_BASE_URL:-https://api.openai.com/v1/chat/completions}"
  VISION_API_KEY_VAL="${VISION_API_KEY:-}"
  VISION_MODEL_VAL="${VISION_MODEL:-gpt-4o-mini}"

  cat > "$CONFIG_FILE" <<EOF
port: ${PORT_VAL}
timeout: ${TIMEOUT_VAL}
enable_thinking: ${ENABLE_THINKING_VAL}
EOF

  # 支持两种方式配置鉴权 token（对应上游 authTokens 字段）:
  # 1. API_KEY=xxx（单个 token，Railway 常用）
  # 2. AUTH_TOKENS=xxx,yyy,zzz（多个 token，逗号分隔）
  if [ "${AUTH_TOKENS:-}" != "" ]; then
    printf 'authTokens:\n' >> "$CONFIG_FILE"
    echo "${AUTH_TOKENS}" | tr ',' '\n' | while IFS= read -r token; do
      token=$(echo "$token" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      [ -n "$token" ] && printf '  - %s\n' "$token" >> "$CONFIG_FILE"
    done
  elif [ "${API_KEY:-}" != "" ]; then
    printf 'authTokens:\n  - %s\n' "${API_KEY}" >> "$CONFIG_FILE"
  fi

  cat >> "$CONFIG_FILE" <<EOF
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
