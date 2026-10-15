from PIL import Image, ImageDraw
from .props import crate


def rect(draw, box, color):
    draw.rectangle(box, fill=color)


def build_interiors(output):

    def save(name, image):
        image.save(output / (name + ".png"))

    for id in ["cottage", "inn", "workshop"]:
        im = Image.new("RGBA", (960, 608), "#172a24")
        d = ImageDraw.Draw(im)
        rect(d, (96, 72, 832, 536), "#584638")
        rect(d, (112, 104, 816, 520), "#a88153")
        for y in range(112, 520, 24):
            d.line((113, y, 815, y), fill="#775a3b", width=2)
            for x in range(128 + (y % 48) * 3, 812, 128):
                d.line((x, y, x, y + 22), fill="#826142")
        rect(d, (96, 48, 832, 127), "#8a9a75")
        rect(d, (96, 122, 832, 134), "#d2ba86")
        for x in [176, 672]:
            rect(d, (x, 62, x + 78, 112), "#584c37")
            rect(d, (x + 5, 67, x + 73, 107), "#a8c7b3")
            d.line((x + 39, 66, x + 39, 108), fill="#d8c390", width=4)
        rect(d, (352, 310, 575, 451), "#6c7e65" if id == "cottage" else "#a56858")
        rect(d, (360, 318, 567, 443), "#8f9c79" if id == "cottage" else "#ba8870")
        for y in [325, 434]:
            d.line((368, y, 559, y), fill="#d5c392", width=2)
        rect(d, (432, 490, 504, 539), "#493c2e")
        rect(d, (440, 492, 496, 530), "#c1a475")
        if id == "cottage":
            # Bed, bookshelf, table, chest, kitchen with oven.
            rect(d, (192, 160, 286, 253), "#5c4534")
            rect(d, (198, 165, 280, 246), "#eee0b2")
            rect(d, (200, 190, 278, 242), "#748d8b")
            rect(d, (205, 169, 272, 185), "#f7eccd")
            rect(d, (608, 160, 704, 216), "#654933")
            for j in range(11):
                rect(
                    d,
                    (613 + j * 8, 168, 619 + j * 8, 205),
                    ["#8d6b6a", "#bca269", "#778c74"][j % 3],
                )
            rect(d, (384, 288, 510, 347), "#6c4d32")
            rect(d, (390, 291, 504, 339), "#b68b55")
            im.alpha_composite(crate(), (208, 359))
            rect(d, (640, 294, 736, 350), "#5b6660")
            rect(d, (643, 296, 733, 312), "#d0bea1")
            d.ellipse((655, 299, 676, 308), fill="#4d5b55")
            d.ellipse((692, 299, 714, 308), fill="#4d5b55")
        else:
            for x in [224, 576]:
                rect(d, (x, 190, x + 127, 252), "#674b36")
                rect(d, (x + 5, 193, x + 122, 244), "#b38a56")
                if id == "inn":
                    for xx in [x + 22, x + 86]:
                        d.ellipse((xx, 202, xx + 18, 220), fill="#e6d5ae")
                        d.ellipse((xx + 4, 206, xx + 14, 216), fill="#b2754a")
                else:
                    for xx in range(x + 12, x + 112, 20):
                        d.line((xx, 205, xx + 10, 232), fill="#b7b6a0", width=4)
            rect(d, (144, 120, 299, 140), "#5d4632")
        save(id + "_background", im)
    # Interior detail pass: curtains, wood grain, small keepsakes and working surfaces.
    for room in ["cottage", "inn", "workshop"]:
        im = Image.open(output / (room + "_background.png"))
        d = ImageDraw.Draw(im)
        for x in [176, 672]:
            for side in [x - 10, x + 69]:
                d.polygon(
                    [
                        (side, 60),
                        (side + 17, 60),
                        (side + 11, 94),
                        (side + 19, 114),
                        (side, 114),
                        (side + 4, 89),
                    ],
                    fill="#6d7f65" if room != "inn" else "#985d57",
                )
                d.line((side + 4, 63, side + 5, 83), fill="#b3b18c", width=2)
            d.line((x - 12, 58, x + 91, 58), fill="#d6bc82", width=3)
        # Warm lamps and a framed pressed leaf above the room.
        for x in [352, 552]:
            rect(d, (x, 87, x + 5, 119), "#63543b")
            d.polygon([(x - 5, 80), (x + 10, 80), (x + 14, 94), (x - 9, 94)], fill="#e7cb87")
            d.line((x - 5, 91, x + 10, 91), fill="#f8e2a4", width=2)
        rect(d, (445, 70, 482, 113), "#664c36")
        rect(d, (449, 74, 478, 109), "#e0ce9c")
        d.line((463, 99, 463, 83), fill="#748955", width=2)
        d.ellipse((454, 80, 463, 90), fill="#759451")
        d.ellipse((464, 85, 473, 94), fill="#8ba260")
        # Floorboards gain occasional nails; decorative marks never change collision.
        for i in range(80):
            x = 132 + (i * 127) % 656
            y = 145 + (i * 59) % 356
            if im.getpixel((x, y))[:3] == (168, 129, 83):
                d.line((x, y, x + 5, y), fill="#bc9562")
                d.point((x, y + 3), fill="#795d3e")
        for x, y in [(131, 151), (773, 151)]:
            rect(d, (x, y + 17, x + 22, y + 38), "#876345")
            rect(d, (x - 3, y + 14, x + 25, y + 20), "#c3925a")
            for j in range(5):
                d.ellipse(
                    (x - 6 + j * 6, y - 4 + (j % 2) * 5, x + 9 + j * 4, y + 15),
                    fill=["#466c44", "#6d914e", "#8ca655"][j % 3],
                )
        if room == "cottage":
            for y in range(199, 239, 9):
                d.line((202, y, 276, y), fill="#9aaf9a", width=2)
            d.line((201, 193, 275, 193), fill="#d9d7b0", width=3)
            d.rectangle((207, 171, 270, 184), outline="#d7c69e", width=2)
            # Journal, cup, and an oven on existing solid furniture.
            rect(d, (413, 302, 443, 325), "#486b65")
            d.line((428, 302, 428, 325), fill="#c4b996", width=2)
            d.ellipse((466, 307, 485, 324), fill="#e3d3b0")
            d.ellipse((470, 310, 482, 319), fill="#7d5538")
            rect(d, (654, 320, 724, 344), "#324d46")
            rect(d, (659, 325, 719, 339), "#746a4e")
            d.line((664, 322, 713, 322), fill="#d9c8a3", width=2)
            for x in [651, 677, 704]:
                d.ellipse((x, 313, x + 7, 318), fill="#dad1ad")
            for x in range(369, 560, 12):
                d.line((x, 320, x + 3, 325), fill="#ddd1a2")
                d.line((x, 435, x + 3, 439), fill="#ddd1a2")
        elif room == "inn":
            # Tea service, tablecloths, baked bread.
            for x in [224, 576]:
                rect(d, (x + 46, 195, x + 79, 242), "#d2bd8e")
                for y in range(198, 241, 8):
                    d.line((x + 48, y, x + 76, y), fill="#e4d4ac")
                d.ellipse((x + 48, 202, x + 76, 222), fill="#b87942")
                d.line((x + 55, 205, x + 62, 214), fill="#edd29a", width=2)
            rect(d, (144, 119, 299, 140), "#a07c4f")
            for x in range(152, 287, 22):
                rect(d, (x, 122, x + 11, 135), "#e1c390")
                d.line((x, 125, x + 10, 125), fill="#8e7251")
        else:
            for x in [224, 576]:
                for yy in range(196, 241, 10):
                    d.line((x + 7, yy, x + 119, yy), fill="#c5a16e")
                d.line((x + 20, 200, x + 36, 231), fill="#c7c7ad", width=5)
                d.line((x + 16, 200, x + 30, 196), fill="#616f6a", width=5)
            rect(d, (145, 121, 298, 141), "#9b7950")
            for x in range(151, 288, 24):
                d.ellipse((x, 119, x + 17, 136), fill="#c9a06b")
                d.ellipse((x + 4, 123, x + 13, 132), outline="#84633f")
        save(room + "_background", im)
