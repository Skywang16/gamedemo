"""Six hand-drawn poses per tool and direction, retaining every avatar palette."""

import math
from .environment import tree
from PIL import Image, ImageDraw, ImageOps
from .characters import actor, SKINS, SHIRTS
from .crops import watering_can

ACTIONS = ["hoe", "seed", "water", "harvest", "scythe", "axe", "pickaxe", "sword"]


def limb(draw, shoulder, hand, skin, shirt):
    # Fixed-length upper arm and forearm; elbow bends instead of stretching.
    dx, dy = hand[0] - shoulder[0], hand[1] - shoulder[1]
    distance = max(0.01, math.hypot(dx, dy))
    reach = min(14.0, distance)
    hand = (shoulder[0] + dx * reach / distance, shoulder[1] + dy * reach / distance)
    middle = ((shoulder[0] + hand[0]) / 2, (shoulder[1] + hand[1]) / 2)
    bend = math.sqrt(max(0, 7 * 7 - (reach / 2) ** 2))
    side = -1 if shoulder[0] < 40 else 1
    elbow = (middle[0] - dy / distance * bend * side, middle[1] + dx / distance * bend * side)
    shoulder, elbow, hand = [tuple(round(v) for v in p) for p in [shoulder, elbow, hand]]
    draw.line([shoulder, elbow, hand], fill=shirt[0], width=5)
    draw.line([shoulder, elbow], fill=shirt[1], width=3)
    draw.line([elbow, hand], fill=skin[1], width=3)
    draw.rectangle((hand[0] - 1, hand[1] - 1, hand[0] + 1, hand[1] + 1), fill=skin[2])


def implement(draw, grip, angle, kind):
    """Tool is drawn around the actual hand grip, rather than orbiting the actor."""
    direction = (math.sin(angle), -math.cos(angle))
    across = (direction[1], -direction[0])

    def at(distance, side=0):
        return tuple(round(grip[i] + direction[i] * distance + across[i] * side) for i in range(2))

    if kind == "sword":
        draw.line([at(-6), at(7)], fill="#6a4a2a", width=3)
        draw.line([at(6, -6), at(6, 6)], fill="#a8802a", width=3)
        draw.polygon([at(8, -2), at(34, -1), at(38, 2), at(34, 5), at(8, 5)], fill="#c8d4dc")
        draw.line([at(9, 1), at(35, 1)], fill="#ffffff", width=1)
        draw.line([at(9, 4), at(34, 4)], fill="#8a98a4", width=1)
        return
    draw.line([at(-5), at(25)], fill="#483a2b", width=5)
    draw.line([at(-4), at(24)], fill="#c09559", width=3)
    draw.line([at(-3, 1), at(22, 1)], fill="#ebc788", width=1)
    if kind == "axe":
        points = [at(17, -2), at(26, -3), at(28, 8), at(24, 13), at(17, 11)]
    elif kind == "pickaxe":
        points = [at(25, -13), at(29, -5), at(28, 8), at(23, 15), at(25, 5), at(25, -5)]
    elif kind == "scythe":
        points = [at(21, -2), at(30, 1), at(30, 12), at(23, 21), at(25, 10), at(24, 3)]
    else:
        points = [at(24, -4), at(29, -4), at(29, 10), at(24, 13)]
    draw.polygon(points, fill="#354b49")
    draw.line(points[1:4], fill="#b9cebe", width=2)


def pose(style, row, frame, action):
    # Mirror a fully posed right-facing farmer for left-facing actions.
    draw_row = 3 if row == 2 else row
    base = actor(*style, draw_row, 0, arms=False)
    image = Image.new("RGBA", (128, 128))
    crouch = action in ("seed", "harvest")
    water = action == "water"
    lean = [0, -2, -4, 4, 3, 0][frame]
    if water:
        lean = [0, 2, 4, 5, 5, 1][frame]
    if crouch:
        lean = [0, 2, 5, 7, 4, 1][frame]
    shift = round(lean * 0.65) if draw_row == 3 else 0
    bob = max(0, round(lean * 0.55))
    image.alpha_composite(base.crop((0, 38, 32, 48)), (24, 62))
    torso = base.crop((0, 0, 32, 38))
    torso = torso.rotate(
        -lean if draw_row == 3 else lean * 0.25, Image.Resampling.NEAREST, center=(16, 36)
    )
    image.alpha_composite(torso, (24 + shift, 24 + bob))
    d = ImageDraw.Draw(image)
    if crouch:
        hands = [(41, 59), (44, 60), (46, 63), (47, 65), (45, 60), (41, 59)]
    elif water:
        hands = [(42, 57), (46, 55), (47, 56), (48, 57), (48, 57), (43, 57)]
    elif action == "scythe":
        hands = [(38, 55), (33, 49), (36, 48), (47, 56), (47, 59), (42, 57)]
    else:
        hands = [
            (41, 55),
            (38, 47),
            (38, 44),
            (46, 60 if action in ("hoe", "pickaxe") else 56),
            (45, 61),
            (41, 57),
        ]
    grip = hands[frame]
    if draw_row == 0:
        grip = (40 + shift, grip[1])
    elif draw_row == 1:
        grip = (40 + shift, min(grip[1], 49))
    if not crouch and not water:
        angle = [0.4, -0.7, -0.9, 1.9 if action in ("hoe", "pickaxe") else 1.4, 1.9, 0.55][frame]
        if action == "scythe":
            angle = [-1.4, -1.7, -0.8, 1.0, 1.7, 0.6][frame]
        if draw_row == 0:
            angle = [0.3, -0.4, -0.65, 2.8, 3.0, 0.4][frame]
        elif draw_row == 1:
            angle = [0.5, -0.7, -0.8, 0.0, 0.2, 0.4][frame]
        implement(d, grip, angle, action)
    elif water:
        can = watering_can().transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        can = can.rotate(-[0, 5, 20, 30, 30, 5][frame], Image.Resampling.NEAREST)
        image.alpha_composite(can, (grip[0] - 9, grip[1] - 14))
    limb(d, (31 + shift, 53 + bob), (grip[0] - 2, grip[1] + 2), SKINS[style[0]], SHIRTS[style[2]])
    limb(d, (47 + shift, 53 + bob), grip, SKINS[style[0]], SHIRTS[style[2]])
    if action == "seed" and frame in (2, 3):
        for x, y in [(54, 65), (58, 70), (51, 72)]:
            d.rectangle((x, y, x + 1, y + 1), fill="#d6ad6c")
    image = image.crop((-8, -4, 88, 108))
    if row == 2:
        image = ImageOps.mirror(image)
    return image


def build_actions(output):
    for skin in range(3):
        for hair in range(3):
            for outfit in range(4):
                for hat in range(2):
                    style = (skin, hair, outfit, hat)
                    sheet = Image.new("RGBA", (576, 3136))
                    for index, action in enumerate(ACTIONS):
                        for row in range(4):
                            for frame in range(6):
                                sheet.alpha_composite(
                                    pose(style, row, frame, action),
                                    (frame * 96, (index * 4 + row) * 112),
                                )
                    sheet.save(output / ("action_%d_%d_%d_%d.png" % style))
    for variant in range(4):
        crown = tree(variant)
        # Ground shadow stays anchored while the trunk falls.
        px = crown.load()
        for y in range(crown.height):
            for x in range(crown.width):
                if px[x, y][3] < 255:
                    px[x, y] = (0, 0, 0, 0)
        crown.save(output / f"tree_moving_{variant}.png")
    stump = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(stump)
    d.ellipse((2, 22, 30, 30), fill="#29473465")
    d.polygon(
        [(8, 9), (23, 9), (24, 23), (29, 27), (20, 26), (16, 23), (6, 28), (3, 25), (8, 21)],
        fill="#67462d",
    )
    d.rectangle((10, 11, 21, 24), fill="#a67440")
    d.line((12, 13, 11, 24), fill="#d0a262", width=2)
    d.ellipse((7, 6, 24, 15), fill="#60442c")
    d.ellipse((9, 7, 23, 13), fill="#dab57b")
    d.ellipse((12, 9, 20, 12), outline="#a77a47")
    stump.save(output / "tree_stump.png")
