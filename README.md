# 弓箭手对战 Demo

弓箭手对决：调整射击角度和力度，利用抛物线命中并击败对手。

Godot 4.7.2 / GDScript / Compatibility 渲染器制作的电脑浏览器单人对战 Demo。

## 运行

1. 双击 `启动Godot.cmd`。
2. 在项目管理器导入本目录的 `project.godot`。
3. 按 F6/F5 运行。

命令行验证：

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --quit
```

Web 导出：

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-release Web 'build/web/index.html'
```

导出后必须通过本地 HTTP 服务器访问 `build/web`，不能直接双击 HTML。

## 操作

- 点击“移动”后用 A/D 行走，移动与射击互斥。
- 点击“射击”后用 W/S 调角，按住空格蓄力、松开发射。
- 玩家行动阶段可在非 UI 区域按住鼠标左键拖动镜头。
- F6 使用相同种子重开（调试快捷键）。

## 当前说明

画面全部为程序绘制的几何占位。数值集中在 `scripts/game_balance.gd`。随机地形最多尝试 20 次，失败使用保底地形；AI 搜索分帧执行并使用与实箭一致的运动公式。

