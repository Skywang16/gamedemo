# 室内布局 · 静态预览

由地图数据与家具素材合成：墙、地板和地毯是搭建出来的，家具是游戏里独立 Y 排序的精灵。每张室内另附碰撞叠图：红色表示阻挡格，青色表示交互点。

![全部室内布局](overview.png)

| 室内 | 地图格数 | 布局图 | 碰撞图 |
| --- | --- | --- | --- |
| 农舍 | 20 × 20 | [布局](cottage.png) | [碰撞与交互点](cottage-collision.png) |
| 玛戈的小酒馆 | 28 × 21 | [布局](inn.png) | [碰撞与交互点](inn-collision.png) |
| 卡弗木工坊 | 26 × 20 | [布局](workshop.png) | [碰撞与交互点](workshop-collision.png) |
| 霍克杂货店 | 24 × 18 | [布局](general_store.png) | [碰撞与交互点](general_store-collision.png) |
| 布兰尼根铁匠铺 | 24 × 20 | [布局](blacksmith.png) | [碰撞与交互点](blacksmith-collision.png) |
| 芦苇渡诊所 | 24 × 20 | [布局](clinic.png) | [碰撞与交互点](clinic-collision.png) |
| 铜壶茶室 | 22 × 18 | [布局](tea_house.png) | [碰撞与交互点](tea_house-collision.png) |
| 托比渔具店 | 20 × 17 | [布局](tackle_shop.png) | [碰撞与交互点](tackle_shop-collision.png) |
| 芦苇渡小学 | 26 × 19 | [布局](school.png) | [碰撞与交互点](school-collision.png) |
| 芦苇渡议事厅 | 26 × 21 | [布局](town_hall.png) | [碰撞与交互点](town_hall-collision.png) |
| 黑兹尔的种子小屋 | 18 × 21 | [布局](hazel_home.png) | [碰撞与交互点](hazel_home-collision.png) |
| 霍克家的家 | 22 × 27 | [布局](hawk_home.png) | [碰撞与交互点](hawk_home-collision.png) |
| 彭伯顿家的家 | 20 × 22 | [布局](pemberton_home.png) | [碰撞与交互点](pemberton_home-collision.png) |
| 费利克斯的钟表屋 | 18 × 20 | [布局](felix_home.png) | [碰撞与交互点](felix_home-collision.png) |
| 奎尔家的家 | 22 × 27 | [布局](quill_home.png) | [碰撞与交互点](quill_home-collision.png) |
| 阿玛拉的邮差小屋 | 18 × 20 | [布局](amara_home.png) | [碰撞与交互点](amara_home-collision.png) |
| 西奥的家 | 18 × 21 | [布局](theo_home.png) | [碰撞与交互点](theo_home-collision.png) |
| 德尔加多家的家 | 20 × 22 | [布局](ranch_home.png) | [碰撞与交互点](ranch_home-collision.png) |
| 约纳斯的林间小屋 | 18 × 20 | [布局](ranger_home.png) | [碰撞与交互点](ranger_home-collision.png) |
| 雷恩的观鸟小屋 | 18 × 20 | [布局](wren_home.png) | [碰撞与交互点](wren_home-collision.png) |
| 弗林家的海边住宅 | 20 × 22 | [布局](ferry_home.png) | [碰撞与交互点](ferry_home-collision.png) |
| 卡弗家的楼上 | 22 × 27 | [布局](carver_loft.png) | [碰撞与交互点](carver_loft-collision.png) |
| 酒馆楼上 · 住客走廊 | 22 × 27 | [布局](inn_lodging.png) | [碰撞与交互点](inn_lodging-collision.png) |
| 铁匠铺后宅 | 20 × 22 | [布局](smith_home.png) | [碰撞与交互点](smith_home-collision.png) |
| 诊所楼上 | 20 × 22 | [布局](clinic_home.png) | [碰撞与交互点](clinic_home-collision.png) |

## 生成来源

- 房间与通路：`tools/world/interior_plan.py`、`interior_layouts.py`、`public_interiors.py`。
- 家庭与个人陈设：`tools/world/residences.py`。
- 墙与地板：`tools/art/room_kit.py`；搭建与拼图：`tools/art/room_backgrounds.py`，运行 `.venv/bin/python tools/art/room_backgrounds.py --collisions`，输出到 `build/interior-previews/`。
- 家具：`assets/library/interiors/` 的源图，经 `tools/art/room_assets.py` 落到 `assets/art/`。
