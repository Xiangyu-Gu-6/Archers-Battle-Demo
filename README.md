# 弓箭手对战 Demo 3

弓箭手对决：调整射击角度和力度，利用抛物线命中并击败对手。

Godot 4.7.2 / GDScript / Compatibility 渲染器制作的电脑浏览器单人对战 Demo。

当前版本：`0.4.0-demo3`。在“荒诞射手嘉年华”场景基础上，翡翠游侠已接入真正的 `Skeleton2D/Bone2D` 骨骼与 16 个美术拆件；玩法碰撞、弹道和数值保持不变。

## 运行

直接试玩：双击 `开始试玩.cmd`，无需打开编辑器。

进入编辑器：

1. 双击 `启动Godot.cmd`，脚本会直接打开本项目（无需在项目管理器中导入）。
2. 进入编辑器后按 F6/F5 运行。

Godot 引擎位于项目的 `.tools` 子目录，因此项目管理器会拒绝手动导入此目录；请始终使用上述启动脚本直接打开项目。

命令行验证：

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --quit
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/smoke_test.gd
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/v2_acceptance_test.gd
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/v3_acceptance_test.gd
```

Web 导出：

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-release Web 'build/web/index.html'
```

导出后必须通过本地 HTTP 服务器访问 `build/web`，不能直接双击 HTML。

## 操作

- 点击“移动”后用 A/D 行走，移动与射击互斥；尚未位移时可返回选择。
- 点击“射击”后用 W/S 调角，轻按变化 0.5°，长按连续变化；按住 Shift 可精调。
- 按住空格开始 4 秒往返蓄力，松开发射；预测显示完整试算路径的前半段。
- 玩家行动阶段可在非 UI 区域按住鼠标左键拖动镜头。
- 点击“查看敌人”切换目标；按住 Tab 临时查看全图，松开恢复此前镜头。
- 玩家上一箭的完整轨迹会以淡蓝色虚线保留，便于修正下一次射击。
- F6 使用相同种子重开（调试快捷键）。

## 当前说明

翡翠游侠由 17 根骨骼驱动 16 个刚性美术拆件：四肢使用双骨 IK，弓弦由程序实时绘制，搭载箭在释放时隐藏，并包含待机呼吸、移动摆动、瞄准、蓄力、放箭后坐和受击二级动作。船骸鲨客尚无可用拆件，因此本版仍使用静态角色图，但已经走同一套视觉状态接口。数值集中在 `scripts/game_balance.gd`；AI、预测和实箭继续共享弹道步进逻辑。

Demo 3 的骨骼动画只改变视觉子节点，不移动角色根节点，也不参与命中检测。详细验收结果见 `验收记录_Demo3.md`。
