class_name ActorVisual
extends RefCounted

## World sprites share a foot anchor. This scale never affects movement, collision or reach.
const SCALE = 1.25
const ORIGIN = Vector2(-16, -44)
const NAME_OFFSET = Vector2(0, -48) * SCALE
