"""Prologue and chapter one: the letter, the bridge, the first lantern night."""

from content.scene_kit import L, meta, quest, reward

QUESTS = [
    quest(
        "welcome",
        "新邻居",
        "农场 · 找黑兹尔",
        "种子商黑兹尔正在农舍东边等你。",
        npc="hazel",
    ),
    quest(
        "first_meal",
        "一顿饭的距离",
        "芦苇渡镇 · 玛戈",
        "玛戈想用新鲜萝卜煮一锅浓汤。带两份萝卜去她的小酒馆。",
        npc="margot",
        needs={"turnip": 2},
        reward=reward(20),
    ),
    quest(
        "bridge",
        "桥的另一边",
        "松木林 → 镇东旧桥",
        "赛拉斯需要四份木材、三份石料修补镇东的旧木桥。",
        station="bridge",
        needs={"wood": 4, "stone": 3},
        lamp=1,
    ),
    quest(
        "notebook",
        "湖边的记录员",
        "萤火湖畔 · 雷恩",
        "穿过木桥，找湖边的鸟类记录员雷恩。",
        npc="wren",
    ),
    quest(
        "feast",
        "请大家再聚一次",
        "芦苇渡镇 · 玛戈",
        "为灯夜带去三份野莓、两份萝卜。",
        npc="margot",
        needs={"berry": 3, "turnip": 2},
    ),
    quest(
        "festival",
        "灯夜重燃",
        "萤火湖畔 · 灯台",
        "去湖边的灯台，和大家一起放灯。",
        station="lantern",
        reward=reward(50),
        flag="wish",
        choice=[
            ("stay", "愿我找到想留下的地方"),
            ("explore", "愿我有勇气出发，也有路回来"),
            ("together", "愿我们以后常常见面"),
        ],
    ),
]

PROLOGUE_CHOICES = [("grow", "我想好好照料这片土地"), ("restart", "我想在这里重新开始")]

SCENES = {
    "prologue": [
        L(
            "letter",
            "给 {name}：\n\n你读到这封信时，我已经坐上南下的火车了。别担心，我只是去找一位很久没见的老朋友。",
            bg="train",
            mood="dawn",
            fx=["steam"],
            cam="pan_right",
            sfx="chime",
        ),
        L(
            "letter",
            "农场交给你，叫它“{farm}”也好，给它起个新名字也好。\n\n别急着把每一块地都种满。给自己留一条散步的小路。",
            bg="farm",
            mood="dawn",
            fx=["leaves"],
            cam="zoom_in",
        ),
        L(
            "letter",
            "镇东的桥去年被洪水冲垮了，灯夜也停办了。\n如果你愿意，就替我去看看那些老朋友。\n\n愿你找到让自己想留下的东西。\n—— 祖母 西尔维娅",
            bg="lake",
            mood="dusk",
            fx=["fireflies"],
            cam="zoom_out",
        ),
    ],
    "welcome": [
        L(
            "hazel",
            "你就是 {name} 吧？我是黑兹尔，西尔维娅奶奶常跟我提起你。",
            bg="farm",
            mood="day",
            actors=["hazel@center_left", "player@center_right"],
            act={"hazel": "hop"},
        ),
        L("hazel", "她留下的种子在你口袋里。那片荒地，你想种成什么样都好。", cam="zoom_in"),
        L(
            "hazel",
            "镇上的玛戈听说你要来，连汤锅都换大了。有了收成，记得带点去让她尝尝。",
            act={"hazel": "nod"},
        ),
    ],
    "first_meal": [
        L(
            "margot",
            "萝卜真新鲜，叶子上还带着露水呢。今天的浓汤有着落了。",
            bg="inn",
            mood="day",
            actors=["margot@center_left", "player@center_right"],
            fx=["steam"],
        ),
        L(
            "margot",
            "以前灯夜，我要煮一大锅汤。桥坏了以后，大家都说“等修好再办”，然后就一直等。",
        ),
        L(
            "silas",
            "……桥的图纸我有。松木林里能拾到木材和石料。四份木材、三份石料，够先把桥面接起来。",
            actors=["margot@left", "silas@center", "player@right"],
            act={"silas": "nod"},
        ),
        L("margot", "你愿意帮忙的话，到镇东旧桥找他。饭钱先给你，下次来，不用带礼物也可以坐坐。"),
    ],
    "bridge": [
        L(
            "silas",
            "材料齐了。你先站远一点，我来。",
            bg="lake",
            mood="day",
            actors=["silas@center_left", "player@far_right"],
            cam="pan_right",
        ),
        L(
            "narrator",
            "锤声落进午后的风里。旧木板被一块块卸下，结实的新桥面从脚下延伸到对岸。",
            sfx="hit",
            shake=0.4,
            fx=["dust"],
            cam="zoom_in",
        ),
        L(
            "silas",
            "我总以为，没人再想去那边了。谢谢你让我知道，不是这样。",
            fx=[],
            act={"silas": "nod"},
        ),
        L(
            "narrator",
            "河灯台上，第一盏灯轻轻亮了起来。",
            bg="lake",
            mood="dusk",
            flash="gold",
            sfx="lantern",
            fx=["fireflies"],
            cam="still",
        ),
        L(
            "silas",
            "湖边有个记录水鸟的姑娘，叫雷恩。她有一本西尔维娅奶奶留下的笔记，也许你会想看看。",
        ),
    ],
    "notebook": [
        L(
            "wren",
            "桥……真的修好了？对不起，我有点惊讶。我是雷恩，在这里做湿地鸟类记录。",
            bg="lake",
            mood="day",
            actors=["wren@center_left", "player@center_right"],
            fx=["leaves"],
        ),
        L("wren", "西尔维娅奶奶留下这本笔记时，说以后会有人来取。这里有一页不是水位，也不是鸟。"),
        L(
            "letter",
            "“纸灯不是寄给离开的人。它是提醒还在岸边的人：\n\n我在这里。明年，也想和你一起。”",
            mood="dusk",
            fx=["fireflies"],
            cam="zoom_in",
        ),
        L(
            "wren",
            "如果灯夜再办一次，我想试着离开记录本，站到大家中间。玛戈应该知道要准备什么。",
            cam="still",
        ),
    ],
    "feast": [
        L(
            "margot",
            "野莓做甜酱，萝卜煮热汤，刚刚好。别担心人数，我会去挨家敲门。",
            bg="inn",
            mood="day",
            actors=["margot@center_left", "player@center_right"],
            fx=["steam"],
        ),
        L(
            "hazel",
            "种子摊今天提前收！这次我要带一盏自己做的灯。",
            bg="market",
            actors=["hazel@center", "player@right"],
            act={"hazel": "hop"},
            fx=[],
        ),
        L(
            "silas",
            "桥已经检查过了。去湖边吧，灯台也修好了。",
            bg="town",
            mood="dusk",
            actors=["silas@center", "player@right"],
        ),
        L(
            "margot",
            "到灯台等我们。现在什么时候去都可以，热闹不用挑“正确的日子”。",
            actors=["margot@center_left", "hazel@center", "silas@center_right", "player@right"],
        ),
    ],
    "festival": [
        L(
            "narrator",
            "灯火一盏盏落在湖面。风很轻，船形的小灯缓缓绕过芦苇。",
            bg="lake",
            mood="night",
            fx=["lanterns", "fireflies"],
            actors=["hazel@left", "silas@center_left", "margot@center", "wren@center_right"],
            sfx="lantern",
            cam="zoom_out",
        ),
        L("hazel", "我本来只想替奶奶把田看好。没想到，今年还能一起出来玩。", act={"hazel": "hop"}),
        L("silas", "桥修好了。以后想来，随时都能来。", act={"silas": "nod"}),
        L("margot", "汤要凉啦！许愿可以慢慢想，吃饭可不能等。"),
        L("wren", "我今天不记鸟了。我想记住你们说话的声音。"),
        L(
            "letter",
            "“愿你找到让自己想留下的东西。”\n\n你终于明白，祖母留给你的不仅是一块土地。",
            actors=["player@center"],
            cam="zoom_in",
        ),
        L("narrator", "在灯上写下一句话。你希望接下来的日子是什么样的？", flash="gold"),
    ],
}

meta("prologue", "train", "dawn")
meta("welcome", "farm", card=["第一章", "灯夜重燃"])
meta("first_meal", "inn")
meta("bridge", "lake")
meta("notebook", "lake")
meta("feast", "inn")
meta("festival", "lake", "night")
