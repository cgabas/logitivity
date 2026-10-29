class_name StrokeUtil

static func path_length(pts: PackedVector2Array) -> float:
	var d := 0.0
	for i in range(1, pts.size()):
		d += pts[i - 1].distance_to(pts[i])
	return d

static func centroid(pts: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p in pts:
		c += p
	return c / maxf(pts.size(), 1.0)

static func resample(pts: PackedVector2Array, n: int) -> PackedVector2Array:
	var total := path_length(pts)
	if pts.size() < 2 or total <= 0.001:
		var fill := PackedVector2Array()
		for i in n:
			fill.append(pts[0] if pts.size() > 0 else Vector2.ZERO)
		return fill
	var interval := total / (n - 1)
	var out := PackedVector2Array([pts[0]])
	var work := pts.duplicate()
	var acc := 0.0
	var i := 1
	while i < work.size():
		var d := work[i - 1].distance_to(work[i])
		if d > 0.0 and acc + d >= interval:
			var q := work[i - 1].lerp(work[i], (interval - acc) / d)
			out.append(q)
			work.insert(i, q)
			acc = 0.0
		else:
			acc += d
		i += 1
	while out.size() < n:
		out.append(work[-1])
	if out.size() > n:
		out.resize(n)
	return out

static func simplify(pts: PackedVector2Array, eps: float) -> PackedVector2Array:
	if pts.size() < 3:
		return pts
	var idx := 0
	var dmax := 0.0
	for i in range(1, pts.size() - 1):
		var d := pts[i].distance_to(Geometry2D.get_closest_point_to_segment(pts[i], pts[0], pts[-1]))
		if d > dmax:
			dmax = d
			idx = i
	if dmax > eps:
		var left := simplify(pts.slice(0, idx + 1), eps)
		var right := simplify(pts.slice(idx), eps)
		return left + right.slice(1)
	return PackedVector2Array([pts[0], pts[-1]])
