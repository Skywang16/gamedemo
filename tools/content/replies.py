"""Short follow-up scenes: how people answer the choices the player makes.

A scene named `<quest>_<choice>` plays right after that quest's choice is made. Scenes with no
backdrop of their own continue on the parent scene's.
"""

from content.scene_kit import L

SCENES = {
    "festival_stay": [
        L(
            "margot",
            "留下来。……我就知道。桌上给你留个位子，永远。",
            actors=["margot@center_left", "player@center_right"],
        ),
    ],
    "festival_explore": [
        L(
            "hazel",
            "出发也好。可你得答应我，路上看到好看的种子，带一包回来。",
            actors=["hazel@center_left", "player@center_right"],
        ),
    ],
    "festival_together": [
        L(
            "wren",
            "常常见面。……好，我把它记在最前面一页。",
            actors=["wren@center_left", "player@center_right"],
        ),
    ],
    "leo_guest_freedom": [
        L(
            "leo",
            "自由。哈，这话从我嘴里说出来就是借口，从你嘴里……像一个选择。",
            actors=["leo@center_left", "player@center_right"],
        ),
        L("leo", "好吧。我的摊子，大概可以在这儿多摆几个季节。"),
    ],
    "leo_guest_family": [
        L(
            "leo",
            "想一起过日子的人……我连这个词都有点陌生。",
            actors=["leo@center_left", "player@center_right"],
        ),
        L("leo", "让我想想。也许，我也该有个能回的地方。"),
    ],
    "leo_guest_craft": [
        L(
            "leo",
            "值得慢慢做好的事。我做过最慢的生意，是在一个陌生镇子等一个人回头。",
            actors=["leo@center_left", "player@center_right"],
        ),
        L("leo", "但你这么一说，我突然想把货架做得结实一点。"),
    ],
    "leo_guest_unsure": [
        L(
            "leo",
            "还不知道。……谢谢，你是头一个跟我说实话的。",
            actors=["leo@center_left", "player@center_right"],
        ),
        L("leo", "我也不知道。那我们就都不知道着，再待一阵子，行吗？"),
    ],
    "wren_letter_go": [
        L(
            "wren",
            "想去就去……你这么说，我反而哭了。",
            actors=["wren@center_left", "player@center_right"],
            act={"wren": "shake"},
        ),
        L(
            "wren",
            "我会写回信。两年后，我带着整本没写完的笔记回来。你替我数数，这里的鸟，回了多少只。",
        ),
    ],
    "wren_letter_stay": [
        L(
            "wren",
            "这里也需要我……原来我也可以这样被需要。",
            actors=["wren@center_left", "player@center_right"],
        ),
        L("wren", "我先回信，说我想以后再去。我的记录本，还有很多页留给这片湖。"),
    ],
    "wren_letter_together": [
        L(
            "wren",
            "你自己决定，我陪你。……这句话我想了很久，没想到会被人先说出口。",
            actors=["wren@center_left", "player@center_right"],
        ),
        L("wren", "我想去一年。你要是愿意，我们写信。我不会让你一个人守着湖。"),
    ],
    "visitors_cooperate": [
        L(
            "veronica",
            "谢谢你。我会把你们的意见，和勘测数据一起交上去。",
            actors=["veronica@center_left", "player@center_right"],
        ),
    ],
    "visitors_oppose": [
        L(
            "veronica",
            "我听到了。反对也是一种意见，我会如实写进去。",
            actors=["veronica@center_left", "player@center_right"],
        ),
        L("roz", "你比我敢说。……我也许需要学一学。"),
    ],
    "visitors_third": [
        L(
            "veronica",
            "第三条路。……你们有三个月。如果它真的能走通，我愿意为它说话。",
            actors=["veronica@center_left", "player@center_right"],
        ),
        L("roz", "我来出图纸。"),
    ],
    "canal_talk_river": [
        L(
            "roz",
            "沿河。少动老街，少拆一堵墙。这个方案，我喜欢。",
            actors=["roz@center_left", "player@center_right"],
        ),
    ],
    "canal_talk_town": [
        L(
            "roz",
            "穿过镇子，水到每家门口。……赛拉斯会头疼，可我觉得对。",
            actors=["roz@center_left", "player@center_right"],
        ),
    ],
    "sylvia_question_stay": [
        L(
            "sylvia",
            "留在这里。好，好。……那我也不走了，我陪你种一季。",
            actors=["sylvia@center_left", "player@center_right"],
        ),
    ],
    "sylvia_question_wander": [
        L(
            "sylvia",
            "偶尔出去走走，但一定回来。……像我年轻时一样。好。",
            actors=["sylvia@center_left", "player@center_right"],
        ),
    ],
    "sylvia_question_both": [
        L(
            "sylvia",
            "两样都要。贪心。……可是，这才像日子。",
            actors=["sylvia@center_left", "player@center_right"],
        ),
    ],
    "theatre_demolish_keep": [
        L(
            "barnaby",
            "留在原址。……好。我们去跟县里谈，用戏去谈。",
            actors=["barnaby@center_left", "player@center_right"],
        ),
    ],
    "theatre_demolish_move": [
        L(
            "barnaby",
            "搬到新址。……戏跟着人走。你说得对。我只是，舍不得这块地板。",
            actors=["barnaby@center_left", "player@center_right"],
        ),
    ],
    "theatre_demolish_county": [
        L(
            "barnaby",
            "交给县里。……行，我听你的。不过我要在拆之前，演最后一场。",
            actors=["barnaby@center_left", "player@center_right"],
        ),
    ],
    "town_meeting_stay": [
        L(
            "augustus",
            "留下来，用自己的办法。……好。那就记下来，这是全镇的话。",
            actors=["augustus@center", "veronica@center_left", "player@center_right"],
        ),
        L("maeve", "这才对嘛！", act={"maeve": "hop"}),
    ],
    "town_meeting_move": [
        L(
            "augustus",
            "接受搬迁，带着河灯走。……这是最难说出口的一种勇气。",
            actors=["augustus@center", "veronica@center_left", "player@center_right"],
        ),
        L("roz", "我会陪着每一家，一起搬。"),
    ],
    "town_meeting_compromise": [
        L(
            "augustus",
            "折中。低洼的搬，镇中心留。……谁都不完全如意，可谁都能睡着觉。",
            actors=["augustus@center", "veronica@center_left", "player@center_right"],
        ),
    ],
}
