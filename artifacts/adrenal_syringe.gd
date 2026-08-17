extends ArtifactResource

# Effect is purely query-based (ArtifactManager.adrenal_speed_mult()).
# No stat modifications to track or undo.

func get_speed_mult() -> float:
	return 1.0 + 0.25 + (stacks - 1) * 0.10
