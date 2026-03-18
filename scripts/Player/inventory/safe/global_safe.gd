extends Node2D

var safe: Array[ItemResource] = []
var saved_inventory: Array[Dictionary] = []
var shards: float

func decrease_shards(remainder):
	shards = maxf(0.0, shards - remainder)
	ShardCounterLobby.change_amount(0)
