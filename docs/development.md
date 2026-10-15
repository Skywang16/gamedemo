# 开发指南

## 项目标识与工具

- 游戏名称：芽田农场 / Sprout Valley。
- 源码目录：`sprout-valley`；当前版本：0.5.0。
- macOS 应用标识：`io.github.skywang16.sproutvalley`。
- 引擎：Godot 4.7.2 标准版；脚本：GDScript。
- 素材和工程工具：Python 3.11+，依赖版本集中在 `requirements-dev.txt`。

所有命令在仓库根目录执行。`tools/godot.sh` 统一定位引擎，启动、编辑器、测试、打包不依赖开发者机器上的源码绝对路径。引擎和 Python 环境不提交到 Git。

```sh
make setup
make run
make editor
```

编辑器配置由 `.editorconfig` 统一；GDScript 使用 Tab 和 gdformat，Python 使用四空格和 Ruff。文本使用 UTF-8 / LF。新增模块应保持 [架构设计](architecture.md) 中的职责边界，外部数据在入口校验。

## 内容与素材

`data/maps/` 的每张地图独立保存。地图生成器与素材生成器都是可重复使用的创作工具：

```sh
make maps        # 根据 tools/world/build_layouts.py 重建室外地图 JSON
make art         # 根据地图与 tools/art/ 重建像素 PNG
make import      # 更新 Godot 资源导入缓存
```

地图生成会覆盖对应室外地图配置；修改地图时应先决定修改生成器还是手工维护 JSON。素材由 Python / Pillow 按像素绘制，生成器不参与运行时。运行所需的 PNG、字体、音频及其 Godot `.import` 设置必须提交；`.gd.uid` 也属于稳定资源标识。`.godot/` 是可重建缓存，不提交。

## 测试

```sh
make check
make test
make test-ui
```

| 测试入口 | 覆盖范围 |
| --- | --- |
| `tests/test_runner.gd` | 内容校验、地图可达性、开垦、种植、买卖、树木状态和存档 |
| `tests/chapter_tests.gd` | 第一章完整流程、人物关系、养成与交付奖励 |
| `tests/ui_smoke.gd` | 标题、角色创建、键鼠输入、菜单、地图、室内与尾声 |
| `tests/animation_smoke.gd` | 动作接触帧、菜单暂停、粒子、倒树与树桩碰撞 |

窗口测试串行运行，每次自动使用唯一的 `user://ui-test-<UUID>` 存档目录，截图写入 `build/test-results/<测试目录名>/`，不修改正常游戏档。诊断失败时可单独执行：

```sh
./tools/godot.sh --headless --editor --import
./tools/godot.sh --script res://tests/ui_smoke.gd -- --save-dir=user://ui-test-$(uuidgen)
./tools/godot.sh --script res://tests/animation_smoke.gd -- --save-dir=user://ui-test-animation-$(uuidgen)
```

窗口测试会模拟输入，跨大地图时直接定位角色；它们不替代真人对节奏、画面和手感的检查。逐格可达性断言较多，断言数不代表独立玩法场景数。当前开发验证环境为 Apple Silicon macOS，其他系统仍需各自验证。

## 存档

正常存档位于 Godot 的 `user://farm.json`。macOS 路径为 `~/Library/Application Support/SproutValley/farm.json`。测试存档为该目录内的 `ui-test-*` 子目录，需要时可单独删除。

当前存档格式为 schema 4。开发期直接调整数据结构，使用新角色验证；不维护历史格式迁移和备份恢复。正常保存采用临时文件写完后替换主文件。

## macOS 打包

```sh
make package
open "build/macos/Sprout Valley.app"
```

打包脚本从 `export_presets.cfg` 读取应用标识和版本，输出始终位于 `build/macos/`，包含游戏资源、引擎、图标及许可。这个流程使用编辑器可执行文件创建本地开发包，并执行 ad-hoc 签名校验；正式发行还需要导出模板、开发者签名与公证。

可直接指定引擎路径：

```sh
.venv/bin/python tools/package_macos.py /absolute/path/to/Godot
```

## 产物与清理

`build/` 保存本地应用、截图与测试报告，并通过 `.gdignore` 避免被 Godot 导入；日志、缓存、虚拟环境和构建产物均由 `.gitignore` 排除。原始素材、可重用工具、测试、设计文档属于项目源码。

```sh
make clean       # 删除 build/、Godot 导入缓存和 Ruff 缓存
```

清理后 `make run`、`make test` 会重新导入资源。不要把录屏、联系表、临时脚本、旧压缩包或执行日志提交到源码仓库。
