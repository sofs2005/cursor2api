#!/bin/sh
set -eu

# 确保日志目录存在（上游 v2.7.x 日志查看器需要）
mkdir -p /app/logs

# Railway 等平台直接通过环境变量注入配置。
# 具体解析逻辑在 src/config.ts 中完成，这里不再写 /app/config.yaml，
# 避免非 root 用户在容器启动时写入 /app 触发 Permission denied。

exec "$@"
