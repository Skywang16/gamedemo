"""Households, their physical front doors and personal room details."""

# map id: display name, outside map, entrance cell, residents
HOMES = {
    "hazel_home": ("黑兹尔的种子小屋", "market", (24, 53), ["hazel"]),
    "hawk_home": ("霍克家的家", "market", (10, 17), ["gregor", "dolly", "ezra", "poppy"]),
    "pemberton_home": ("彭伯顿家的家", "market", (24, 17), ["augustus", "clara"]),
    "felix_home": ("费利克斯的钟表屋", "market", (36, 17), ["felix"]),
    "quill_home": ("奎尔家的家", "market", (60, 17), ["odette", "barnaby", "colette"]),
    "amara_home": ("阿玛拉的邮差小屋", "market", (72, 17), ["amara"]),
    "theo_home": ("西奥的家", "market", (84, 17), ["theo"]),
    "ranch_home": ("德尔加多家的家", "ranch", (14, 17), ["rosa", "nora"]),
    "ranger_home": ("约纳斯的林间小屋", "forest", (46, 50), ["jonas"]),
    "wren_home": ("雷恩的观鸟小屋", "lake", (10, 36), ["wren"]),
    "ferry_home": ("弗林家的海边住宅", "seaside", (70, 11), ["maeve", "toby"]),
    "carver_loft": ("卡弗家的楼上", "workshop", (30, 19), ["eleanor", "silas", "roz"]),
    "inn_lodging": ("酒馆楼上 · 住客走廊", "inn", (34, 21), ["margot", "milo", "leo", "veronica"]),
    "smith_home": ("铁匠铺后宅", "blacksmith", (26, 19), ["magnus", "declan"]),
    "clinic_home": ("诊所楼上", "clinic", (28, 19), ["ambrose", "juniper"]),
}

# Each personal room has a concrete, inspectable detail; no loot or repeatable reward.
DETAILS = {
    "hazel": (
        "seedbench",
        "种子便签",
        "种袋按播种月份分了格。最旧的一袋写着：留给西尔维娅，别忘了。",
    ),
    "gregor": ("counter", "旧账簿", "账簿里夹着一张全家合影。几笔赊账旁，格雷戈尔只画了一个小圆。"),
    "dolly": ("seedbench", "菜市篮子", "篮子里有干净的围裙、秤砣和半张食谱。余下半张似乎在茶室。"),
    "ezra": ("workbench", "学徒作品", "一只打歪的铁鸟。底座反复打磨过，旁边压着马格纳斯画的草图。"),
    "poppy": (
        "toys",
        "波比的画",
        "画里每个人都牵着手，河上有一座特别大的桥。祖父的帽子涂成了紫色。",
    ),
    "augustus": ("mapdesk", "镇长的旧地图", "地图边缘卷起了毛边。旧渡口和桥头被铅笔圈过许多次。"),
    "clara": ("desk", "克拉拉的笔记", "一本医学入门书压着学校作业。页边认真画着草药的叶脉。"),
    "felix": ("clockdesk", "未走动的钟", "钟面停在四点十七分。抽屉里有一封还没寄出的信。"),
    "odette": (
        "loom",
        "奥黛特的针线篮",
        "针线按颜色绕好。小毯子织了一半，边角绣着科莱特小时候的名字。",
    ),
    "barnaby": ("bookshelf", "旧剧本", "许多演员的名字被划去又写上。最后一页的谢幕词仍空着。"),
    "colette": (
        "dressrack",
        "演出衣架",
        "裙摆缝过几次，羽毛帽却收得很新。镜边夹着巴纳比年轻时的节目单。",
    ),
    "amara": ("maildesk", "投递路线", "每条小路都有记号。最偏远的住户旁画着一杯热茶。"),
    "theo": (
        "bookshelf",
        "教师书架",
        "童话、植物图鉴和数学课本挤在一起。最下面一层留给借书的孩子。",
    ),
    "rosa": ("desk", "牧场日记", "天气、饲料和每只小牛的生日记得很细。诺拉的生日被画了两道线。"),
    "nora": ("tea_table", "试茶记录", "茶罐旁写着不同的冲泡时间。最后一行是：下次请姑妈来尝。"),
    "jonas": ("mapdesk", "巡林图", "有一条避开湿地鸟巢的小径。蓝色记号一直延伸到湖畔。"),
    "wren": ("mapdesk", "候鸟观察簿", "每只鸟旁都标着日期和水位。最近一页夹着一片轻薄的白羽毛。"),
    "maeve": ("fishrack", "旧航海箱", "箱里装着磨亮的罗盘和船绳。河船的名字被认真刻在箱盖内侧。"),
    "toby": ("fishrack", "渡船票根", "一叠旧船票用细绳扎着。有几张背面是梅芙小时候的涂鸦。"),
    "eleanor": ("loom", "织机", "织机上绷着河水颜色的布。经线没有乱过，连闲置时也盖得整整齐齐。"),
    "silas": (
        "workbench",
        "木鸟",
        "每只木鸟的翅膀都稍有不同。最小的一只放在写着母亲名字的盒子里。",
    ),
    "roz": (
        "mapdesk",
        "测绘图纸",
        "新旧水渠的线叠在一起。纸角印着县水利局的章，背面却是家里的地址。",
    ),
    "margot": (
        "desk",
        "酒馆菜单",
        "汤的价格改过，米洛喜欢的甜点一直没划掉。后面贴着母亲留下的做法。",
    ),
    "milo": ("toys", "小木船", "木船绑着红线当船帆。船底刻了两个名字：米洛和玛戈。"),
    "leo": ("chest", "旅行箱", "各地的小物件收在分格里。一格还是空的，标签上写着芦苇渡。"),
    "veronica": ("desk", "县城来信", "文件夹下面压着家人的来信。信封边缘被翻得有些发软。"),
    "magnus": ("anvil", "旧锻锤", "这把锤子已经不能用，柄上却一直擦着油。旁边放着外甥的新手套。"),
    "declan": ("mapdesk", "矿井笔记", "危险岔路都标了红叉。有一行重重写着：绝不让新人独自下去。"),
    "ambrose": ("bookshelf", "医案", "医案的字很工整。抽屉半开着，里面有一张年轻女子的旧照片。"),
    "juniper": ("seedbench", "压花册", "采来的草药按用途压在纸里。有一页留下了老师补写的小字。"),
}

NPC_HOME = {npc: ident for ident, row in HOMES.items() for npc in row[3]}
