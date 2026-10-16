"""Layout of the farm terrain atlas, shared by the atlas painter and the map compiler.

Terrain is painted per map cell in the TMX (woodland floor, earth path, pond water). The visible
tiles sit on a dual grid shifted by half a cell: every visible tile covers the meeting point of four
map cells, and those four cells (its corners) decide its shape. The corner bits are TL=1, TR=2,
BL=4, BR=8. Ground textures repeat every BLOCK tiles, and every tile is painted for its own place
inside that period, so textures run continuously across tile borders.

Atlas: COLUMNS tiles wide, 16 art pixels per tile, exported at 2x (32 game pixels).
  ground  rows  0-31   grass (corner bit clear) / woodland floor (bit set), all 16 shapes
  paths   rows 32-63   earth over transparent, shapes 1-15
  shore   rows 64-95   pond banks with still water, shapes 1-14
  water   rows 96-103  open water, FRAMES animation frames side by side, BLOCK tiles apart
Inside a section, shape m is the 8 x 8 block at block column m % 4, block row m // 4.
"""

COLUMNS = 32
BLOCK = 8
TILE = 16
SCALE = 2
SECTIONS = {"ground": 0, "paths": 32, "shore": 64}
WATER_ROW = 96
ROWS = 104
FRAMES = 4
FRAME_SECONDS = 0.28
FULL = 15


def corners(mask: int) -> tuple[int, int, int, int]:
    """(TL, TR, BL, BR) as 0/1."""
    return mask & 1, (mask >> 1) & 1, (mask >> 2) & 1, (mask >> 3) & 1


def index(section: str, mask: int, bx: int, by: int) -> int:
    row = SECTIONS[section] + (mask // 4) * BLOCK + by
    return row * COLUMNS + (mask % 4) * BLOCK + bx


def water(bx: int, by: int) -> int:
    return (WATER_ROW + by) * COLUMNS + bx


def animation() -> dict:
    """The animated region as the game reads it: base tiles and how their frames are laid out."""
    return dict(
        rect=[0, WATER_ROW, BLOCK, BLOCK],
        frames=FRAMES,
        separation=[BLOCK - 1, 0],
        duration=FRAME_SECONDS,
    )
