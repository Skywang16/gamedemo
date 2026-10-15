# 芽田农场 · Sprout Valley

使用 Godot 4.7.2 / GDScript 开发的 PC 单机像素农场角色扮演游戏。玩家在青苇镇开垦荒地、经营农场、结识居民，逐步恢复停办的河灯夜。

当前开发版本为 0.5.0：支持标题菜单、角色创建、七张地图、耕种与清荒、村民关系、工具养成、存档和可完整完成的第一章「河灯归来」。后续章节、季节、动物、钓鱼与战斗仍在规划中。

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

WASD / 方向键移动，Shift 跑步，E 交互，空格使用工具，数字键切换工具，M 地图，B 背包，J 手记，Esc 暂停。详细操作与已实现内容见 [玩法说明](docs/gameplay.md)。

## 开发

开发工具需要 Python 3.11+、Make；macOS 自带的 `/usr/bin/python3` 可能低于所需版本。使用已安装的新版本 Python 创建环境：

```sh
make setup                 # 创建 .venv 并安装固定版本工具
make editor                # 打开 Godot 编辑器
make check                 # GDScript 格式、Python 静态检查与格式、Shell 语法
make test                  # 无窗口的规则和剧情测试
make test-ui               # 原生窗口流程与动画测试，需要图形桌面
make package               # 本地 macOS 应用包，输出到 build/macos/
```

`make setup PYTHON=python3.12` 可指定 Python。素材重建、测试产物、存档、打包与清理约定见 [开发指南](docs/development.md)。

## 项目结构

```text
assets/          游戏使用的像素素材、字体和音效
data/            物品、作物、剧情及独立地图配置
scenes/          Godot 场景入口
src/
  core/          内容索引与游戏状态
  gameplay/      清荒、耕种、时间与买卖规则
  story/         剧情、社交、技能与养成规则
  world/         人物、地图、碰撞、镜头与特效
  ui/            标题、创建角色、HUD、菜单与对话
  persistence/   存档读写与入口校验
tests/           规则、剧情、界面与动画测试
tools/           可重复使用的素材绘制、地图生成与打包工具
docs/            架构、玩法、人物剧情和开发文档
licenses/        第三方许可说明
build/           本地产物，自动生成，不提交 Git
```

模块职责和数据流见 [架构设计](docs/architecture.md)，人物与章节规划见 [故事设计](docs/story.md)。源代码与原创素材绘制工具保留在仓库；字体许可见 [OFL](assets/fonts/OFL.txt)，引擎许可见 [licenses/](licenses/)。
