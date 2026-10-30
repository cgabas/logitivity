extends RefCounted

const EFFECT_FRAMES := {
	"fire": [
		preload("res://sprite/summon/fire_summon_1.png"),
		preload("res://sprite/summon/fire_summon_2.png"),
		preload("res://sprite/summon/fire_summon_3.png")
	],
	"water": [
		preload("res://sprite/summon/water_summon_1.png"),
		preload("res://sprite/summon/water_summon_2.png"),
		preload("res://sprite/summon/water_summon_3.png")
	],
	"earth": [
		preload("res://sprite/summon/earth_summon_1.png"),
		preload("res://sprite/summon/earth_summon_2.png"),
		preload("res://sprite/summon/earth_summon_3.png")
	],
	"wind": [
		preload("res://sprite/summon/wind_summon_1.png"),
		preload("res://sprite/summon/wind_summon_2.png"),
		preload("res://sprite/summon/wind_summon_3.png"),
		preload("res://sprite/summon/wind_summon_4.png")
	],
	"poison": [
		preload("res://sprite/summon/poison_summon_1.png"),
		preload("res://sprite/summon/poison_summon_2.png"),
		preload("res://sprite/summon/poison_summon_3.png"),
		preload("res://sprite/summon/poison_summon_4.png")
	],
	"heal": [
		preload("res://sprite/summon/healing_summon_1.png"),
		preload("res://sprite/summon/healing_summon_2.png"),
		preload("res://sprite/summon/healing_summon_3.png")
	]
}

static func spawn(parent: Node, element: String, world_position: Vector2, effect_scale: float = 1.5, effect_z: int = 5) -> AnimatedSprite2D:
	if parent == null or not EFFECT_FRAMES.has(element):
		return null
	var animation_frames := SpriteFrames.new()
	animation_frames.add_animation("effect")
	animation_frames.set_animation_loop("effect", false)
	animation_frames.set_animation_speed("effect", 10.0)
	for frame in EFFECT_FRAMES[element]:
		animation_frames.add_frame("effect", frame)
	var effect := AnimatedSprite2D.new()
	effect.sprite_frames = animation_frames
	effect.animation = "effect"
	effect.scale = Vector2.ONE * effect_scale
	effect.z_index = effect_z
	parent.add_child(effect)
	effect.global_position = world_position
	effect.animation_finished.connect(effect.queue_free)
	effect.play("effect")
	return effect
