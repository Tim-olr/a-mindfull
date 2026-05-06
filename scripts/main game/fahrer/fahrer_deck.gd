extends Node

const CHANCE_TWO_CARDS: float = 0.04
const CHANCE_ONE_CARD: float = 0.18

var force_draw: bool = false

const RARITY_WEIGHT := {
	FahrerCard.Rarity.NORMAL: 100.0,
	FahrerCard.Rarity.RARE:    25.0,
	FahrerCard.Rarity.VERY_RARE: 4.0,
}

const CARD_PATHS: Array[String] = [
	"res://resources/fahrer/cards/king_of_hearts.tres",
	"res://resources/fahrer/cards/king_of_diamonds.tres",
	"res://resources/fahrer/cards/queen_of_hearts.tres",
	"res://resources/fahrer/cards/queen_of_diamonds.tres",
	"res://resources/fahrer/cards/queen_of_spades.tres",
	"res://resources/fahrer/cards/jack_of_spades.tres",
	"res://resources/fahrer/cards/the_birds.tres",
	"res://resources/fahrer/cards/the_fahrer.tres",
	"res://resources/fahrer/cards/the_son.tres",
	"res://resources/fahrer/cards/the_moon.tres",
	"res://resources/fahrer/cards/the_sun.tres",
]

# Cards that exist in the world. Populated at startup.
var card_pool: Array[FahrerCard] = []

# Cards drawn for the current run.
var active_cards: Array[FahrerCard] = []

# When true, the next call to draw_cards() does nothing (the Ignitor burned
# the would-be card). Survives between scenes; toggled by the Ignitor station.
var ignitor_enabled: bool = false

signal cards_drawn(cards: Array)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_default_cards()


# --- Pool management ---

func register_card(card: FahrerCard) -> void:
	if card == null:
		return
	for existing in card_pool:
		if existing.card_id == card.card_id:
			return
	card_pool.append(card)


func _register_default_cards() -> void:
	for path in CARD_PATHS:
		if not ResourceLoader.exists(path):
			push_warning("FahrerDeck: missing card resource at " + path)
			continue
		var res = load(path)
		if res is FahrerCard:
			register_card(res)
		else:
			push_warning("FahrerDeck: %s did not load as a FahrerCard" % path)
	print("FahrerDeck: %d cards loaded" % card_pool.size())


# --- Drawing ---

func draw_cards() -> void:
	clear_active()
	if ignitor_enabled:
		ignitor_enabled = false  # Ignitor consumes itself per run; toggle again in hub for next run
		cards_drawn.emit([])
		return

	var roll := randf()
	var n: int = 0
	if roll < CHANCE_TWO_CARDS:
		n = 2
	elif roll < CHANCE_TWO_CARDS + CHANCE_ONE_CARD:
		n = 1

	var drawn: Array[FahrerCard] = []
	var available := card_pool.duplicate()
	for i in n:
		var card := _weighted_pick(available)
		if card == null:
			break
		available.erase(card)
		drawn.append(card)
		active_cards.append(card)
		card.apply()
	cards_drawn.emit(drawn)


func _weighted_pick(pool: Array) -> FahrerCard:
	if pool.is_empty():
		return null
	var total: float = 0.0
	for c in pool:
		total += RARITY_WEIGHT.get(c.rarity, 1.0)
	if total <= 0.0:
		return pool[0]
	var pick := randf() * total
	var acc := 0.0
	for c in pool:
		acc += RARITY_WEIGHT.get(c.rarity, 1.0)
		if pick <= acc:
			return c
	return pool[pool.size() - 1]


func clear_active() -> void:
	for c in active_cards:
		c.remove()
	active_cards.clear()


func has_card(card_id: String) -> bool:
	for c in active_cards:
		if c.card_id == card_id:
			return true
	return false


# --- Effect query hooks (called by other systems) ---

# Returns a Vector2 to force every projectile's scale to that value, or null
# to leave each projectile alone.
func bullet_scale_override():
	if has_card("jack_of_spades"):
		return Vector2(1.0, 1.0)
	return null

# Multiplier on enemy movement speed (applied at enemy spawn).
func enemy_speed_mult() -> float:
	var m := 1.0
	if has_card("the_birds"):
		m *= 1.30
	return m

# Multiplier on number of enemies per wave.
func enemy_count_mult() -> float:
	if has_card("queen_of_spades"):
		return 0.0
	var m := 1.0
	if has_card("queen_of_diamonds"):
		m *= 2.0
	if has_card("queen_of_hearts"):
		m *= 0.30
	return m

# Multiplier on damage dealt by spirit weapons.
func spirit_damage_mult() -> float:
	var m := 1.0
	if has_card("the_son"):
		m *= 2.0
	if has_card("the_fahrer"):
		m *= 0.5
	return m
