"""Courtship, weddings and married life for the twelve villagers who can be courted.

For each person: the line when they accept a heart lantern (`dating`), a ring (`engage`), their
wedding vow, a friend's words at the wedding, three lines for daily life, and two married-life
events that arrive after a week and after four weeks.
"""

from content.scene_kit import L, meta, reward

ROMANCE = {
    "hazel": {
        "dating": "原来被人这样认真地喜欢，是这种感觉。我还想说“我很忙”……可我不想再说了。",
        "engage": "我说过，谢谢这个词很重。现在我想用它的另一半：我愿意。",
        "vow": "我会把地浇好，把你也放在日子里的第一垄。不用你说“我来帮忙”，你只要站在田边，我就够了。",
        "guest": ("margot", "黑兹尔，你终于有人陪着收摊了。今天的汤我煮了双份。"),
        "talk": [
            "早。田里的水我浇过了，你先吃饭。",
            "奶奶说，把种子交给对的人，它会自己长。我想，我也是。",
            "今天不忙。……骗你的。可我愿意为你空出来。",
        ],
        "m1": (
            [
                L(
                    "hazel",
                    "我想把摊子挂上正式的招牌。你说叫什么好？",
                    bg="farm",
                    mood="day",
                    actors=["hazel@center_left", "player@center_right"],
                ),
                L("hazel", "“黑兹尔和她的邻居们”。嗯……邻居们，包括你。", act={"hazel": "hop"}),
            ],
            reward(100, pumpkin_seed=3),
        ),
        "m2": (
            [
                L(
                    "hazel",
                    "奶奶回信了。她说，你们俩要是不先把那一垄老菜种下，她就不回来。",
                    bg="farm",
                    mood="dusk",
                    actors=["hazel@center_left", "player@center_right"],
                    fx=["leaves"],
                ),
                L("hazel", "我们种吧。一起。……我手上有老种子，是真的。", act={"hazel": "nod"}),
            ],
            reward(200, wheat_seed=3, corn_seed=3),
        ),
    },
    "silas": {
        "dating": "……心意灯。我收下。我不太会说话，但我会一直在你周围。",
        "engage": "我愿意。这三个字，我想了一整夜，怕说出口太轻。",
        "vow": "我给你做过很多东西。以后每一件，我都先想你会不会喜欢。桥会旧，椅子会坏，我不会。",
        "guest": ("roz", "赛拉斯，我弟弟，你今天笑得像换了一个人。"),
        "talk": [
            "早。劈了点柴，放门口了。",
            "今天做把新椅子，你先别坐，漆没干。",
            "……你回来了。我，嗯，刚好做好了晚饭。",
        ],
        "m1": (
            [
                L(
                    "silas",
                    "给你的。小凳子，你够不着高处时用。",
                    bg="farm",
                    mood="day",
                    actors=["silas@center_left", "player@center_right"],
                ),
                L("silas", "……我是说，我想让你多笑几次，所以做了。", act={"silas": "nod"}),
            ],
            reward(100, wood=10),
        ),
        "m2": (
            [
                L(
                    "silas",
                    "姐姐来信了。说她想回镇上长住。我想，家里的饭桌，可以再加一把椅子。",
                    bg="cottage",
                    mood="dusk",
                    actors=["silas@center_left", "player@center_right"],
                ),
                L("silas", "你不介意的话。……我觉得，我们的家，也该有她的位置。"),
            ],
            reward(200, wood=20, stone=10),
        ),
    },
    "margot": {
        "dating": "你记得我爱吃什么吗？……你记得。呀，我要被你问住了——这灯，我收下。",
        "engage": "桌上永远给你留位子——现在，是我给你留一辈子的位子。我愿意！",
        "vow": "我记得每个人爱吃的，你是我第一次不用记的那一个。因为我早就知道你想要什么：热的汤，和一个等你的人。",
        "guest": ("hazel", "玛戈！你今天哭花了妆，看起来是全镇最漂亮的新娘！"),
        "talk": [
            "早饭在灶上，别忘了吃。我再烤点面包。",
            "今天酒馆特色菜，是我新想的。你尝尝，一定说真话。",
            "我不怕空桌子了。因为桌边有人等我回家。",
        ],
        "m1": (
            [
                L(
                    "margot",
                    "我在酒馆后头开了一间小小的“家人桌”。第一个位子，是你的。",
                    bg="inn",
                    mood="day",
                    actors=["margot@center_left", "player@center_right"],
                    fx=["steam"],
                ),
                L("margot", "呀，别不好意思，我是认真的。", act={"margot": "hop"}),
            ],
            reward(100, berry_oatmeal=2),
        ),
        "m2": (
            [
                L(
                    "margot",
                    "米洛今天问我，能不能把新年愿望写在我们的桌子上。",
                    bg="inn",
                    mood="dusk",
                    actors=["margot@center_left", "milo@center", "player@center_right"],
                ),
                L("milo", "我想让小姨一直笑。就这一个愿望！", act={"milo": "hop"}),
                L("margot", "……好。我们一起满足它。"),
            ],
            reward(200, apple_pie=2),
        ),
    },
    "wren": {
        "dating": "我、我的笔记本里，没有这一页。……我现在写进去，可以吗？这灯，我收下。",
        "engage": "我愿意。我想写一整本，里面只有“我们”。",
        "vow": "我把这片湖记了一年又一年。以后，我想把你也记在里面，不是作为被记录的人，而是并肩记录的人。",
        "guest": ("jonas", "雷恩，你看，今天没有鸟走错路，所有人都到齐了。"),
        "talk": [
            "早上好。窗台上有只翠鸟，我想让你也看看。",
            "水位今天涨了一指。我记下来了，也记了你笑的样子。",
            "我的第三本笔记，开头一页是你的名字。",
        ],
        "m1": (
            [
                L(
                    "wren",
                    "我把湖畔小屋收拾了一个小角落，放你的东西。",
                    bg="lake",
                    mood="day",
                    actors=["wren@center_left", "player@center_right"],
                    fx=["leaves"],
                ),
                L(
                    "wren",
                    "我以前总觉得一个人住最舒服。……现在知道，是我没遇见合适的。",
                    act={"wren": "nod"},
                ),
            ],
            reward(100, feather=2),
        ),
        "m2": (
            [
                L(
                    "wren",
                    "研究所又来信了。这次，我想自己回。",
                    bg="cottage",
                    mood="dusk",
                    actors=["wren@center_left", "player@center_right"],
                ),
                L(
                    "wren",
                    "我写：欢迎你们来看这片湖。不是我去，是你们来。你觉得呢？",
                    act={"wren": "hop"},
                ),
            ],
            reward(200, lamp_note=2),
        ),
    },
    "juniper": {
        "dating": "我习惯用数据判断事情。但这一次……我不需要。灯，我收下。",
        "engage": "我计算过无数次。结论只有一个：我愿意。",
        "vow": "我会照顾你，像照顾一株最珍贵的植物：不过分，也不缺席。冬天来的时候，我是你的温室。",
        "guest": ("clara", "朱妮姐姐，你今天紧张得发抖，可你比任何时候都美。"),
        "talk": [
            "早。我在温室里新栽了一排薄荷，你路过可以掐几片。",
            "今天的数据很好。……我是说，你。",
            "别太累。我配了点茶，趁热喝。",
        ],
        "m1": (
            [
                L(
                    "juniper",
                    "我把诊所的辞职信交了。……是我自己想交的，不是逃。",
                    bg="farm",
                    mood="day",
                    actors=["juniper@center_left", "player@center_right"],
                ),
                L(
                    "juniper",
                    "以后，我想在家里种药草，也种点别的。比如，一点闲着不做的时间。",
                    act={"juniper": "nod"},
                ),
            ],
            reward(100, medicine=2),
        ),
        "m2": (
            [
                L(
                    "juniper",
                    "你看，窗台上的这盆番茄，冬天又结果了。",
                    bg="cottage",
                    mood="dusk",
                    actors=["juniper@center_left", "player@center_right"],
                ),
                L("juniper", "和我最初那盆一样。……不一样的是，现在有人和我一起吃。"),
            ],
            reward(200, tomato_seed=4, pea_seed=4),
        ),
    },
    "leo": {
        "dating": "灯？……你知道我这种人会怎么答。我不拆行李了。这盏灯，我收下。",
        "engage": "我愿意。我这辈子第一次，用“愿意”回答一个“要不要停下”。",
        "vow": "我走过很多路，每一条路尽头都是别人的家。现在，我想要的，是你这里的一把椅子。",
        "guest": ("amara", "利奥，你这家伙，信封都拆过了，还敢说不收。"),
        "talk": [
            "早啊。我昨晚梦见在路上，醒来发现你在。真好。",
            "今天我去集市街摆了一整天，赚了点零钱，你拿去买糖。",
            "旅行不会停，只是现在，有了终点。",
        ],
        "m1": (
            [
                L(
                    "leo",
                    "我给你带了一件远方的小玩意，其实是在邻镇买的。别拆穿我。",
                    bg="cottage",
                    mood="day",
                    actors=["leo@center_left", "player@center_right"],
                ),
                L("leo", "我想，下次旅行带上你。就一两天，来回的。", act={"leo": "hop"}),
            ],
            reward(100, candy_apple=2),
        ),
        "m2": (
            [
                L(
                    "leo",
                    "我做了个决定。我把货架钉在了农舍边上，永久的。",
                    bg="farm",
                    mood="day",
                    actors=["leo@center_left", "player@center_right"],
                    fx=["dust"],
                ),
                L("leo", "钉钉子的时候我一直在想：这是我第一次，把东西固定在一个地方。"),
            ],
            reward(200, honey=3),
        ),
    },
    "felix": {
        "dating": "这盏灯……我研究过很多钟，从没有一盏让我的手这样抖过。我收下。",
        "engage": "我愿意。……不用再校对了，这一次，时间对得很准。",
        "vow": "父亲留下的怀表停在三点十二分。从今天起，它重新开始走，因为我身边的人，是你。",
        "guest": ("augustus", "费利克斯，这座钟楼，终于有人替它守时了。恭喜。"),
        "talk": [
            "早。钟我上过弦了，别担心迟到。",
            "今天修了三只表。你的，我放在最后，慢慢修。",
            "……你的表，一直走得很准。我是说，你每天回来的时间。",
        ],
        "m1": (
            [
                L(
                    "felix",
                    "给你。一只新怀表。里面刻了日期。",
                    bg="cottage",
                    mood="day",
                    actors=["felix@center_left", "player@center_right"],
                    sfx="tick",
                ),
                L("felix", "我想，它会比我的更守时，因为你总是准时回家。", act={"felix": "nod"}),
            ],
            reward(100, copper_bar=2),
        ),
        "m2": (
            [
                L(
                    "felix",
                    "我把父亲那只表，修好了。",
                    bg="cottage",
                    mood="dusk",
                    actors=["felix@center_left", "player@center_right"],
                    sfx="tick",
                ),
                L(
                    "felix",
                    "不是零件的问题。……是我终于肯让它走过三点十二分。谢谢你。",
                    act={"felix": "shake"},
                ),
            ],
            reward(200, iron_bar=2),
        ),
    },
    "colette": {
        "dating": "有人为我提灯……这是我写不出来的一场戏。我收下，你不许退场。",
        "engage": "我愿意！……哎呀，我准备的台词呢？算了，这一句是真的。",
        "vow": "我演过很多次新娘，每一次都是假的。今天这一次，不用台词。我愿意和你，把这一出，一辈子演下去。",
        "guest": ("barnaby", "我的孩子，今天站在台上，不用我提词了。"),
        "talk": [
            "早！我在背新戏的词，你来对对戏。",
            "今天排了三场，累是累，可回家有你。",
            "谢幕之后，我想看到的人，只有你。",
        ],
        "m1": (
            [
                L(
                    "colette",
                    "我把戏服放进了你的衣柜，别吓一跳。",
                    bg="cottage",
                    mood="day",
                    actors=["colette@center_left", "player@center_right"],
                ),
                L(
                    "colette",
                    "我想，日子也可以当一场戏。我们俩，一人一个角色，也一起编台词。",
                    act={"colette": "hop"},
                ),
            ],
            reward(100, primrose=3),
        ),
        "m2": (
            [
                L(
                    "colette",
                    "我写了一出新戏，只有两个角色。",
                    bg="stage",
                    mood="dusk",
                    actors=["colette@center_left", "player@center_right"],
                    fx=["confetti"],
                ),
                L(
                    "colette",
                    "第一幕，是我们在灯下相遇。第二幕，还没写，想先听听你的意见。",
                    act={"colette": "nod"},
                ),
            ],
            reward(200, cloth=2),
        ),
    },
    "jonas": {
        "dating": "我一个人在林子里守了很多夜。有人愿意递灯，我才发现原来天是会亮的。我收下。",
        "engage": "我愿意。……这三个字，说出口才发现不那么沉。",
        "vow": "我守夜，是为了让别人安心睡觉。今天起，我想让一个人安心醒来，那个人是你。",
        "guest": ("maeve", "约纳斯，我的儿子，这回你不用躲在林子里了。来，抱一下。"),
        "talk": [
            "早。林子里有新落的栗子，我给你捡了一些。",
            "昨晚巡了一遍林，没事，安心。",
            "夜里你睡得好吗？我在窗外，没走远。",
        ],
        "m1": (
            [
                L(
                    "jonas",
                    "我从救援队退下来那件事，一直没跟人细说。",
                    bg="farm",
                    mood="dusk",
                    actors=["jonas@center_left", "player@center_right"],
                ),
                L("jonas", "今天告诉你。因为我想，有人可以一起听。", act={"jonas": "nod"}),
            ],
            reward(100, chestnut=4),
        ),
        "m2": (
            [
                L(
                    "jonas",
                    "妈来了，在厨房里和你说话呢。我在院里劈柴，听得到笑声。",
                    bg="cottage",
                    mood="day",
                    actors=["jonas@center_left", "maeve@center", "player@center_right"],
                ),
                L("maeve", "你把我儿子养得挺好！别告诉他我说的。", act={"maeve": "hop"}),
            ],
            reward(200, honey=2, pinenut=3),
        ),
    },
    "nora": {
        "dating": "家传的方子里，没有“收下一盏灯”这一味。……我先记下，慢慢调。",
        "engage": "我愿意。这一杯茶，我想和你一起煮一辈子。",
        "vow": "茶要静，要等，要用心。你来了之后，我觉得，我等的，一直是你。",
        "guest": ("rosa", "诺拉，姑姑把你养大，今天是我一辈子最骄傲的一天！"),
        "talk": [
            "早。茶我煮好了，趁热。",
            "今天的茶是新方子，你说说，加几片薄荷比较好。",
            "家里有茶香，是我最喜欢的日子。",
        ],
        "m1": (
            [
                L(
                    "nora",
                    "我把茶具搬了一套过来，放在窗边。",
                    bg="cottage",
                    mood="day",
                    actors=["nora@center_left", "player@center_right"],
                    fx=["steam"],
                ),
                L("nora", "以后，我们的下午，都这样开始。", act={"nora": "nod"}),
            ],
            reward(100, honey_tea=2),
        ),
        "m2": (
            [
                L(
                    "nora",
                    "姑姑把我母亲留下的那封信，拿给我了。",
                    bg="cottage",
                    mood="dusk",
                    actors=["nora@center_left", "player@center_right"],
                ),
                L(
                    "nora",
                    "我读了。……不难过。有你在旁边，那封信就只是一封信。",
                    act={"nora": "shake"},
                ),
            ],
            reward(200, grape_juice=2),
        ),
    },
    "theo": {
        "dating": "书里写过很多种告白，我背得出来。可是现在……一句都想不起来。灯，我收下。",
        "engage": "我愿意。……这三个字，比我读过的任何一本书里的，都更好听。",
        "vow": "我教过很多孩子认字。以后，我想和你一起认识，什么是家。",
        "guest": ("clara", "西奥老师，今天作业我交晚了，可是你结婚我一定到。"),
        "talk": [
            "早。我整理了一份图志，你看看哪些要补。",
            "今天放学后，孩子们送了我一束花，我放窗台了。",
            "夜里读书，你睡着了，我给你盖了毯子。",
        ],
        "m1": (
            [
                L(
                    "theo",
                    "我把一半的书搬了来，你不介意吧？",
                    bg="cottage",
                    mood="day",
                    actors=["theo@center_left", "player@center_right"],
                ),
                L("theo", "我给其中一本夹了书签。你什么时候想读，我给你念。", act={"theo": "nod"}),
            ],
            reward(100, lamp_note=1),
        ),
        "m2": (
            [
                L(
                    "theo",
                    "学校想让我当校长。我说我要问问家里人。",
                    bg="cottage",
                    mood="dusk",
                    actors=["theo@center_left", "player@center_right"],
                ),
                L("theo", "……我从来没有“家里人”可以问。现在有了。你怎么想？", act={"theo": "hop"}),
            ],
            reward(200, lamp_note=2),
        ),
    },
    "declan": {
        "dating": "我这人嘴笨。灯我收下，余下的，用行动说。",
        "engage": "我愿意。……够直接吧？我想不出更好的词。",
        "vow": "我走过很多暗道，每一次都想着怎么出去。这一次，我想的是，怎么回到你身边。",
        "guest": ("magnus", "德克兰，我的外甥，你舅舅我这辈子，没见你笑得这么好看。"),
        "talk": [
            "早。昨天下矿带了点煤回来，放在炉边。",
            "今天没活，我就在家陪你。就在这儿。",
            "你不用说话，我知道。",
        ],
        "m1": (
            [
                L(
                    "declan",
                    "我在石室里挖到一块不错的原石，给你打磨了一枚小摆件。",
                    bg="cottage",
                    mood="day",
                    actors=["declan@center_left", "player@center_right"],
                ),
                L("declan", "不好看的话，不许笑。", act={"declan": "shake"}),
            ],
            reward(100, quartz=2, copper_ore=3),
        ),
        "m2": (
            [
                L(
                    "declan",
                    "我和舅舅一起，去矿洞口刻了块碑。",
                    bg="quarry",
                    mood="dusk",
                    actors=["declan@center_left", "magnus@center", "player@center_right"],
                ),
                L(
                    "declan",
                    "我搭档的名字，也在上面。……我今天，终于可以在他面前，好好站着了。",
                    act={"declan": "nod"},
                ),
            ],
            reward(200, coal=5, iron_ore=3),
        ),
    },
}


# Where a villager's private scenes are set when no scene says otherwise.
HOME_BACKDROP = {
    "hazel": "farm",
    "silas": "town",
    "margot": "inn",
    "wren": "lake",
    "juniper": "forest",
    "leo": "market",
    "felix": "shop",
    "colette": "stage",
    "jonas": "forest",
    "nora": "shop",
    "theo": "town",
    "declan": "quarry",
    "augustus": "town",
    "clara": "town",
    "maeve": "seaside",
    "toby": "seaside",
    "roz": "town",
    "eleanor": "shop",
    "gregor": "shop",
    "dolly": "market",
    "ezra": "market",
    "poppy": "town",
    "milo": "inn",
    "magnus": "shop",
    "ambrose": "shop",
    "rosa": "ranch",
    "amara": "town",
    "barnaby": "stage",
    "odette": "town",
    "veronica": "town",
}

WEDDING_GUESTS = ["margot", "hazel", "silas", "dolly", "gregor", "eleanor"]


def build_scenes(names):
    """Dating, engagement and wedding scenes for each romanceable villager."""
    scenes = {}
    for ident, r in ROMANCE.items():
        who = names[ident]
        home = HOME_BACKDROP[ident]
        scenes["dating_" + ident] = [
            L(
                "narrator",
                "你把写好的心意灯，轻轻递给%s。" % who,
                bg=home,
                mood="dusk",
                fx=["lanterns"],
                actors=[ident + "@center_left", "player@center_right"],
            ),
            L(ident, r["dating"], act={ident: "hop"}),
            L(
                "narrator",
                "灯在两人之间亮起来。从今天起，你们是恋人。",
                flash="gold",
                sfx="lantern",
            ),
        ]
        scenes["engage_" + ident] = [
            L(
                "narrator",
                "你拿出同心环，认真地站在%s面前。" % who,
                bg=home,
                mood="dusk",
                fx=["petals"],
                actors=[ident + "@center_left", "player@center_right"],
            ),
            L(ident, r["engage"], act={ident: "hop"}),
            L("narrator", "三天后，镇广场会为你们办一场婚礼。", flash="gold", sfx="chime"),
        ]
        guest_id, guest_line = r["guest"]
        extra = [g for g in WEDDING_GUESTS if g not in (ident, guest_id)][:1]
        scenes["wedding_" + ident] = [
            L(
                "narrator",
                "婚礼的早晨。镇广场被花和纸灯布置得满满当当，连钟楼都系上了彩带。",
                bg="town",
                mood="day",
                fx=["petals"],
                actors=[
                    guest_id + "@far_left",
                    ident + "@center_left",
                    "augustus@center",
                    "player@center_right",
                    extra[0] + "@far_right",
                ],
                cam="zoom_in",
            ),
            L("augustus", "今天，我们在芦苇渡的灯下，见证两个人决定一起过日子。……来，说吧。"),
            L(ident, r["vow"], cam="still"),
            L(
                "narrator",
                "你把同心环戴在%s的手上，花瓣落满了肩头。" % who,
                sfx="wedding",
                flash="gold",
                fx=["petals", "confetti"],
            ),
            L(guest_id, guest_line, act={guest_id: "hop"}),
            L(
                "narrator",
                "钟声响起。从今天起，农舍里多了一个人的脚步声。",
                sfx="bell",
                fx=["bells", "petals"],
                cam="zoom_out",
            ),
        ]
        meta("dating_" + ident, home, "dusk")
        meta("engage_" + ident, home, "dusk")
        meta("wedding_" + ident, "town", "day")
        scenes[ident + "_m1"] = r["m1"][0]
        scenes[ident + "_m2"] = r["m2"][0]
    return scenes
