"""Collision of the furniture in the five shop rooms; it follows what the image-drawn room backgrounds show.

Each entry is (kind, x, y, w, h) in cells. All of it is solid; wall decorations are painted on the
back wall by the art and have no collision. Places used by schedules (see places.py) must stay
free, which build_story's reachability check verifies.
"""

SHOP_FURNITURE = {
    "general_store": [
        ("sacks", 4, 4, 2, 2),
        ("barrels", 23, 4, 2, 2),
        ("produce", 4, 9, 4, 4),
        ("produce", 22, 8, 3, 4),
        ("crates", 23, 13, 2, 2),
    ],
    "blacksmith": [
        ("anvil", 4, 8, 3, 3),
        ("grindstone", 4, 12, 3, 3),
        ("water_barrel", 23, 4, 2, 2),
        ("ingots", 23, 9, 2, 3),
        ("worktable", 19, 8, 4, 4),
    ],
    "clinic": [
        ("bed", 4, 8, 2, 5),
        ("bed", 23, 8, 2, 5),
        ("fern", 4, 4, 1, 2),
        ("bench", 4, 13, 3, 2),
        ("fern", 24, 4, 1, 2),
    ],
    "tea_house": [
        ("round_table", 4, 10, 5, 3),
        ("round_table", 20, 10, 5, 3),
        ("stove", 5, 4, 2, 2),
        ("sofa", 22, 4, 3, 4),
        ("fern", 23, 13, 2, 2),
    ],
    "tackle_shop": [
        ("bait_crates", 4, 4, 3, 3),
        ("bait_barrels", 4, 12, 3, 3),
        ("lure_table", 4, 8, 5, 4),
        ("tank", 22, 6, 4, 5),
        ("rope", 23, 12, 3, 3),
    ],
}
