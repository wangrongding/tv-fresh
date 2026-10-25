#!/usr/bin/env bash
# mitv-debloat: 小米电视去广告 + 换 Projectivy 桌面 (免 root, 可逆)
# 用法: mitv-debloat.sh <list|install|switch|debloat|restore 包名> [TV_IP]
# 原则: 只 pm uninstall --user 0 (系统分区不动, install-existing 可还原)
set -u
TV_IP="${2:-}"
APK="${LAUNCHER_APK:-/tmp/projectivy.apk}"

# 国内 MIUI TV 社区验证过的广告/推送/统计组件 (MiTVNoAd + 博客园/CSDN 实战清单)
AD_PKGS=(
  com.miui.systemAdSolution        # 系统广告引擎(横幅/开屏)
  com.duokan.videodaily            # 今日头屏
  com.xiaomi.mitv.tvpush           # 消息推送弹窗
  com.xiaomi.mitv.advertise        # 广告服务
  com.mitv.tvad                    # 电视广告
  com.mitv.analysis                # 行为统计
  com.xiaomi.mistat.analyticstracker # 埋点
  com.xiaomi.tv.musicadapter       # 音乐卡片(常驻后台)
  com.xiaomi.mitv.tvmanager        # 电视管家(推送清理提示)
)

connect() {
  [ -z "$TV_IP" ] && { echo "用法: $0 <命令> <TV_IP>"; exit 1; }
  adb disconnect >/dev/null 2>&1
  adb connect "$TV_IP:5555" || { echo "连接失败: 检查电视『账号与安全→ADB调试』"; exit 1; }
}

case "${1:-}" in
  list)
    connect
    echo "== 广告相关已装组件:"
    adb shell pm list packages | sed 's/package://' | sort > /tmp/tv_pkgs.txt
    for p in "${AD_PKGS[@]}" com.mitv.tvhome; do
      grep -qx "$p" /tmp/tv_pkgs.txt && echo "  $p  [存在]"
    done
    echo "== HOME 候选桌面:"
    adb shell cmd package resolve-activity --brief -c android.intent.category.HOME 2>/dev/null | tail -1
    ;;
  install)
    connect
    adb install -r "$APK" || { echo "安装失败"; exit 1; }
    echo "Projectivy 已安装"
    ;;
  switchhome)
    # 用法: switchhome <TV_IP> <包名/Activity>
    # 例: switchhome 192.168.1.4 com.spocky.projengmenu/.ui.home.MainActivity
    #     switchhome 192.168.1.4 com.spocky.projengmenu/com.spocky.projengmenu.ui.home.MainActivity
    COMP="${3:-}"
    [ -z "$COMP" ] && { echo "用法: $0 switchhome <TV_IP> <包名/Activity>"; exit 1; }
    connect
    adb shell cmd package set-home-activity "$COMP" \
      && echo "✓ 首选桌面已注册: $COMP"
    adb shell pm uninstall --user 0 com.mitv.tvhome >/dev/null 2>&1 \
      && echo "✓ PatchWall 已禁用"
    adb shell pm disable-user --user 0 com.android.tv.settings >/dev/null 2>&1 \
      && echo "✓ 兜底页宿主已禁用"
    adb shell input keyevent 3
    echo "→ 按 HOME 键验证; 回滚: $0 restorehome <TV_IP>"
    ;;
  perm)
    # 给 TVBox 系应用补存储权限(清数据/曾被拒绝后失效的场景)
    connect
    for p in com.github.tvbox.osc.tk com.fongmi.android.tv com.huawei.himovceie; do
      adb shell pm grant $p android.permission.READ_EXTERNAL_STORAGE 2>/dev/null
      adb shell pm grant $p android.permission.WRITE_EXTERNAL_STORAGE 2>/dev/null
      echo "✓ $p 存储权限已授予"
    done
    ;;
  restorehome)
    connect
    adb shell cmd package install-existing com.mitv.tvhome && echo "✓ PatchWall 已恢复"
    adb shell pm enable com.android.tv.settings && echo "✓ 兜底页已恢复"
    ;;
  debloat)
    connect
    adb shell pm list packages | sed 's/package://' > /tmp/tv_pkgs.txt
    for p in "${AD_PKGS[@]}"; do
      if grep -qx "$p" /tmp/tv_pkgs.txt; then
        adb shell pm uninstall --user 0 "$p" >/dev/null 2>&1 && echo "✓ $p" || echo "✗ $p"
      else
        echo "- $p (未安装, 跳过)"
      fi
    done
    ;;
  restore)
    [ -z "${2:-}" ] && { echo "用法: $0 restore <包名> <TV_IP>"; exit 1; }
    TV_IP="${3:-}"; connect
    adb shell cmd package install-existing "$2" && echo "已还原 $2"
    ;;
  *) echo "命令: list | install | switchhome | restorehome | perm | debloat | restore"; exit 1 ;;
esac
