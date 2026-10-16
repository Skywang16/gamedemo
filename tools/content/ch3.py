"""Chapter three, autumn: the falling water, the reservoir plan, the ferry and the canal."""

from content.scene_kit import L, meta, quest, reward

QUESTS = [
    quest(
        "water_falls",
        "水位下降",
        "萤火湖畔 · 雷恩",
        "秋天，湖水比往年退得更多。雷恩在湖边量水位，想让你看看。",
        npc="wren",
        chapter=3,
        available="autumn 1",
    ),
    quest(
        "visitors",
        "陌生的来客",
        "芦苇渡镇 · 维罗妮卡",
        "县里来了两位客人：规划办的维罗妮卡和水利局的罗兹。去听听她们的方案。",
        npc="veronica",
        chapter=3,
        flag="reservoir",
        choice=[
            ("cooperate", "我愿意配合勘测，先听听她们的方案。"),
            ("oppose", "这里是我们的家，我不赞成搬迁。"),
            ("third", "也许有第三条路——先让我们试着自己治水。"),
        ],
    ),
    quest(
        "three_voices",
        "三种声音",
        "镇公所 · 奥古斯都",
        "镇长想让你听听大家的想法。先和梅芙成为朋友（好感 30）。",
        npc="augustus",
        chapter=3,
        friendship={"maeve": 30},
    ),
    quest(
        "stranded_boat",
        "搁浅的船",
        "海鸥湾 · 梅芙",
        "梅芙的老船搁浅在泥滩上。需要 25 块木材和 6 根麻绳（杂货店有卖）。",
        npc="maeve",
        chapter=3,
        needs={"wood": 25, "rope": 6},
    ),
    quest(
        "ferry_mends",
        "修船",
        "萤火湖畔 · 托比",
        "渡口的老摆渡人托比要两块铜锭和十块木材，把船修到能再下水。",
        npc="toby",
        chapter=3,
        needs={"copper_bar": 2, "wood": 10},
        lamp=4,
        reward=reward(200),
    ),
    quest(
        "canal_talk",
        "水渠之议",
        "芦苇渡镇 · 罗兹",
        "罗兹提出“自己修一条水渠”。她要三十块石料，并想听听水渠该怎么走。",
        npc="roz",
        chapter=3,
        needs={"stone": 30},
        flag="canal_route",
        choice=[
            ("river", "沿着河走，尽量少动老街。"),
            ("town", "穿过镇子，让水到每家门口。"),
        ],
    ),
    quest(
        "dig",
        "开渠",
        "芦苇渡镇 · 赛拉斯",
        "全镇出人开渠。赛拉斯要四十块石料、二十份纤维。",
        npc="silas",
        chapter=3,
        needs={"stone": 40, "fiber": 20},
    ),
    quest(
        "water_runs",
        "通水",
        "芦苇渡镇 · 罗兹",
        "水渠挖通了。去和罗兹一起看第一股水流进来。",
        npc="roz",
        chapter=3,
        lamp=5,
        reward=reward(250),
    ),
    quest(
        "return",
        "灯夜归人",
        "萤火湖畔 · 灯台",
        "灯夜到了，湖边有一个熟悉的身影。去灯台。",
        chapter=3,
        station="lantern",
    ),
    quest(
        "sylvia_question",
        "西尔维娅的问题",
        "萤火湖畔 · 灯台",
        "祖母想问你一个问题。",
        chapter=3,
        station="lantern",
        flag="life_path",
        choice=[
            ("stay", "留在这里，把这片地种成家。"),
            ("wander", "偶尔出去走走，但一定回来。"),
            ("both", "两样我都要，慢慢来。"),
        ],
    ),
]

SCENES = {
    "water_falls": [
        L(
            "narrator",
            "秋天的清晨，湖面像一块被人悄悄拿走一角的镜子。",
            bg="lake",
            mood="dawn",
            fx=["leaves"],
            cam="pan_left",
        ),
        L(
            "wren",
            "你看这根水尺。去年这个时候，水线在这里，现在在这里。三十年来最低。",
            actors=["wren@center_left", "player@center_right"],
            cam="zoom_in",
        ),
        L(
            "wren",
            "鸟群比往年早走了十天。它们比我们更早知道要发生什么。",
            act={"wren": "shake"},
        ),
        L(
            "wren",
            "我想把这些数字交给能用得上的人。可是我怕……说出来，大家会更慌。",
            cam="still",
        ),
        L(
            "wren",
            "不过，如果是你的话，也许可以和我一起去镇上，把本子打开。",
            act={"wren": "nod"},
        ),
    ],
    "visitors": [
        L(
            "narrator",
            "镇口多了两张陌生的面孔，和一块刚刷好的告示板。",
            bg="town",
            mood="day",
            actors=["veronica@center_left", "roz@center", "augustus@center_right"],
            cam="pan_right",
        ),
        L(
            "veronica",
            "我是县规划办的维罗妮卡。这位是水利局的罗兹——你们应该认识。",
            act={"veronica": "nod"},
        ),
        L(
            "veronica",
            "下游要修一座水库。蓄水以后，这片低地会被淹没，镇上的人会得到补偿，搬到更高、更安全的地方。",
        ),
        L(
            "roz",
            "数据我提供的。河道三十年淤积了四成，旱涝一年比一年极端。……我也是这里长大的，所以我才来。",
            act={"roz": "shake"},
        ),
        L(
            "augustus",
            "补偿，安全，更高的地方。……每一个词都对。可我们要搬走的，是名字都在这片地上的东西。",
        ),
        L(
            "veronica",
            "我不是来说服你们的，{name}。我是来问你们：如果有更好的办法，大家愿意试吗？",
            cam="zoom_in",
        ),
        L("narrator", "所有人都看向你。"),
    ],
    "three_voices": [
        L(
            "augustus",
            "我想让你听听三种声音，再回答我。",
            bg="town",
            mood="dusk",
            actors=["augustus@center_left", "player@center_right"],
        ),
        L(
            "augustus",
            "我的是规矩：小镇不能因为一份报告就散。可规矩也不能假装水没有退。",
        ),
        L(
            "maeve",
            "我的是船！我爹一辈子摆渡，我这辈子跑船，现在船搁在泥滩上，像一条晒干的鱼！",
            actors=["maeve@center", "player@right"],
            act={"maeve": "hop"},
        ),
        L(
            "hazel",
            "我的是地。奶奶种下的每一垄菜，我都认得。……可我也怕下一个旱年。",
            actors=["hazel@center", "player@right"],
        ),
        L(
            "augustus",
            "三种声音，都不是错的。我们要找的，是一个都不必丢掉的办法。",
            actors=["augustus@center_left", "player@center_right"],
        ),
    ],
    "stranded_boat": [
        L(
            "maeve",
            "你看！我爹留下的老船，趴在泥里一个月了。我每天去看它，每天骂它。",
            bg="river",
            mood="dusk",
            actors=["maeve@center_left", "player@center_right"],
            fx=["water"],
        ),
        L(
            "maeve",
            "我没告诉约纳斯，也没告诉托比。我怕他们说：“早就说过。”",
            act={"maeve": "shake"},
        ),
        L(
            "maeve",
            "木板二十五块，麻绳六根，我自己去买就丢脸了。你帮我，好不好？……别笑，我声音大是因为害羞。",
            cam="zoom_in",
        ),
    ],
    "ferry_mends": [
        L(
            "toby",
            "来，搭把手。……对，就是这里。老骨头，一用就响。",
            bg="river",
            mood="dusk",
            actors=["toby@center_left", "maeve@center", "jonas@center_right", "player@right"],
            fx=["water"],
            sfx="water",
        ),
        L(
            "narrator",
            "铜钉一颗颗钉进船板，缆绳绷紧，浸了水的老船缓缓浮起。",
            sfx="hit",
            shake=0.3,
            cam="zoom_in",
        ),
        L("jonas", "妈。你怎么不早说。", act={"jonas": "step"}),
        L("maeve", "……现在说了。别站着，推！", act={"maeve": "hop"}),
        L(
            "toby",
            "对岸有一盏灯，等了很多年了。{name}，等你有空，我带你去看。",
            fx=["lanterns"],
            mood="night",
            cam="still",
        ),
        L(
            "narrator",
            "河灯台上，第四盏灯亮了。湖边多了一个可以上船的渡口。",
            bg="lake",
            mood="dusk",
            flash="gold",
            sfx="lantern",
            fx=["fireflies"],
            actors=["player@center"],
        ),
    ],
    "canal_talk": [
        L(
            "roz",
            "我把图纸画了三遍。河道清不动，水库挡不住，那就自己修一条渠，把水引到田边。",
            bg="hall",
            mood="day",
            actors=["roz@center_left", "player@center_right"],
        ),
        L(
            "roz",
            "石料我算过，三十块起步。……赛拉斯会说我异想天开。他一直这样。",
            act={"roz": "shake"},
        ),
        L(
            "silas",
            "我没说。",
            actors=["roz@center_left", "silas@center_right"],
            act={"silas": "step"},
        ),
        L("roz", "你刚才说了。在心里。"),
        L(
            "narrator",
            "姐弟对视了一会儿，谁也没有笑，可屋里比刚才暖。",
            cam="zoom_in",
        ),
        L("roz", "水渠该怎么走？{name}，你来定。", cam="still"),
    ],
    "dig": [
        L(
            "narrator",
            "秋天的田野上，第一铲土翻了起来。",
            bg="canal",
            mood="day",
            fx=["dust"],
            actors=[
                "silas@left",
                "roz@center_left",
                "hazel@center",
                "gregor@center_right",
                "ezra@right",
            ],
            sfx="hit",
            cam="pan_right",
        ),
        L("silas", "石料在这边。纤维先垫在底下，防渗。", act={"silas": "nod"}),
        L("gregor", "账本我先放一边了。这回出力不记账。", act={"gregor": "hop"}),
        L("ezra", "我来抬石头！马格纳斯师傅说，打铁的手劲用在这儿正好。", act={"ezra": "hop"}),
        L("hazel", "我给大家送水！别笑，我的汤和种子一样靠谱。"),
        L(
            "narrator",
            "一天又一天，水渠一寸寸向前。镇上的人第一次发现，原来这么多人都会用铲子。",
            mood="dusk",
            cam="zoom_out",
        ),
    ],
    "water_runs": [
        L(
            "roz",
            "闸门要开了。……我手有点抖。",
            bg="canal",
            mood="dawn",
            actors=["roz@center_left", "silas@center", "player@center_right"],
            fx=["water"],
        ),
        L("silas", "我来拉。你站着看。", act={"silas": "nod"}),
        L(
            "narrator",
            "闸板抬起，一线清亮的水从河里涌出来，沿着石槽往田里去。",
            sfx="water",
            shake=0.5,
            flash="white",
            cam="zoom_in",
        ),
        L("roz", "它真的走了。……我第一次觉得，这里有一部分是我留下的。"),
        L("silas", "你一直都留着。只是离得远。", act={"silas": "nod"}),
        L(
            "narrator",
            "河灯台上，第五盏灯亮了。从今天起，每个清晨田里都有水。",
            bg="lake",
            mood="dusk",
            flash="gold",
            sfx="lantern",
            fx=["fireflies"],
            actors=["player@center"],
            cam="still",
        ),
    ],
    "return": [
        L(
            "narrator",
            "灯夜。湖面上浮着五盏灯的倒影，还有无数手里的小灯。",
            bg="lake",
            mood="night",
            fx=["lanterns", "fireflies"],
            actors=[
                "hazel@left",
                "silas@center_left",
                "margot@center",
                "wren@center_right",
                "augustus@right",
            ],
            sfx="lantern",
            cam="zoom_out",
        ),
        L("wren", "你们看，对岸有人。", act={"wren": "nod"}),
        L(
            "narrator",
            "渡口的灯火里，一个提着旧皮箱的身影慢慢走近。",
            actors=["sylvia@center_right", "player@center_left"],
            cam="zoom_in",
        ),
        L(
            "sylvia",
            "我的孩子。让你一个人守了这么久。",
            act={"sylvia": "step"},
        ),
        L(
            "narrator",
            "你什么也没说，只是走上去，把她抱住了。",
            flash="gold",
        ),
        L(
            "hazel",
            "奶奶！",
            actors=["hazel@left", "sylvia@center", "player@right"],
            act={"hazel": "hop"},
        ),
        L(
            "sylvia",
            "我在南方听说桥修好了，灯也亮了。我坐了三天火车，路上一直在想，我该说什么。……现在不想了，你们都在。",
        ),
    ],
    "sylvia_question": [
        L(
            "sylvia",
            "来，陪我坐一会儿。灯太多，人太多，我只想和你说几句。",
            bg="lake",
            mood="night",
            fx=["lanterns", "fireflies"],
            actors=["sylvia@center_left", "player@center_right"],
            cam="zoom_in",
        ),
        L(
            "sylvia",
            "我年轻时在这个湖边写过一盏灯，寄给一个叫“摆渡灯人”的人。我以为那是最重要的一件事。后来我才知道，最重要的是之后的日子怎么过。",
        ),
        L(
            "sylvia",
            "我走的这一年，其实是想知道，没有我，这个镇子还会不会有灯。……现在我知道了。",
            act={"sylvia": "nod"},
        ),
        L(
            "sylvia",
            "所以轮到我问你，{name}。我不要你的承诺，也不要你的感谢。我只想知道：",
        ),
        L("sylvia", "你想怎么过你的日子？"),
    ],
}

meta("water_falls", "lake", "dawn", card=["第三章", "水从哪里来"])
meta("visitors", "town")
meta("three_voices", "town", "dusk")
meta("stranded_boat", "river", "dusk")
meta("ferry_mends", "river", "dusk")
meta("canal_talk", "hall")
meta("dig", "canal")
meta("water_runs", "canal", "dawn")
meta("return", "lake", "night")
meta("sylvia_question", "lake", "night")
