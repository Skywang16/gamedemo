"""Image-model client for game art: one shared style bible, async generation, cut-out, game scale.

The key is read from $IMAGE2FREE_KEY or ~/.config/gamedemo/image2free.key (never from the repo).
Raw downloads go to build/art-raw (gitignored); finished sprites are written by the callers.
"""

from pathlib import Path
import base64
import io
import json
import os
import time
import urllib.error
import urllib.request
from PIL import Image

from art import finish

BASE = "https://image2free.com"
# Only the GPT Image 2.5 family is used for game art (sunburst: best quality).
MODEL = "gpt-image-2.5-sunburst"
RAW = Path(__file__).resolve().parents[2] / "build/art-raw"

# Every prompt starts with this block, so all assets share one camera, one palette and one look.
STYLE = (
    "Original hand-painted 16-bit pixel art for a cozy riverside European-village farming game. "
    "CAMERA: the classic 2D RPG top-down 3/4 view, camera tilted about 30 degrees above the horizon, looking straight at the "
    "long front wall. The roof RIDGE RUNS LEFT TO RIGHT, parallel to the image edge, so we see the long eave wall and door "
    "on the front, and above it only the front slope of the roof as a foreshortened, flattened band (roughly one third of the "
    "object height). NO gable triangle facing the camera, no side wall, no corner view, no isometric diamond, no rotation, "
    "no steep tall roof; gable ends are never visible. Orthographic, flat 2D sprite look. "
    "LIGHT: from the upper left, gentle shading, shadow sides slightly darker with a cool teal tint instead of black. "
    "RENDERING: crisp pixel art with a limited palette, dark warm-brown 1-pixel outlines, chunky readable pixel clusters, "
    "soft storybook colours (terracotta, cream, moss, river teal, oak), gentle saturation, the same level of detail and the "
    "same pixel size for every asset. "
    "The subject is ONE single isolated object: no ground, no grass, no cast shadow, no frame, no border, "
    "no text, no letters, no signboard writing, no watermark, no UI."
)
FLAT_BG = (
    " The background is one perfectly flat solid pure magenta colour (#FF00FF) with nothing else on it, "
    "and the object contains no magenta."
)


REFERENCE_NOTE = (
    " The attached reference image is the STYLE BOARD of this game. Copy its art style exactly: the same outline weight, "
    "pixel size, colour saturation, cel shading and cheerful daylight look. Do not copy its objects, only its style."
)


def style_board() -> str:
    """Read a versioned, immutable reference; never silently derive a new look mid-batch."""
    fixed = Path(__file__).resolve().parents[2] / "assets/reference/interior_style_v1.png"
    return "data:image/png;base64," + base64.b64encode(fixed.read_bytes()).decode()


def key() -> str:
    value = os.environ.get("IMAGE2FREE_KEY")
    if value:
        return value.strip()
    return (Path.home() / ".config/gamedemo/image2free.key").read_text().strip()


def call(method: str, path: str, body: dict | None = None, timeout: int = 60) -> dict:
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Authorization", "Bearer " + key())
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", "gamedemo-art/1.0")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as res:
            return json.loads(res.read())
    except urllib.error.HTTPError as err:
        return json.loads(err.read() or b"{}") | {"http": err.code}


def balance() -> float:
    return call("GET", "/v1/me")["balance"]


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "gamedemo-art/1.0"})
    with urllib.request.urlopen(req, timeout=120) as res:
        return res.read()


def generate(
    prompt: str,
    model: str = MODEL,
    quality: str = "hd",
    transparent: bool = True,
    keep_background: bool = False,
    size: str = "1:1",
    references: list[str] | None = None,
    attempts: int = 6,
    reference_note: str = REFERENCE_NOTE,
) -> Image.Image:
    """One transparent PNG. Upstream outages are retried; any other failure raises."""
    body = {
        "model": model,
        "prompt": prompt,
        "size": size,
        "quality": quality,
        "async": True,
    }
    if transparent:
        body["background"] = "transparent"
    elif not keep_background:
        body["prompt"] += FLAT_BG
    body["image_urls"] = references if references is not None else [style_board()]
    body["prompt"] += reference_note
    last = None
    for attempt in range(attempts):
        sub = call("POST", "/v1/images/generations", body)
        if "data" not in sub:
            last = sub
            time.sleep(8 * (attempt + 1))
            continue
        task = sub["data"][0]["task_id"]
        RAW.mkdir(parents=True, exist_ok=True)
        (RAW / (task + ".request.json")).write_text(
            json.dumps(
                {
                    "task_id": task,
                    "model": model,
                    "quality": quality,
                    "size": size,
                    "prompt": body["prompt"],
                },
                ensure_ascii=False,
            )
        )
        print("Image task submitted:", task, flush=True)
        deadline = time.monotonic() + 900
        while time.monotonic() < deadline:
            time.sleep(6)
            try:
                response = call("GET", "/v1/tasks/" + task)
            except (urllib.error.URLError, TimeoutError):
                continue  # Query the same accepted job; never resubmit after a polling timeout.
            if "data" not in response:
                last = response
                if response.get("http") not in {429, 500, 502, 503, 504}:
                    raise RuntimeError(f"Unable to query accepted image task {task}: {response}")
                continue
            info = response["data"]
            if info["status"] == "done":
                RAW.mkdir(parents=True, exist_ok=True)
                (RAW / (task + ".json")).write_text(json.dumps(info, ensure_ascii=False))
                url = info["result"]["images"][0]["url"]
                url = url[0] if isinstance(url, list) else url
                return Image.open(io.BytesIO(fetch(url))).convert("RGBA")
            if info["status"] == "error":
                last = info["error"]
                break
        else:
            raise TimeoutError(
                f"Generation task {task} is still pending; inspect it before retrying"
            )
        time.sleep(8 * (attempt + 1))
    raise RuntimeError(f"generation failed after {attempts} tries: {last}")


def decode(b64: str) -> Image.Image:
    return Image.open(io.BytesIO(base64.b64decode(b64))).convert("RGBA")


def cut_out(im: Image.Image, key_magenta: bool = False) -> Image.Image:
    """Clean alpha and trim. With key_magenta the flat #FF00FF background is keyed out (with despill
    on the edge pixels); otherwise the model's own transparency is kept. Trims to the visible pixels."""
    im = im.convert("RGBA")
    if key_magenta:
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                # magenta-ness: red and blue both far above green
                m = min(r, b) - g
                if m > 110:
                    px[x, y] = (0, 0, 0, 0)
                elif m > 40:
                    # edge: pull the pink tint back to the neighbouring colour and fade out
                    px[x, y] = (
                        min(r, g + 40),
                        g,
                        min(b, g + 40),
                        max(0, 255 - (m - 40) * 255 // 70),
                    )
    box = im.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox()
    return im.crop(box) if box else im


def to_game(
    im: Image.Image,
    max_w: int,
    max_h: int,
    canvas: tuple[int, int] | None = None,
    bottom_pad: int = 4,
    shadow: str | None = None,
) -> Image.Image:
    """Fit inside max_w x max_h keeping the aspect ratio, then put it on the art grid and the world palette.

    With a canvas the sprite sits bottom-centred on it (bottom_pad pixels above the lower edge), which is
    where the game anchors doors and trunks. `shadow` ("ellipse" or "band") bakes a contact shadow into
    that bottom padding."""
    scale = min(max_w / im.width, max_h / im.height)
    grain = finish.GRAIN
    size = (
        max(grain, round(im.width * scale / grain) * grain),
        max(grain, round(im.height * scale / grain) * grain),
    )
    small = finish.grain(im.resize(size, Image.BOX))
    if canvas is None:
        return small
    out = Image.new("RGBA", canvas, (0, 0, 0, 0))
    left = (canvas[0] - small.width) // (2 * grain) * grain
    out.alpha_composite(small, (left, canvas[1] - bottom_pad - small.height))
    return finish.shadow(out, shadow) if shadow else out
