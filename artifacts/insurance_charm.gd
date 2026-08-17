extends ArtifactResource

# Effect is purely query-based (ArtifactManager.shard_death_retention()).

func get_retention_bonus() -> float:
	# Stack 1 raises the base 10% to 25% (+0.15).
	# Each further stack adds another 10%.
	return 0.15 + (stacks - 1) * 0.10
