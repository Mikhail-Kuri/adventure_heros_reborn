class_name SpellManager
extends Node

@export_group("ElementType")
enum ElementType { FIRE, ICE, ELECTRIC }

var current_element : ElementType

func _init(element):
	current_element = element

func m_attack():
	match current_element:
		ElementType.FIRE:
			print("🔥 Épée de FEU")
		ElementType.ICE:
			print("❄️ Lame de GLACE")
		ElementType.ELECTRIC:
			print("⚡ Éclair FULGURANT")
