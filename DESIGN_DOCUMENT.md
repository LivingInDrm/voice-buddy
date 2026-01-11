# Voice Studio - macOS 语音助手设计文档

## 1. 项目概述

### 1.1 产品定位
Voice Studio 是一款 macOS 原生语音助手应用，提供高精度的语音转文字功能，并支持可选的 LLM 翻译。应用采用混合形态设计（菜单栏 + 主窗口），专为 Apple Silicon 优化。

### 1.2 技术栈

| 模块 | 技术选型 | 说明 |
|------|----------|------|
| UI 框架 | SwiftUI | Apple 原生声明式 UI |
| 语音识别 | WhisperKit | Apple Silicon 深度优化 |
| 音频采集 | AVAudioEngine | Apple 原生音频框架 |
| 全局快捷键 | KeyboardShortcuts | Sindre Sorhus 开源库 |
| 文本输出 | NSPasteboard | 系统剪贴板 |
| 翻译服务 | OpenAI / Anthropic API | 云端 LLM |
| 设置存储 | UserDefaults + @AppStorage | SwiftUI 原生方案 |
| 网络请求 | URLSession + async/await | Swift 原生异步 |

### 1.3 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | macOS 14.0 (Sonoma) 及以上 |
| 芯片 | Apple Silicon (M1/M2/M3/M4) |
| 内存 | 8GB 及以上（推荐 16GB） |
| 存储 | 2GB 可用空间（模型存储） |

---

## 2. 应用架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        Voice Studio App                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Menu Bar      │  │   Main Window   │  │  Settings       │  │
│  │   Component     │  │   (SwiftUI)     │  │  Window         │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
│           │                    │                    │           │
│           └────────────────────┼────────────────────┘           │
│                                │                                │
│  ┌─────────────────────────────▼─────────────────────────────┐  │
│  │                    AppState (Observable)                   │  │
│  │  - recordingState: RecordingState                         │  │
│  │  - transcriptionText: String                              │  │
│  │  - translationText: String                                │  │
│  │  - selectedModel: WhisperModel                            │  │
│  │  - isTranslationEnabled: Bool                             │  │
│  └─────────────────────────────┬─────────────────────────────┘  │
│                                │                                │
│  ┌──────────────┬──────────────┼──────────────┬──────────────┐  │
│  │              │              │              │              │  │
│  ▼              ▼              ▼              ▼              ▼  │
│ ┌────────┐ ┌─────────┐ ┌───────────┐ ┌──────────┐ ┌────────┐   │
│ │ Audio  │ │Whisper  │ │Translation│ │ Hotkey   │ │ Model  │   │
│ │Manager │ │Service  │ │ Service   │ │ Manager  │ │Manager │   │
│ └────────┘ └─────────┘ └───────────┘ └──────────┘ └────────┘   │
│     │           │            │            │           │         │
│     ▼           ▼            ▼            ▼           ▼         │
│ ┌────────┐ ┌─────────┐ ┌───────────┐ ┌──────────┐ ┌────────┐   │
│ │AVAudio │ │Whisper  │ │ OpenAI /  │ │Keyboard  │ │ File   │   │
│ │Engine  │ │Kit      │ │ Anthropic │ │Shortcuts │ │Manager │   │
│ └────────┘ └─────────┘ └───────────┘ └──────────┘ └────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 模块职责

| 模块 | 职责 | 依赖 |
|------|------|------|
| **AppState** | 全局状态管理，数据绑定 | - |
| **AudioManager** | 音频采集、音量监测 | AVAudioEngine |
| **WhisperService** | 语音转文字 | WhisperKit |
| **TranslationService** | 文本翻译 | URLSession |
| **HotkeyManager** | 全局快捷键监听 | KeyboardShortcuts |
| **ModelManager** | 模型下载和管理 | FileManager, WhisperKit |

---

## 3. 核心功能设计

### 3.1 语音识别

#### 3.1.1 模型配置

| 模型 | HuggingFace ID | 参数量 | 下载大小 | 推荐场景 |
|------|----------------|--------|----------|----------|
| Small | `openai_whisper-small` | 244M | ~500MB | 快速转录 |
| Large-v3-Turbo | `openai_whisper-large-v3-turbo` | 809M | ~1.6GB | **默认推荐** |
| Large-v3 | `openai_whisper-large-v3` | 1.5B | ~3GB | 最高精度 |

#### 3.1.2 转录参数

```swift
struct TranscriptionConfig {
    var language: String = "zh"           // 源语言
    var task: DecodingTask = .transcribe  // 转录任务
}
```

#### 3.1.3 处理流程

```
用户触发录音
      ↓
AudioManager.startRecording()
      ↓
AVAudioEngine 采集音频（设备原生采样率，如 48kHz）
      ↓
AVAudioConverter 重采样 → 16kHz, mono, Float32
      ↓
实时音量回调 → UI 波形更新
      ↓
用户停止录音
      ↓
AudioManager.stopRecording() → [Float] 音频数据
      ↓
WhisperService.transcribe(audioData)
      ↓
WhisperKit.transcribe() → TranscriptionResult
      ↓
更新 AppState.transcriptionText
      ↓
(可选) 触发翻译流程
```

#### 3.1.4 音频采集与格式转换

WhisperKit 要求输入格式为 **16kHz, mono, Float32**，但 macOS 麦克风通常为 44.1kHz 或 48kHz。需要在采集时进行格式转换：

```swift
import AVFoundation

@MainActor
final class AudioManager {
    
    private let audioEngine = AVAudioEngine()
    private var audioConverter: AVAudioConverter?
    private var audioBuffer: [Float] = []
    
    // Whisper 要求的目标格式
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16000,
        channels: 1,
        interleaved: false
    )!
    
    // 音量回调（用于波形可视化）
    var onAudioLevelUpdate: ((Float) -> Void)?
    
    func startRecording() throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // 创建格式转换器：设备格式 → Whisper 格式
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioError.converterCreationFailed
        }
        self.audioConverter = converter
        self.audioBuffer.removeAll()
        
        // 安装音频 Tap（在音频渲染线程回调）
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        try audioEngine.start()
    }
    
    func stopRecording() -> [Float] {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        return audioBuffer
    }
    
    // 在音频渲染线程执行（非主线程）
    private func processAudioBuffer(_ inputBuffer: AVAudioPCMBuffer) {
        guard let converter = audioConverter else { return }
        
        // 计算输出缓冲区大小
        let ratio = targetFormat.sampleRate / inputBuffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCapacity
        ) else { return }
        
        // 执行格式转换（重采样 + 声道转换）
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        guard status != .error, let floatData = outputBuffer.floatChannelData?[0] else { return }
        
        // 计算音量（RMS）并回调到主线程更新 UI
        let frameLength = Int(outputBuffer.frameLength)
        let rms = Self.calculateRMS(floatData, frameCount: frameLength)
        
        Task { @MainActor [weak self] in
            self?.onAudioLevelUpdate?(rms)
        }
        
        // 追加到缓冲区（需要线程安全）
        let samples = Array(UnsafeBufferPointer(start: floatData, count: frameLength))
        
        Task { @MainActor [weak self] in
            self?.audioBuffer.append(contentsOf: samples)
        }
    }
    
    private static func calculateRMS(_ data: UnsafePointer<Float>, frameCount: Int) -> Float {
        var sum: Float = 0
        for i in 0..<frameCount {
            sum += data[i] * data[i]
        }
        return sqrt(sum / Float(frameCount))
    }
}

enum AudioError: LocalizedError {
    case converterCreationFailed
    case engineStartFailed
    
    var errorDescription: String? {
        switch self {
        case .converterCreationFailed:
            return "Failed to create audio format converter"
        case .engineStartFailed:
            return "Failed to start audio engine"
        }
    }
}
```

**关键设计点**：

| 问题 | 解决方案 |
|------|----------|
| 采样率不匹配 | 使用 `AVAudioConverter` 将设备采样率转换为 16kHz |
| 声道不匹配 | Converter 自动处理 stereo → mono 转换 |
| 线程安全 | 音频回调在渲染线程，通过 `Task { @MainActor in }` 回写主线程状态 |
| 性能 | 格式转换在音频线程完成，不阻塞主线程 |

### 3.2 翻译服务

#### 3.2.1 支持的提供商

| 提供商 | 模型 | 特点 |
|--------|------|------|
| OpenAI | gpt-4o-mini | 快速、经济 |
| Anthropic | claude-sonnet-4-20250514 | 高质量 |

#### 3.2.2 API 设计

```swift
protocol TranslationService {
    func translate(text: String, to targetLanguage: String) async throws -> String
}

class OpenAITranslator: TranslationService { ... }
class AnthropicTranslator: TranslationService { ... }
```

### 3.3 快捷键设计

#### 3.3.1 默认快捷键

| 功能 | 快捷键 | 触发方式 |
|------|--------|----------|
| 录音切换 | ⌘ + Shift + V | 按下开始，松开结束（Push-to-Talk） |
| 显示窗口 | ⌘ + Shift + A | 单次按下 |
| 快速复制 | ⌘ + Shift + C | 复制最近转录结果 |

#### 3.3.2 实现方案

```swift
import KeyboardShortcuts

// 1. 定义快捷键名称
extension KeyboardShortcuts.Name {
    static let pushToTalk = Self("pushToTalk", default: .init(.v, modifiers: [.command, .shift]))
    static let showWindow = Self("showWindow", default: .init(.a, modifiers: [.command, .shift]))
    static let copyResult = Self("copyResult", default: .init(.c, modifiers: [.command, .shift]))
}
```

#### 3.3.3 Push-to-Talk 完整实现

HotkeyManager 采用解耦设计，不直接持有 AudioManager，而是通过回调通知外部处理录音逻辑。这样设计更灵活、易于测试。

```swift
import SwiftUI
import KeyboardShortcuts

// 通知名称扩展
extension Notification.Name {
    static let showMainWindow = Notification.Name("showMainWindow")
    static let copyLastResult = Notification.Name("copyLastResult")
}

@MainActor
@Observable
final class HotkeyManager {
    
    private(set) var isRecording = false
    
    private var onRecordingStarted: (() -> Void)?
    private var onRecordingStopped: (() -> Void)?
    
    init() {}
    
    func configure(
        onRecordingStarted: @escaping () -> Void,
        onRecordingStopped: @escaping () -> Void
    ) {
        self.onRecordingStarted = onRecordingStarted
        self.onRecordingStopped = onRecordingStopped
        
        setupHotkeys()
    }
    
    private func setupHotkeys() {
        KeyboardShortcuts.onKeyDown(for: .pushToTalk) { [weak self] in
            Task { @MainActor in
                self?.startRecording()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .pushToTalk) { [weak self] in
            Task { @MainActor in
                self?.stopRecording()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .showWindow) {
            NotificationCenter.default.post(name: .showMainWindow, object: nil)
        }
        
        KeyboardShortcuts.onKeyUp(for: .copyResult) {
            NotificationCenter.default.post(name: .copyLastResult, object: nil)
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        onRecordingStarted?()
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        onRecordingStopped?()
    }
    
    func removeHotkeys() {
        KeyboardShortcuts.disable(.pushToTalk)
        KeyboardShortcuts.disable(.showWindow)
        KeyboardShortcuts.disable(.copyResult)
    }
}
```

**设计要点**：

| 特性 | 说明 |
|------|------|
| 解耦设计 | 不持有 AudioManager，通过回调通知外部 |
| 延迟配置 | 使用 `configure()` 方法设置回调，便于依赖注入 |
| 状态跟踪 | `isRecording` 属性可被 UI 观察 |
| 防重入 | startRecording/stopRecording 有状态检查 |
| 清理支持 | `removeHotkeys()` 方法可禁用所有快捷键 |

#### 3.3.4 辅助功能权限处理

全局快捷键需要辅助功能权限，需在应用启动时检查并引导用户授权：

```swift
import Cocoa

struct AccessibilityHelper {
    /// 检查辅助功能权限
    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// 请求辅助功能权限（弹出系统提示）
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// 打开系统辅助功能设置页面
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
```

### 3.4 文本输出

#### 3.4.1 输出方式

| 方式 | 实现 | 触发 |
|------|------|------|
| 剪贴板复制 | NSPasteboard | 点击 Copy 按钮 |
| 自动复制 | NSPasteboard | 可选设置 |
| 模拟输入 | CGEvent (预留) | 未来扩展 |

---

## 4. UI 设计

### 4.1 应用形态

**混合模式**：
- 菜单栏常驻图标（主入口）
- 独立主窗口（详细操作）
- 设置窗口（配置管理）

### 4.2 菜单栏组件

```
┌──────────────────────────────┐
│  🎤 ▼                        │  ← 菜单栏图标（录音时变红）
├──────────────────────────────┤
│  ● Start Recording  ⌘⇧V     │
│  ─────────────────────────   │
│  Last: "你好世界"             │  ← 最近转录预览
│  ─────────────────────────   │
│  📋 Copy Last Result         │
│  ─────────────────────────   │
│  ⚙️ Settings...              │
│  📖 Open Main Window         │
│  ─────────────────────────   │
│  ⏻ Quit Voice Studio        │
└──────────────────────────────┘
```

### 4.3 主窗口设计

```
┌─────────────────────────────────────────────────────────────────┐
│  Voice Studio                                    ─  □  ✕       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │     ▁ ▂ ▅ ▇ █ ▇ ▅ ▂ ▁ ▂ ▅ ▇ █ ▇ ▅ ▂ ▁ ▂ ▅ ▇ █        │   │ ← 波形可视化
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│                         ┌───────┐                               │
│                         │       │                               │
│                         │   ◉   │  ← 录音按钮（大圆形）          │
│                         │       │     录音时脉动 + 红色光晕      │
│                         └───────┘                               │
│                                                                 │
│                    Recording... Speak now                       │ ← 状态文字
│                      ⌘⇧V to toggle                             │ ← 快捷键提示
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  TRANSCRIPTION                                       [Copy]     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 转录的文字将显示在这里...                                  │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  TRANSLATION                                         [Copy]     │ ← 可折叠面板
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ English translation will appear here...                 │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  ☑ Translate to English    Model: [Large-v3-Turbo ▼]          │
│                                                                 │
│  Audio: 2.5s → Process: 0.8s (3.1x)              [Clear]       │ ← 性能统计
└─────────────────────────────────────────────────────────────────┘
```

### 4.4 设置窗口

```
┌─────────────────────────────────────────────────────────────────┐
│  Settings                                           ✕           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  GENERAL                                                        │
│  ─────────────────────────────────────────────────────────────  │
│  ☑ Launch at login                                             │
│  ☑ Show in menu bar                                            │
│  ☑ Auto-copy transcription to clipboard                        │
│                                                                 │
│  SPEECH RECOGNITION                                             │
│  ─────────────────────────────────────────────────────────────  │
│  Model:     [Large-v3-Turbo ▼]        [Download]               │
│  Language:  [Chinese (zh) ▼]                                    │
│                                                                 │
│  TRANSLATION                                                    │
│  ─────────────────────────────────────────────────────────────  │
│  Provider:  ○ OpenAI    ● Claude                               │
│  API Key:   [••••••••••••••••••••]  👁                         │
│  Target:    [English ▼]                                         │
│                                                                 │
│  SHORTCUTS                                                      │
│  ─────────────────────────────────────────────────────────────  │
│  Toggle Recording:  [⌘⇧V]    [Record New]                      │
│  Show Window:       [⌘⇧A]    [Record New]                      │
│                                                                 │
│                                          [Cancel]  [Save]       │
└─────────────────────────────────────────────────────────────────┘
```

### 4.5 模型下载（内嵌式进度）

模型下载采用**非阻塞、内嵌式**设计，直接在模型选择器位置显示进度，不弹出对话框：

#### 4.5.1 状态流转

```
[未下载] → 点击下载 → [下载中] → 完成 → [已下载]
                         ↓
                    点击取消 → [未下载]
```

#### 4.5.2 UI 状态设计

**状态 1：模型未下载**
```
Model:  [Large-v3-Turbo ▼]  ⬇️ Download (1.6 GB)
```

**状态 2：下载中（替换原位置）**
```
Model:  [Large-v3-Turbo ▼]  ████████░░░░ 67%  ✕
                            ↑ 进度条      ↑ 取消按钮
```

**状态 3：已下载**
```
Model:  [Large-v3-Turbo ▼]  ✓ Ready
```

#### 4.5.3 主窗口底部状态栏集成

下载进度也可在底部状态栏显示，允许用户继续其他操作：

```
┌─────────────────────────────────────────────────────────────────┐
│  ...（主窗口其他内容）...                                         │
├─────────────────────────────────────────────────────────────────┤
│  ☑ Translate to English    Model: [Small ▼]  ✓ Ready           │
│                                                                 │
│  ⬇️ Downloading Large-v3-Turbo: ████████░░ 67% (1.1/1.6 GB)  ✕  │
│                                                                 │
│  Audio: 2.5s → Process: 0.8s (3.1x)              [Clear]       │
└─────────────────────────────────────────────────────────────────┘
```

**特点**：
- 下载时可继续使用当前已下载的模型进行转录
- 下载完成后自动切换到新模型（可选）
- 点击 ✕ 取消下载，进度会保留（支持断点续传，取决于 HuggingFace Hub）

#### 4.5.4 SwiftUI 实现

```swift
import SwiftUI

struct ModelSelectorView: View {
    @Binding var selectedModel: WhisperModel
    @State var downloadManager: ModelDownloadManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Model:")
                .foregroundColor(.secondary)
            
            Picker("", selection: $selectedModel) {
                ForEach(WhisperModel.allCases) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .frame(width: 160)
            
            // 根据状态显示不同内容
            modelStatusView
        }
    }
    
    @ViewBuilder
    private var modelStatusView: some View {
        let status = downloadManager.status(for: selectedModel)
        
        switch status {
        case .notDownloaded:
            Button {
                downloadManager.startDownload(selectedModel)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                    Text("Download (\(selectedModel.downloadSize))")
                }
            }
            .buttonStyle(.borderless)
            
        case .downloading(let progress):
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .frame(width: 80)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .monospacedDigit()
                
                Button {
                    downloadManager.cancelDownload(selectedModel)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
            
        case .downloaded:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Ready")
            }
            .foregroundColor(.secondary)
        }
    }
}

// 下载状态枚举
enum ModelDownloadStatus {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
}

// 下载管理器（使用 @Observable 宏，macOS 14+）
// 注意：所有状态修改必须在 MainActor 上执行
@MainActor
@Observable
final class ModelDownloadManager {
    private var downloadTasks: [WhisperModel: Task<Void, Never>] = [:]
    private(set) var downloadProgress: [WhisperModel: Double] = [:]
    private(set) var downloadedModels: Set<WhisperModel> = []
    private(set) var downloadErrors: [WhisperModel: Error] = [:]
    
    init() {
        // 启动时检查已下载的模型
        Task {
            await checkDownloadedModels()
        }
    }
    
    func status(for model: WhisperModel) -> ModelDownloadStatus {
        if downloadedModels.contains(model) {
            return .downloaded
        }
        if let progress = downloadProgress[model] {
            return .downloading(progress: progress)
        }
        return .notDownloaded
    }
    
    func startDownload(_ model: WhisperModel) {
        // 避免重复下载
        guard downloadTasks[model] == nil else { return }
        
        // 使用 Task { @MainActor in } 确保所有状态修改在主线程
        let task = Task { @MainActor in
            downloadProgress[model] = 0
            downloadErrors.removeValue(forKey: model)
            
            do {
                // WhisperKit 下载
                // 注意：WhisperKit 的下载是异步的，会自动在后台线程执行
                // 但我们在 @MainActor Task 中调用，状态更新是安全的
                let whisperKit = try await WhisperKit(
                    model: model.id,
                    modelRepo: "argmaxinc/whisperkit-coreml",
                    download: true
                )
                
                // 下载成功，更新状态
                downloadProgress.removeValue(forKey: model)
                downloadedModels.insert(model)
                
            } catch is CancellationError {
                // 用户取消下载，静默处理
                downloadProgress.removeValue(forKey: model)
                
            } catch {
                // 其他错误，记录并清理状态
                downloadProgress.removeValue(forKey: model)
                downloadErrors[model] = error
            }
            
            // 无论成功失败，清理 task 引用
            downloadTasks.removeValue(forKey: model)
        }
        
        downloadTasks[model] = task
    }
    
    func cancelDownload(_ model: WhisperModel) {
        downloadTasks[model]?.cancel()
        downloadTasks.removeValue(forKey: model)
        downloadProgress.removeValue(forKey: model)
    }
    
    /// 检查本地已下载的模型
    private func checkDownloadedModels() async {
        for model in WhisperModel.allCases {
            // 尝试获取本地模型路径，如果存在则标记为已下载
            // 实际实现需要调用 WhisperKit 的模型检查 API
            let localPath = try? await WhisperKit.modelPath(for: model.id)
            if localPath != nil {
                downloadedModels.insert(model)
            }
        }
    }
}
```

### 4.6 视觉规范

#### 4.6.1 颜色系统

| 用途 | Light Mode | Dark Mode |
|------|------------|-----------|
| 背景 | #FFFFFF | #1C1C1E |
| 次级背景 | #F2F2F7 | #2C2C2E |
| 主文字 | #000000 | #FFFFFF |
| 次级文字 | #8E8E93 | #8E8E93 |
| 强调色 | #007AFF | #0A84FF |
| 录音状态 | #FF3B30 | #FF453A |
| 成功状态 | #34C759 | #30D158 |

#### 4.6.2 动画规范

| 动画 | 时长 | 曲线 |
|------|------|------|
| 状态切换 | 0.3s | easeInOut |
| 波形更新 | 0.05s | linear |
| 按钮脉动 | 1.0s | easeInOut (循环) |
| 面板展开 | 0.25s | spring |

---

## 5. 数据模型

### 5.1 核心数据结构

```swift
// 录音状态
enum RecordingState {
    case idle
    case recording
    case processing
    case error(String)
}

// Whisper 模型
enum WhisperModel: String, CaseIterable, Identifiable {
    case small = "openai_whisper-small"
    case largeTurbo = "openai_whisper-large-v3-turbo"
    case large = "openai_whisper-large-v3"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .largeTurbo: return "Large v3 Turbo"
        case .large: return "Large v3"
        }
    }
    
    var downloadSize: String {
        switch self {
        case .small: return "~500 MB"
        case .largeTurbo: return "~1.6 GB"
        case .large: return "~3 GB"
        }
    }
    
    var parameters: String {
        switch self {
        case .small: return "244M"
        case .largeTurbo: return "809M"
        case .large: return "1.5B"
        }
    }
    
    var description: String {
        switch self {
        case .small: return "Fast transcription with good accuracy"
        case .largeTurbo: return "Best balance of speed and accuracy (Recommended)"
        case .large: return "Highest accuracy, slower processing"
        }
    }
}

// 翻译提供商
enum TranslationProvider: String, CaseIterable {
    case openai = "openai"
    case anthropic = "anthropic"
}

// 转录结果
struct TranscriptionResult {
    let text: String
    let language: String
    let segments: [TranscriptionSegment]
    let audioDuration: TimeInterval
    let processingTime: TimeInterval
}

// 翻译结果
struct TranslationResult {
    let originalText: String
    let translatedText: String
    let targetLanguage: String
    let processingTime: TimeInterval
}
```

### 5.2 持久化数据

```swift
// UserDefaults Keys
enum SettingsKey: String {
    case selectedModel = "selectedWhisperModel"
    case sourceLanguage = "sourceLanguage"
    case translationEnabled = "translationEnabled"
    case translationProvider = "translationProvider"
    case targetLanguage = "targetLanguage"
    case openaiApiKey = "openaiApiKey"          // Keychain
    case anthropicApiKey = "anthropicApiKey"    // Keychain
    case launchAtLogin = "launchAtLogin"
    case autoCopyToClipboard = "autoCopyToClipboard"
    case showInMenuBar = "showInMenuBar"
}
```

### 5.3 Keychain 存储

敏感数据（API 密钥）使用 Keychain 存储，确保安全性：

```swift
import Security

final class KeychainManager {
    
    // Keychain 服务标识符
    private static let service = "com.voicestudio.app"
    
    // Keychain 访问策略
    private static let accessible = kSecAttrAccessibleWhenUnlocked
    
    /// 保存数据到 Keychain
    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        // 先尝试删除已存在的项
        try? delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessible
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    /// 从 Keychain 读取数据
    static func load(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.loadFailed(status)
        }
        
        return value
    }
    
    /// 从 Keychain 删除数据
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode value"
        case .saveFailed(let status):
            return "Failed to save to Keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load from Keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain: \(status)"
        }
    }
}

// Keychain 存储的 Key 常量
enum KeychainKey {
    static let openaiApiKey = "openai_api_key"
    static let anthropicApiKey = "anthropic_api_key"
}
```

---

## 6. 项目结构

```
VoiceStudio/
├── VoiceStudioApp.swift              # 应用入口
├── Info.plist                        # 应用配置
├── Entitlements.plist                # 权限声明
│
├── App/
│   ├── AppState.swift                # 全局状态管理
│   ├── AppDelegate.swift             # 应用生命周期
│   └── Constants.swift               # 常量定义
│
├── Models/
│   ├── RecordingState.swift
│   ├── WhisperModel.swift
│   ├── TranscriptionResult.swift
│   ├── TranslationResult.swift
│   └── TranslationProvider.swift
│
├── Services/
│   ├── Audio/
│   │   ├── AudioManager.swift        # 音频采集管理
│   │   └── AudioLevelMonitor.swift   # 音量监测
│   │
│   ├── Transcription/
│   │   ├── WhisperService.swift      # WhisperKit 封装
│   │   └── ModelManager.swift        # 模型下载管理
│   │
│   ├── Translation/
│   │   ├── TranslationService.swift  # 翻译服务协调
│   │   ├── OpenAITranslator.swift    # OpenAI 实现
│   │   └── AnthropicTranslator.swift # Anthropic 实现
│   │
│   ├── Hotkey/
│   │   └── HotkeyManager.swift       # 快捷键管理
│   │
│   └── Storage/
│       ├── SettingsManager.swift     # 设置管理
│       └── KeychainManager.swift     # 安全存储
│
├── Views/
│   ├── MenuBar/
│   │   ├── MenuBarView.swift         # 菜单栏视图
│   │   └── MenuBarIcon.swift         # 菜单栏图标
│   │
│   ├── MainWindow/
│   │   ├── MainWindowView.swift      # 主窗口
│   │   ├── WaveformView.swift        # 波形可视化
│   │   ├── RecordButton.swift        # 录音按钮
│   │   ├── TranscriptionPanel.swift  # 转录面板
│   │   └── TranslationPanel.swift    # 翻译面板
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift        # 设置主视图
│   │   ├── GeneralSettingsView.swift
│   │   ├── RecognitionSettingsView.swift
│   │   ├── TranslationSettingsView.swift
│   │   └── ShortcutsSettingsView.swift
│   │
│   └── Components/
│       ├── StatusLabel.swift         # 状态标签
│       ├── CopyButton.swift          # 复制按钮
│       ├── ModelSelector.swift       # 模型选择器
│       └── SecureTextField.swift     # 密码输入框
│
├── Utilities/
│   ├── Extensions/
│   │   ├── Color+Extensions.swift
│   │   ├── View+Extensions.swift
│   │   └── String+Extensions.swift
│   │
│   └── Helpers/
│       ├── ClipboardHelper.swift     # 剪贴板操作
│       ├── PermissionHelper.swift    # 权限检查
│       └── Logger.swift              # 日志工具
│
└── Resources/
    ├── Assets.xcassets               # 图片资源
    ├── Localizable.strings           # 多语言
    └── Sounds/                       # 音效文件
        ├── start_recording.aiff
        └── stop_recording.aiff
```

---

## 7. 依赖管理

### 7.1 Swift Package Manager

```swift
// Package.swift 依赖
dependencies: [
    .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.15.0"),
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
    .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0"),
]
```

### 7.2 依赖说明

| 依赖 | 版本 | 用途 |
|------|------|------|
| WhisperKit | 0.15.x | 语音识别核心 |
| KeyboardShortcuts | 2.x | 全局快捷键 |
| LaunchAtLogin-Modern | 1.x | 开机自启动 |

---

## 8. 权限配置

### 8.1 Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <!-- 麦克风访问 -->
    <key>com.apple.security.device.audio-input</key>
    <true/>
    
    <!-- 网络访问（翻译API） -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- 沙盒（可选，非App Store分发可关闭） -->
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

### 8.2 Info.plist

```xml
<!-- 麦克风使用说明 -->
<key>NSMicrophoneUsageDescription</key>
<string>Voice Studio needs microphone access to transcribe your speech.</string>

<!-- 菜单栏应用（不显示 Dock 图标） -->
<key>LSUIElement</key>
<true/>
```

### 8.3 辅助功能权限

全局快捷键功能需要辅助功能 (Accessibility) 权限。此权限**无法通过 Info.plist 声明**，需要在应用运行时：

1. **检测权限状态**：使用 `AXIsProcessTrustedWithOptions()` 检查
2. **引导用户授权**：弹出提示并引导用户前往 `系统设置 > 隐私与安全性 > 辅助功能`
3. **添加应用到白名单**：用户需手动勾选应用

```swift
// 启动时检查权限
func checkPermissionsOnLaunch() {
    // 检查麦克风权限
    AVCaptureDevice.requestAccess(for: .audio) { granted in
        if !granted {
            // 提示用户开启麦克风权限
        }
    }
    
    // 检查辅助功能权限
    if !AccessibilityHelper.checkAccessibilityPermission() {
        // 显示引导对话框
        showAccessibilityPermissionAlert()
    }
}
```

---

## 9. 错误处理

### 9.1 错误类型定义

```swift
enum VoiceStudioError: LocalizedError {
    // 音频相关
    case microphonePermissionDenied
    case audioEngineError(String)
    case recordingTooShort
    
    // 模型相关
    case modelNotDownloaded
    case modelDownloadFailed(String)
    case modelLoadFailed(String)
    
    // 转录相关
    case transcriptionFailed(String)
    case emptyTranscription
    
    // 翻译相关
    case translationFailed(String)
    case apiKeyMissing
    case networkError(String)
    
    var errorDescription: String? { ... }
    var recoverySuggestion: String? { ... }
}
```

### 9.2 错误处理策略

| 错误类型 | 处理方式 | 用户提示 |
|----------|----------|----------|
| 麦克风权限 | 引导到系统设置 | Alert + 跳转按钮 |
| 模型未下载 | 触发下载流程 | 下载进度提示 |
| 网络错误 | 自动重试 (3次) | Toast 提示 |
| 转录失败 | 显示错误信息 | 状态栏提示 |
| API 密钥缺失 | 打开设置页 | Alert + 跳转 |

---

## 10. 性能优化

### 10.1 内存管理

| 策略 | 实现方式 |
|------|----------|
| 模型懒加载 | 首次转录时加载模型 |
| 音频缓冲 | 固定大小的环形缓冲区 |
| 及时释放 | 转录完成后释放音频数据 |

### 10.2 线程模型

```
┌─────────────────┐
│   Main Thread   │ ← UI 更新、用户交互
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌───▼───┐
│ Audio │ │ Task  │
│ Queue │ │ Queue │
└───────┘ └───────┘
    │         │
    │    ┌────┴────┬────────┐
    │    │         │        │
┌───▼────▼───┐ ┌───▼───┐ ┌──▼──┐
│ Audio      │ │Whisper│ │ API │
│ Callback   │ │Transcr│ │Call │
└────────────┘ └───────┘ └─────┘
```

### 10.3 启动优化

| 阶段 | 操作 | 目标时间 |
|------|------|----------|
| 冷启动 | 显示窗口 | < 0.5s |
| 模型加载 | 后台异步 | 不阻塞 UI |
| 首次转录 | 包含模型加载 | < 5s |

---

## 11. 测试策略

### 11.1 单元测试

| 模块 | 测试重点 |
|------|----------|
| AudioManager | 音频格式、采样率、缓冲区 |
| WhisperService | 模型加载、转录结果 |
| TranslationService | API 调用、错误处理 |
| SettingsManager | 持久化、默认值 |

### 11.2 集成测试

| 场景 | 验证点 |
|------|--------|
| 完整转录流程 | 录音 → 转录 → 显示 |
| 翻译流程 | 转录 → 翻译 → 显示 |
| 快捷键 | Push-to-Talk 正常工作 |
| 模型切换 | 切换后立即可用 |

### 11.3 性能测试

| 指标 | 目标 |
|------|------|
| 转录延迟 (10s音频) | < 2s (Large-v3-Turbo) |
| 内存峰值 | < 2GB (Large-v3-Turbo) |
| CPU 占用 (待机) | < 1% |
| 启动时间 | < 1s |

---

## 12. 发布计划

### 12.1 分发方式

| 方式 | 优点 | 缺点 |
|------|------|------|
| **直接分发 (DMG)** | 无审核、灵活更新 | 需要公证 |
| App Store | 用户信任度高 | 审核严格、沙盒限制 |
| Homebrew Cask | 开发者友好 | 用户群体小 |

**推荐**：直接分发 (DMG) + Apple 公证

### 12.2 版本规划

| 版本 | 功能 |
|------|------|
| v1.0 | 核心语音转录、菜单栏、主窗口 |
| v1.1 | 翻译功能、设置界面 |
| v1.2 | 多语言 UI、历史记录 |
| v2.0 | 流式转录、本地 LLM 翻译 |

---

## 13. 附录

### 13.1 参考资源

| 资源 | 链接 |
|------|------|
| WhisperKit 文档 | https://github.com/argmaxinc/WhisperKit |
| WhisperKit 模型 | https://huggingface.co/argmaxinc/whisperkit-coreml |
| KeyboardShortcuts | https://github.com/sindresorhus/KeyboardShortcuts |
| AVAudioEngine 指南 | Apple Developer Documentation |
| SwiftUI 设计指南 | Apple Human Interface Guidelines |

### 13.2 从 Python 版本迁移对照

| Python 组件 | Swift 对应 |
|-------------|-----------|
| PyQt6 | SwiftUI |
| mlx-whisper | WhisperKit |
| sounddevice | AVAudioEngine |
| pynput | KeyboardShortcuts |
| QThread | Swift Concurrency (async/await) |
| QSettings | UserDefaults / @AppStorage |
| dotenv | 无需（使用 Keychain） |

### 13.3 已知限制

1. **仅支持 Apple Silicon**：Intel Mac 无法使用 WhisperKit
2. **模型存储**：首次使用需下载模型（500MB - 3GB）
3. **翻译需网络**：翻译功能依赖云端 API
4. **macOS 14+**：需要较新的系统版本

---

*文档版本: 1.4*
*最后更新: 2026-01-11*

### 修订记录

| 版本 | 日期 | 修改内容 |
|------|------|----------|
| 1.0 | 2026-01-11 | 初始版本 |
| 1.1 | 2026-01-11 | 修复 Review 问题：补充 Push-to-Talk 完整实现、更新 WhisperKit 版本至 0.15.0、修正辅助功能权限说明、补充模型下载 UI 设计、补充 Keychain 完整实现 |
| 1.2 | 2026-01-11 | 修复命名冲突：将翻译服务 protocol 改名为 `TranslationService`，避免与 `TranslationProvider` 枚举冲突；修复 `@Observable`/`@ObservedObject` 混用问题，改用 `@State` 注入；补充 `CancellationError` 处理 |
| 1.3 | 2026-01-11 | 修复并发问题：`ModelDownloadManager.startDownload()` 使用 `Task { @MainActor in }` 确保状态修改在主线程；Task 完成后自动清理 `downloadTasks` 引用；新增 `AudioManager` 完整实现，包含 `AVAudioConverter` 重采样（设备采样率 → 16kHz）和线程安全的音频缓冲处理 |
| 1.4 | 2026-01-11 | 优化 HotkeyManager 设计：采用解耦架构，不直接持有 AudioManager，通过回调通知外部处理录音逻辑；新增 `isRecording` 状态属性和 `removeHotkeys()` 方法；使用 `configure()` 延迟配置替代构造函数注入 |
