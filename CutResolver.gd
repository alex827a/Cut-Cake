class_name CutResolver
extends RefCounted

static func resolve(distance: float, perfect_threshold: float, good_threshold: float) -> String:
	if distance <= perfect_threshold:
		return "Perfect"
	if distance <= good_threshold:
		return "Good"
	return "Miss"
