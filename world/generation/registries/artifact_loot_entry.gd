extends Resource
class_name ArtifactLootEntry

@export var artifact: ArtifactResource
## Higher weight = more likely to be selected relative to other entries.
@export var weight: float = 1.0
