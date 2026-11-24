# Andarium 1.1 — iOS 15.1 移植版构建指南

本仓库是 [imxieyi/Kernarium](https://github.com/imxieyi/Kernarium) `andarium-1.1` 标签的 iOS 15.1 真机移植版。上游用 Metal 4（仅 iOS 26+）渲染 Android 虚拟机；本移植改用项目自带的 Mesa 软件光栅化器（llvmpipe/softpipe），交叉编译到 iphoneos/15.1，因此可在 **iPhone 13 Pro Max / iOS 15.1.1（A15）** 上运行。

> 这是功能验证型移植，CPU 软件渲染很慢，不是性能版。

## 一、推送到 GitHub

GitHub Actions 需要有 Xcode 27 的 runner（`xcode-27`，Apple Silicon），本地无法编译，必须借助 GitHub 云端。

**方式 A：网页上传**
1. 在 GitHub 新建一个空仓库（建议公开，公开仓库的 macOS runner 免费）。
2. 把本仓库**全部文件**（含隐藏的 `.github` 目录）上传，分支名用 `main` 或 `ios15.1-port`。
3. 上传后 `Actions` 标签会自动出现 `Build Andarium 1.1 for iOS 15.1` 工作流。

**方式 B：命令行一键推送**（在本仓库根目录执行）
```sh
sh push-to-github.sh https://github.com/你的用户名/你的仓库.git
```

推送到 `main` / `master` / `ios15.1-port` 任一分支都会自动触发构建；也可在 Actions 页面手动点 **Run workflow**。

## 二、下载 IPA

构建完成后（约 1–3 小时，取决于依赖编译）：
- 进入本次运行的页面，在右侧 **Artifacts** 下载 `Andarium-1.1-ios15.1-IPA`。
- 解压得到 `Andarium-1.1-ios15.1-trollstore.ipa` —— 这是**未签名 IPA**，用 TrollStore 安装。
- 如果配置了签名 secrets，还会额外得到 `Andarium*.ipa`（已签名，可用 AltStore/SideStore 安装）。

## 三、在 iPhone 上安装（TrollStore 路线，推荐）

你的 iOS 15.1.1 + A15 被 TrollStore 完整支持，装一次即可永久使用，无需每 7 天重签：

1. 用 [TrollInstallerX](https://github.com/opa334/TrollStore) 通过 Sideloadly/AltStore 临时安装 TrollStore（iPhone 需连电脑，登录 Apple ID 做一次临时签名）。
2. 打开 TrollStore，装好持久化助手（Persistence Helper，选「Tips」）。
3. 把下载的 `Andarium-1.1-ios15.1-trollstore.ipa` 用 AirDrop / 文件 App 传到手机，在文件 App 里长按 → 分享 → TrollStore 安装。
4. 桌面出现 Andarium，打开即可。

> 关键：TrollStore 会用 CoreTrust 漏洞给 IPA 永久伪签，并保留 `Andarium.entitlements` 里的两个高内存权限（increased-memory-limit、extended-virtual-addressing），因此无需付费开发者账号。 entitlements 已随 IPA 打包在 `Entitlements.plist`。

## 四、（可选）用付费开发者账号签名

如果不想用 TrollStore，可在仓库 **Settings → Secrets and variables → Actions** 添加：

| Secret | 值 |
|---|---|
| `APPLE_TEAM_ID` | 你的 Apple Developer Team ID |

配置后重新运行工作流，会额外产出一个自动签名的 IPA，可用 AltStore/SideStore 侧载（免费账号需注意 7 天重签和内存上限）。注意：那两个高内存 entitlement 需要苹果单独审批，普通账号签名时可能失效——这正是推荐 TrollStore 的原因。

## 五、改了什么（相对上游）

- 所有部署目标 iOS 26/27 → **15.1**（App 工程、Info.plist、CMake 工具链、Swift Package、依赖契约、侧载元数据）。
- 新增软件渲染真机平台 `ios-software` / `ios15-device`：构建脚本、依赖校验、平台契约 `ios-device-gpu-software-arm64.tsv` 全线打通。
- `AppEntry.swift` 放宽 Metal 4 启动检查；`AndariumApp.swift` 启动时设 `LIBGL_ALWAYS_SOFTWARE=true`、`GALLIUM_DRIVER=softpipe`（纯解释器，规避 iOS 对 JIT 的限制）。
- 新增 `Kernarium/scripts/package-ios15-frameworks.sh`：打包不含 KosmicKrisp 的软件渲染 XCFramework。
- KosmicKrisp 嵌入改为 optional（软件渲染不产出它）。

## 六、已知风险

1. **Mesa/LLVM 交叉编译到 iphoneos**：上游只验证过 Simulator，machine file 可能需按编译错误现场微调。失败时把日志发回，按报错定位。
2. **softpipe 性能**：纯 CPU 解释器跑完整 Android 会很慢，属正常现象。
3. **内核/镜像 ABI**：预编译内核与软件 runtime 若不匹配需重建。
4. **xcode-27 是公开预览镜像**：可能有排队，付费/公开仓库策略见 GitHub 文档。

构建失败时，下载 Artifacts 里的 `build-logs` 或复制 Actions 日志，即可精确定位到出错步骤。
