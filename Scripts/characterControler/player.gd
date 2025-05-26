extends CharacterBody3D
const Enums = preload("res://Scripts/utils/Enums.gd")

@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity := 0.003
@export_range(30.0, 100.0) var zoom_min_fov := 60.0
@export_range(30.0, 100.0) var zoom_max_fov := 90.0
@export_range(1.0, 10.0) var zoom_speed := 5.0

const SPEED = 5.0
const RUN_SPEED = 10.0
const JUMP_VELOCITY = 6
var rotation_speed := 12.0
var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var is_attacking := false
var is_aiming := false

var melee_attack_order := [
	
	"1H_Melee_Attack_Slice_Horizontal",
	"1H_Melee_Attack_Chop",
	"1H_Melee_Attack_Stab",
]
var melee_attack_index := 0
var propulsion_force := 3.0


@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var skin : Node3D = $Mage
@onready var crossHair :Control = %crosshair

@onready var current_class: Mage = Mage.new(Enums.ElementType.FIRE)

@onready var anim_player: AnimationPlayer = skin.get_node("AnimationPlayer")

func _ready():
	anim_player.animation_finished.connect(_on_animation_finished)
	crossHair.visible = false



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("right_click") and is_on_floor():
		is_aiming = true
		_start_aiming()
	elif event.is_action_released("right_click"):
		is_aiming = false

	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_perform_attack()
		
	if event.is_action_pressed("attack_1"):
		_perform_character_attack(1)
		
	if event.is_action_pressed("attack_2"):
		_perform_character_attack(2)
		
	if event.is_action_pressed("attack_3"):
		_perform_character_attack(3)
		
	

	if event.is_action("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and 
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

	# Zoom avec la molette
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		camera.fov = max(zoom_min_fov, camera.fov - zoom_speed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		camera.fov = min(zoom_max_fov, camera.fov + zoom_speed)



var was_in_air := false  # À placer en haut du script si pas déjà fait

func _physics_process(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Saut
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Déplacement (interdit pendant attaque melee)
	var can_move = not is_attacking or is_aiming

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction : Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = RUN_SPEED if Input.is_action_pressed("run") else SPEED
	
	if is_aiming and not is_on_floor():
		is_aiming = false

	if can_move:
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
			_last_movement_direction = direction
		else:
			velocity.x = 0
			velocity.z = 0

	# Déplacement physique

	move_and_slide()


	# Rotation du skin vers la direction du mouvement
	if is_aiming:
		var camera_dir = -camera.global_transform.basis.z
		camera_dir.y = 0
		camera_dir = camera_dir.normalized()
		_last_movement_direction = camera_dir
		var target_angle = Vector3.BACK.signed_angle_to(camera_dir, Vector3.UP)
		skin.global_rotation.y = lerp_angle(skin.rotation.y, target_angle, rotation_speed * delta)
		crossHair.visible = true
	elif not is_aiming and not is_attacking:
		var target_angle = Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
		skin.global_rotation.y = lerp_angle(skin.rotation.y, target_angle, rotation_speed * delta)
		crossHair.visible = false

	# Animation (seulement quand pas en attaque ou visée)
	if not is_attacking and not is_aiming:
		var is_currently_in_air = not is_on_floor()

		if is_currently_in_air:
			if velocity.y > 0:
				anim_player.play("Jump_Start")
			else:
				anim_player.play("Jump_Idle")
		else:
			if was_in_air:
				anim_player.play("Jump_Land")
			elif velocity.length() < 0.1:
				anim_player.play("Idle")
			else:
				var is_running = Input.is_action_pressed("run")
				anim_player.play("Running_A" if is_running else "Walking_A")

		was_in_air = is_currently_in_air

	# Zoom automatique selon visée
	var target_fov = zoom_min_fov if is_aiming else zoom_max_fov
	camera.fov = lerp(camera.fov, target_fov, delta * zoom_speed)


	
	
	
func _perform_attack():
	if is_attacking or not is_on_floor():
		return

	is_attacking = true

	if is_aiming:
		anim_player.play("1H_Ranged_Shoot")
	else:
		# Direction d'attaque basée sur la caméra
		var attack_dir = -camera.global_transform.basis.z
		attack_dir.y = 0
		attack_dir = attack_dir.normalized()
		_last_movement_direction = attack_dir

		# Tourner le skin vers l'attaque
		var angle = Vector3.BACK.signed_angle_to(attack_dir, Vector3.UP)
		skin.global_rotation.y = angle

		# Appliquer propulsion
		velocity.x = attack_dir.x * propulsion_force
		velocity.z = attack_dir.z * propulsion_force

		# Attaque
		var selected_attack = melee_attack_order[melee_attack_index]
		melee_attack_index = (melee_attack_index + 1) % melee_attack_order.size()
		current_class.perform_m_attack()
		anim_player.play(selected_attack)

	anim_player.speed_scale = 2.0
	await anim_player.animation_finished
	anim_player.speed_scale = 1.0
	is_attacking = false



		
func _start_aiming():
	if not is_attacking:
		anim_player.play("1H_Ranged_Aiming")
		
		
func _on_animation_finished(anim_name: String) -> void:
	# Fin de toute attaque
	if anim_name.begins_with("1H_Melee_Attack") or anim_name == "1H_Ranged_Shoot":
		is_attacking = false

	# Si on est toujours en train de viser, relancer l’animation de visée
	if is_aiming and anim_name == "1H_Ranged_Shoot":
		anim_player.play("1H_Ranged_Aiming")
		
		
func _perform_character_attack(attack_number : int):
	if not is_aiming:
		is_aiming = true
		_start_aiming()
		
		
