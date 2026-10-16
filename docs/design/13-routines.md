# 13 · 村民日程总表

本表由 `tools/content/build_routines_doc.py` 从日程数据生成。每位村民的规则按从上到下的顺序判断，第一条条件全部满足的规则生效；最后一条没有条件。规则写法见 [12 · 日程系统](12-schedules.md)。

## 黑兹尔（种子商 · 把日子种回土里）

1. **生日当天**
   - 06:00 home_farm/hazel_house｜起床
   - 09:00 home_farm/stall｜在摊位前收邻居们的小礼物
   - 12:30 town/fountain_n｜和朋友们聊天
   - 18:00 inn/table_a｜在小酒馆过生日
   - 22:00 home_farm/hazel_house｜回家休息
2. **节日当天**
   - 06:00 home_farm/hazel_house｜起床
   - 09:00 festival｜参加节日
   - 14:30 home_farm/field_a｜回农场浇水
   - 18:30 inn/table_b｜和大家一起吃晚饭
   - 22:00 home_farm/hazel_house｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜给你煮了热茶
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 home_farm/stall｜摆摊分种子
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 home_farm/field_a｜在田里浇水
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **天气：雨、雷暴、雪**
   - 06:30 home_farm/hazel_house｜起床
   - 08:00 home_farm/stall｜在雨棚下分装种子
   - 12:30 home_farm/stall_side｜午饭
   - 13:30 home_farm/stall｜继续分装种子
   - 18:00 inn/table_a｜在小酒馆躲雨吃饭
   - 21:00 home_farm/hazel_house｜休息
5. **周六**
   - 06:30 home_farm/hazel_house｜起床
   - 08:00 home_farm/field_a｜浇水
   - 09:30 market/stall_a｜去集市买麻绳和纸袋
   - 12:00 market/plaza_w｜和朋友们午饭
   - 15:00 market/stall_b｜逛摊位
   - 17:00 town/fountain_s｜散步
   - 19:00 inn/table_a｜晚餐
   - 22:00 home_farm/hazel_house｜回家
6. **周日**
   - 07:30 home_farm/hazel_house｜睡了个懒觉
   - 09:00 home_farm/well｜修水桶
   - 10:30 town/bench_w｜晒太阳发呆
   - 12:30 inn/table_b｜午饭
   - 15:00 town/bridge｜看河水
   - 18:30 inn/table_a｜晚餐
   - 22:00 home_farm/hazel_house｜回家
7. **冬**
   - 07:00 home_farm/hazel_house｜起床
   - 09:00 home_farm/stall｜只摆冬季的种子
   - 14:00 home_farm/hazel_house｜回屋取暖
   - 18:00 inn/table_a｜晚餐
   - 21:30 home_farm/hazel_house｜休息
8. **其余日子**
   - 06:00 home_farm/hazel_house｜起床
   - 07:30 home_farm/field_a｜浇水
   - 09:00 home_farm/stall｜摆摊卖种子
   - 12:30 home_farm/stall_side｜午饭
   - 13:30 home_farm/stall｜摆摊卖种子
   - 17:30 home_farm/field_b｜傍晚再浇一遍水
   - 19:00 inn/table_a｜晚餐
   - 22:00 home_farm/hazel_house｜回家休息

## 赛拉斯（木匠 · 没说出口的承诺）

1. **生日当天**
   - 06:00 town/workshop_door｜起床
   - 09:00 workshop/bench｜照常刨木头，说不想过生日
   - 12:30 inn/table_a｜被玛戈拉去吃饭
   - 18:00 town/bridge｜站在桥上看水
   - 22:00 town/workshop_door｜回家休息
2. **节日当天**
   - 06:00 town/workshop_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/bridge｜检查桥栏
   - 18:30 inn/table_b｜沉默地吃饭
   - 22:00 town/workshop_door｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜劈好了柴
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 town/workshop_door｜回木工坊赶活
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 home_farm/east_road｜给农场修篱笆
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **天气：雨、雷暴、雪 · 故事进度 ≥ 3**
   - 06:30 town/workshop_door｜起床
   - 08:30 workshop/bench｜雨天刨木头
   - 12:30 workshop/table｜午饭
   - 13:30 workshop/bench｜做家具
   - 18:00 inn/table_a｜晚餐
   - 21:00 town/workshop_door｜休息
5. **周日**
   - 07:30 town/workshop_door｜起床
   - 09:00 town/bridge｜巡桥
   - 11:00 town/bench_w｜在长椅上削木片
   - 13:00 workshop/table｜午饭
   - 15:00 town/south_w｜散步
   - 18:00 inn/table_a｜晚餐
   - 21:30 town/workshop_door｜休息
6. **周六**
   - 06:30 town/workshop_door｜起床
   - 08:00 workshop/bench｜备料
   - 10:00 market/smith_door｜去铁匠铺取铁钉
   - 12:00 market/plaza_w｜集市日买菜
   - 14:00 workshop/bench｜做家具
   - 18:00 inn/table_a｜晚餐
   - 21:30 town/workshop_door｜休息
7. **天气：雨、雷暴、雪**
   - 06:30 town/workshop_door｜起床
   - 08:30 workshop/bench｜雨天刨木头
   - 12:30 workshop/table｜午饭
   - 13:30 workshop/bench｜做家具
   - 18:00 inn/table_a｜晚餐
   - 21:00 town/workshop_door｜休息
8. **其余日子**
   - 06:00 town/workshop_door｜起床
   - 07:30 workshop/bench｜开工，刨木头
   - 09:00 workshop/bench｜接订单
   - 12:30 workshop/table｜午饭
   - 13:30 workshop/bench｜做家具
   - 17:00 town/bridge｜巡一遍桥
   - 18:30 inn/table_a｜晚餐
   - 21:30 town/workshop_door｜休息

## 玛戈（小酒馆老板 · 一顿饭的距离）

1. **生日当天**
   - 06:00 town/inn_door｜起床
   - 09:00 inn/counter｜照常开张，把窗边的位子留给自己
   - 12:30 inn/table_a｜难得坐下来吃饭
   - 18:00 town/fountain_s｜傍晚去广场透气
   - 22:00 town/inn_door｜回家休息
2. **节日当天**
   - 06:00 town/inn_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 inn/counter｜准备节日的大锅汤
   - 18:30 inn/counter｜给大家上汤
   - 22:00 town/inn_door｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜在灶台边做早饭
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 inn/counter｜去酒馆备料
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 inn/table_a｜打烊前收拾桌子
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **周日**
   - 07:30 town/inn_door｜起床
   - 09:00 inn/counter｜备料
   - 11:00 inn/counter｜周日简餐营业
   - 15:00 town/bench_e｜带米洛晒太阳
   - 17:30 inn/counter｜晚餐营业
   - 22:00 town/inn_door｜打烊
5. **周六**
   - 06:00 town/inn_door｜起床
   - 07:30 market/stall_c｜去集市买菜
   - 10:00 inn/counter｜开张
   - 14:00 inn/counter｜午市
   - 18:00 inn/counter｜晚市很忙
   - 22:30 town/inn_door｜打烊
6. **冬**
   - 06:30 town/inn_door｜起床
   - 08:00 inn/counter｜熬一大锅浓汤
   - 11:00 inn/counter｜午市
   - 17:00 inn/counter｜晚市
   - 22:00 town/inn_door｜打烊
7. **其余日子**
   - 06:00 town/inn_door｜起床
   - 07:00 inn/counter｜备料
   - 09:00 inn/counter｜开张
   - 12:00 inn/table_b｜给米洛喂午饭
   - 13:00 inn/counter｜午市
   - 17:30 inn/counter｜晚市
   - 22:00 town/inn_door｜打烊

## 雷恩（湿地鸟类记录员 · 给未来的信）

1. **生日当天**
   - 06:00 lake/hut｜起床
   - 09:00 lake/shore_w｜在水边观察候鸟
   - 12:30 lake/bench_w｜吃带来的面包
   - 18:00 lake/lantern｜在灯台旁坐着
   - 22:00 lake/hut｜回家休息
2. **故事进度 ≤ 2**
   - 06:00 lake/hut｜起床
   - 07:00 lake/shore_w｜记录水位
   - 10:00 lake/pier｜观鸟
   - 13:00 lake/bench_w｜午饭
   - 15:00 lake/shore_w｜记录水位
   - 18:00 lake/lantern｜看灯台
   - 21:00 lake/hut｜回屋
3. **节日当天 · 故事进度 ≤ 2**
   - 06:00 lake/hut｜起床
   - 09:00 lake/lantern｜听见对岸传来的热闹
   - 14:30 lake/pier｜观察候鸟
   - 18:30 lake/lantern｜看灯台
   - 21:00 lake/hut｜回屋
4. **节日当天 · 故事进度 ≥ 3**
   - 06:00 lake/hut｜起床
   - 09:00 festival｜参加节日
   - 14:30 lake/pier｜观察夜里的候鸟
   - 18:30 lake/lantern｜站在人群边上看灯
   - 22:00 lake/hut｜回家休息
5. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜窗台上放了新的笔记
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 lake/shore_w｜记录水位
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 lake/pier｜观察水鸟
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
6. **天气：雨、雷暴、雪**
   - 06:30 lake/hut｜起床
   - 08:00 lake/hut｜在屋里整理笔记
   - 11:00 lake/bench_w｜在雨里听芦苇的声音
   - 13:00 lake/hut｜午饭
   - 16:00 lake/shore_w｜雨停后记录水位
   - 20:00 lake/hut｜回屋
7. **周日 · 故事进度 ≥ 3**
   - 07:30 lake/hut｜起床
   - 09:00 lake/pier｜观鸟
   - 12:00 town/bench_w｜去镇上和黑兹尔聊天
   - 15:00 inn/table_a｜在小酒馆吃点心
   - 18:30 lake/lantern｜回到湖边
   - 21:00 lake/hut｜回屋
8. **秋**
   - 06:00 lake/hut｜起床
   - 07:00 lake/shore_w｜数候鸟
   - 11:00 lake/pier｜候鸟迁徙季，整日观测
   - 14:00 lake/bench_e｜午饭
   - 16:00 lake/pier｜继续观测
   - 21:00 lake/hut｜回屋
9. **其余日子**
   - 06:00 lake/hut｜起床
   - 07:00 lake/shore_w｜记录水位
   - 10:00 lake/pier｜观鸟
   - 12:30 lake/bench_w｜午饭
   - 14:00 lake/shore_w｜抄写笔记
   - 17:00 lake/lantern｜看灯台
   - 21:00 lake/hut｜回屋

## 朱妮（草药师 · 不被打断地照顾一件事）

1. **生日当天**
   - 06:00 market/clinic_door｜起床
   - 09:00 clinic/front｜给大家泡茶
   - 12:30 forest/herbs｜采一束生日花
   - 18:00 tea_house/table_a｜和诺拉喝茶
   - 22:00 market/clinic_door｜回家休息
2. **节日当天**
   - 06:00 market/clinic_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 forest/herbs｜采药
   - 18:30 tea_house/table_b｜和诺拉喝茶
   - 22:00 market/clinic_door｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜烧好了热水
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 forest/herbs｜采药
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 home_farm/well｜在院里晾药草
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **周日**
   - 07:30 market/clinic_door｜起床
   - 09:00 forest/herbs｜休息日采药
   - 13:00 forest/stump｜在林中午餐
   - 16:00 forest/herbs｜整理药草
   - 19:00 tea_house/table_a｜在茶室喝茶
   - 22:00 market/clinic_door｜回诊所
5. **天气：雨、雷暴、雪**
   - 06:30 market/clinic_door｜起床
   - 08:30 clinic/front｜雨天病人多，帮忙
   - 12:30 clinic/front｜午饭
   - 13:30 clinic/behind_r｜整理药柜
   - 18:00 tea_house/table_a｜喝茶
   - 21:30 market/clinic_door｜回诊所
6. **冬**
   - 06:30 market/clinic_door｜起床
   - 08:30 clinic/front｜诊所帮忙
   - 12:30 clinic/behind_r｜午饭
   - 14:00 clinic/behind_r｜熬冬季药剂
   - 18:30 tea_house/table_a｜喝茶
   - 21:30 market/clinic_door｜休息
7. **周一、周二、周三、周四 · 第 2 年起**
   - 06:00 market/clinic_door｜起床
   - 07:30 forest/herbs｜晨间采药
   - 11:30 market/clinic_door｜回诊所
   - 12:30 clinic/front｜门诊
   - 15:00 clinic/behind_r｜带克拉拉学习
   - 18:30 tea_house/table_a｜喝茶
   - 21:30 market/clinic_door｜休息
8. **其余日子**
   - 06:00 market/clinic_door｜起床
   - 07:00 forest/herbs｜晨间采药
   - 10:30 market/clinic_door｜回诊所
   - 11:00 clinic/behind_r｜整理药草
   - 13:00 clinic/front｜门诊
   - 17:00 forest/herbs｜傍晚去采药
   - 19:00 tea_house/table_a｜喝茶
   - 22:00 market/clinic_door｜回诊所

## 利奥（行脚商人 · 放下行李）

1. **生日当天**
   - 06:00 town/inn_door｜起床
   - 09:00 market/plaza_w｜在广场摆开背包
   - 12:30 market/stall_e｜尝摊位上的小吃
   - 18:00 inn/table_b｜和阿玛拉庆祝
   - 22:00 town/inn_door｜回家休息
2. **节日当天**
   - 06:00 town/inn_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 market/plaza_w｜逛集市
   - 18:30 inn/table_b｜和大家吃晚饭
   - 22:00 town/inn_door｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜泡了杯茶
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 market/plaza_w｜摆摊卖远方的小物件
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 market/bench_e｜在长椅上数零钱
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **周一、周二、周三、周四、周五 · 故事进度 ≤ 5**
   - 06:00 away｜在别的镇子路上
5. **周六、周日**
   - 06:30 town/inn_door｜起床
   - 09:00 market/plaza_w｜摆摊卖远方的小物件
   - 13:00 market/bench_e｜午饭
   - 15:00 market/plaza_e｜继续摆摊
   - 19:00 inn/table_b｜晚餐
   - 22:00 town/inn_door｜回房间
6. **天气：雨、雷暴、雪**
   - 07:00 town/inn_door｜起床
   - 09:00 inn/table_b｜躲雨看地图
   - 13:00 tea_house/table_a｜喝茶
   - 17:00 inn/table_b｜晚餐
   - 22:00 town/inn_door｜回房间
7. **其余日子**
   - 06:30 town/inn_door｜起床
   - 08:30 forest/camp｜去林中营地整理行李
   - 12:30 forest/stump｜午饭
   - 15:00 market/plaza_w｜摆摊
   - 19:00 inn/table_b｜晚餐
   - 22:00 town/inn_door｜回房间

## 费利克斯（钟表匠 · 让时间慢一点）

1. **生日当天**
   - 06:00 market/home_36｜起床
   - 09:00 market/plaza_n｜站在广场上听钟楼
   - 12:30 tea_house/table_a｜和诺拉喝茶
   - 18:00 market/bench_w｜傍晚坐着看天
   - 22:00 market/home_36｜回家休息
2. **节日当天**
   - 06:00 market/home_36｜起床
   - 09:00 festival｜参加节日
   - 14:30 market/plaza_n｜远远看着热闹
   - 18:30 tea_house/table_b｜躲在茶室角落吃饭
   - 22:00 market/home_36｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜把表一只一只擦亮
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 town/hall_steps｜给钟楼上弦
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 home_farm/yard｜在院里修表
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **周日**
   - 08:00 market/home_36｜起床
   - 10:00 market/bench_w｜看书
   - 13:00 tea_house/table_a｜午饭和茶
   - 15:00 market/back_w｜散步
   - 19:00 market/home_36｜回屋修表
   - 24:00 market/home_36｜熬夜修表
5. **天气：雨、雷暴、雪**
   - 06:30 market/home_36｜起床
   - 08:00 market/home_36｜雨天安静修表
   - 12:30 tea_house/table_a｜午饭
   - 14:00 market/home_36｜继续修表
   - 20:00 market/home_36｜修表
6. **周日 · 每月第 4 周**
   - 08:00 market/home_36｜起床
   - 10:00 town/hall_steps｜去镇公所清点钟楼零件
   - 14:00 market/bench_w｜休息
   - 19:00 market/home_36｜回屋
7. **冬**
   - 07:00 market/home_36｜起床
   - 09:00 market/home_36｜室内修表
   - 12:30 tea_house/table_a｜午饭
   - 14:00 market/home_36｜修表
   - 20:00 tea_house/table_b｜喝热茶
   - 22:00 market/home_36｜回屋
8. **其余日子**
   - 06:30 market/home_36｜起床
   - 08:00 market/plaza_n｜去广场校对钟楼
   - 09:30 market/home_36｜开始修表
   - 12:30 tea_house/table_a｜午饭
   - 14:00 market/home_36｜修表
   - 18:00 market/bench_w｜傍晚散步
   - 20:00 market/home_36｜修表到深夜

## 科莱特（剧团女演员 · 谢幕之后）

1. **生日当天**
   - 06:00 market/home_60｜起床
   - 09:00 market/plaza_e｜在广场上表演一小段
   - 12:30 tea_house/table_a｜和朋友喝茶
   - 18:00 inn/table_a｜晚餐
   - 22:00 market/home_60｜回家休息
2. **节日当天**
   - 06:00 market/home_60｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/fountain_n｜即兴演出
   - 18:30 inn/table_b｜和剧团的人吃晚饭
   - 22:00 market/home_60｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜对着镜子练台词
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 town/fountain_n｜在喷泉边背台词
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 market/plaza_e｜排练新戏
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **周六**
   - 07:30 market/home_60｜起床
   - 09:00 town/fountain_n｜街头小演出
   - 12:00 inn/table_a｜午饭
   - 14:30 market/plaza_e｜集市日卖票
   - 19:00 town/fountain_s｜晚间演出
   - 22:00 market/home_60｜回家
5. **周日**
   - 08:00 market/home_60｜起床
   - 10:00 town/bench_e｜背台词
   - 13:00 inn/table_b｜午饭
   - 15:00 market/bench_e｜散步
   - 18:30 tea_house/table_b｜喝茶
   - 22:00 market/home_60｜回家
6. **天气：雨、雷暴、雪**
   - 07:30 market/home_60｜起床
   - 09:00 inn/window｜在窗边练声
   - 12:30 inn/table_a｜午饭
   - 14:00 market/home_60｜在家排练
   - 18:30 inn/table_a｜晚餐
   - 22:00 market/home_60｜回家
7. **冬**
   - 07:00 market/home_60｜起床
   - 09:00 town/hall_steps｜为剧院之夜排练
   - 12:30 inn/table_a｜午饭
   - 14:00 town/hall_steps｜排练
   - 18:30 inn/table_a｜晚餐
   - 22:30 market/home_60｜回家
8. **其余日子**
   - 06:30 market/home_60｜起床
   - 08:00 town/fountain_n｜晨间练声
   - 11:00 town/hall_steps｜排练
   - 13:00 inn/table_a｜午饭
   - 15:00 town/hall_steps｜排练
   - 18:30 inn/table_b｜晚餐
   - 22:00 market/home_60｜回家

## 约纳斯（巡林员 · 值夜的人）

1. **生日当天**
   - 06:00 forest/lodge｜起床
   - 09:00 seaside/maeve_house｜回母亲家吃生日饭
   - 12:30 seaside/promenade_w｜陪外祖父晒太阳
   - 18:00 seaside/maeve_house｜家人晚餐
   - 22:00 forest/lodge｜回家休息
2. **节日当天**
   - 06:00 forest/lodge｜起床
   - 09:00 festival｜参加节日
   - 14:30 forest/crossing｜夜里巡林
   - 18:30 seaside/promenade_w｜和家人吃晚饭
   - 22:00 forest/lodge｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜烤好了面包
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 forest/crossing｜巡林
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 forest/glade｜检查林中小路
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **天气：雨、雷暴、雪**
   - 06:00 forest/lodge｜起床
   - 07:00 forest/crossing｜雨天加巡一遍
   - 11:00 forest/glade｜检查山路
   - 13:00 forest/lodge｜午饭
   - 15:00 forest/stream｜看溪水涨落
   - 19:00 forest/lodge｜回屋
5. **周日**
   - 07:30 forest/lodge｜起床
   - 09:00 seaside/maeve_house｜回家看望母亲
   - 12:30 seaside/promenade_w｜陪外祖父吃饭
   - 16:00 seaside/dock_mid｜帮忙修缆绳
   - 19:00 forest/lodge｜回林中
   - 22:00 forest/lodge｜休息
6. **冬**
   - 06:30 forest/lodge｜起床
   - 08:00 forest/crossing｜巡林查看积雪
   - 12:00 forest/lodge｜午饭
   - 14:00 forest/glade｜检查落雪的树
   - 19:00 forest/lodge｜休息
7. **其余日子**
   - 06:00 forest/lodge｜起床
   - 07:00 forest/crossing｜晨间巡林
   - 10:00 forest/glade｜看动物脚印
   - 12:30 forest/stump｜午饭
   - 14:00 forest/stream｜查溪水
   - 17:00 forest/gate｜检查矿洞口
   - 19:30 forest/lodge｜回巡护站
   - 22:00 forest/lodge｜休息

## 诺拉（茶室老板 · 家传的方子）

1. **生日当天**
   - 06:00 market/tea_door｜起床
   - 09:00 tea_house/behind｜给自己泡一杯放两块糖的茶
   - 12:30 tea_house/table_a｜朋友们来喝茶
   - 18:00 market/plaza_w｜傍晚散步
   - 22:00 market/tea_door｜回家休息
2. **节日当天**
   - 06:00 market/tea_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/fountain_s｜在广场卖茶
   - 18:30 tea_house/behind｜给节日后的客人泡茶
   - 22:00 market/tea_door｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜烧好了茶
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 tea_house/behind｜回茶室煮茶
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 tea_house/behind_r｜午市接待客人
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **周六**
   - 06:00 market/tea_door｜起床
   - 07:00 tea_house/behind｜烧水备茶
   - 09:30 market/stall_g｜集市日摆茶摊
   - 15:00 tea_house/behind｜回茶室
   - 19:00 tea_house/behind_r｜晚间客人
   - 22:30 market/tea_door｜打烊
5. **天气：雨、雷暴、雪**
   - 06:30 market/tea_door｜起床
   - 08:00 tea_house/behind｜烧水备茶
   - 10:00 tea_house/behind｜雨天生意最好
   - 15:00 tea_house/behind_r｜招呼客人
   - 21:00 tea_house/behind｜收拾
   - 22:30 market/tea_door｜打烊
6. **周日**
   - 07:30 market/tea_door｜起床
   - 10:00 tea_house/behind｜营业
   - 14:00 ranch/road_w｜去牧场看罗西
   - 17:00 tea_house/behind｜回茶室
   - 22:00 market/tea_door｜打烊
7. **第 2 年起**
   - 06:00 market/tea_door｜起床
   - 07:00 tea_house/behind｜烧水备茶
   - 10:00 tea_house/behind_r｜第二个柜台开张
   - 14:00 tea_house/behind｜午市
   - 19:00 tea_house/behind_r｜晚间客人
   - 22:30 market/tea_door｜打烊
8. **其余日子**
   - 06:00 market/tea_door｜起床
   - 07:00 tea_house/behind｜烧水备茶
   - 10:00 tea_house/behind｜营业
   - 13:00 tea_house/behind_r｜午市
   - 17:00 tea_house/behind｜傍晚客人
   - 22:00 market/tea_door｜打烊

## 西奥（小学教师 · 放学以后）

1. **生日当天**
   - 06:00 market/home_84｜起床
   - 09:00 town/school_yard｜孩子们给他唱生日歌
   - 12:30 town/school_yard｜和孩子们吃蛋糕
   - 18:00 tea_house/table_a｜喝茶
   - 22:00 market/home_84｜回家休息
2. **节日当天**
   - 06:00 market/home_84｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/school_yard｜整理节日用的桌椅
   - 18:30 inn/table_b｜和大家吃晚饭
   - 22:00 market/home_84｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜在桌前读书
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 town/school_yard｜给孩子们上课
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 town/school_door｜批改作业
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **周一、周二、周三、周四、周五 · 每月第 3、4 周 · 夏**
   - 06:30 market/home_84｜起床
   - 08:00 town/school_door｜暑假前最后的课
   - 12:00 town/school_yard｜和孩子们一起午饭
   - 13:00 town/school_door｜下午的课
   - 16:00 town/hall_steps｜在镇公所递交报告
   - 19:00 tea_house/table_a｜喝茶
   - 22:00 market/home_84｜回家
5. **周一、周二、周三、周四、周五 · 每月第 1、2 周 · 夏**
   - 06:30 market/home_84｜起床
   - 08:00 town/school_door｜上课
   - 12:00 town/school_yard｜午饭
   - 13:00 town/school_door｜下午的课
   - 16:00 market/back_e｜家访
   - 19:00 tea_house/table_a｜喝茶
   - 22:00 market/home_84｜回家
6. **周一、周二、周三、周四、周五**
   - 06:30 market/home_84｜起床
   - 08:00 town/school_door｜上课
   - 12:00 town/school_yard｜和孩子们一起午饭
   - 13:00 town/school_door｜下午的课
   - 16:00 town/school_yard｜批改作业
   - 18:30 tea_house/table_a｜喝茶
   - 22:00 market/home_84｜回家
7. **周六**
   - 08:00 market/home_84｜起床
   - 09:30 market/stall_d｜在集市上买书和蜂蜜
   - 13:00 tea_house/table_b｜午饭
   - 15:00 market/bench_w｜读书
   - 19:00 inn/table_b｜晚餐
   - 22:00 market/home_84｜回家
8. **其余日子**
   - 08:00 market/home_84｜起床
   - 10:00 town/bench_w｜在长椅上备课
   - 13:00 inn/table_b｜午饭
   - 15:00 town/bridge｜看河水
   - 19:00 tea_house/table_a｜喝茶
   - 22:00 market/home_84｜回家

## 德克兰（采石矿向导 · 出口）

1. **生日当天**
   - 06:00 market/smith_door｜起床
   - 09:00 blacksmith/front｜在舅舅铺子里吃炖肉
   - 12:30 market/bench_e｜晒太阳
   - 18:00 tea_house/table_b｜喝茶
   - 22:00 market/smith_door｜回家休息
2. **节日当天**
   - 06:00 market/smith_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 mine_1/entrance｜去矿洞口站一会儿
   - 18:30 inn/table_b｜默默吃饭
   - 22:00 market/smith_door｜回家休息
3. **故事进度 ≥ 6**
   - 06:00 cottage/bed_side｜起床
   - 07:00 cottage/kitchen_side｜擦拭矿灯
   - 08:30 home_farm/yard｜在院子里等你出门
   - 09:30 mine_1/entrance｜下矿勘探
   - 12:30 cottage/table｜回家吃午饭
   - 14:00 forest/camp｜在林地营地休息
   - 18:30 home_farm/yard｜在院子里等你
   - 19:30 cottage/table｜晚饭
   - 22:00 cottage/bed_side｜休息
4. **天气：雨、雷暴、雪**
   - 06:30 market/smith_door｜起床
   - 08:00 mine_1/entrance｜矿口渗水，守着
   - 12:00 mine_1/cart｜午饭
   - 14:00 mine_1/entrance｜擦矿灯
   - 18:00 market/smith_door｜回铁铺
   - 21:00 market/smith_door｜休息
5. **周日**
   - 08:00 market/smith_door｜起床
   - 10:00 blacksmith/front｜帮舅舅整理
   - 13:00 blacksmith/table｜午饭
   - 16:00 market/bench_e｜发呆
   - 19:00 tea_house/table_b｜喝茶
   - 21:30 market/smith_door｜休息
6. **冬**
   - 07:00 market/smith_door｜起床
   - 09:00 blacksmith/forge｜帮忙烧炉子
   - 12:00 blacksmith/table｜午饭
   - 14:00 mine_1/entrance｜去矿口看一眼
   - 18:00 market/smith_door｜回铁铺
   - 21:00 market/smith_door｜休息
7. **其余日子**
   - 06:00 market/smith_door｜起床
   - 07:30 forest/gate｜走去矿洞
   - 08:30 mine_1/entrance｜检查矿道
   - 12:00 mine_1/cart｜午饭
   - 13:00 mine_1/deep｜带路和采石
   - 17:00 mine_1/entrance｜擦矿灯
   - 18:30 market/smith_door｜回家
   - 21:30 market/smith_door｜休息

## 奥古斯都（镇长 · 规矩为人服务）

1. **生日当天**
   - 06:00 market/home_24｜起床
   - 09:00 town/hall_steps｜在镇公所前收礼物
   - 12:30 inn/table_a｜克拉拉给他做的蛋糕
   - 18:00 town/fountain_s｜傍晚散步
   - 22:00 market/home_24｜回家休息
2. **节日当天**
   - 06:00 market/home_24｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/fountain_n｜主持节日
   - 18:30 inn/table_a｜和大家吃节日晚餐
   - 22:00 market/home_24｜回家休息
3. **周日**
   - 07:30 market/home_24｜起床
   - 09:00 town/bench_e｜读报
   - 12:00 inn/table_b｜午饭
   - 14:00 town/bridge｜看河水
   - 17:00 town/hall_steps｜擦钟楼的钟
   - 19:00 market/home_24｜回家
   - 21:30 market/home_24｜休息
4. **周六**
   - 07:00 market/home_24｜起床
   - 08:30 town/hall_door｜开会
   - 11:00 market/plaza_n｜巡视集市
   - 13:00 inn/table_a｜午饭
   - 15:00 market/plaza_w｜和商贩聊天
   - 18:00 market/home_24｜回家
   - 21:30 market/home_24｜休息
5. **天气：雨、雷暴、雪**
   - 06:30 market/home_24｜起床
   - 08:30 town/hall_door｜雨天在镇公所对账
   - 12:30 inn/table_a｜午饭
   - 14:00 town/hall_door｜对账
   - 18:00 market/home_24｜回家
   - 21:00 market/home_24｜休息
6. **周一、周二、周三、周四、周五 · 故事进度 ≥ 6**
   - 06:30 market/home_24｜起床
   - 08:30 town/hall_door｜处理镇务
   - 12:00 inn/table_a｜午饭
   - 13:30 town/hall_steps｜接待来访的人
   - 16:00 town/bridge｜巡桥
   - 18:30 market/home_24｜回家
   - 21:30 market/home_24｜休息
7. **其余日子**
   - 06:30 market/home_24｜起床
   - 08:30 town/hall_door｜处理镇务
   - 12:00 inn/table_a｜午饭
   - 13:30 town/hall_door｜处理镇务
   - 16:00 town/fountain_s｜散步
   - 18:30 market/home_24｜回家
   - 21:30 market/home_24｜休息

## 克拉拉（学生 · 想学医）

1. **生日当天**
   - 06:00 market/home_24｜起床
   - 09:00 town/fountain_s｜朋友们送来小礼物
   - 12:30 inn/table_a｜祖父请吃饭
   - 18:00 tea_house/table_a｜喝茶
   - 22:00 market/home_24｜回家休息
2. **节日当天**
   - 06:00 market/home_24｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/fountain_n｜和朋友们玩
   - 18:30 inn/table_b｜帮玛戈端菜
   - 22:00 market/home_24｜回家休息
3. **周一、周二、周三、周四、周五、周六 · 第 2 年起**
   - 06:00 away｜在外地读书
4. **周一、周二、周三、周四、周五 · 天气：雨、雷暴、雪**
   - 06:30 market/home_24｜起床
   - 08:00 town/school_door｜上学（带伞）
   - 15:30 clinic/front｜去诊所帮忙
   - 18:30 inn/table_a｜晚餐
   - 21:30 market/home_24｜回家
5. **周一、周二、周三、周四、周五**
   - 06:30 market/home_24｜起床
   - 08:00 town/school_door｜上学
   - 12:00 town/school_yard｜午饭
   - 13:00 town/school_door｜下午的课
   - 15:30 clinic/front｜去诊所帮忙
   - 17:30 market/clinic_door｜背骨头的名字
   - 19:00 market/home_24｜回家
   - 21:30 market/home_24｜复习
6. **周六**
   - 07:30 market/home_24｜起床
   - 09:00 market/stall_f｜集市日帮摊
   - 13:00 tea_house/table_a｜午饭
   - 15:00 clinic/front｜去诊所帮忙
   - 19:00 market/home_24｜回家
   - 22:00 market/home_24｜复习
7. **其余日子**
   - 08:00 market/home_24｜睡了个懒觉
   - 10:00 town/bench_e｜复习
   - 13:00 inn/table_b｜午饭
   - 15:00 town/bridge｜看河水
   - 19:00 market/home_24｜回家
   - 22:00 market/home_24｜复习

## 梅芙（前河运船主 · 嗓门最大的人）

1. **生日当天**
   - 06:00 seaside/maeve_house｜起床
   - 09:00 seaside/tackle_door｜去父亲店里领一碗鱼汤
   - 12:30 seaside/promenade_w｜和老朋友聊天
   - 18:00 seaside/maeve_house｜家人晚餐
   - 22:00 seaside/maeve_house｜回家休息
2. **节日当天**
   - 06:00 seaside/maeve_house｜起床
   - 09:00 festival｜参加节日
   - 14:30 seaside/dock_end｜看一眼自己的船
   - 18:30 town/fountain_n｜和老朋友们一起吃饭
   - 22:00 seaside/maeve_house｜回家休息
3. **天气：雨、雷暴、雪**
   - 06:00 seaside/maeve_house｜起床
   - 07:00 seaside/dock_mid｜去码头看水位
   - 10:00 tackle_shop/table｜在父亲店里喝茶
   - 14:00 seaside/maeve_house｜回家补网
   - 18:00 seaside/promenade_w｜雨停了就出来透气
   - 21:00 seaside/maeve_house｜休息
4. **周日**
   - 07:30 seaside/maeve_house｜起床
   - 09:00 seaside/promenade_w｜晒太阳
   - 12:00 seaside/maeve_house｜全家午饭
   - 15:00 seaside/dock_mid｜补缆绳
   - 18:00 seaside/promenade_e｜散步
   - 21:30 seaside/maeve_house｜休息
5. **夏、秋 · 故事进度 ≥ 6**
   - 06:00 seaside/maeve_house｜起床
   - 07:00 seaside/dock_end｜修船
   - 12:00 seaside/promenade_w｜午饭
   - 14:00 seaside/dock_mid｜继续修船
   - 18:00 seaside/promenade_e｜唱歌
   - 21:30 seaside/maeve_house｜休息
6. **其余日子**
   - 06:00 seaside/maeve_house｜起床
   - 07:00 seaside/dock_end｜看自己的船
   - 10:00 seaside/promenade_w｜和路人聊天
   - 12:30 seaside/beach_w｜午饭
   - 14:00 seaside/dock_mid｜补网
   - 18:00 seaside/promenade_e｜散步
   - 21:30 seaside/maeve_house｜休息

## 托比（前摆渡人 · 灯夜的守护者）

1. **生日当天**
   - 06:00 seaside/maeve_house｜起床
   - 09:00 tackle_shop/behind｜照常开店
   - 12:30 seaside/promenade_w｜梅芙煮了鱼汤
   - 18:00 seaside/maeve_house｜家人晚餐
   - 22:00 seaside/maeve_house｜回家休息
2. **节日当天**
   - 06:00 seaside/maeve_house｜起床
   - 09:00 festival｜参加节日
   - 14:30 seaside/dock_end｜在码头发呆
   - 18:30 town/fountain_s｜为灯夜多放一盏灯
   - 22:00 seaside/maeve_house｜回家休息
3. **天气：雨、雷暴、雪**
   - 06:00 seaside/maeve_house｜起床
   - 06:30 tackle_shop/behind｜开店
   - 12:00 tackle_shop/table｜午饭
   - 13:00 tackle_shop/behind｜磨鱼钩
   - 18:00 seaside/maeve_house｜关店回家
   - 21:00 seaside/maeve_house｜休息
4. **周日**
   - 07:00 seaside/maeve_house｜起床
   - 08:00 seaside/dock_mid｜钓鱼
   - 12:00 seaside/maeve_house｜午饭
   - 14:00 tackle_shop/behind｜开店
   - 18:00 seaside/maeve_house｜回家
   - 21:00 seaside/maeve_house｜休息
5. **冬**
   - 06:30 seaside/maeve_house｜起床
   - 07:30 tackle_shop/behind｜开店
   - 12:00 tackle_shop/table｜午饭
   - 13:00 tackle_shop/behind｜修竿
   - 17:00 seaside/maeve_house｜回家
   - 20:30 seaside/maeve_house｜休息
6. **其余日子**
   - 06:00 seaside/maeve_house｜起床
   - 06:30 tackle_shop/behind｜开店
   - 12:00 tackle_shop/table｜午饭
   - 13:00 tackle_shop/behind｜磨鱼钩
   - 17:30 seaside/dock_end｜傍晚钓鱼
   - 19:00 seaside/maeve_house｜回家
   - 21:00 seaside/maeve_house｜休息

## 罗兹（县水利局测绘员 · 回家的人）

1. **故事进度 ≤ 5**
   - 06:00 away｜在县里工作
2. **生日当天**
   - 06:00 town/workshop_door｜起床
   - 09:00 workshop/bench｜家里人给她煮了面
   - 12:30 inn/table_a｜和赛拉斯吃饭
   - 18:00 town/bridge｜在桥上站着
   - 22:00 town/workshop_door｜回家休息
3. **节日当天**
   - 06:00 town/workshop_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/bridge｜和赛拉斯并肩看灯
   - 18:30 inn/table_b｜和家人吃节日晚餐
   - 22:00 town/workshop_door｜回家休息
4. **天气：雨、雷暴、雪**
   - 07:00 town/workshop_door｜起床
   - 09:00 workshop/loom｜陪母亲织布
   - 12:30 workshop/table｜午饭
   - 14:00 workshop/bench｜抄写勘测数据
   - 18:00 inn/table_a｜晚餐
   - 21:30 town/workshop_door｜休息
5. **周日**
   - 08:00 town/workshop_door｜起床
   - 10:00 workshop/loom｜陪母亲织布
   - 13:00 workshop/table｜午饭
   - 15:00 town/bridge｜和赛拉斯在桥上聊天
   - 19:00 inn/table_a｜晚餐
   - 22:00 town/workshop_door｜休息
6. **其余日子**
   - 06:30 town/workshop_door｜起床
   - 08:00 town/bridge｜沿河勘测
   - 10:30 forest/stream｜测水位
   - 13:00 town/bench_e｜午饭
   - 14:30 town/south_e｜勘测南段
   - 17:30 workshop/bench｜整理数据
   - 19:00 inn/table_a｜晚餐
   - 22:00 town/workshop_door｜休息

## 埃莉诺（退休织工 · 调停的人）

1. **生日当天**
   - 06:00 town/workshop_door｜起床
   - 09:00 workshop/loom｜织一条新围巾
   - 12:30 inn/table_a｜玛戈送来了蛋糕
   - 18:00 town/bench_w｜在长椅上看夕阳
   - 22:00 town/workshop_door｜回家休息
2. **节日当天**
   - 06:00 town/workshop_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/fountain_s｜看大家布置
   - 18:30 inn/table_b｜和孩子们吃饭
   - 22:00 town/workshop_door｜回家休息
3. **天气：雨、雷暴、雪**
   - 06:30 town/workshop_door｜起床
   - 08:00 workshop/loom｜织布
   - 12:00 workshop/table｜午饭
   - 13:30 workshop/loom｜织布
   - 18:00 workshop/table｜晚饭
   - 21:00 town/workshop_door｜休息
4. **周日**
   - 07:30 town/workshop_door｜起床
   - 09:00 tea_house/table_a｜和朋友喝茶
   - 12:00 workshop/table｜午饭
   - 14:00 town/bench_w｜在长椅上织围巾
   - 17:00 inn/table_a｜晚餐
   - 21:00 town/workshop_door｜休息
5. **周六**
   - 07:00 town/workshop_door｜起床
   - 09:00 market/stall_b｜去集市挑线
   - 12:00 market/plaza_w｜午饭
   - 14:00 market/stall_a｜逛摊位
   - 17:00 workshop/loom｜回家织布
   - 21:00 town/workshop_door｜休息
6. **其余日子**
   - 06:30 town/workshop_door｜起床
   - 08:00 workshop/loom｜织布
   - 12:00 workshop/table｜午饭
   - 13:30 town/bench_w｜晒太阳
   - 16:00 workshop/loom｜织布
   - 18:00 workshop/table｜晚饭
   - 21:00 town/workshop_door｜休息

## 格雷戈尔（杂货店老板 · 赊账的人）

1. **生日当天**
   - 06:00 market/store_door｜起床
   - 09:00 general_store/front｜多莉煮了土豆炖肉
   - 12:30 market/plaza_w｜和邻居聊天
   - 18:00 general_store/table｜全家晚餐
   - 22:00 market/store_door｜回家休息
2. **节日当天**
   - 06:00 market/store_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 market/plaza_w｜逛节日摊位
   - 18:30 inn/table_b｜和家人吃晚饭
   - 22:00 market/store_door｜回家休息
3. **周日**
   - 07:30 market/store_door｜起床
   - 09:00 general_store/table｜全家早午餐
   - 11:00 market/bench_w｜带波比晒太阳
   - 14:00 general_store/table｜对账
   - 17:00 market/plaza_w｜散步
   - 19:00 general_store/table｜晚餐
   - 22:00 market/store_door｜休息
4. **周六**
   - 06:30 market/store_door｜起床
   - 08:30 general_store/behind｜开店，集市日客人多
   - 12:00 general_store/behind_r｜午饭
   - 13:00 general_store/behind｜卖货
   - 17:00 general_store/table｜对账
   - 19:30 general_store/table｜晚餐
   - 22:00 market/store_door｜休息
5. **周日 · 每月第 4 周**
   - 07:30 market/store_door｜起床
   - 09:00 general_store/table｜清点日，盘存
   - 14:00 general_store/table｜继续盘存
   - 19:00 general_store/table｜晚餐
   - 22:00 market/store_door｜休息
6. **天气：雨、雷暴、雪**
   - 06:30 market/store_door｜起床
   - 08:30 general_store/behind｜开店
   - 12:00 general_store/behind_r｜午饭
   - 13:00 general_store/behind｜卖雨具
   - 17:00 general_store/table｜对账
   - 19:30 general_store/table｜晚餐
   - 21:30 market/store_door｜休息
7. **其余日子**
   - 06:30 market/store_door｜起床
   - 08:30 general_store/behind｜开店
   - 12:00 general_store/behind_r｜午饭
   - 13:00 general_store/behind｜卖货
   - 17:00 general_store/table｜对账
   - 19:30 general_store/table｜晚餐
   - 22:00 market/store_door｜休息

## 多莉（菜贩 · 镇上的消息通）

1. **生日当天**
   - 06:00 market/store_door｜起床
   - 09:00 market/stall_c｜收到邻居的小礼物
   - 12:30 market/plaza_w｜边吃草莓边聊天
   - 18:00 general_store/table｜家人晚餐
   - 22:00 market/store_door｜回家休息
2. **节日当天**
   - 06:00 market/store_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 market/plaza_e｜给大家分水果
   - 18:30 inn/table_b｜和家人吃晚饭
   - 22:00 market/store_door｜回家休息
3. **周日**
   - 07:30 market/store_door｜起床
   - 09:00 general_store/table｜做早午餐
   - 11:00 market/bench_w｜和邻居聊天
   - 14:00 market/stall_c｜看一眼摊子
   - 17:00 general_store/table｜晚餐
   - 22:00 market/store_door｜休息
4. **天气：雨、雷暴、雪**
   - 06:30 market/store_door｜起床
   - 08:00 general_store/shelf｜在店里摆菜
   - 12:00 general_store/table｜午饭
   - 13:00 general_store/shelf｜摆菜
   - 17:30 general_store/table｜晚餐
   - 22:00 market/store_door｜休息
5. **周六**
   - 06:00 market/store_door｜起床
   - 07:00 market/stall_c｜集市日最早摆摊
   - 12:00 market/stall_c｜午饭
   - 17:00 market/plaza_w｜收摊后聊天
   - 19:00 general_store/table｜晚餐
   - 22:00 market/store_door｜休息
6. **其余日子**
   - 06:30 market/store_door｜起床
   - 07:30 market/stall_c｜摆摊
   - 12:30 market/stall_c｜午饭
   - 13:30 market/stall_d｜去邻摊聊天
   - 17:00 market/stall_c｜收摊
   - 19:00 general_store/table｜晚餐
   - 22:00 market/store_door｜休息

## 艾兹拉（铁匠学徒 · 想学手艺）

1. **生日当天**
   - 06:00 market/store_door｜起床
   - 09:00 market/bench_e｜一个人听音乐
   - 12:30 general_store/table｜妈妈煮了排骨
   - 18:00 market/plaza_e｜和朋友们玩
   - 22:00 market/store_door｜回家休息
2. **节日当天**
   - 06:00 market/store_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/bridge｜一个人听音乐
   - 18:30 inn/table_b｜和家人吃晚饭
   - 22:00 market/store_door｜回家休息
3. **周一、周二、周三、周四、周五、周六 · 第 2 年起**
   - 06:30 market/store_door｜起床
   - 07:30 blacksmith/forge｜正式出师，独立打铁
   - 12:00 blacksmith/table｜午饭
   - 13:00 blacksmith/forge｜打铁
   - 17:30 market/bench_e｜听音乐
   - 19:00 general_store/table｜晚餐
   - 22:00 market/store_door｜休息
4. **周一、周二、周三、周四、周五 · 天气：雨、雷暴、雪**
   - 06:30 market/store_door｜起床
   - 08:00 town/school_door｜上学
   - 15:30 blacksmith/forge｜铁匠铺帮忙
   - 17:30 market/bench_e｜听雨声
   - 19:00 general_store/table｜晚餐
   - 22:00 market/store_door｜休息
5. **周一、周二、周三、周四、周五**
   - 06:30 market/store_door｜起床
   - 08:00 town/school_door｜上学
   - 12:00 town/school_yard｜午饭
   - 13:00 town/school_door｜下午的课
   - 15:30 blacksmith/forge｜铁匠铺学徒
   - 17:30 market/bench_e｜听音乐
   - 19:00 general_store/table｜晚餐
   - 22:00 market/store_door｜休息
6. **周六**
   - 07:30 market/store_door｜起床
   - 09:00 blacksmith/forge｜整天学艺
   - 12:30 blacksmith/table｜午饭
   - 13:30 blacksmith/forge｜继续学艺
   - 18:00 market/plaza_e｜听街头乐手
   - 19:30 general_store/table｜晚餐
   - 22:00 market/store_door｜休息
7. **其余日子**
   - 08:30 market/store_door｜起床
   - 10:00 town/bridge｜看河水发呆
   - 13:00 general_store/table｜午饭
   - 15:00 market/bench_e｜听音乐
   - 19:00 general_store/table｜晚餐
   - 22:00 market/store_door｜休息

## 波比（小学生 · 爱听传说）

1. **生日当天**
   - 06:00 market/store_door｜起床
   - 09:00 market/stall_a｜收到全镇的小礼物
   - 12:30 market/plaza_w｜吹蜡烛
   - 18:00 general_store/table｜全家晚餐
   - 22:00 market/store_door｜回家休息
2. **节日当天**
   - 06:00 market/store_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 market/plaza_w｜追着蝴蝶跑
   - 18:30 inn/table_b｜吃节日蛋糕
   - 22:00 market/store_door｜回家休息
3. **周一、周二、周三、周四、周五 · 天气：雨、雷暴、雪**
   - 07:00 market/store_door｜起床
   - 08:00 town/school_door｜上学（穿雨靴）
   - 15:30 general_store/table｜在窗上画画
   - 17:30 general_store/table｜晚餐
   - 20:30 market/store_door｜睡觉
4. **周一、周二、周三、周四、周五**
   - 07:00 market/store_door｜起床
   - 08:00 town/school_door｜上学
   - 12:00 town/school_yard｜和同学午饭
   - 13:00 town/school_door｜下午的课
   - 15:30 market/plaza_w｜回家路上玩
   - 17:30 general_store/table｜晚餐
   - 20:30 market/store_door｜睡觉
5. **周六**
   - 07:30 market/store_door｜起床
   - 09:00 market/stall_c｜帮妈妈看摊子
   - 12:00 market/plaza_e｜吃冰
   - 15:00 market/bench_w｜画画
   - 17:30 general_store/table｜晚餐
   - 20:30 market/store_door｜睡觉
6. **其余日子**
   - 08:00 market/store_door｜起床
   - 09:30 market/plaza_w｜玩跳房子
   - 12:00 general_store/table｜午饭
   - 14:00 market/bench_e｜画画
   - 17:30 general_store/table｜晚餐
   - 20:30 market/store_door｜睡觉

## 米洛（小学生 · 酒馆跑腿）

1. **生日当天**
   - 06:00 town/inn_door｜起床
   - 09:00 town/fountain_s｜小姨给他做了蛋糕
   - 12:30 inn/table_a｜吃蛋糕
   - 18:00 town/bench_e｜和朋友们玩
   - 22:00 town/inn_door｜回家休息
2. **节日当天**
   - 06:00 town/inn_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/fountain_n｜追着大孩子跑
   - 18:30 inn/table_b｜吃节日大餐
   - 22:00 town/inn_door｜回家休息
3. **周一、周二、周三、周四、周五 · 天气：雨、雷暴、雪**
   - 07:00 town/inn_door｜起床
   - 08:00 town/school_door｜上学
   - 15:30 inn/table_a｜在酒馆里写作业
   - 17:30 inn/counter｜帮小姨端盘子
   - 20:30 town/inn_door｜睡觉
4. **周一、周二、周三、周四、周五**
   - 07:00 town/inn_door｜起床
   - 08:00 town/school_door｜上学
   - 12:00 town/school_yard｜午饭
   - 13:00 town/school_door｜下午的课
   - 15:30 town/fountain_s｜玩
   - 17:30 inn/counter｜帮小姨
   - 20:30 town/inn_door｜睡觉
5. **周六**
   - 07:30 town/inn_door｜起床
   - 09:00 inn/counter｜帮小姨
   - 12:00 market/stall_c｜逛集市
   - 15:00 town/north_road｜去林子边玩
   - 17:30 inn/counter｜帮小姨
   - 20:30 town/inn_door｜睡觉
6. **其余日子**
   - 08:00 town/inn_door｜起床
   - 09:30 town/fountain_n｜玩
   - 12:00 inn/table_b｜午饭
   - 14:00 town/bench_e｜和朋友玩
   - 17:30 inn/counter｜帮小姨
   - 20:30 town/inn_door｜睡觉

## 马格纳斯（铁匠 · 手艺没人学）

1. **生日当天**
   - 06:00 market/smith_door｜起床
   - 09:00 blacksmith/front｜生日不开工，在铺子里喝汤
   - 12:30 blacksmith/table｜德克兰端来炖肉
   - 18:00 market/bench_e｜傍晚坐着
   - 22:00 market/smith_door｜回家休息
2. **节日当天**
   - 06:00 market/smith_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 blacksmith/forge｜回去看炉火
   - 18:30 inn/table_b｜沉默地吃饭
   - 22:00 market/smith_door｜回家休息
3. **周日**
   - 08:00 market/smith_door｜起床
   - 10:00 market/bench_e｜晒太阳
   - 13:00 blacksmith/table｜午饭
   - 15:00 market/plaza_w｜散步
   - 19:00 blacksmith/table｜晚饭
   - 22:00 market/smith_door｜休息
4. **天气：雨、雷暴、雪**
   - 06:30 market/smith_door｜起床
   - 08:30 blacksmith/behind｜开铺
   - 12:00 blacksmith/table｜午饭
   - 13:00 blacksmith/forge｜雨天炉子最旺
   - 17:30 blacksmith/forge｜收工
   - 19:00 blacksmith/table｜晚饭
   - 22:00 market/smith_door｜休息
5. **周六**
   - 06:30 market/smith_door｜起床
   - 08:30 blacksmith/behind｜开铺
   - 12:00 blacksmith/table｜午饭
   - 13:00 blacksmith/behind｜集市日来买农具的人多
   - 17:30 blacksmith/forge｜收工
   - 19:00 blacksmith/table｜晚饭
   - 22:00 market/smith_door｜休息
6. **冬**
   - 06:30 market/smith_door｜起床
   - 08:30 blacksmith/behind｜开铺
   - 12:00 blacksmith/table｜午饭
   - 13:00 blacksmith/forge｜烧旺炉子
   - 17:30 blacksmith/forge｜收工
   - 19:00 blacksmith/table｜晚饭
   - 21:30 market/smith_door｜休息
7. **其余日子**
   - 06:30 market/smith_door｜起床
   - 08:30 blacksmith/behind｜开铺
   - 12:00 blacksmith/table｜午饭
   - 13:00 blacksmith/forge｜打铁
   - 17:30 blacksmith/forge｜收工
   - 19:00 blacksmith/table｜晚饭
   - 22:00 market/smith_door｜休息

## 安布罗斯（诊所医生 · 想退休）

1. **生日当天**
   - 06:00 market/clinic_door｜起床
   - 09:00 clinic/front｜朱妮给他泡了苦茶
   - 12:30 tea_house/table_a｜和朋友喝茶
   - 18:00 market/bench_w｜傍晚坐着
   - 22:00 market/clinic_door｜回家休息
2. **节日当天**
   - 06:00 market/clinic_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 clinic/behind｜守着诊所
   - 18:30 inn/table_b｜和大家吃饭
   - 22:00 market/clinic_door｜回家休息
3. **周日**
   - 08:00 market/clinic_door｜起床
   - 10:00 clinic/behind｜值班看诊
   - 13:00 clinic/front｜午饭
   - 15:00 market/bench_w｜读报
   - 19:00 clinic/front｜晚饭
   - 22:00 market/clinic_door｜休息
4. **天气：雨、雷暴、雪**
   - 06:30 market/clinic_door｜起床
   - 08:30 clinic/behind｜开诊
   - 12:30 clinic/front｜午饭
   - 13:30 clinic/behind｜雨天病人多
   - 17:30 clinic/front｜收诊
   - 19:00 clinic/front｜晚饭
   - 21:30 market/clinic_door｜休息
5. **冬**
   - 06:30 market/clinic_door｜起床
   - 08:30 clinic/behind｜开诊，流感季
   - 12:30 clinic/front｜午饭
   - 13:30 clinic/behind｜开诊
   - 17:30 clinic/front｜收诊
   - 19:00 clinic/front｜晚饭
   - 21:30 market/clinic_door｜休息
6. **其余日子**
   - 06:30 market/clinic_door｜起床
   - 08:30 clinic/behind｜开诊
   - 12:30 clinic/front｜午饭
   - 13:30 clinic/behind｜开诊
   - 17:30 market/bench_w｜傍晚散步
   - 19:00 clinic/front｜晚饭
   - 21:30 market/clinic_door｜休息

## 罗西（牧场主 · 替人长大的人）

1. **生日当天**
   - 06:00 ranch/home｜起床
   - 09:00 ranch/barn｜牧场今天不挤奶
   - 12:30 ranch/road_w｜和邻居聊天
   - 18:00 tea_house/table_a｜诺拉请她喝茶
   - 22:00 ranch/home｜回家休息
2. **节日当天**
   - 06:00 ranch/home｜起床
   - 09:00 festival｜参加节日
   - 14:30 ranch/barn｜回去照看牛羊
   - 18:30 inn/table_b｜和大家吃节日晚餐
   - 22:00 ranch/home｜回家休息
3. **周日**
   - 06:00 ranch/home｜起床
   - 06:30 ranch/barn｜早晨照看牲口
   - 10:00 ranch/road_w｜休息
   - 14:00 tea_house/table_a｜去茶室看诺拉
   - 17:00 ranch/barn｜傍晚照看牲口
   - 20:30 ranch/home｜休息
4. **天气：雨、雷暴、雪**
   - 06:00 ranch/home｜起床
   - 06:30 ranch/barn｜挤奶
   - 10:00 ranch/barn｜在谷仓里给牲口添草
   - 12:30 ranch/barn｜午饭
   - 17:00 ranch/barn｜给牲口添草
   - 20:00 ranch/home｜休息
5. **周六**
   - 06:00 ranch/home｜起床
   - 06:30 ranch/barn｜挤奶
   - 09:30 market/plaza_e｜去集市卖蛋奶
   - 14:00 ranch/barn｜回牧场
   - 17:00 ranch/paddock_a｜放牧
   - 20:00 ranch/home｜休息
6. **冬**
   - 06:30 ranch/home｜起床
   - 07:00 ranch/barn｜挤奶
   - 10:00 ranch/barn｜给牲口添草
   - 13:00 ranch/barn｜午饭
   - 17:00 ranch/barn｜给牲口添草
   - 20:00 ranch/home｜休息
7. **其余日子**
   - 06:00 ranch/home｜起床
   - 06:30 ranch/barn｜挤奶
   - 09:00 ranch/paddock_a｜放牧
   - 12:30 ranch/barn｜午饭
   - 14:00 ranch/paddock_b｜照看牲口
   - 17:00 ranch/barn｜收工挤奶
   - 20:00 ranch/home｜休息

## 阿玛拉（邮差 · 走街串巷的人）

1. **生日当天**
   - 06:00 market/home_72｜起床
   - 09:00 market/plaza_n｜给自己寄一封信
   - 12:30 tea_house/table_a｜和朋友喝茶
   - 18:00 inn/table_a｜晚餐
   - 22:00 market/home_72｜回家休息
2. **节日当天**
   - 06:00 market/home_72｜起床
   - 09:00 festival｜参加节日
   - 14:30 market/plaza_w｜送节日请柬
   - 18:30 inn/table_b｜和大家吃饭
   - 22:00 market/home_72｜回家休息
3. **周日**
   - 08:00 market/home_72｜起床
   - 10:00 market/bench_e｜给利奥写信
   - 13:00 tea_house/table_a｜午饭
   - 15:00 town/bridge｜看河水
   - 19:00 market/home_72｜回家
   - 22:00 market/home_72｜休息
4. **天气：雨、雷暴、雪**
   - 06:30 market/home_72｜起床
   - 08:00 market/plaza_n｜穿着黄雨衣送信
   - 11:00 town/fountain_n｜送镇上的信
   - 13:00 inn/table_a｜午饭
   - 14:30 town/south_w｜送信
   - 17:30 market/back_w｜送信
   - 19:00 market/home_72｜回家
   - 22:00 market/home_72｜休息
5. **周六**
   - 06:00 market/home_72｜起床
   - 07:00 market/plaza_n｜集市日分拣包裹
   - 10:00 market/stall_b｜送摊位的信
   - 13:00 tea_house/table_a｜午饭
   - 15:00 market/plaza_e｜送信
   - 19:00 market/home_72｜回家
   - 22:00 market/home_72｜休息
6. **其余日子**
   - 06:30 market/home_72｜起床
   - 07:30 market/plaza_n｜分拣信件
   - 09:00 market/back_w｜送后街的信
   - 10:30 town/fountain_n｜送镇上的信
   - 12:30 inn/table_a｜午饭
   - 14:00 town/south_w｜送信
   - 15:30 ranch/road_w｜送牧场的信
   - 17:30 seaside/promenade_w｜送海边的信
   - 19:30 market/home_72｜回家
   - 22:00 market/home_72｜休息

## 巴纳比（剧团团长 · 最后一场《灯归》）

1. **生日当天**
   - 06:00 market/home_60｜起床
   - 09:00 town/hall_steps｜在台阶上朗诵一段
   - 12:30 inn/table_a｜科莱特给他订了蛋糕
   - 18:00 tea_house/table_a｜喝茶
   - 22:00 market/home_60｜回家休息
2. **节日当天**
   - 06:00 market/home_60｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/hall_steps｜给剧院之夜试灯
   - 18:30 inn/table_a｜和全镇一起吃饭
   - 22:00 market/home_60｜回家休息
3. **周日**
   - 08:00 market/home_60｜起床
   - 10:00 market/bench_w｜带母亲晒太阳
   - 13:00 inn/table_b｜午饭
   - 15:00 town/hall_steps｜看剧院
   - 19:00 market/home_60｜回家
   - 22:00 market/home_60｜休息
4. **冬**
   - 07:00 market/home_60｜起床
   - 09:00 town/hall_steps｜排练《灯归》
   - 12:30 inn/table_a｜午饭
   - 14:00 town/hall_steps｜排练
   - 18:30 inn/table_a｜晚餐
   - 22:30 market/home_60｜休息
5. **天气：雨、雷暴、雪**
   - 07:00 market/home_60｜起床
   - 09:00 town/hall_steps｜在剧院里整理布景
   - 12:30 inn/table_a｜午饭
   - 14:00 town/hall_steps｜整理布景
   - 18:30 market/home_60｜回家陪母亲
   - 21:30 market/home_60｜休息
6. **其余日子**
   - 07:00 market/home_60｜起床
   - 09:00 town/hall_steps｜写剧本
   - 12:30 inn/table_a｜午饭
   - 14:00 town/hall_steps｜排练
   - 17:00 market/bench_w｜带母亲散步
   - 19:00 market/home_60｜回家
   - 22:00 market/home_60｜休息

## 奥黛特奶奶（老人 · 记得每年灯夜）

1. **生日当天**
   - 06:00 market/home_60｜起床
   - 09:00 town/bench_w｜在长椅上等人来说生日快乐
   - 12:30 inn/table_b｜吃蛋糕
   - 18:00 town/bench_e｜傍晚坐着
   - 22:00 market/home_60｜回家休息
2. **节日当天**
   - 06:00 market/home_60｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/bench_w｜晒太阳
   - 18:30 town/fountain_s｜坐在广场边上看热闹
   - 22:00 market/home_60｜回家休息
3. **周日 · 秋 · 故事进度 ≥ 3**
   - 08:00 market/home_60｜起床
   - 10:00 town/bench_w｜晒太阳
   - 14:00 lake/bench_w｜去湖边坐着
   - 17:00 lake/lantern｜看灯台
   - 19:30 market/home_60｜回家
4. **天气：雨、雷暴、雪**
   - 08:00 market/home_60｜起床
   - 10:00 market/home_60｜坐在门廊里听雨
   - 13:00 market/home_60｜午饭
   - 15:00 market/home_60｜坐着打盹
   - 18:00 market/home_60｜晚饭
   - 20:00 market/home_60｜休息
5. **其余日子**
   - 07:30 market/home_60｜起床
   - 09:30 town/bench_w｜晒太阳
   - 12:00 inn/table_b｜午饭
   - 14:00 town/bench_e｜和路人聊天
   - 17:00 market/bench_w｜看夕阳
   - 19:00 market/home_60｜回家
   - 20:30 market/home_60｜休息

## 维罗妮卡（县规划办干部 · 水库项目负责人）

1. **故事进度 ≤ 5**
   - 06:00 away｜在县里工作
2. **生日当天**
   - 06:00 market/tea_door｜起床
   - 09:00 tea_house/table_a｜收到丈夫寄来的信
   - 12:30 inn/table_a｜镇上的人请她吃饭
   - 18:00 tea_house/table_a｜喝茶
   - 22:00 market/tea_door｜回家休息
3. **节日当天**
   - 06:00 market/tea_door｜起床
   - 09:00 festival｜参加节日
   - 14:30 town/fountain_n｜观察节日
   - 18:30 inn/table_b｜和大家吃饭
   - 22:00 market/tea_door｜回家休息
4. **天气：雨、雷暴、雪**
   - 07:00 market/tea_door｜起床
   - 09:00 tea_house/table_b｜雨天无法勘测，在茶室改方案
   - 13:00 tea_house/table_a｜午饭
   - 15:00 tea_house/table_b｜继续改方案
   - 19:00 tea_house/table_a｜晚饭
   - 22:00 market/tea_door｜休息
5. **周日**
   - 08:00 market/tea_door｜起床
   - 10:00 town/bench_w｜看报
   - 13:00 tea_house/table_a｜午饭
   - 15:00 town/bridge｜看河水
   - 19:00 tea_house/table_a｜晚饭
   - 22:00 market/tea_door｜休息
6. **其余日子**
   - 07:00 market/tea_door｜起床
   - 08:30 town/hall_steps｜与镇长开会
   - 11:00 town/bridge｜勘测河岸
   - 13:00 tea_house/table_a｜午饭
   - 14:30 forest/stream｜勘测水位
   - 17:30 town/hall_steps｜整理报告
   - 19:00 tea_house/table_a｜晚饭
   - 22:00 market/tea_door｜休息
