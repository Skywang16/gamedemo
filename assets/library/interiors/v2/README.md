# Sprout Valley 室内可复用资产库 v2

本目录是独立资产库，尚未替换游戏内地图。根目录 `.gdignore` 排除未接入的库文件，避免将源图和预览作为运行时资源导入。

## 交付结构

- `room_*.png`：逐件导出的游戏尺寸素材；家具、门窗与地毯使用真实透明通道。
- `manifest.json`：尺寸、分类、摆放格数、锚点、原图来源与哈希。
- `preview.png`：同一缩放比例下的家具与当前人物对照。
- 原始 4K 素材板、独立高分辨率裁切与提示词保存在项目 `build/art-raw/`。4K 指原始素材板，不代表每件游戏 PNG 都是 4K。

## 统一规则

一格为 32×32 像素；人物源帧为 32×48，世界显示倍率 1.25（画布 40×60，不含相机缩放），预览按此倍率与家具对照。所有物件使用同一原创参考图 `assets/reference/interior_style_v2.png`，同一 112 色共享调色板（参考图 96 色，加石材 16 色），硬像素透明边缘；显示使用 nearest，不开 mipmap。不可按任意目标矩形拉伸。

家具锚点为画布底部中心。`placement_box_px` 是相对锚点的摆放包围盒，**不是精确碰撞框**；接入时按可见底座校准碰撞并验证门、座椅和过道。窗、挂画、挂架属于墙饰，没有地面碰撞；地毯属于地面装饰。

木地板、石地板支持 XY 重复，墙面支持水平重复。纹理导出做镜像边界闭合；这能保证接缝像素连续，但不能替代整面铺设后的重复感审美检查。墙面是立面纹理，仍需在地图制作阶段设计墙角、侧墙、门洞和遮挡。

## 生成与复查

```sh
.venv/bin/python tools/art/ai_interior_library.py
.venv/bin/python tools/art/ai_interior_library.py --process-only
.venv/bin/python tools/art/check_interior_library.py
.venv/bin/python tools/art/check_interior_library.py --package
```

首次生成会调用 image2free 的 `gpt-image-2.5-sunburst`，请求 `uhd`、16:9。每张素材板最多四个分离物件，随后独立导出。缓存命中不会再次收费；`--force` 才重新请求。密钥从用户配置目录读取，不写入资产或清单。

打包命令输出 `build/art-delivery/sprout-valley-interiors-v2.zip`，包含独立 PNG、4K 素材板、高分辨率裁切、提示词、参考图、预览和规格清单。门框允许超出一格入口的视觉范围；诊疗床与托盘为 2×2 格的组合陈设，酒架为落地柜。组合陈设内部的杯盘书本不作为可操作道具。

最初的空间与风格参考为《星露谷物语》的酒馆、杂货店公开截图；这些仅传入模型作学习参考，不作为游戏资产交付。后续所有物件只参考原创 v2 基准图。

参考来源：https://stardewvalleywiki.com/File:Saloon_Interior.png 、https://stardewvalleywiki.com/File:Pierre%27s_General_Store_Interior.png 。

功能交互、人物动画、分房间地图、碰撞与存档接入属于后续地图阶段，不由本素材库宣称完成。
