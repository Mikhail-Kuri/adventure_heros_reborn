extends Node
# Mage.gd
class_name Mage

# === Statistiques de base ===
var level: int = 1
var max_health: int = 100
var current_health: int = max_health

var max_mana: int = 200
var current_mana: int = max_mana

var intelligence: int = 15  # Affecte la puissance magique
var spell_power: int = 30
var mana_regen_rate: float = 5.0  # mana/sec

var defense: int = 5  # réduction de dégâts
var is_alive: bool = true

var spell_manager : SpellManager

func _init(element):
	spell_manager = SpellManager.new(element)

# === Signaux ===
signal died
signal health_changed(current_health)
signal mana_changed(current_mana)

func _process(delta: float) -> void:
	_regen_mana(delta)
	
	

func take_damage(amount: int):
	var effective_damage = max(amount - defense, 0)
	current_health -= effective_damage
	emit_signal("health_changed", current_health)
	print("💔 Mage subit", effective_damage, "dégâts.")

	if current_health <= 0 and is_alive:
		is_alive = false
		emit_signal("died")
		print("☠️ Le mage est mort.")

func heal(amount: int):
	if not is_alive:
		return
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health)
	print("💚 Mage se soigne de", amount, "points de vie.")

func use_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		emit_signal("mana_changed", current_mana)
		print("🔷 Utilisation de", amount, "mana.")
		return true
	print("⚠️ Pas assez de mana.")
	return false

func _regen_mana(delta: float) -> void:
	if current_mana < max_mana:
		current_mana = min(current_mana + mana_regen_rate * delta, max_mana)
		emit_signal("mana_changed", current_mana)

func get_spell_damage() -> int:
	return spell_power + intelligence * 2
	
	
func perform_m_attack():
	spell_manager.m_attack()

func level_up():
	level += 1
	max_health += 20
	max_mana += 30
	intelligence += 3
	spell_power += 5
	defense += 1
	current_health = max_health
	current_mana = max_mana
	print("📈 Le mage passe au niveau", level)
