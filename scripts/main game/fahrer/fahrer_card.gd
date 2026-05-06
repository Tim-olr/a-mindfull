extends Resource
class_name FahrerCard

# Add a new card by:
#   1. Make a script that extends FahrerCard
#   2. Override apply()/remove() (and optional query hooks)
#   3. Save a .tres resource using your script
#   4. Drop the .tres into FahrerDeck.card_pool (in the autoload's inspector
#      OR call FahrerDeck.register_card(card) at startup)

enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES, FAHRER }
enum Rarity { NORMAL, RARE, VERY_RARE }

@export var card_id: String                  # unique key, e.g. "king_of_hearts"
@export var card_name: String                # shown in UI
@export var description: String              # one-line flavour
@export var suit: Suit = Suit.HEARTS
@export var rarity: Rarity = Rarity.NORMAL
@export var icon: Texture2D

# --- Lifecycle (subclasses override these) ---

# Called once when the card is drawn at the start of a run.
func apply() -> void:
	pass

# Called when the run ends (player returns to hub) so persistent stats are
# returned to their pre-card values.
func remove() -> void:
	pass
