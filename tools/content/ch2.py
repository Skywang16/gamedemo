"""Chapter two, summer: the clock tower, the greenhouse, and the people who stay."""

from content.scene_kit import L, meta, quest, reward

QUESTS = [
    quest(
        "ledger",
        "钟楼上的账本",
        "镇公所台阶 · 奥古斯都",
        "夏天开始了。镇长奥古斯都有话想对你说，白天多半在镇公所前。",
        npc="augustus",
        chapter=2,
        available="summer 1",
    ),
    quest(
        "broken_watch",
        "一只停摆的怀表",
        "集市街 · 费利克斯",
        "钟表匠费利克斯的铺子总是亮到很晚。去问问他钟楼的事，别催他。",
        npc="felix",
        chapter=2,
    ),
    quest(
        "gears",
        "齿轮与铜",
        "集市街 · 费利克斯",
        "费利克斯要三根铜锭、两根铁锭做钟楼的齿轮。矿石拿到铁匠铺熔炼。",
        npc="felix",
        chapter=2,
        needs={"copper_bar": 3, "iron_bar": 2},
    ),
    quest(
        "bell",
        "钟声",
        "镇公所 · 费利克斯",
        "齿轮装好了。等正午的钟声，和大家一起听。",
        npc="felix",
        chapter=2,
        lamp=2,
        reward=reward(150),
    ),
    quest(
        "leo_guest",
        "行脚的客人",
        "集市街 · 利奥",
        "行脚商人利奥有个问题想问你：为什么留下来？",
        npc="leo",
        chapter=2,
        flag="leo_stay",
        choice=[
            ("freedom", "因为我喜欢这里的自由。"),
            ("family", "因为这里有想一起过日子的人。"),
            ("craft", "因为这里有值得慢慢做好的事。"),
            ("unsure", "说实话，我还不知道。"),
        ],
    ),
    quest(
        "glasshouse",
        "玻璃与温室",
        "松木林 · 朱妮",
        "朱妮想建一座温室，需要二十块木材和三块玻璃。玻璃要在铁匠铺用沙子和煤炼。",
        npc="juniper",
        chapter=2,
        needs={"wood": 20, "glass": 3},
    ),
    quest(
        "wren_letter",
        "雷恩的信",
        "萤火湖畔 · 雷恩",
        "雷恩收到了一封研究所的信。她想听听你的看法。",
        npc="wren",
        chapter=2,
        flag="wren_path",
        choice=[
            ("go", "想去就去，我会替你记着这里。"),
            ("stay", "这里也需要你。"),
            ("together", "你自己决定，我陪你。"),
        ],
    ),
    quest(
        "greenhouse_bloom",
        "温室开花",
        "芽田农场 · 朱妮",
        "带两个番茄、两束罗勒给朱妮，温室就能开花。",
        npc="juniper",
        chapter=2,
        needs={"tomato": 2, "basil": 2},
        lamp=3,
        reward=reward(200),
        build="greenhouse",
    ),
]

SCENES = {
    "ledger": [
        L(
            "narrator",
            "夏天的第一个早晨，镇公所的钟楼安静得过分。",
            bg="town",
            mood="day",
            fx=["leaves"],
            cam="pan_right",
        ),
        L(
            "augustus",
            "你来了。上来看看吧——这座钟已经停了十一个月。",
            bg="hall",
            actors=["augustus@center_left", "player@center_right"],
            fx=["dust"],
        ),
        L(
            "augustus",
            "河灯台有六个灯位，对应小镇的六处旧景：桥、钟、暖房、渡口、水渠、剧院。桥你们已经修好了。",
            cam="zoom_in",
        ),
        L(
            "augustus",
            "灯夜那天我才明白，点亮一盏灯，比我想的容易，也比我想的难。难的不是修东西，是有人愿意站出来说“修吧”。",
            act={"augustus": "nod"},
        ),
        L(
            "augustus",
            "钟楼是第二盏。我爬不动梯子了，也不会修这样细的东西。费利克斯说他能，可他一直不肯接这个活。",
            cam="still",
        ),
        L(
            "narrator",
            "你想起集市街那间总是亮到很晚的小铺子。",
            bg="market",
            mood="dusk",
            actors=["player@center"],
            fx=[],
        ),
        L(
            "augustus",
            "去问问他吧。别催，那孩子不爱被人催。",
            bg="hall",
            mood="day",
            actors=["augustus@center_left", "player@center_right"],
        ),
    ],
    "broken_watch": [
        L(
            "felix",
            "钟楼？……奥古斯都告诉你的吧。",
            bg="shop",
            mood="dusk",
            actors=["felix@center_left", "player@center_right"],
            fx=["dust"],
            sfx="tick",
        ),
        L(
            "felix",
            "我修过它。三年前，整整一个月，修好了，然后它又停了。",
            act={"felix": "shake"},
        ),
        L(
            "felix",
            "这只怀表是我父亲的，停在三点十二分。我拆开过无数次，每个零件都没坏。",
            cam="zoom_in",
            sfx="tick",
        ),
        L(
            "felix",
            "钟楼和这只表一样，缺的大概不是零件。……不过，镇上的人愿意再试一次的话，我也许可以再试一次。",
            cam="still",
        ),
        L(
            "felix",
            "钟楼的主轴要换齿轮：三根铜锭、两根铁锭。我自己炼不出这么多。矿石拿到布兰尼根的铁匠铺去熔。",
        ),
        L("narrator", "他把怀表放回口袋，像放回一个很久没人碰的约定。"),
    ],
    "gears": [
        L(
            "felix",
            "铜是软的，铁是硬的。一个负责转，一个负责撑。……你炼得不错。",
            bg="shop",
            mood="dusk",
            actors=["felix@center_left", "player@center_right"],
            sfx="tick",
        ),
        L(
            "narrator",
            "夜里，钟楼里点起了油灯。费利克斯把新齿轮一枚一枚嵌进老旧的钟芯。",
            bg="clock",
            mood="night",
            fx=["sparks"],
            cam="zoom_in",
            sfx="tick",
        ),
        L(
            "felix",
            "咔哒。……又一枚。你听见了吗？它咬上了。",
            actors=["felix@center_left", "player@center_right"],
        ),
        L(
            "felix",
            "明天正午，钟会走。我不想一个人站在下面听。你……能来吗？",
            cam="still",
            act={"felix": "nod"},
        ),
    ],
    "bell": [
        L(
            "narrator",
            "正午。镇公所前站满了人，连在摊位后的多莉也探出了头。",
            bg="town",
            mood="day",
            actors=[
                "augustus@left",
                "dolly@center_left",
                "clara@center",
                "milo@center_right",
                "felix@right",
            ],
            cam="zoom_in",
        ),
        L("milo", "它动了！指针动了！", act={"milo": "hop"}),
        L(
            "narrator",
            "咚——钟声从塔顶落下来，越过屋顶、河水，落到更远的田野里。",
            sfx="bell",
            flash="gold",
            shake=0.6,
            fx=["bells"],
        ),
        L("augustus", "十二下。我有十一个月没数过这个数了。", act={"augustus": "nod"}),
        L("clara", "爷爷你哭啦。", act={"clara": "hop"}),
        L("felix", "……不是零件的问题。原来真的不是。"),
        L(
            "narrator",
            "河灯台上，第二盏灯静静亮起。从今天起，钟楼每个整点都会报时。",
            bg="lake",
            mood="dusk",
            flash="gold",
            sfx="lantern",
            fx=["fireflies"],
            actors=["player@center"],
        ),
    ],
    "leo_guest": [
        L(
            "leo",
            "嘿，{name}！尝尝这个，南边带来的蜜枣。别客气，当作我收你的摊位费。",
            bg="market",
            mood="dusk",
            actors=["leo@center_left", "player@center_right"],
            fx=["leaves"],
        ),
        L(
            "leo",
            "我这辈子在路上的时间比在屋里长。每次拆行李，都当它是最后一次拆。",
            act={"leo": "shake"},
        ),
        L(
            "leo",
            "可你们这镇子奇怪——钟一响，大家就笑。我看着，竟然有点想把行李放下来。",
            cam="zoom_in",
        ),
        L("leo", "所以我想问你一个问题，你别当真，也别敷衍我。", cam="still"),
        L("leo", "你为什么留下来？"),
    ],
    "glasshouse": [
        L(
            "juniper",
            "你来得正好。我在统计种子的发芽率，冬天的数据难看得很。",
            bg="forest",
            mood="day",
            actors=["juniper@center_left", "player@center_right"],
            fx=["leaves"],
        ),
        L(
            "juniper",
            "辞掉医院的工作之前，我在窗台上养过一盆番茄，冬天也结果。我想让整个镇子都吃到冬天的番茄。",
        ),
        L(
            "juniper",
            "我需要一座温室：二十块木材，三块玻璃。玻璃在布兰尼根的铁匠铺炼——五份沙子、一份煤，炉子够热就行。",
            act={"juniper": "nod"},
        ),
        L(
            "juniper",
            "沙子在海鸥湾的海滩上能捡到。……不用急。种子比人有耐心。",
        ),
    ],
    "wren_letter": [
        L(
            "wren",
            "你看，水位本旁边夹着一封信。研究所，三周前寄来的。",
            bg="lake",
            mood="dusk",
            actors=["wren@center_left", "player@center_right"],
            fx=["fireflies"],
        ),
        L(
            "wren",
            "他们想让我去做两年的迁徙研究。三个月没回信。每天我都想，今天回。每天我都又把它放回去。",
            cam="zoom_in",
        ),
        L(
            "wren",
            "我的记录本里，每一页都是别人的故事。鸟的，水的。唯独没有我自己要不要走。",
            act={"wren": "shake"},
        ),
        L("wren", "你觉得……我该怎么办？", cam="still"),
    ],
    "greenhouse_bloom": [
        L(
            "juniper",
            "番茄、罗勒。刚好。你先别进去，我想让你第一眼就看到完整的样子。",
            bg="farm",
            mood="day",
            actors=["juniper@center_left", "player@center_right"],
        ),
        L(
            "narrator",
            "农场东边，一座通透的玻璃温室在阳光里立起来。门一开，湿润的暖气扑到脸上。",
            bg="greenhouse",
            fx=["petals"],
            cam="zoom_in",
            flash="white",
        ),
        L(
            "juniper",
            "第一次，我没有计算。我只是……想一直站在这里。",
            actors=["juniper@center", "player@right"],
        ),
        L(
            "narrator",
            "河灯台上，第三盏灯亮了。从今天起，作物不再惧怕换季。",
            bg="lake",
            mood="dusk",
            flash="gold",
            sfx="lantern",
            fx=["fireflies"],
            actors=["player@center"],
            cam="still",
        ),
    ],
}

meta("ledger", "town", card=["第二章", "留下的人"])
meta("broken_watch", "shop", "dusk")
meta("gears", "shop", "dusk")
meta("bell", "town")
meta("leo_guest", "market", "dusk")
meta("glasshouse", "forest")
meta("wren_letter", "lake", "dusk")
meta("greenhouse_bloom", "farm")
