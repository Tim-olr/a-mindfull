extends Node2D

var safe: Array[ItemResource] = []
var saved_inventory: Array[Dictionary] = []
var shards: float = 10000

func add_shards(amount: float) -> void:
	shards = minf(shards + amount, 1000000.0)
	ShardCounterLobby.change_amount(0)

func decrease_shards(remainder) -> void:
	shards = maxf(0.0, shards - remainder)
	ShardCounterLobby.change_amount(0)
