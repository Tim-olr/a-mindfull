extends Resource
class_name ArtifactLootPool

@export var entries: Array[ArtifactLootEntry] = []

## Rolls a single artifact from this pool. luck (0.0-inf) boosts rarer artifacts,
## matching ArtifactManager.roll_random()'s weighting.
func roll_artifact(rng: RandomNumberGenerator, luck: float = 0.0) -> ArtifactResource:
	if entries.is_empty():
		return null

	var weights: Array[float] = []
	var total := 0.0
	for entry in entries:
		var w := maxf(0.0, entry.weight)
		if entry.artifact != null:
			w *= (1.0 + luck * int(entry.artifact.rarity) * 0.5)
		weights.append(w)
		total += w

	if total <= 0.0:
		return null

	var roll := rng.randf() * total
	var acc := 0.0
	for i in entries.size():
		acc += weights[i]
		if roll <= acc:
			return entries[i].artifact
	return entries[entries.size() - 1].artifact
