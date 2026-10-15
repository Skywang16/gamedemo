# 芽田农场 · Sprout Valley

使用 Godot 4.7.2 / GDScript 开发的 PC 单机像素农场角色扮演游戏。玩家继承祖母留下的农场，来到欧洲乡间小镇芦苇渡，开荒种地、钓鱼、做饭、养动物、下矿，结识三十位有自己生活的村民，一起让停办的灯夜重新亮起来。

当前版本 0.6.0：

- 18 张地图（农场、小镇、集市街、牧场、海鸥湾、松木林、湖畔、三层旧采石矿和八处室内），道路相连，村民真的在地图上走路；
- 30 位村民各有按星期、天气、季节、节日、生日、年份和剧情阶段变化的日程，114 段心事件，12 位可恋爱；
- 一年四季 × 28 天，天气、季节外观、13 个节日和 20 种清晨小事；
- 63 种作物、65 种鱼、42 种采集物、22 种矿物、411 个食谱、9 种动物、8 家有营业时间的商店；
- 钓鱼小游戏、烹饪、养殖、矿石熔炼与工具升级、告示板委托、图志；
- 第一章「灯夜重燃」完整剧情、三个存档位、设置与改键。

完整设计见 [docs/design/00-overview.md](docs/design/00-overview.md)。

## 运行

安装 Godot 4.7.2 标准版，用编辑器导入 `project.godot`，按 F5 运行。素材、字体和音效已包含在仓库中，运行游戏不需要 Python。

```sh
git clone https://github.com/Skywang16/gamedemo.git sprout-valley
cd sprout-valley
./launch.command
```

macOS 可直接双击 `launch.command`。引擎查找顺序是 `GODOT_BIN`、PATH 中的 `godot` / `godot4`、`~/Applications/Godot.app`、`/Applications/Godot.app`。也可指定引擎：

```sh
GODOT_BIN="/absolute/path/to/Godot" ./launch.command
```

WASD / 方向键移动，Shift 跑步，E 交互，空格使用工具，1–8 切换工具，Q 换种子，B 背包，J 手记，M 地图，Esc 暂停。详细操作见 [玩法说明](docs/gameplay.md)。

## 开发

开发工具需要 Python 3.11+、Make。

```sh
make setup                 # 创建 .venv 并安装固定版本工具
make maps                  # 重新生成 18 张地图
make content               # 重新生成故事、日历、日程与说明文档
make art                   # 重新绘制全部像素素材
make import                # 更新 Godot 导入缓存
make check                 # GDScript 格式、Python 静态检查与格式、Shell 语法
make test                  # 无窗口的规则、剧情、日程与设置测试
make test-ui               # 原生窗口流程与动画测试，需要图形桌面
make package               # 本地 macOS 应用包，输出到 build/macos/
```

`make setup PYTHON=python3.12` 可指定 Python。生成器、测试、存档、打包与清理约定见 [开发指南](docs/development.md)。

## 项目结构

```text
assets/          游戏使用的像素素材、字体、音效和季节着色器
data/            物品、作物、鱼、食谱、商店、剧情、日历和地图配置（由 tools/ 生成）
scenes/          Godot 场景入口
src/
  core/          内容目录、游戏状态、日历、设置
  gameplay/      农耕、商店、采集、烹饪、钓鱼、动物、小事、委托、天气规则
  story/         主线、社交、心事件、节日
  world/         地图世界、村民日程与路线、玩家动作、季节与天气表现
  ui/            标题、存档位、HUD、对话与各个面板
  persistence/   存档读写与入口校验
tests/           规则、日程、设置、窗口流程与动画测试
tools/           内容与地图生成器、素材绘制工具、打包工具
docs/            玩法、架构、设计文档（design/）
licenses/        第三方许可说明
build/           本地产物，自动生成，不提交 Git
```

模块职责和数据流见 [架构设计](docs/architecture.md)。源代码与原创素材绘制工具保留在仓库；字体许可见 [OFL](assets/fonts/OFL.txt)，引擎许可见 [licenses/](licenses/)。
