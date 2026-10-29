class_name PointCloudRecognizer
extends RefCounted

const N := 32
var templates := {}

func add(sigil_name: String, strokes: Array) -> void:
	if not templates.has(sigil_name):
		templates[sigil_name] = []
	templates[sigil_name].append(_to_cloud(strokes))

func recognize(strokes: Array) -> Dictionary:
	var cloud := _to_cloud(strokes)
	if cloud.size() != N:
		return {"name": "none", "score": 0.0}
	var best_name := "none"
	var best := INF
	for n in templates:
		for t in templates[n]:
			var d := _match(cloud, t)
			if d < best:
				best = d
				best_name = n
	var avg := best / (N * 0.5)
	return {"name": best_name, "score": clampf(1.0 - avg / 0.30, 0.0, 1.0)}

func _to_cloud(strokes: Array) -> PackedVector2Array:
	var lens: Array[float] = []
	var total := 0.0
	for s in strokes:
		var l := StrokeUtil.path_length(PackedVector2Array(s))
		lens.append(l)
		total += l
	if total < 1.0 or strokes.size() > 8:
		return PackedVector2Array()
	var counts: Array[int] = []
	var sum := 0
	for l in lens:
		var c := maxi(2, roundi(N * l / total))
		counts.append(c)
		sum += c
	while sum != N:
		var k := counts.find(counts.max())
		counts[k] += -1 if sum > N else 1
		sum += -1 if sum > N else 1
	var cloud := PackedVector2Array()
	for i in strokes.size():
		cloud.append_array(StrokeUtil.resample(PackedVector2Array(strokes[i]), counts[i]))
	var mn := cloud[0]
	var mx := cloud[0]
	for p in cloud:
		mn = mn.min(p)
		mx = mx.max(p)
	var span := (mx - mn).max(Vector2.ONE)
	for i in cloud.size():
		cloud[i] = (cloud[i] - mn) / span
	var c := StrokeUtil.centroid(cloud)
	for i in cloud.size():
		cloud[i] -= c
	return cloud

func _match(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var best := INF
	var step := int(floor(sqrt(N)))
	var s := 0
	while s < N:
		best = minf(best, minf(_cloud_dist(a, b, s), _cloud_dist(b, a, s)))
		s += step
	return best

func _cloud_dist(a: PackedVector2Array, b: PackedVector2Array, start: int) -> float:
	var matched := PackedByteArray()
	matched.resize(N)
	var sum := 0.0
	var i := start
	for k in N:
		var best := INF
		var idx := -1
		for j in N:
			if matched[j] == 0:
				var d := a[i].distance_to(b[j])
				if d < best:
					best = d
					idx = j
		matched[idx] = 1
		sum += (1.0 - float(k) / N) * best
		i = (i + 1) % N
	return sum
