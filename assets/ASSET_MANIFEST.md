# 弓箭手对战：美术资产清单

更新日期：2026-09-15  
当前阶段：静态风格已确认；第一批分层环境、道具与游戏尺寸角色预览已交付，尚未接入正式场景

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

## 程序接入建议

- 当前没有替换 `scripts/archer.gd` 与 `scripts/terrain.gd` 中的几何占位绘制；详细接入顺序见 `ART_INTEGRATION_GUIDE.md`。
- 风格确认后，将正式角色拆分或导出为独立透明 PNG；Godot 中以脚底中心作为 `Sprite2D` 原点，并让角色视觉中心对齐现有 `Archer.global_position`。
- 翡翠游侠透明内容高度约 1141 像素。若以 100 世界单位显示，初始缩放建议约 `0.0876`。
- 船骸鲨客透明内容高度约 1009 像素。若以 100 世界单位显示，初始缩放建议约 `0.0991`。
- 弓和服装可以超出玩法碰撞宽度，但头、躯干、腿脚的视觉分区必须继续对应现有三个命中区。船骸鲨客的宽轮廓不可直接用于扩大碰撞体，除非策划后续单独批准角色特性。
- 角色 PNG 建议使用无损导入；缩小时使用线性过滤。正式动画阶段再确定图集、帧尺寸、帧率和纹理预算。
- 场景样板是构图参考，不可直接当作随机地形背景：正式环境需要拆为天空、远山、嘉年华建筑/道具和可平铺地表层，保留程序生成地形的轮廓控制。
- UI 继续使用中文，但任何文字均由 Godot UI 绘制，不烘焙进图片资产。
- 100 像素角色图仍是静态瞄准姿势：箭离弦后会产生“手中仍有箭”的重复视觉，因此在拆分持弓、搭箭和放箭状态之前，不建议直接替换正式战斗角色。

## 验收结果

- 两张角色图均有真实 alpha 通道，四角 alpha 为 0。
- 已在深浅棋盘背景上以约 100 像素高度检查；角色、朝向、弓和主要配色仍可识别。
- 光照统一来自左上方；角色均为严格侧视。
- 本轮未生成动画、未覆盖已有素材、未修改核心玩法代码。
- 天空为不透明底层；远景、中景、草缘和三件道具的四角 alpha 均为 0，并已在棋盘背景检查。
- 技术处理中产生的两张 207 字节空白失败文件已删除；旅行车的两个早期候选版本与首次半透明 QA 预览保留在 `art/candidates/`，未覆盖。
