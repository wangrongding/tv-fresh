# 换桌面（第三方 Launcher 上位）

> 核心结论先行：MIUI TV 的 HOME 解析被三重锁定，单靠 `set-home-activity` 无效。
> 必须让目标 Launcher 成为"唯一候选"。完整逆向过程见仓库 README Part 2。

## 三步解法（顺序执行）

```bash
# 0. 已装目标 Launcher。推荐 Projectivy（projectivylauncher.com）；任意带 HOME filter 的均可（FLauncher/当贝…）
# 1. 注册首选
adb shell cmd package set-home-activity <包名>/<Activity>
# 2. 禁用 PatchWall（可逆）
adb shell pm uninstall --user 0 com.mitv.tvhome
# 3. 禁用兜底页宿主（关键一步）
adb shell pm disable-user --user 0 com.android.tv.settings
# 4. 验证：焦点应落在新 Launcher
adb shell input keyevent 3 && adb shell "dumpsys window windows | grep mCurrentFocus"
```

第 3 步安全性：用户看到的中文「设置」是 `com.xiaomi.mitv.settings`，不受影响；
AOSP 的 `com.android.tv.settings` 只承载兜底页。

## 换另一个 Launcher 时

```bash
adb install <new-launcher>.apk
adb shell cmd package set-home-activity <新包名>/<新Activity>
adb uninstall <旧launcher包名>   # 数据应用可彻底卸载
```

## 回滚（黑屏自救）

```bash
adb shell cmd package install-existing com.mitv.tvhome   # PatchWall 回来
adb shell pm enable com.android.tv.settings               # 兜底页回来
```

## 为什么 priority 补丁没用（背景）

- `set-home-activity` 的首选记录 `mAlways=false`，候选 match(0x108000) 更高时被跳过
- MIUI PMS 把第三方 HOME intent-filter 的 `android:priority` 钳制为 0（写 1000 也归零）
- FallbackHome（系统特权）在 PatchWall 缺席时永远赢解析 → 黑屏死循环
- 所以解法只有一个方向：把竞争者清场，目标 Launcher 唯一化

## 附：Projectivy 无障碍服务启用（解锁前台检测/LED时钟/自动切源）

```bash
adb shell settings put secure enabled_accessibility_services \
  "com.xiaomi.voicecontrol/com.xiaomi.voicecontrol.VoiceAccessibilityService:com.spocky.projengmenu/.services.ProjectivyAccessibilityService"
```

（保留原有的小爱语音服务，两者共存。）
