"""The calendar: seasons, weekdays, weather odds and festivals.

Authoritative source for data/calendar.json. Every festival gathers the villagers on the town
plaza; the builder fills in the gathering cells from the generated town map.
"""

SEASONS = [
    {"id": "spring", "name": "春"},
    {"id": "summer", "name": "夏"},
    {"id": "autumn", "name": "秋"},
    {"id": "winter", "name": "冬"},
]
WEEKDAYS = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
WEATHER_NAMES = {
    "sunny": {"name": "晴", "long": "晴天"},
    "cloudy": {"name": "阴", "long": "阴天"},
    "rain": {"name": "雨", "long": "下雨"},
    "storm": {"name": "雷", "long": "雷雨"},
    "wind": {"name": "风", "long": "大风"},
    "snow": {"name": "雪", "long": "下雪"},
}
WEATHER = {
    "spring": [["sunny", 50], ["cloudy", 15], ["rain", 22], ["wind", 8], ["storm", 5]],
    "summer": [["sunny", 55], ["cloudy", 12], ["rain", 18], ["wind", 5], ["storm", 10]],
    "autumn": [["sunny", 45], ["cloudy", 20], ["rain", 18], ["wind", 12], ["storm", 5]],
    "winter": [["sunny", 30], ["cloudy", 25], ["snow", 40], ["wind", 5]],
}
# id, name, season, day, kind, weather, what happens
FESTIVALS = [
    ("plow_rite", "春耕日", "spring", 8, "festival", "sunny", "全镇聚在农场边比赛翻地。"),
    ("kite_day", "风筝日", "spring", 15, "minor", "wind", "草坡上放风筝。"),
    ("spring_lantern", "春之灯夜", "spring", 20, "festival", "sunny", "湖畔点起第一批纸灯。"),
    ("regatta", "划船赛", "summer", 12, "festival", "sunny", "河上划船比赛。"),
    ("lakeside_picnic", "湖畔野餐", "summer", 18, "minor", "cloudy", "傍晚的野餐聚会。"),
    ("midsummer_stars", "仲夏观星夜", "summer", 26, "festival", "sunny", "夜里躺在河边看星星。"),
    ("harvest_fair", "丰收集市", "autumn", 9, "festival", "sunny", "评比作物、手工与料理。"),
    ("cider_day", "苹果酒日", "autumn", 18, "minor", "sunny", "压苹果酒，家家门前摆苹果。"),
    (
        "lantern_night",
        "灯夜",
        "autumn",
        24,
        "festival",
        "cloudy",
        "全年最大的节日，把话写在纸灯上放进河里。",
    ),
    ("winter_market", "冬季集市", "winter", 9, "festival", "snow", "雪中的集市，交换礼物。"),
    ("soup_day", "浓汤日", "winter", 14, "minor", "cloudy", "广场上煮一大锅浓汤，每家带一样食材。"),
    ("playhouse_night", "剧院之夜", "winter", 18, "festival", "snow", "鹅毛笔剧团的年度演出。"),
    ("year_end_feast", "年终宴", "winter", 28, "festival", "snow", "全镇共享的长桌晚宴。"),
]
