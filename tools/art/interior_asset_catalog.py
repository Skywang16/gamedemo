"""Furniture catalogue: (placement width, depth, canvas height, subject), in 32 px units.

The subject text is the model prompt; changing it means regenerating the sheet that holds the piece.
"""

FURNITURE = {
    "stairs": (
        2,
        2,
        3,
        "short straight wooden staircase seen from below and above in RPG view, oak steps "
        "rising toward the top of image, side handrail, no floor",
    ),
    "door": (
        1,
        1,
        2,
        "open cottage doorway in oak frame, dark teal interior opening, small stone "
        "threshold, front elevation, isolated no wall",
    ),
    "sofa": (
        2,
        1,
        2,
        "cozy moss green two-seat sofa with oak frame, cream throw and terracotta cushion",
    ),
    "fireplace": (
        2,
        1,
        3,
        "small cottage stone fireplace, warm ember fire, oak mantel with family "
        "photograph and candlesticks",
    ),
    "plant": (1, 1, 1, "lush leafy houseplant in a terracotta pot"),
    "lamp": (1, 1, 1, "small oak bedside table with a warm cream shaded lamp and one closed book"),
    "cabinet": (
        2,
        1,
        2,
        "oak kitchen dresser with cream plates, blue bowls, jars and folded tea towels",
    ),
    "window": (
        2,
        1,
        2,
        "front elevation cottage window with cream curtains, green shutters, blue sky and "
        "small flower pots on sill, isolated no wall",
    ),
    "painting": (
        1,
        1,
        1,
        "framed small landscape painting of a river and stone bridge, warm oak frame",
    ),
    "bed": (
        1,
        2,
        2,
        "single oak bed with terracotta patchwork quilt, cream pillow, headboard at the top",
    ),
    "desk": (2, 1, 2, "writing desk with open journal, ink pot and a brass desk lamp"),
    "bookshelf": (2, 1, 2, "oak bookcase with colorful worn books and a small potted fern"),
    "wardrobe": (2, 1, 2, "closed oak wardrobe with two paneled doors and brass handles"),
    "table": (
        2,
        2,
        2,
        "one small square oak dining table with a cream runner and blue vase, NO chairs, "
        "NO surrounding objects",
    ),
    "kitchen": (
        2,
        1,
        2,
        "compact farmhouse kitchen range and wooden worktop, iron kettle and hanging copper pans",
    ),
    "chest": (1, 1, 1, "oak storage chest with iron latch and a folded green blanket on top"),
    "counter": (4, 1, 2, "wooden shop counter with brass scales, a ledger and one wrapped parcel"),
    "workbench": (
        3,
        2,
        2,
        "carpenter workbench with vice, saw, hand plane and a half-carved wooden bird",
    ),
    "loom": (
        2,
        2,
        3,
        "wooden weaving loom with a cream and moss-green woven blanket and yarn basket",
    ),
    "forge": (
        2,
        2,
        3,
        "stone forge with small orange coal fire, black chimney hood and hanging tongs",
    ),
    "anvil": (1, 1, 1, "black iron anvil on a thick tree stump with a smith hammer"),
    "medical": (
        2,
        2,
        2,
        "clinic examination bed with cream linen, pale teal blanket and a small medical tray",
    ),
    "tea_table": (
        2,
        1,
        1,
        "one low round oak tea table with copper teapot and two cups, NO chairs or stools",
    ),
    "fishrack": (
        2,
        1,
        2,
        "wooden fishing tackle cabinet with rods, coiled rope, floats and a folded blue "
        "fishing net",
    ),
    "seedbench": (
        2,
        1,
        2,
        "gardener potting bench with seed envelopes, terracotta pots, seedlings and twine",
    ),
    "mapdesk": (
        2,
        1,
        2,
        "naturalist desk with bird sketchbook, binoculars, compass and rolled river maps",
    ),
    "clockdesk": (
        2,
        1,
        2,
        "clockmaker desk with an ornate mantel clock, tiny brass gears and magnifying lens",
    ),
    "maildesk": (
        2,
        1,
        2,
        "postal sorting desk with pigeonholes, tied letters, canvas mailbag and red wax seal",
    ),
    "toys": (
        2,
        1,
        1,
        "low toy shelf with wooden boat, toy horse, colored pencils and a cloth doll",
    ),
    "dressrack": (
        2,
        1,
        2,
        "theatre costume rack with teal and terracotta dresses, feather hat and theatre mask",
    ),
    "bar_shelf": (
        2,
        1,
        2,
        "walnut tavern wall cabinet lined with blue and green bottles, mugs and little "
        "brass lantern",
    ),
    "stool": (1, 1, 1, "one small round wooden bar stool with a faded terracotta upholstered seat"),
    "herbs": (
        2,
        1,
        1,
        "wall rail with hanging bundles of sage, lavender and copper ladle, frontal elevation",
    ),
    "coat": (
        1,
        1,
        2,
        "wall mounted coat hook with a worn green raincoat, scarf and small shoulder satchel",
    ),
    "bread": (1, 1, 1, "small woven basket filled with rustic bread and a cream cloth"),
    "chair": (
        1,
        1,
        1,
        "one straight front-facing wooden dining chair with a sage upholstered seat and "
        "oak backrest, symmetrical, no table",
    ),
}

# Doorframe overhang is visual only; keep a one-tile opening for map authoring.
CANVAS_PX = {"door": (48, 64)}
# Hung on the wall face or used as a passage: no ground shadow. Everything else stands on the floor.
HANGING = {"window", "painting", "herbs", "coat"}
PASSAGES = {"door", "stairs"}
SHADOW_PAD = 4  # game pixels under a standing piece that hold its baked contact shadow
