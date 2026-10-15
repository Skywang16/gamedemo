# 10 · 内容规模与代码架构

## 1. 内容规模（以数据为准）

| 内容 | 数量 | 数据文件 |
| --- | --- | --- |
| 物品 | 687 | `data/items.json` |
| 作物 | 63（春 25、夏 30、秋 24、冬 16） | `data/crops.json` |
| 鱼 | 65（春 39、夏 45、秋 41、冬 22） | `data/fish.json` |
| 食谱 | 411 | `data/recipes.json` |
| 采集表 | 6 张（林地、湖畔、海滩、矿洞三层） | `data/gather_tables.json` |
| 商店、鱼竿、工具档位、熔炼 | 8 家 / 4 档鱼竿 / 4 档工具 | `data/shops.json` |
| 动物、建筑 | 9 种 / 2 座 | `data/animals.json`、`data/buildings.json` |
| 清晨小事 | 20 | `data/events.json` |
| 村民、主线阶段、场景 | 30 / 7 / 121 | `data/story.json` |
| 日历、节日、天气表、广场站位 | 13 个节日 / 40 个站位 | `data/calendar.json` |
| 地点（日程用的名字） | 123 | `data/places.json` |
| 地图 | 18 | `data/maps/*.json` |

物品种类：种子 63、农产品 73、鱼 65、野外采集物 42、矿物 22、食物 415、材料 7。

## 2. 数据驱动的生成流程

内容文件**不手写**，全部由 `tools/` 下的生成器产出，运行时只读。每个生成器每次都从头写出完整文件，不在上一次的结果上修补。

```text
tools/world/places.py        日程用的命名地点（地图/名称 → 格坐标）
tools/world/build_maps.py    18 张地图 + places.json（带出口、站点、碰撞、装饰）
tools/content/specs.py       作物、鱼、采集物、矿物、动物产物、杂项、手工食物的数据表
tools/content/dishes.py      食谱模板（把食材套进菜式，生成 411 个食谱）
tools/content/economy.py     商店、鱼竿、工具档位、熔炼、动物、建筑、采集表、小事
tools/content/build_content.py 校验并写出物品 / 作物 / 鱼 / 食谱 / 商店 / 动物 / 建筑 / 采集表 / 小事
tools/content/story_data.py  主线阶段、场景、30 位村民与心事件
tools/content/schedules.py   30 位村民的日程规则
tools/content/calendar_data.py 季节、星期、天气表、节日
tools/content/reach.py       地图可达性（日程里的每个相邻停靠点必须走得通）
tools/content/build_story.py 写出 story.json 与 calendar.json（校验：物品存在、地点存在、喜好有效、日程可达）
tools/content/build_cast_doc.py / build_routines_doc.py / tools/world/build_map_doc.py   生成 02、13、09 号文档
tools/build_art.py           全部像素美术
```

命令：

```sh
make maps      # 地图与 places.json
make content   # maps 之后的内容与文档（story、calendar、cast、routines）
make art       # 全部美术
make import    # Godot 导入缓存
```

生成器在发现任何引用错误时直接停止并列出问题（未知物品、未知地点、不可达的日程停靠点等），不产出半成品。

## 3. 代码分层

```text
src/
  core/         ContentCatalog（读取并校验全部内容）、FarmState（存档状态）、GameCalendar、GameSettings
  gameplay/     纯规则：FarmRules、ShopRules、GatherRules、CookingRules、FishingRules、AnimalRules、
                EventRules、BoardRules、WeatherRules
  story/        StoryRules（主线阶段、交谈、送礼、心事件、节日、采集、换图）
  world/        FarmWorld（地图、玩家、村民、特效）、NpcPlanner（日程与路线）、Farmer / ToolMotion（动作）、
                WorldAtmosphere / WeatherLayer / WorldEffects / WorldAmbient / TreeProp
  ui/           FrontMenu（标题、存档位、创建角色、设置）、FarmHUD、GameDialogs 及各个面板
  persistence/  SaveStore（三个存档位）、SaveValidator（入口校验）
  game.gd       主控制器：输入 → 规则 → 画面 / 界面 / 存档
```

边界约定：

| 层 | 职责 | 不做 |
| --- | --- | --- |
| core | 载入并校验内容、保存状态快照 | 不处理输入、节点、磁盘存档 |
| gameplay / story | 修改 `FarmState`，返回 `{ok, message, ...}`；失败时状态完全不变 | 不碰节点，不播放声音 |
| world | 画面、碰撞、镜头、村民行走、特效 | 不决定任务、经济、好感 |
| ui | 展示状态，通过 `action_requested(action, payload)` 发出意图 | 不直接修改状态 |
| persistence | 读写 JSON、校验、反序列化 | 不修复、不迁移、不备份 |
| game.gd | 把输入交给规则，再通知界面、画面和存档 | 不写规则 |

## 4. 关键设计

- **ContentCatalog** 在启动时校验全部内容（引用、类型、坐标、素材是否存在、日程规则是否合法），任何一处不合格都会返回错误并拒绝启动，不会带着坏数据运行。
- **FarmState** 的存档格式有 schema 版本号（当前 6）；`SaveValidator` 在入口检查每一个字段的类型、范围和引用，通过后才构造状态。
- **确定性**：天气、清晨小事、采集结果、公告栏委托都是“世界种子 + 日期（+ 采集点 / 周数）”的纯函数，所以存档不需要保存它们，预报永远正确。
- **村民位置不保存**：`NpcPlanner` 按“当天条件 + 当前分钟”推出每个人在哪里、在做什么、朝哪走。读档、换图、睡觉回来都一致。
- **路线**：每张地图一个 `AStarGrid2D`，跨地图时在“出口图”上做广度优先搜索，得到逐格路径；出发时间按到达时间倒推。
- **世界渲染**：游戏区域是 1280×800 的 SubViewport，Camera2D 在室外跟随玩家并限制边界；界面在主视口里，鼠标坐标通过 canvas_transform 换算。
- **工具动作**：蓄力 → 接触帧（改变世界一次）→ 收势；菜单暂停未完成的动作；规则不依赖动画。

## 5. 约定

- 数据模型和代码只有一套当前版本：没有备份、迁移入口或兼容分支，格式不对就报错。
- 外部数据（JSON 内容、存档、设置、玩家输入）在入口验证，失败时明确报错；内部关系保持简单。
- GDScript 用 gdformat，Python 用 Ruff；`make check` 必须通过。
- 改规则后跑规则测试；改完整流程、镜头或 UI 后跑窗口测试并看截图。
- 内容与行为分开；不把截图当作可交互的地图，生成工具不进入游戏运行时。
