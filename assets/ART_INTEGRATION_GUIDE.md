# 荒诞射手嘉年华：Godot 美术接入建议

本文只规定美术层级和资源用法，不要求修改玩法数值、碰撞或回合逻辑。

## 推荐层级

由后向前：

1. `art/environments/carnival_sky_base_v01.png`：天空底层。
2. `art/environments/carnival_far_parallax_v01.png`：远景层。
3. `art/environments/carnival_midground_parallax_v01.png`：中景陈设层。
4. 程序生成的地形多边形，使用 `art/environments/terrain_soil_tile_512_v01.png` 填充。
5. 地表轮廓使用 `art/environments/terrain_grass_edge_strip_1024x64_v01.png`。
6. 角色、箭、轨迹和命中反馈。
7. 固定中文 UI。

天空可以固定到相机或使用接近 0 的视差。远景横向视差建议从 `0.10–0.18` 起调，中景从 `0.28–0.40` 起调。数值只影响视觉运动，不应改变世界坐标或弹道。

## 基准视口与世界宽度

- 基准视口仍为 1280×720，世界宽仍为 2400。
- 远景和中景源图宽 2103，可在 2400 世界单位内轻微横向放大，或由 `Parallax2D` 控制覆盖范围。
- 不要让中景帐篷、靶子或草垛看起来像可碰撞平台。它们应放在地表线之后，并降低对比度。
- `art/candidates/layer_composite_preview_1280x720_v01.png` 仅验证层间颜色与缩小辨识度，不是要接入的合并背景。

## 随机地形

- 地形高度数据、碰撞和可达性继续由现有程序生成。
- 将 `art/environments/terrain_soil_tile_512_v01.png` 作为 `Polygon2D` 或同类地形绘制节点的重复纹理；保持纹理重复，不缩放碰撞形状。
- 将草缘条作为视觉覆盖层沿同一组地表采样点绘制。可考虑 `Line2D` 的平铺纹理模式，初始视觉宽度约 48–64 世界单位。
- 草缘只覆盖地表顶部，不参与碰撞，不替代当前地形折线。

## 角色

- 两张游戏尺寸预览画布均为 160×128，实际角色内容高度约 100 像素，脚底基线在画布 `y=116` 附近。
- 若使用 `Sprite2D.centered = false`，建议把贴图左上角放在角色节点局部坐标约 `(-80, -116)`，使脚底中心对齐角色原点。
- 继续沿用现有头、躯干、腿脚命中区。宽帽、弓、箭袋和船板盔甲都是视觉外扩，不自动扩大碰撞体。
- 船骸鲨客的视觉体型更宽，但在策划批准差异化属性前仍使用与玩家相同的玩法碰撞尺寸。
- 当前静态稿包含搭箭动作，只适合构图验证。进入动画制作时至少拆分：身体、前臂/后臂、弓、弦、搭载箭、箭袋；放箭后必须隐藏搭载箭。

### 翡翠游侠切片骨架

- 推荐使用 `art/characters/emerald_ranger/rig_parts_v02/`，羽毛单独选择 `emerald_ranger_hat_feather_v03.png`。
- 默认关节、层级和锚点见 `art/characters/emerald_ranger/emerald_ranger_anchors_v02.json`；射击阶段与事件建议见同目录 `EMERALD_RANGER_RIG_SPEC.md`。
- `animation_previews/emerald_ranger/emerald_ranger_shoot_preview.tscn` 是隔离预览，不应直接设为正式主场景，也不负责实例化玩法箭。
- 预览用程序绘制弓弦；正式角色也建议用 `Line2D` 或等价线条节点连接弓梢和拉弦手，这样蓄力时不需要额外弦贴图。
- 视觉根节点缩放到约 100 像素高后挂在现有角色节点下；头、躯干、腿的视觉分组继续对齐现有三段命中区，不从图片透明轮廓生成碰撞。

### Skeleton2D 正式接入

- Demo 3 的正式运行时位于 `scripts/emerald_ranger_rig.gd`，使用真正的 `Skeleton2D/Bone2D` 层级；`animation_previews/emerald_ranger_skeleton/` 保留为隔离预览与制作参考。
- 四肢使用双骨IK：持弓手追踪瞄准目标，拉弦手追踪蓄力目标，双脚追踪地表接触目标。
- 正式绑定结构和约束见 `art/characters/emerald_ranger/EMERALD_RANGER_SKELETON_SPEC.md`；翡翠游侠已替换静态正式角色引用，鲨客等待对应拆件。

## 道具

- 帐篷、旅行车、星形靶均为透明高分辨率母版，默认只作为不可交互中景道具。
- 建议显示高度：帐篷 150–220、旅行车 130–180、靶子 100–150 世界单位，最终以不遮挡角色和预测轨迹为准。
- 如果以后将靶子用于教学或挑战模式，应另建碰撞与玩法定义，不能从贴图轮廓自动推导。

## Godot 导入

- PNG 使用无损压缩；角色与道具保留 alpha。
- 缩放使用线性过滤；远景可启用 mipmap，100 像素角色图通常不需要 mipmap。
- 不将中文文字烘焙进素材，所有文字继续由 Godot UI 与字体资源渲染。
- 正式替换任何占位素材前，先复制场景或创建候选资源引用，确保可回退。
