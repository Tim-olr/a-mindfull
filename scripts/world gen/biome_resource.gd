extends Resource
class_name Biome

@export_category("General settings")
@export var biome_name: String

@export_category("Generation")
@export var tile_set: TileSet
@export var terrain_infos: Array[TerrainInfo]
@export var noise: NoiseTexture2D

@export_category("Objects")
@export var physics_objects: Array[PackedScene]
@export var min_objects: int
@export var max_objects: int

@export_category("Shops")
@export var biome_shops: Array[PackedScene]
@export var min_shops: int
@export var max_shops: int

@export_category("Spawners and Extraction")
@export var enemy_spawners: Array[PackedScene]
@export var min_spawners: int
@export var max_spawners: int
@export var extraction_points: Array[PackedScene]
@export var min_points: int
@export var max_points: int
@export var buildings: Array[PackedScene]
@export var min_buildings: int
@export var max_buildings: int

@export_category("Wave Spawning")
@export var enemy_pool: Array[PackedScene]
@export var wave_interval_min: float = 60.0
@export var wave_interval_max: float = 120.0
@export var enemies_per_wave_min: int = 4
@export var enemies_per_wave_max: int = 8
@export var spawn_radius: float = 100.0
