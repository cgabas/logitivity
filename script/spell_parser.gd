class_name SpellParser
extends RefCounted

const SIGIL_FRAC := 0.34
const MOD_FRAC := 0.64
const EDGES := [[0.0, SIGIL_FRAC], [SIGIL_FRAC, MOD_FRAC], [MOD_FRAC, 1.0]]
const MAX_DOTS := 6
const OUTLINE_COST := {"arrow": 10.0, "asterisk": 18.0, "line": 4.0, "seal": 4.0}
const SIGIL_COST := {"fire": 8.0, "earth": 10.0, "water": 6.0, "wind": 6.0, "poison": 9.0, "heal": 12.0}

var sigils := PointCloudRecognizer.new()

func _init() -> void:
	sigils.add("fire", [[Vector2(0, 1), Vector2(0.5, 0), Vector2(1, 1), Vector2(0, 1)]])
	sigils.add("earth", [[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(0, 0)]])
	sigils.add("water", [_circle()])
	sigils.add("wind", [_s_curve()])
	sigils.add("poison", [[Vector2(0, 0), Vector2(1, 1)], [Vector2(1, 0), Vector2(0, 1)]])
	sigils.add("heal", [_heart()])

func parse(strokes: Array, center: Vector2, radius: float) -> SpellData:
	var spell := SpellData.new()
	var bands: Array = [[], [], []]   # 0 sigil, 1 modifier, 2 outline
	var bleed_pts := 0
	var all_pts := 0
	for s in strokes:
		var d := center.distance_to(StrokeUtil.centroid(s)) / radius
		if d > 1.15:
			continue
		var band := 2 if d >= MOD_FRAC else (1 if d >= SIGIL_FRAC else 0)
		bands[band].append(s)
		for p in s:
			var pd: float = center.distance_to(p) / radius
			all_pts += 1
			if pd < EDGES[band][0] - 0.04 or pd > EDGES[band][1] + 0.04:
				bleed_pts += 1
	var bleed := float(bleed_pts) / maxf(all_pts, 1.0)

	var outline := OutlineClassifier.classify(bands[2], radius, center)
	spell.outline = outline.type
	spell.aim = outline.dir
	spell.aims = outline.get("aims", [])
	spell.outline_count = int(outline.get("count", 1))

	var sig := {"name": "none", "score": 0.0}
	var sigil_strokes: Array = bands[0].filter(
		func(s): return StrokeUtil.path_length(s) > radius * 0.05)
	if not sigil_strokes.is_empty():
		sig = sigils.recognize(sigil_strokes)
	spell.sigil = sig.name
	spell.sigil_score = float(sig.score)

	var dots: Array = bands[1]
	var avg_len := 0.0
	for d in dots:
		avg_len += StrokeUtil.path_length(d)
	avg_len /= maxf(dots.size(), 1.0)
	var band_w := radius * (MOD_FRAC - SIGIL_FRAC)
	spell.count = clampi(dots.size(), 0, MAX_DOTS)
	spell.strength = 1.0 + spell.count * 0.25
	spell.reach = lerpf(1.0, 3.0, clampf(avg_len / band_w, 0.0, 1.0))

	if outline.type == "none":
		spell.fail_reason = "no readable outline"
	elif sig.score < 0.45:
		spell.fail_reason = "unreadable sigil"
	spell.valid = spell.fail_reason == ""
	spell.quality = minf(outline.score, sig.score) * (1.0 - clampf(bleed * 1.5, 0.0, 0.6))
	if spell.valid:
		var modifier_cost: float = float(SIGIL_COST[spell.sigil]) * 0.25
		spell.mana_cost = OUTLINE_COST[spell.outline] * spell.outline_count \
			+ SIGIL_COST[spell.sigil] + modifier_cost * spell.count
	return spell

func _circle() -> Array:
	var pts := []
	for i in 33:
		pts.append(Vector2(0.5, 0.5) + Vector2(cos(TAU * i / 32.0), sin(TAU * i / 32.0)) * 0.5)
	return pts

func _s_curve() -> Array:
	var pts := []
	for d in range(-30, -271, -15):
		var a := deg_to_rad(d)
		pts.append(Vector2(0.5 + 0.25 * cos(a), 0.25 + 0.25 * sin(a)))
	for d in range(-90, 151, 15):
		var a := deg_to_rad(d)
		pts.append(Vector2(0.5 + 0.25 * cos(a), 0.75 + 0.25 * sin(a)))
	return pts

func _heart() -> Array:
	var pts := []
	for i in 41:
		var t := TAU * i / 40.0
		pts.append(Vector2(16.0 * pow(sin(t), 3),
			-(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))))
	return pts
