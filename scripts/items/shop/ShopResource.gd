extends Resource
class_name ShopResource

@export_category("Identity")
@export var shop_name: String = "Shop"
@export var icon: Texture2D
@export var description: String = ""

@export_category("Items for sale")
@export var items: Array[ShopItem] = []
