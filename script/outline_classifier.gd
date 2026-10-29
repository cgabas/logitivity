class_name OutlineClassifier

static func classify(strokes: Array, radius: float, center: Vector2 = Vector2.ZERO) -> Dictionary:
	var result := {"type": "none", "score": 0.0, "dir": Vector2.ZERO, "aims": [], "count": 1}
	var all := PackedVector2Array()
	for s in strokes:
		all.append_array(s)
	if all.size() < 2:
		return result

	# Keep arrowhead strokes intact even when several arrows span the whole ring.
	var eps := maxf(2.0, radius * 0.02)

	var segs: Array = []
	for s in strokes:
		var simp := StrokeUtil.simplify(s, eps)
		for i in range(1, simp.size()):
			if simp[i - 1].distance_to(simp[i]) > radius * 0.06:
				segs.append([simp[i - 1], simp[i]])
	var n := segs.size()
	var sum := Vector2.ZERO
	var cnt := 0
	var interior := 0
	var near_center_ends := 0
	if n >= 2:
		for i in n:
			for j in range(i + 1, n):
				var hit = Geometry2D.line_intersects_line(
					segs[i][0], segs[i][1] - segs[i][0],
					segs[j][0], segs[j][1] - segs[j][0])
				if hit != null:
					sum += hit
					cnt += 1
	if cnt > 0:
		var meet := sum / cnt
		for sg in segs:
			var ab: Vector2 = sg[1] - sg[0]
			var t: float = (meet - sg[0]).dot(ab) / ab.length_squared()
			if t > 0.25 and t < 0.75:
				interior += 1
			if sg[0].distance_to(center) < radius * 0.08 or sg[1].distance_to(center) < radius * 0.08:
				near_center_ends += 1
		if (meet.distance_to(center) < radius * 0.12 and near_center_ends >= 3) \
			or interior >= ceili(n * 0.7):
			return {"type": "asterisk", "score": maxf(float(interior) / maxf(n, 1), 0.7), "dir": Vector2.ZERO, "aims": [], "count": 1}

	var arrow_directions: Array[Vector2] = []
	for i in n:
		var shaft: Array = segs[i]
		var shaft_vector: Vector2 = shaft[1] - shaft[0]
		var shaft_length := shaft_vector.length()
		if shaft_length < radius * 0.12:
			continue
		var midpoint: Vector2 = (shaft[0] + shaft[1]) * 0.5
		var radial := midpoint - center
		if radial.length() < radius * 0.45:
			continue

		var a_wings := 0
		var b_wings := 0
		for j in n:
			if i == j or segs[j][0].distance_to(segs[j][1]) >= shaft_length * 0.65:
				continue
			if segs[j][0].distance_to(shaft[0]) < radius * 0.07 or segs[j][1].distance_to(shaft[0]) < radius * 0.07:
				a_wings += 1
			if segs[j][0].distance_to(shaft[1]) < radius * 0.07 or segs[j][1].distance_to(shaft[1]) < radius * 0.07:
				b_wings += 1
		if maxi(a_wings, b_wings) < 2:
			continue
		var tip: Vector2 = shaft[0] if a_wings > b_wings else shaft[1]
		var tail: Vector2 = shaft[1] if a_wings > b_wings else shaft[0]
		arrow_directions.append((tip - tail).normalized())

	if not arrow_directions.is_empty():
		var first_aim: Vector2 = arrow_directions[0]
		return {"type": "arrow", "score": 1.0, "dir": first_aim, "aims": arrow_directions, "count": arrow_directions.size()}

	# If the sketch's arrowheads were drawn too small to survive cleanup, use
	# several separate radial shafts as focused arrows aimed toward the center.
	var radial_candidates: Array[Dictionary] = []
	for sg in segs:
		var fallback_vector: Vector2 = sg[1] - sg[0]
		if fallback_vector.length() < radius * 0.12:
			continue
		var fallback_midpoint: Vector2 = (sg[0] + sg[1]) * 0.5
		var shaft_radial: Vector2 = fallback_midpoint - center
		if shaft_radial.length() < radius * 0.45:
			continue
		if absf(fallback_vector.normalized().dot(shaft_radial.normalized())) < 0.65:
			continue
		var near_end: Vector2 = sg[0] if sg[0].distance_to(center) < sg[1].distance_to(center) else sg[1]
		var far_end: Vector2 = sg[1] if near_end == sg[0] else sg[0]
		var candidate := {"midpoint": fallback_midpoint, "length": fallback_vector.length(), "aim": (near_end - far_end).normalized()}
		var duplicate_index := -1
		for candidate_index in radial_candidates.size():
			if radial_candidates[candidate_index]["midpoint"].distance_to(fallback_midpoint) < radius * 0.15:
				duplicate_index = candidate_index
				break
		if duplicate_index < 0:
			radial_candidates.append(candidate)
		elif fallback_vector.length() > radial_candidates[duplicate_index]["length"]:
			radial_candidates[duplicate_index] = candidate
	if radial_candidates.size() >= 1:
		var radial_aims: Array[Vector2] = []
		for candidate in radial_candidates:
			radial_aims.append(candidate["aim"])
		return {"type": "arrow", "score": 0.8, "dir": radial_aims[0], "aims": radial_aims, "count": radial_aims.size()}

	if not strokes.is_empty():
		var all_straight := true
		var straightness_total := 0.0
		for stroke in strokes:
			if stroke.size() < 2:
				all_straight = false
				break
			var chord: float = stroke[0].distance_to(stroke[-1])
			var straightness := chord / maxf(StrokeUtil.path_length(stroke), 1.0)
			straightness_total += straightness
			if straightness < 0.75:
				all_straight = false
				break
		if all_straight:
			return {"type": "line", "score": straightness_total / strokes.size(), "dir": Vector2.ZERO, "aims": [], "count": 1}
	return result
