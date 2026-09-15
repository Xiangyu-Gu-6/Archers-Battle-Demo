# 弓箭手对战：美术资产清单

更新日期：2026-09-15  
当前阶段：静态风格已确认；翡翠游侠已完成首轮切片骨架与射击动画竖切，尚未接入正式战斗场景

## 新增文件

| 文件 | 用途 | 像素尺寸 | 透明背景 | 状态 |
| --- | --- | ---: | --- | --- |
| `art/styleboards/absurd_archer_carnival_battle_style_v01.png` | “荒诞射手嘉年华”战斗场景与总体色彩样板 | 1672×941 | 否 | 已确认 |
| `art/characters/emerald_ranger_static_right_v01.png` | 翡翠游侠静态角色母版，默认面向右 | 1227×1282 | 是，32 位 ARGB | 已确认 |
| `art/characters/shipwreck_shark_static_left_v01.png` | 船骸鲨客静态角色母版，默认面向左 | 1374×1145 | 是，32 位 ARGB | 已确认 |
| `art/characters/emerald_ranger_ingame_100px_right_v01.png` | 翡翠游侠约 100 像素高的游戏尺寸预览 | 160×128 | 是，32 位 ARGB | 静态预览 |
| `art/characters/shipwreck_shark_ingame_100px_left_v01.png` | 船骸鲨客约 100 像素高的游戏尺寸预览 | 160×128 | 是，32 位 ARGB | 静态预览 |
| `art/environments/carnival_sky_base_v01.png` | 不透明天空底层 | 1672×941 | 否 | 可接入 |
| `art/environments/carnival_far_parallax_v01.png` | 远山、远处帐篷、城堡与摩天轮剪影层 | 2103×748 | 是，32 位 ARGB | 可接入 |
| `art/environments/carnival_midground_parallax_v01.png` | 帐篷、旅行车、旗帜、草垛与靶场中景层 | 2103×748 | 是，32 位 ARGB | 可接入 |
| `art/environments/terrain_soil_source_v01.png` | 地表填充纹理母版 | 1254×1254 | 否 | 母版 |
| `art/environments/terrain_soil_tile_512_v01.png` | 通过镜像拼接制作的四边连续地表纹理 | 512×512 | 否 | 可接入 |
| `art/environments/terrain_grass_edge_v01.png` | 草缘生成母版 | 2172×724 | 是，32 位 ARGB | 母版 |
| `art/environments/terrain_grass_edge_strip_1024x64_v01.png` | 可沿地表重复或拉伸的草缘条 | 1024×64 | 是，32 位 ARGB | 可接入 |
| `art/props/carnival_tent_v01.png` | 独立嘉年华帐篷道具 | 1303×1207 | 是，32 位 ARGB | 可接入 |
| `art/props/carnival_wagon_v01.png` | 独立旅行车道具 | 1536×1024 | 是，32 位 ARGB | 可接入 |
| `art/props/carnival_target_v01.png` | 独立星形靶道具 | 1312×1199 | 是，32 位 ARGB | 可接入 |
| `art/candidates/battle_readability_1280x720_v02.png` | 基准视口下的不透明场景缩放验收图 | 1280×720 | 否 | QA |
| `art/candidates/character_readability_100px_v01.png` | 两名角色缩小到约 100 像素高时的轮廓验收图，不作为游戏资产接入 | 480×160 | 否 | QA |
| `art/candidates/layer_composite_preview_1280x720_v01.png` | 独立环境层与游戏尺寸角色的合成测试 | 1280×720 | 否 | QA |
| `art/candidates/props_alpha_readability_v01.png` | 三件透明道具在棋盘背景上的边缘检查 | 960×360 | 否 | QA |

## 动画竖切新增文件

| 文件 | 用途 | 像素尺寸 | 透明背景 | 状态 |
| --- | --- | ---: | --- | --- |
| `art/characters/emerald_ranger/rig_source/emerald_ranger_rig_atlas_v01.png` | 16 部件生成母版；只用于追溯与重新切分 | 1254×1254 | 是，32 位 ARGB | 母版 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_head_v02.png` | 头部 | 303×289 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_hat_v02.png` | 帽子 | 325×191 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_hat_feather_v02.png` | 羽毛原始切片 | 337×243 | 是 | 已被 v03 候选替代 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_hat_feather_v03.png` | 清除孤立碎片后的羽毛 | 337×243 | 是 | 推荐接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_torso_v02.png` | 躯干 | 323×304 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_rear_upper_arm_v02.png` | 后侧上臂 | 190×279 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_rear_forearm_hand_v02.png` | 后侧前臂与手 | 260×121 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_front_upper_arm_v02.png` | 前侧上臂 | 199×220 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_front_forearm_hand_v02.png` | 前侧前臂与手 | 280×255 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_rear_thigh_v02.png` | 后侧大腿 | 183×329 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_rear_lower_leg_boot_v02.png` | 后侧小腿与靴 | 176×335 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_front_thigh_v02.png` | 前侧大腿 | 139×254 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_front_lower_leg_boot_v02.png` | 前侧小腿与靴 | 180×279 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_bow_v02.png` | 弓 | 227×317 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_quiver_v02.png` | 箭袋 | 231×306 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_nocked_arrow_v02.png` | 搭载箭；释放后隐藏 | 322×79 | 是 | 可接入 |
| `art/characters/emerald_ranger/rig_parts_v02/emerald_ranger_belt_pouch_v02.png` | 腰包 | 241×145 | 是 | 可接入 |
| `art/characters/emerald_ranger/emerald_ranger_anchors_v02.json` | 关节锚点、挂接层级与前后关系 | 不适用 | 不适用 | 规范数据 |
| `art/characters/emerald_ranger/EMERALD_RANGER_RIG_SPEC.md` | 动画时序、事件和接入约束 | 不适用 | 不适用 | 规范文档 |
| `animation_previews/emerald_ranger/emerald_ranger_shoot_preview.tscn` | 独立 Godot 动画预览入口 | 1280×720 基准视口 | 不适用 | 可预览 |
| `animation_previews/emerald_ranger/emerald_ranger_shoot_preview.gd` | 12 FPS 切片骨架射击循环，仅供美术预览 | 不适用 | 不适用 | 可预览 |
| `animation_previews/emerald_ranger/emerald_ranger_shoot_preview_{idle,anticipation,charge,release,recoil,recover}_v03.png` | 六张最终关键阶段质检图 | 各 1280×720 | 否 | QA |
| `animation_previews/emerald_ranger/emerald_ranger_shoot_storyboard_v03.png` | 六阶段动作故事板 | 1280×720 | 否 | QA |
| `art/candidates/emerald_ranger_animation_readability_100px_v01.png` | 六阶段缩小至约 100 像素高的辨识度检查 | 960×160 | 否 | QA |
| `animation_previews/tools/split_rig_atlas.ps1` | 按真实图集尺寸重新切分并修边的制作工具 | 不适用 | 不适用 | 制作工具 |

失败或已被替代的动画预览保存在 `art/candidates/animation_crop_failed_v01/` 与 `art/candidates/emerald_ranger_animation_preview_superseded/`，未覆盖或冒充正式素材。

## Skeleton2D 骨骼候选新增文件

| 文件 | 用途 | 像素尺寸 | 状态 |
| --- | --- | ---: | --- |
| `animation_previews/emerald_ranger_skeleton/emerald_ranger_skeleton_preview.tscn` | 真正的 `Skeleton2D/Bone2D` 独立预览入口 | 1280×720 基准视口 | 候选 |
| `animation_previews/emerald_ranger_skeleton/emerald_ranger_skeleton_preview.gd` | 17 骨层级、双骨IK、弓弦和二级摆动 | 不适用 | 候选 |
| `animation_previews/emerald_ranger_skeleton/emerald_ranger_skeleton_preview_{idle,anticipation,charge,release,recoil,recover}_v01.png` | 六张骨骼动画关键阶段图 | 各 1280×720 | QA |
| `animation_previews/emerald_ranger_skeleton/emerald_ranger_skeleton_storyboard_v01.png` | 骨骼版六阶段故事板 | 1280×720 | QA |
| `art/candidates/emerald_ranger_skeleton_readability_100px_v01.png` | 骨骼版实际游戏尺寸辨识度检查 | 960×160 | QA |
| `art/characters/emerald_ranger/emerald_ranger_skeleton_v01.json` | 骨骼层级、IK链和玩法约束 | 不适用 | 规范数据 |
| `art/characters/emerald_ranger/EMERALD_RANGER_SKELETON_SPEC.md` | 绑定策略与程序接入说明 | 不适用 | 规范文档 |

## 程序接入建议

- 当前没有替换 `scripts/archer.gd` 与 `scripts/terrain.gd` 中的几何占位绘制；详细接入顺序见 `ART_INTEGRATION_GUIDE.md`。
- 风格确认后，将正式角色拆分或导出为独立透明 PNG；Godot 中以脚底中心作为 `Sprite2D` 原点，并让角色视觉中心对齐现有 `Archer.global_position`。
- 翡翠游侠透明内容高度约 1141 像素。若以 100 世界单位显示，初始缩放建议约 `0.0876`。
- 船骸鲨客透明内容高度约 1009 像素。若以 100 世界单位显示，初始缩放建议约 `0.0991`。
- 弓和服装可以超出玩法碰撞宽度，但头、躯干、腿脚的视觉分区必须继续对应现有三个命中区。船骸鲨客的宽轮廓不可直接用于扩大碰撞体，除非策划后续单独批准角色特性。
- 角色 PNG 建议使用无损导入；缩小时使用线性过滤。翡翠游侠动画采用切片骨架，作者采样率 12 FPS；事件与关节说明见 `art/characters/emerald_ranger/EMERALD_RANGER_RIG_SPEC.md`。
- 场景样板是构图参考，不可直接当作随机地形背景：正式环境需要拆为天空、远山、嘉年华建筑/道具和可平铺地表层，保留程序生成地形的轮廓控制。
- UI 继续使用中文，但任何文字均由 Godot UI 绘制，不烘焙进图片资产。
- 100 像素角色图仍是静态瞄准姿势：箭离弦后会产生“手中仍有箭”的重复视觉，因此在拆分持弓、搭箭和放箭状态之前，不建议直接替换正式战斗角色。

## 验收结果

- 两张角色图均有真实 alpha 通道，四角 alpha 为 0。
- 已在深浅棋盘背景上以约 100 像素高度检查；角色、朝向、弓和主要配色仍可识别。
- 光照统一来自左上方；角色均为严格侧视。
- 动画竖切仅新增在 `assets/` 内；未覆盖既有素材、未修改核心玩法代码。
- 天空为不透明底层；远景、中景、草缘和三件道具的四角 alpha 均为 0，并已在棋盘背景检查。
- 技术处理中产生的两张 207 字节空白失败文件已删除；旅行车的两个早期候选版本与首次半透明 QA 预览保留在 `art/candidates/`，未覆盖。
- 16 个角色部件均有 alpha 通道并包含可见像素；羽毛孤立碎片在递增版本 `v03` 中清除。
- 射击循环已由 Godot 4.7.2 实际加载并渲染；脚底、膝部、箭离弦显隐和六阶段轮廓已复检。
- 六阶段缩至约 100 像素高后，朝向、帽羽、弓和释放箭仍可辨识。
