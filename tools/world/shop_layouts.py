"""Furniture of the five shop rooms, shared by the map generator (collision) and the art.

Each entry is (kind, x, y, w, h) in cells. All of it is solid; wall decorations are painted on the
back wall by the art and have no collision. Places used by schedules (see places.py) must stay
free, which build_story's reachability check verifies.
"""

SHOP_FURNITURE = {
    "general_store": [
        ("sacks", 4, 4, 2, 2),
        ("barrels", 23, 4, 2, 2),
        ("produce", 4, 10, 3, 2),
        ("produce", 22, 9, 3, 2),
        ("crates", 23, 13, 2, 2),
    ],
    "blacksmith": [
        ("anvil", 6, 9, 2, 2),
        ("grindstone", 4, 13, 2, 2),
        ("water_barrel", 23, 4, 2, 2),
        ("ingots", 22, 9, 3, 2),
        ("worktable", 19, 10, 3, 1),
    ],
    "clinic": [
        ("bed", 4, 10, 3, 2),
        ("bed", 21, 10, 3, 2),
        ("fern", 4, 4, 1, 2),
        ("bench", 4, 14, 3, 1),
        ("fern", 24, 4, 1, 2),
    ],
    "tea_house": [
        ("round_table", 6, 10, 3, 2),
        ("round_table", 18, 10, 3, 2),
        ("stove", 4, 4, 2, 2),
        ("sofa", 23, 5, 2, 3),
        ("fern", 23, 13, 2, 2),
    ],
    "tackle_shop": [
        ("bait_crates", 4, 4, 2, 2),
        ("bait_barrels", 4, 12, 2, 2),
        ("lure_table", 6, 10, 3, 1),
        ("tank", 22, 8, 3, 3),
        ("rope", 23, 13, 2, 2),
    ],
}
