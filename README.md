# 弓箭手对战 Demo 3 · 角色技能

弓箭手对决：调整射击角度和力度，利用抛物线命中并击败对手。

Godot 4.7.2 / GDScript / Compatibility 渲染器制作的电脑浏览器单人对战 Demo。

当前版本：`0.5.0-plan3`。开局可选翡翠游侠、船骸鲨客或建筑师；电脑从其余两位随机选择。翡翠游侠拥有骨骼动画，鲨客和建筑师暂用静态战斗图。

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
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/plan3_acceptance_test.gd
```

Web 导出：

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-release Web 'build/web/index.html'
```

导出后必须通过本地 HTTP 服务器访问 `build/web`，不能直接双击 HTML。

## 操作

- 首次进入先选英雄；结算时“再来一局”保留英雄并重抽电脑，“更换英雄”返回选角。
- 点击“移动”后用 A/D 行走，移动与射击互斥；尚未位移时可返回选择。
- 点击“射击”后用 W/S 调角，轻按变化 0.5°，长按连续变化；按住 Shift 可精调。
- 点击“专属技能”使用每局一次的角色行动：游侠三箭各造成 80% 普通伤害；鲨客单箭造成 150%；建筑师在己方区域点击放置 120×80 壁垒，占一回合，挡两次箭矢。
- 按住空格开始 4 秒往返蓄力，松开发射；预测显示完整试算路径的前半段。
- 玩家行动阶段可在非 UI 区域按住鼠标左键拖动镜头。
- 点击“查看敌人”切换目标；按住 Tab 临时查看全图，松开恢复此前镜头。
- 玩家上一箭的完整轨迹会以淡蓝色虚线保留，便于修正下一次射击。
- F6 使用相同种子重开（调试快捷键）。

## 当前说明

翡翠游侠由 17 根骨骼驱动 16 个刚性美术拆件。鲨客和建筑师尚无可用骨骼拆件，使用静态战斗图。数值集中在 `scripts/game_balance.gd`；电脑和玩家使用同样的技能次数，预测和实箭共享弹道与壁垒碰撞逻辑。建筑师使用次数仍可在该配置中调整，本版暂按每局一次实现。

Demo 3 的骨骼动画只改变视觉子节点，不移动角色根节点，也不参与命中检测。详细验收结果见 `验收记录_Demo3.md`。
