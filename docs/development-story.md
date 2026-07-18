# 用 Codex 从零实现 mdPreview：一个原生 Mac Markdown 预览应用的开发复盘

## 1. 起点：我想要一个本地 Markdown 预览工具

这个项目一开始的需求很直接：我想做一个 macOS 上的本地应用，用来打开、预览和简单编辑 Markdown 文件。

当时已经有一个浏览器版本，但它需要打开浏览器访问。我希望新的工具是真正的本地 Mac 应用，可以像普通应用一样双击启动、拖到“应用程序”里使用，并且后续能用 Git 管理代码。

最初的目标并不是做一个复杂的写作软件，而是一个“预览为主、编辑为辅”的轻量工具：

- 可以打开 `.md` 和 `.markdown` 文件。
- 默认展示 Markdown 预览。
- 需要时可以进入编辑模式。
- 可以保存回原文件。
- 最终能打包成 `.app`。

项目最早放在 `aiskills` 这个父仓库下面，路径是：

```text
/Users/liangbo/aiskills/markdown-mac-preview
```

后面项目成熟以后，又被拆成了独立仓库：

```text
/Users/liangbo/Documents/workspace/markdown-mac-preview
```

远端仓库是：

```text
git@github.com:liangbo/markdown-mac-preview.git
```

## 2. 第一阶段：先把产品形态说清楚

开发不是直接从写代码开始的。第一步是和 Codex 一起把需求梳理成设计文档。

最早的设计文档明确了几个关键方向：

- 这是一个 native macOS app，不是网页。
- 使用 SwiftUI 做界面。
- 用 Swift Package 组织项目，保持轻量。
- 用独立的 core 层处理文档、统计和 Markdown 渲染。
- 用打包脚本生成本地 `.app`。
- 预览体验优先，编辑只是辅助。

这个阶段的核心产物包括：

```text
docs/superpowers/specs/2026-07-17-markdown-mac-preview-design.md
docs/superpowers/plans/2026-07-17-markdown-mac-preview.md
```

这里我开始形成一个工作方式：

1. 先讨论需求和产品边界。
2. 再生成设计文档。
3. 再写实施计划。
4. Codex 按计划实现。
5. 每一轮都跑测试和打包验证。

这个方式的好处是，项目不会变成“想到哪写到哪”。每次改动都有上下文，也能回溯为什么这么做。

## 3. 第二阶段：搭建 SwiftUI macOS 应用骨架

明确方向后，Codex 开始搭建项目。

项目采用 Swift Package 结构，主要分成两层：

```text
Sources/
  MarkdownMacPreviewApp/
  MarkdownMacPreviewCore/
```

`MarkdownMacPreviewCore` 负责不依赖 UI 的核心逻辑：

- Markdown 文档加载。
- 文件扩展名校验。
- 编辑后的 dirty state。
- 保存文件。
- 文字、单词、标题数量统计。
- Markdown 渲染。

`MarkdownMacPreviewApp` 负责 macOS 应用层：

- App 启动。
- 窗口创建。
- 菜单和快捷键。
- 主界面布局。
- 预览视图。
- 编辑器视图。
- 状态栏。

早期版本先实现了最小闭环：

- app 可以启动。
- 可以打开 Markdown 文件。
- 可以预览内容。
- 可以切换编辑。
- 可以保存。
- 可以显示文件名和统计信息。
- 可以打包成 `.app`。

这个阶段解决了一个重要问题：它证明这个项目不是一个概念，而是一个真实可运行的 Mac 应用。

## 4. 第三阶段：把预览体验放到中心

一开始的预览是基于 Markdown 到富文本的转换。这个方式能展示基本内容，但很快发现它并不是真正的 HTML 渲染。

问题主要体现在：

- Markdown 里的 HTML 标签不能按预期显示。
- 表格、代码块、复杂列表的表现不稳定。
- 整体排版不像真正的 Markdown 阅读器。

于是项目进入了一个关键架构调整：把预览切换成 HTML 预览。

新的方向是：

```text
Markdown -> HTML -> 本地 CSS -> WKWebView
```

也就是说：

- 用 Markdown 引擎把 Markdown 转成 HTML。
- 包一层完整 HTML 文档。
- 加入适合阅读的 CSS。
- 在 app 内部用 `WKWebView` 展示，而不是打开外部浏览器。

这个变化让 mdPreview 更像一个真正的本地 Markdown 阅读器。

相关设计文档是：

```text
docs/superpowers/specs/2026-07-18-mdpreview-webview-html-preview-design.md
docs/superpowers/plans/2026-07-18-mdpreview-webview-html-preview.md
```

实现后，预览支持了更完整的文档样式：

- 标题。
- 段落。
- 链接。
- 引用。
- 列表。
- 行内代码。
- 代码块。
- 表格。
- 分割线。
- 图片。
- 原始 HTML。

## 5. 第四阶段：加入最近打开文件侧边栏

当 app 能打开和预览文件之后，下一个明显需求是：不要每次都从文件选择器重新找文件。

于是增加了左侧 `Recent` 侧边栏。

这个侧边栏的目标不是做完整文件管理器，而是做一个轻量的最近打开记录：

- 打开过的 Markdown 文件会出现在左侧。
- 每行显示文件名和所在路径。
- 点击最近文件可以重新打开。
- 文件不存在时自动移除并显示错误。
- 最近文件最多保留 20 个。
- 重复文件不会重复出现。
- 用户可以拖动调整顺序。
- 点击已有最近文件时不重新排序。

这个阶段还顺手把 app 名称统一成了 `mdPreview`：

- 窗口标题是 `mdPreview`。
- 打包产物是 `build/mdPreview.app`。
- 菜单里是 `Quit mdPreview`。

这一步让应用从“能打开一个文件”变成了“能持续使用的小工具”。

相关设计文档是：

```text
docs/superpowers/specs/2026-07-18-mdpreview-recent-files-live-preview-design.md
docs/superpowers/plans/2026-07-18-mdpreview-recent-files-live-preview.md
```

## 6. 第五阶段：优化编辑和实时预览

编辑功能一开始只是辅助，但它仍然需要符合直觉。

目标是：

- 默认只看预览。
- 点 `Edit` 后进入编辑模式。
- 左边编辑 Markdown，右边实时预览。
- 不需要保存也能看到预览变化。
- 保存后 dirty state 清除。

这个过程中，Codex 把编辑内容和预览内容都接到同一份内存状态上。这样用户输入时，预览可以基于未保存内容更新，而不是必须等到保存后才变化。

后面又加了轻微 debounce，避免每个键盘输入都立即触发一次完整 HTML 渲染。编辑时会保留旧预览，等新预览完成后再替换，这样视觉上更稳定。

## 7. 第六阶段：处理本地图片路径

Markdown 文档经常会引用同目录或子目录里的图片，例如：

```markdown
![screenshot](./images/screenshot.png)
```

一开始图片无法稳定显示，因为 WebView 加载 HTML 时，对本地文件访问路径有权限和基准目录问题。

后面优化成：

- 以当前 Markdown 文件所在目录作为图片路径基准。
- 只允许读取这个目录及其子目录里的图片。
- 把本地图片转换成 data URL 写进预览 HTML。
- 远程图片和找不到的图片保持原样，不让 app 崩溃。

这个改动让普通 Markdown 文档里的相对图片可以正常预览，同时也避免了 WebView 随便读取本机任意文件。

相关计划文档是：

```text
docs/superpowers/plans/2026-07-18-mdpreview-icon-local-images.md
```

## 8. 第七阶段：优化 Recent 侧边栏交互

用起来以后，又发现 Recent 侧边栏有几个细节需要优化：

- 宽度偏宽，希望变窄。
- 需要能拖动调整宽度。
- 点击最近文件时，只有点到文字才有效，体验不好。
- 点击最近文件不应该改变排序。
- 用户要能手动拖动排序。
- 操作按钮位置要更符合使用习惯。

这些反馈推动了 UI 的进一步打磨：

- 侧边栏宽度收窄到更适合工具型 app 的比例。
- 使用 split view，让用户可以调整宽度。
- 最近文件整行都可以点击。
- 最近文件点击不再自动置顶。
- 支持拖动排序并持久化。
- `Open`、`Edit`、`Save` 最终放到了 `Recent` 标题后面。

这个阶段也移除了标题栏里重复的按钮，让界面只保留一套清晰入口。

最终侧边栏头部变成：

```text
Recent    Open  Edit  Save
```

当进入编辑模式时，`Edit` 会变成：

```text
Hide Editor
```

按钮状态也会跟着文档状态变化：

- 没打开文档时，`Edit` 不可用。
- 没有未保存修改时，`Save` 不可用。
- 有修改时，`Save` 可用。

相关文档包括：

```text
docs/superpowers/plans/2026-07-18-mdpreview-sidebar-toolbar-polish.md
docs/superpowers/plans/2026-07-18-mdpreview-async-preview-toolbar-left.md
docs/superpowers/specs/2026-07-18-logo-sidebar-actions-design.md
docs/superpowers/plans/2026-07-18-logo-sidebar-actions.md
```

## 9. 第八阶段：解决性能感知问题

在真实测试中发现，点击最近文件时如果 Markdown 渲染比较慢，用户会感觉 app 卡住。

这个问题不是单纯的“代码慢”，而是体验问题：

- 用户点击后，希望立即看到选中文件切换。
- 预览可以慢一点出来，但不能让整个界面像没反应。

于是实现了异步预览渲染：

- 文件选择和当前文档状态先立即切换。
- 预览生成放到后台队列。
- UI 显示 `Rendering...`。
- 如果用户快速切换文件，旧的渲染结果不能覆盖新的文件。
- 使用 generation/version 检查避免 stale render。

这一步让 app 的响应感明显更像成熟桌面应用。

## 10. 第九阶段：加入应用图标并打包

项目后期加入了自定义 logo。

这里也经历了一次细节处理：用户提供的新 logo 看起来是透明背景，但实际 PNG 是 RGB，棋盘格背景已经被烘进图片里。

Codex 做了图像处理：

- 把棋盘格背景转换成真正的 alpha 透明。
- 替换 `Resources/AppIcon.png`。
- 用打包脚本生成 `.icns`。
- 验证 `Info.plist` 仍然引用 `AppIcon`。
- 用 macOS 工具验证 `AppIcon.icns` 可以正常解析。

最终生成的 app 是：

```text
build/mdPreview.app
```

可以拖到 macOS 的“应用程序”目录里使用。由于它是本地未签名 app，第一次打开时 macOS 可能会提示安全确认。

## 11. 第十阶段：从父仓库拆成独立仓库

项目一开始放在 `aiskills` 父仓库下面，后面为了更好地独立维护，把它拆成了单独仓库。

拆分目标是：

- 保留 `markdown-mac-preview` 相关提交历史。
- 创建独立本地仓库。
- 推送到独立 GitHub 仓库。
- 原父仓库以后不再维护这个项目目录。

新的本地仓库位置是：

```text
/Users/liangbo/Documents/workspace/markdown-mac-preview
```

新的远端仓库是：

```text
git@github.com:liangbo/markdown-mac-preview.git
```

拆分完成后，又从父仓库 `aiskills` 中删除了旧目录，并把删除提交推送到了父仓库远端。

这一步让项目边界变得更清楚：以后所有开发都只在独立仓库里做。

## 12. 第十一阶段：沉淀 PRD 和分享文档

项目实现完成后，又做了两类文档沉淀。

第一类是产品需求文档：

```text
docs/product-requirements.md
```

这份文档面向其他 coding agent 或开发者，目标是让别人可以基于它从零实现 mdPreview。

第二类就是当前这份开发过程复盘：

```text
docs/development-story.md
```

这份文档面向分享和传播，重点不是“要实现什么”，而是“我是怎么一步一步用 Codex 把它做出来的”。

## 13. 我在这个项目里使用 Codex 的方式

这次开发不是简单地让 Codex 一次性生成代码，而是持续协作式开发。

整体模式大概是：

```text
想法 -> 讨论需求 -> 写 spec -> 写 plan -> 编码实现 -> 测试验证 -> 用户试用 -> 反馈优化 -> 再迭代
```

几个比较重要的实践：

### 13.1 先讨论，不急着写代码

有些问题一开始看起来像 bug，但其实背后是产品期望不清楚。

例如：

- Markdown 到底要不要渲染成真正 HTML？
- Recent 点击后要不要重新排序？
- 操作按钮应该放标题栏还是侧边栏？
- 点击最近文件时怎样才算“不卡”？

这些问题都是先讨论方案，再落代码。

### 13.2 每个阶段都留下文档

`docs/superpowers/specs` 保存的是设计决策。

`docs/superpowers/plans` 保存的是实施计划。

这样做的好处是：项目后来回看时，可以知道每个功能为什么出现、当时有哪些边界条件、验证标准是什么。

### 13.3 小步迭代，而不是一次做完

mdPreview 最终看起来是一个完整 app，但它不是一次性生成出来的。

它是这样逐步长出来的：

1. 先能启动。
2. 再能打开文件。
3. 再能预览。
4. 再能编辑和保存。
5. 再加最近文件。
6. 再修渲染方式。
7. 再加本地图片。
8. 再优化 UI。
9. 再优化性能。
10. 再打包和沉淀文档。

每一步都可以独立验证。

### 13.4 用测试保护迭代

项目里有针对核心逻辑的测试：

- 文档加载和保存。
- dirty state。
- Markdown stats。
- Markdown HTML 渲染。
- 最近文件存储。
- 最近文件排序。
- 本地图片处理。
- 异步预览状态。
- stale render 防护。
- 侧边栏按钮状态。

每次重要改动后都会跑：

```bash
swift test
```

打包时也会跑：

```bash
scripts/build-app.sh
plutil -lint build/mdPreview.app/Contents/Info.plist
```

### 13.5 用真实试用反馈推动优化

很多关键改动来自实际试用：

- HTML 没有真正渲染出来。
- 点击最近文件感觉慢。
- 最近文件点击区域不够大。
- 侧边栏太宽。
- app 图标背景不透明。
- 按钮位置不符合使用习惯。

这些不是一开始 PRD 里就写完的，而是在使用中发现，再让 Codex 继续调整。

## 14. 最终实现出来的 mdPreview

最终 mdPreview 具备这些能力：

- 原生 macOS app。
- 支持 `.md` 和 `.markdown`。
- 左侧 Recent 文件列表。
- Recent 后面有 `Open`、`Edit`、`Save`。
- 支持最近文件持久化。
- 支持手动拖动排序。
- 支持整行点击最近文件。
- 支持 HTML 预览。
- 支持 WebView 内嵌预览。
- 支持相对路径本地图片。
- 支持编辑模式。
- 支持实时预览。
- 支持异步渲染，减少卡顿感。
- 支持保存和 dirty state。
- 支持状态栏统计信息。
- 支持打包为 `mdPreview.app`。
- 有自定义透明背景 app 图标。
- 有完整测试覆盖。
- 有独立 GitHub 仓库。

## 15. 项目结构

当前独立仓库结构大致如下：

```text
markdown-mac-preview/
  Package.swift
  README.md
  Resources/
    AppIcon.png
  Sources/
    MarkdownMacPreviewApp/
      AppViewModel.swift
      ContentView.swift
      EditorView.swift
      MarkdownMacPreviewApp.swift
      PreviewView.swift
      RecentFile.swift
      RecentFilesSidebarView.swift
      StatusBarView.swift
    MarkdownMacPreviewCore/
      MarkdownDocument.swift
      MarkdownRenderer.swift
      MarkdownStats.swift
  Tests/
    MarkdownMacPreviewAppTests/
    MarkdownMacPreviewCoreTests/
  docs/
    product-requirements.md
    development-story.md
    superpowers/
      specs/
      plans/
  scripts/
    build-app.sh
```

## 16. 可以分享的核心观点

如果要把这次过程分享给别人，我觉得可以总结成几句话。

第一，AI coding agent 不是只能“一次性生成代码”，更适合做持续协作。

第二，一个真实应用的开发，很多价值不在第一次生成，而在后续反复试用、反馈、修正和沉淀。

第三，文档很重要。`spec` 记录为什么做，`plan` 记录怎么做，PRD 记录最终产品要求，复盘文档记录开发过程。

第四，测试和打包验证让 AI 写出来的东西从“看起来能用”变成“真的可交付”。

第五，把项目拆成独立仓库，是从实验变成正式项目的一个重要节点。

## 17. 后续可以继续做的方向

这个项目目前已经是一个可用的本地 Markdown 预览工具。后续还可以继续增强：

- 更完整的 GitHub Flavored Markdown 支持。
- 代码高亮。
- 深色模式细节优化。
- 文件拖拽打开。
- 设置默认打开方式。
- 最近文件搜索。
- 导出 HTML 或 PDF。
- app 签名和正式发布。
- 更完整的 UI 自动化测试。

这些都可以继续沿用当前工作方式：先写清楚需求，再设计，再计划，再小步实现和验证。

## 18. 总结

mdPreview 从一个简单想法开始：我想要一个本地 Mac 应用来预览 Markdown。

通过 Codex 的持续协作，它逐步变成了一个有真实 app 形态、有预览、有编辑、有最近文件、有图标、有打包脚本、有测试、有独立仓库、有产品文档的完整小项目。

这次过程最有价值的地方，不只是生成了一个应用，而是形成了一套可复用的 AI 协作开发流程：

```text
需求表达 -> 方案讨论 -> 文档沉淀 -> 计划拆解 -> 编码实现 -> 测试验证 -> 真实试用 -> 迭代优化 -> 项目独立化
```

这套流程以后也可以用在其他小工具、桌面应用或个人项目上。
