# cursor2api Vue3 日志 UI

基于 Vue3 + Vite + TypeScript 构建的日志查看与配置前端，挂载在 `/vuelogs` 路由下。

## 技术栈

- Vue 3.5 + Pinia 状态管理
- Vite 6 构建工具
- TypeScript
- highlight.js（代码高亮）
- marked（Markdown 渲染）

## 目录结构

```
vue-ui/
├── src/
│   ├── App.vue                  # 根组件
│   ├── main.ts                  # 入口
│   ├── api.ts                   # API 请求封装
│   ├── types.ts                 # 类型定义
│   ├── components/
│   │   ├── LoginPage.vue        # 登录页
│   │   ├── AppHeader.vue        # 顶部导航（含配置按钮）
│   │   ├── LogList.vue          # 日志列表
│   │   ├── RequestList.vue      # 请求列表
│   │   ├── DetailPanel.vue      # 请求详情面板
│   │   ├── PayloadView.vue      # Payload 查看
│   │   ├── PhaseTimeline.vue    # 阶段时间线
│   │   └── ConfigDrawer.vue     # 配置抽屉（热重载配置）
│   ├── composables/
│   │   └── useSSE.ts            # SSE 实时推送
│   └── stores/
│       ├── auth.ts              # 登录状态
│       ├── logs.ts              # 日志数据
│       ├── stats.ts             # 统计数据
│       └── config.ts            # 配置状态
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

## 开发

```bash
# 进入前端目录
cd vue-ui

# 安装依赖
npm install

# 启动开发服务器（默认 http://localhost:5173）
# 会自动将 /api 请求代理到 http://localhost:3010
npm run dev
```

开发时需同时启动后端服务：

```bash
# 在项目根目录
npm run dev
```

## 构建

```bash
cd vue-ui
npm run build
```

产物输出到项目根目录的 `public/vue/`，后端通过 `/vuelogs` 路由提供服务。

> **重要**：Docker 镜像打包前必须先执行此构建步骤，否则容器内将缺少前端静态资源。

## Docker 部署注意事项

### 1. 先构建前端再构建镜像

Dockerfile 不会自动构建 Vue UI，需要先在本地生成产物：

```bash
# 第一步：构建前端（在 vue-ui 目录）
cd vue-ui && npm install && npm run build && cd ..

# 第二步：构建并启动容器
docker compose up -d --build
```

### 2. config.yaml 不能挂载为只读

配置抽屉支持通过 Web UI 实时修改并写回 `config.yaml`，因此挂载时**不能**加 `:ro` 只读标志：

```yaml
# ✅ 正确
volumes:
  - ./config.yaml:/app/config.yaml

# ❌ 错误（UI 保存配置时会报 EROFS: read-only file system）
volumes:
  - ./config.yaml:/app/config.yaml:ro
```

### 3. 首次部署前准备 config.yaml

挂载前宿主机上必须已存在 `config.yaml`，否则 Docker 会将其创建为目录：

```bash
cp config.yaml.example config.yaml
# 按需编辑 config.yaml
```

### 4. 完整部署流程

```bash
# 1. 准备配置文件
cp config.yaml.example config.yaml

# 2. 构建前端
cd vue-ui && npm install && npm run build && cd ..

# 3. 启动服务
docker compose up -d --build

# 4. 访问日志 UI
open http://localhost:3010/vuelogs
```

## 配置抽屉

点击顶部右侧的 **⚙ 配置** 按钮可打开配置面板，支持修改以下热重载配置项：

| 分组 | 字段 | 说明 |
|------|------|------|
| 基础 | `cursor_model` | 使用的 Cursor 模型 |
| 基础 | `timeout` | 请求超时（秒） |
| 基础 | `max_auto_continue` | 自动续写次数 |
| 基础 | `max_history_messages` | 历史消息条数上限（建议改用 max_history_tokens） |
| 基础 | `max_history_tokens` | 历史消息 token 数上限（推荐），代码自动补偿 Cursor 后端开销（1,300 基础 + 工具 tokenizer 差异，动态计算），参考值 130000~170000，默认 150000 |
| 功能 | `thinking.enabled` | Thinking 模式（跟随客户端/强制关闭/强制开启） |
| 功能 | `sanitize_response` | 响应内容清洗 |
| 历史压缩 | `compression.*` | 压缩开关、级别、保留条数等 |
| 工具处理 | `tools.*` | Schema 模式、透传/禁用 |
| 日志持久化 | `logging.*` | 文件持久化、目录、落盘模式 |
| 高级 | `refusal_patterns` | 自定义拒绝检测正则 |

保存后配置立即写入 `config.yaml`，fs.watch 热重载下一次请求即生效，无需重启服务。

## 与原有日志页面的关系

| 路由 | 实现 | 鉴权方式 |
|------|------|----------|
| `/logs` | 原生 HTML（`public/logs.html`）| 服务端 cookie 鉴权 |
| `/vuelogs` | 本 Vue3 应用 | 前端登录页处理 |

两者独立共存，互不影响。
