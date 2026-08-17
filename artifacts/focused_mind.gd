extends ArtifactResource

# Effect is purely query-based (ArtifactManager.spirit_cdr()).

func get_cdr() -> float:
	return stacks * 0.10
