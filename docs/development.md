# 开发指南

## 项目标识与工具

- 游戏名称：芽田农场 / Sprout Valley。
- 源码目录：`sprout-valley`；当前版本：0.6.0。
- macOS 应用标识：`io.github.skywang16.sproutvalley`。
- 引擎：Godot 4.7.2 标准版；脚本：GDScript。
- 素材和内容工具：Python 3.11+（Pillow、Ruff），依赖版本集中在 `requirements-dev.txt`；GDScript 格式用 gdtoolkit。

所有命令在仓库根目录执行。`tools/godot.sh` 统一定位引擎，启动、编辑器、测试、打包不依赖开发者机器上的绝对路径。引擎和 Python 环境不提交到 Git。

```sh
make setup
make run
make editor
```

编辑器配置由 `.editorconfig` 统一；GDScript 使用 Tab 和 gdformat，Python 使用四空格和 Ruff。文本使用 UTF-8 / LF。新增模块应保持 [架构设计](architecture.md) 里的职责边界，外部数据在入口校验。

## 内容与素材

`data/` 下的所有文件、`docs/design/` 中带“由数据生成”标记的文档、`assets/` 下的全部 PNG 都是**生成结果**，不要手改；改生成器，重新运行。每个生成器每次都从头写出完整结果。

```sh
make maps        # tools/world/build_maps.py → data/maps/*.json、data/places.json
make content     # 依赖 maps：故事、日历、物品、商店等 JSON，以及 02 / 09 / 13 号文档
make art         # tools/build_art.py → assets/art、assets/ui（约 2 分钟）
make import      # 更新 Godot 导入缓存
```

| 生成器 | 产出 |
| --- | --- |
| `tools/world/build_maps.py` | 18 张地图、地点表 |
| `tools/content/build_content.py` | 物品、作物、鱼、食谱、商店、动物、建筑、采集表、小事 |
| `tools/content/build_story.py` | 故事（村民、日程、场景）、日历；同时校验物品、地点、日程可达性 |
| `tools/content/build_cast_doc.py` | `docs/design/02-cast.md` |
| `tools/content/build_routines_doc.py` | `docs/design/13-routines.md` |
| `tools/world/build_map_doc.py` | `docs/design/09-world-map.md` |
| `tools/build_art.py` | 全部像素美术 |

生成器发现引用错误会停止并列出问题。运行所需的 PNG、字体、音频及其 Godot `.import` 设置必须提交；`.gd.uid` 也属于稳定资源标识。`.godot/` 是可重建缓存，不提交。

## 测试

```sh
make check
make test
make test-ui
```

| 测试入口 | 覆盖范围 |
| --- | --- |
| `tests/test_runner.gd` | 内容载入、工具与体力、树木、清荒、作物生长与重复收获、换季枯萎、买卖、存档位读写与校验、农场可达性 |
| `tests/chapter_tests.gd` | 30 位村民资料、第一章完整流程、交谈送礼、心事件、节日、采集、存档往返、18 张地图与全部地点的可达性 |
| `tests/calendar_tests.gd` | 日历换算、节日与生日、确定性天气、雨雪浇灌、换季枯萎、存档 schema 6、季节与大气着色 |
| `tests/rules_tests.gd` | 内容规模与素材存在、商店营业时间与库存、熔炼与升级、诊所与鱼竿、烹饪、钓鱼、动物、清晨小事、告示板、采集表 |
| `tests/world_tests.gd` | 村民日程规则、时间线连续性、走路速度、节日人群、确定性、全年规则覆盖 |
| `tests/settings_tests.gd` | 设置校验与持久化、改键冲突与保留键、音频总线与输入映射 |
| `tests/motion_tests.gd` | 界面缓动的单调性、收敛、减弱动效时即时到位 |
| `tests/ui_smoke.gd` | 标题、设置页、创建角色与存档位、键鼠输入、各个面板与商店、钓鱼小游戏、剧情与村民、跨地图旅行、睡觉与日卡、读取与删除存档 |
| `tests/animation_smoke.gd` | 动作接触帧、菜单暂停、粒子、倒树与树桩碰撞、重载后恢复 |
| `tests/map_tour.gd` | 视觉巡检：相机走遍 18 张地图并截图（人工查看 `build/test-results/`），只要求每张地图都能建成并渲染 |
| `tests/weather_smoke.gd` | 六种天气与四季在真实画面上的渲染、季节着色器像素断言、室内无天气 |

窗口测试串行运行，每次自动使用唯一的 `user://ui-test-<UUID>` 存档目录，截图写入 `build/test-results/<测试目录名>/`，不修改正常存档。无显示器的服务器上用 `xvfb-run -a -s "-screen 0 1280x800x24"` 并加 `--rendering-driver opengl3`。诊断失败时可单独执行：

```sh
./tools/godot.sh --headless --editor --import
./tools/godot.sh --script res://tests/ui_smoke.gd -- --save-dir=user://ui-test-$(uuidgen)
```

新增带 `class_name` 的脚本后，先运行 `make import`，否则测试会因找不到类型而挂起。

## 存档

存档位于 Godot 的 `user://`：`farm.json`（位置 1）、`farm_2.json`、`farm_3.json`。macOS 路径为 `~/Library/Application Support/SproutValley/`。设置在同一目录的 `settings.json`。测试存档在该目录内的 `ui-test-*` 子目录，需要时可单独删除。

存档格式是 schema 6，只接受当前版本，格式不合格的存档在“读取存档”里显示原因，不会被修复。保存采用临时文件写完后替换主文件。

## macOS 打包

```sh
make package
open "build/macos/Sprout Valley.app"
```

打包脚本从 `export_presets.cfg` 读取应用标识和版本，输出始终位于 `build/macos/`，包含游戏资源、引擎、图标及许可。这个流程使用编辑器可执行文件创建本地开发包，并执行 ad-hoc 签名校验；正式发行还需要导出模板、开发者签名与公证。可直接指定引擎路径：

```sh
.venv/bin/python tools/package_macos.py /absolute/path/to/Godot
```

## 产物与清理

`build/` 保存本地应用、截图与测试报告，并通过 `.gdignore` 避免被 Godot 导入；日志、缓存、虚拟环境和构建产物均由 `.gitignore` 排除。不要把录屏、联系表、临时脚本、压缩包或执行日志提交到源码仓库。

```sh
make clean       # 删除 build/、Godot 导入缓存和 Ruff 缓存
```
