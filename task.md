# Voice Studio 开发任务清单

> 基于 DESIGN_DOCUMENT.md 分解的独立可测试任务

---

## 阶段一：项目基础设施 ✅

### Task 1.1: 创建 Xcode 项目
- [x] 创建 macOS App 项目，使用 SwiftUI 生命周期
- [x] 配置最低部署目标为 macOS 14.0
- [x] 设置 Bundle Identifier
- **验证**: 项目可编译运行，显示空白窗口 ✅

### Task 1.2: 配置 Swift Package 依赖
- [x] 添加 WhisperKit (0.15.0+)
- [x] 添加 KeyboardShortcuts (2.0.0+)
- [x] 添加 LaunchAtLogin-Modern (1.0.0+)
- **验证**: `swift build` 成功，依赖可导入 ✅

### Task 1.3: 配置权限文件
- [x] 创建 Entitlements.plist（麦克风、网络权限）
- [x] 配置 Info.plist（麦克风使用说明、LSUIElement）
- **验证**: 权限配置正确，无编译警告 ✅

---

## 阶段二：数据模型层 ✅

### Task 2.1: 实现 RecordingState 枚举
- [x] 定义 `idle`, `recording`, `processing`, `error(String)` 状态
- **验证**: 单元测试覆盖所有状态转换 ✅

### Task 2.2: 实现 WhisperModel 枚举
- [x] 定义 `small`, `largeTurbo`, `large` 三种模型
- [x] 实现 `id`, `displayName`, `downloadSize`, `parameters`, `description` 属性
- [x] 遵循 `CaseIterable`, `Identifiable` 协议
- **验证**: 单元测试验证所有模型属性值正确 ✅

### Task 2.3: 实现 TranscriptionResult 结构体
- [x] 包含 `text`, `language`, `segments`, `audioDuration`, `processingTime`
- **验证**: 可正确初始化并访问属性 ✅

### Task 2.4: 实现 TranslationProvider 枚举与 TranslationResult 结构体
- [x] TranslationProvider: `openai`, `anthropic`
- [x] TranslationResult: `originalText`, `translatedText`, `targetLanguage`, `processingTime`
- **验证**: 单元测试验证枚举和结构体 ✅

---

## 阶段三：存储服务层 ✅

### Task 3.1: 实现 KeychainManager
- [x] 实现 `save(key:value:)` 方法
- [x] 实现 `load(key:)` 方法
- [x] 实现 `delete(key:)` 方法
- [x] 定义 `KeychainError` 错误类型
- [x] 定义 `KeychainKey` 常量（openaiApiKey, anthropicApiKey）
- **验证**: 编译通过，代码符合设计文档 ✅

### Task 3.2: 实现 SettingsManager
- [x] 使用 `@Observable` + UserDefaults 管理用户设置
- [x] 包含：selectedModel, sourceLanguage, translationEnabled, translationProvider, targetLanguage, launchAtLogin, autoCopyToClipboard, showInMenuBar
- [x] 与 KeychainManager 集成管理 API 密钥
- **验证**: 编译通过，代码符合设计文档 ✅

---

## 阶段四：音频服务层 ✅

### Task 4.1: 实现 AudioManager 基础框架
- [x] 创建 `@MainActor` 类
- [x] 初始化 AVAudioEngine
- [x] 定义目标音频格式（16kHz, mono, Float32）
- [x] 实现 `onAudioLevelUpdate` 回调
- **验证**: 类可正确初始化 ✅

### Task 4.2: 实现音频录制功能
- [x] 实现 `startRecording()` 方法
- [x] 创建 AVAudioConverter（设备格式 → Whisper 格式）
- [x] 安装音频 Tap 采集数据
- [x] 启动 audioEngine
- **验证**: 可成功开始录音，无崩溃 ✅

### Task 4.3: 实现音频处理与格式转换
- [x] 实现 `processAudioBuffer()` 方法
- [x] 执行重采样（48kHz → 16kHz）
- [x] 执行声道转换（stereo → mono）
- [x] 线程安全地追加到 audioBuffer
- **验证**: 输出音频格式符合 WhisperKit 要求 ✅

### Task 4.4: 实现音量监测
- [x] 实现 RMS 计算方法
- [x] 通过 `Task { @MainActor in }` 回调到主线程
- **验证**: 录音时 onAudioLevelUpdate 持续回调，值在 0-1 范围 ✅

### Task 4.5: 实现停止录音功能
- [x] 实现 `stopRecording()` 方法
- [x] 移除 Tap，停止 Engine
- [x] 返回音频数据 `[Float]`
- **验证**: 录音停止后返回有效音频数据 ✅

### Task 4.6: 实现 AudioError 错误处理
- [x] 定义 `converterCreationFailed`, `engineStartFailed` 错误
- [x] 实现 `LocalizedError` 协议
- **验证**: 错误信息可正确显示 ✅

---

## 阶段五：语音识别服务层 ✅

### Task 5.1: 实现 WhisperService 基础框架
- [x] 创建服务类，持有 WhisperKit 实例
- [x] 定义 TranscriptionConfig 配置结构
- [x] 支持延迟加载模型
- **验证**: 服务可正确初始化 ✅

### Task 5.2: 实现模型加载功能
- [x] 实现 `loadModel(model:)` 异步方法
- [x] 处理模型未下载的情况
- [x] 更新加载状态
- **验证**: 可成功加载已下载的模型 ✅

### Task 5.3: 实现音频转录功能
- [x] 实现 `transcribe(audioData:)` 异步方法
- [x] 配置语言、标点优化等参数
- [x] 返回 TranscriptionResult
- **验证**: 输入音频数据，返回正确转录文本 ✅

### Task 5.4: 实现 ModelManager
- [x] 使用 `@Observable` 宏
- [x] 实现 `status(for:)` 查询模型状态
- [x] 实现 `startDownload()` 启动下载
- [x] 实现 `cancelDownload()` 取消下载
- [x] 实现 `checkDownloadedModels()` 检查本地模型
- [x] 实现进度更新回调
- **验证**: 可下载模型并跟踪进度，支持取消 ✅

---

## 阶段六：翻译服务层 ✅

### Task 6.1: 定义 TranslationService 协议
- [x] 定义 `translate(text:to:) async throws -> String` 方法
- [x] 定义 `TranslationError` 错误类型
- [x] 实现 `NetworkRetry` 网络重试工具（3次自动重试）
- **验证**: 协议定义正确，编译通过 ✅

### Task 6.2: 实现 OpenAITranslator
- [x] 遵循 TranslationService 协议
- [x] 使用 URLSession + async/await
- [x] 调用 GPT-4o-mini API
- [x] 处理网络错误和 API 错误
- [x] 集成网络重试机制
- **验证**: 编译通过，代码符合设计文档 ✅

### Task 6.3: 实现 AnthropicTranslator
- [x] 遵循 TranslationService 协议
- [x] 使用 URLSession + async/await
- [x] 调用 Claude API
- [x] 处理网络错误和 API 错误
- [x] 集成网络重试机制
- **验证**: 编译通过，代码符合设计文档 ✅

### Task 6.4: 实现翻译服务工厂/协调器
- [x] 创建 `TranslationCoordinator`（@MainActor @Observable）
- [x] 根据 TranslationProvider 选择具体实现
- [x] 管理 API 密钥获取（从 KeychainManager）
- [x] 返回 TranslationResult（含处理时间）
- **验证**: 可根据配置切换翻译提供商，编译通过 ✅

---

## 阶段七：快捷键服务层 ✅

### Task 7.1: 定义快捷键名称
- [x] 扩展 `KeyboardShortcuts.Name`
- [x] 定义 `pushToTalk` (⌘⇧V)
- [x] 定义 `showWindow` (⌘⇧A)
- [x] 定义 `copyResult` (⌘⇧C)
- **验证**: 快捷键名称可正确访问 ✅

### Task 7.2: 实现 HotkeyManager
- [x] 创建 `@MainActor @Observable` 类
- [x] 实现 Push-to-Talk（按下开始，松开停止）
- [x] 实现显示窗口快捷键
- [x] 实现复制结果快捷键
- [x] 发送通知到 NotificationCenter
- **验证**: 快捷键可触发对应回调 ✅

### Task 7.3: 实现辅助功能权限检查
- [x] 实现 `AccessibilityHelper.checkAccessibilityPermission()`
- [x] 实现 `requestAccessibilityPermission()`
- [x] 实现 `openAccessibilitySettings()`
- **验证**: 可正确检测和请求辅助功能权限 ✅

---

## 阶段八：应用状态管理 ✅

### Task 8.1: 实现 AppState
- [x] 创建 `@Observable` 类
- [x] 包含 recordingState, transcriptionText, translationText
- [x] 包含 selectedModel, isTranslationEnabled
- [x] 包含 audioLevel（用于波形显示）
- **验证**: 状态变化可被 SwiftUI 视图观察 ✅

### Task 8.2: 实现 AppDelegate
- [x] 处理应用生命周期
- [x] 启动时检查权限（麦克风、辅助功能）
- [x] 初始化核心服务
- **验证**: 应用启动时正确初始化 ✅

### Task 8.3: 实现 Constants
- [x] 定义通知名称（showMainWindow, copyLastResult）
- [x] 定义 UI 常量（动画时长、颜色等）
- **验证**: 常量可被正确引用 ✅

---

## 阶段九：UI 组件层 ✅

### Task 9.1: 实现 StatusLabel 组件
- [x] 显示当前状态文字
- [x] 根据 RecordingState 显示不同样式
- **验证**: 状态变化时 UI 正确更新 ✅

### Task 9.2: 实现 CopyButton 组件
- [x] 点击复制文本到剪贴板
- [x] 使用 NSPasteboard
- [x] 复制成功反馈动画
- **验证**: 点击后文本被复制到剪贴板 ✅

### Task 9.3: 实现 ModelSelector 组件
- [x] Picker 选择模型
- [x] 显示模型下载状态
- [x] 集成下载进度条
- [x] 支持取消下载
- **验证**: 可选择模型，显示正确状态 ✅

### Task 9.4: 实现 SecureTextField 组件
- [x] 密码输入框（API Key）
- [x] 支持显示/隐藏切换
- **验证**: 输入可被隐藏/显示 ✅

---

## 阶段十：主窗口视图 ✅

### Task 10.1: 实现 WaveformView
- [x] 根据音量数据绘制波形
- [x] 使用 Canvas 或 Shape
- [x] 动画更新（0.05s 间隔）
- **验证**: 录音时显示动态波形 ✅

### Task 10.2: 实现 RecordButton
- [x] 大圆形按钮
- [x] 录音时显示红色脉动动画
- [x] 点击触发录音/停止
- **验证**: 按钮状态与录音状态同步 ✅

### Task 10.3: 实现 TranscriptionPanel
- [x] 显示转录文本
- [x] 包含标题和复制按钮
- [x] 支持文本选择
- **验证**: 转录完成后正确显示文本 ✅

### Task 10.4: 实现 TranslationPanel
- [x] 可折叠面板
- [x] 显示翻译文本
- [x] 包含标题和复制按钮
- **验证**: 翻译完成后正确显示，可折叠 ✅

### Task 10.5: 实现 MainWindowView
- [x] 组合 WaveformView, RecordButton, TranscriptionPanel, TranslationPanel
- [x] 底部状态栏（性能统计、模型选择、清除按钮）
- [x] 显示下载进度（如有）
- **验证**: 完整主窗口 UI 渲染正确 ✅

---

## 阶段十一：菜单栏视图 ✅

### Task 11.1: 实现 MenuBarIcon
- [x] 麦克风图标
- [x] 录音时变红
- **验证**: 图标随录音状态变化 ✅

### Task 11.2: 实现 MenuBarView
- [x] 开始/停止录音菜单项
- [x] 显示最近转录预览
- [x] 复制最近结果
- [x] 打开设置/主窗口
- [x] 退出应用
- **验证**: 所有菜单项可点击并执行对应功能 ✅

---

## 阶段十二：设置窗口视图 ✅

### Task 12.1: 实现 GeneralSettingsView
- [x] 开机自启动开关（集成 LaunchAtLogin）
- [x] 菜单栏显示开关
- [x] 自动复制到剪贴板开关
- **验证**: 设置可保存并生效 ✅

### Task 12.2: 实现 RecognitionSettingsView
- [x] 模型选择器（集成 ModelSelector）
- [x] 语言选择
- **验证**: 模型和语言设置可保存 ✅

### Task 12.3: 实现 TranslationSettingsView
- [x] 翻译提供商选择（OpenAI/Anthropic）
- [x] API Key 输入（集成 SecureTextField）
- [x] 目标语言选择
- **验证**: 翻译配置可保存到 Keychain ✅

### Task 12.4: 实现 ShortcutsSettingsView
- [x] 显示当前快捷键
- [x] 支持录制新快捷键（使用 KeyboardShortcuts.Recorder）
- **验证**: 快捷键可自定义并保存 ✅

### Task 12.5: 实现 SettingsView
- [x] 组合各设置分组
- [x] TabView 或分段布局
- **验证**: 完整设置窗口渲染正确 ✅

---

## 阶段十三：应用入口与集成 ✅

### Task 13.1: 实现 VoiceStudioApp 入口
- [x] 配置 @main App 结构
- [x] 初始化 AppState
- [x] 配置 MenuBarExtra
- [x] 配置主窗口 WindowGroup
- [x] 配置设置窗口 Settings
- **验证**: 应用启动显示菜单栏图标和主窗口 ✅

### Task 13.2: 集成核心工作流
- [x] 录音 → 转录 → 显示完整流程
- [x] 可选翻译流程
- [x] 快捷键触发录音
- **验证**: 端到端工作流正常运行 ✅

### Task 13.3: 实现错误处理与用户提示
- [x] 定义 VoiceStudioError 错误类型
- [x] 权限缺失提示（Alert + 跳转）
- [x] 网络错误提示（Toast）
- [x] 模型未下载提示（触发下载）
- **验证**: 各类错误场景有友好提示 ✅

---

## 阶段十四：工具类与优化

### Task 14.1: 实现 ClipboardHelper
- [ ] 封装 NSPasteboard 操作
- [ ] 支持复制文本
- **验证**: 文本可正确复制到系统剪贴板

### Task 14.2: 实现 PermissionHelper
- [ ] 麦克风权限检查与请求
- [ ] 辅助功能权限检查与引导
- **验证**: 权限状态可正确检测

### Task 14.3: 实现 Logger
- [ ] 统一日志工具
- [ ] 支持不同日志级别
- **验证**: 日志可正确输出

### Task 14.4: 实现 View/Color Extensions
- [ ] 颜色系统扩展（Light/Dark Mode）
- [ ] 常用 View 修饰符
- **验证**: 扩展可正常使用

---

## 阶段十五：测试与发布

### Task 15.1: 单元测试
- [ ] 数据模型测试
- [ ] 服务层测试（Mock 依赖）
- [ ] 工具类测试
- **验证**: 测试覆盖率 > 70%

### Task 15.2: 集成测试
- [ ] 完整转录流程测试
- [ ] 翻译流程测试
- [ ] 快捷键功能测试
- **验证**: 核心流程自动化测试通过

### Task 15.3: 性能测试
- [ ] 转录延迟 < 2s（10s 音频，Large-v3-Turbo）
- [ ] 内存峰值 < 2GB
- [ ] 启动时间 < 1s
- **验证**: 性能指标达标

### Task 15.4: 发布准备
- [ ] App Icon 设计
- [ ] 代码签名配置
- [ ] Apple 公证
- [ ] DMG 打包
- **验证**: 可生成可分发的 DMG 安装包

---

## 任务依赖关系

```
阶段一 (基础设施)
    ↓
阶段二 (数据模型) + 阶段三 (存储服务)
    ↓
阶段四 (音频服务) + 阶段五 (语音识别) + 阶段六 (翻译服务) + 阶段七 (快捷键服务)
    ↓
阶段八 (应用状态)
    ↓
阶段九 (UI组件)
    ↓
阶段十 (主窗口) + 阶段十一 (菜单栏) + 阶段十二 (设置窗口)
    ↓
阶段十三 (应用集成)
    ↓
阶段十四 (工具类优化)
    ↓
阶段十五 (测试发布)
```

---

*任务清单版本: 1.0*
*生成日期: 2026-01-11*
*基于: DESIGN_DOCUMENT.md v1.3*
