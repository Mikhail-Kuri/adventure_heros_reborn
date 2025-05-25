extends CharacterBody3D


@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity := 0.003
@export_range(30.0, 100.0) var zoom_min_fov := 30.0
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


@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var skin : Node3D = $Mage

@onready var anim_player: AnimationPlayer = skin.get_node("AnimationPlayer")

func _ready():
	anim_player.animation_finished.connect(_on_animation_finished)



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("right_click"):
		is_aiming = true
		_start_aiming()
	elif event.is_action_released("right_click"):
		is_aiming = false

	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_perform_attack()

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

	# Déplacement
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction : Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = RUN_SPEED if Input.is_action_pressed("run") else SPEED

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		_last_movement_direction = direction
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Déplacement physique
	move_and_slide()
	if is_aiming:
		var camera_dir = -camera.global_transform.basis.z
		camera_dir.y = 0
		camera_dir = camera_dir.normalized()
		var target_angle = Vector3.BACK.signed_angle_to(camera_dir, Vector3.UP)
		skin.global_rotation.y = lerp_angle(skin.rotation.y, target_angle, rotation_speed * delta)
	# Rotation du skin vers la direction du mouvement
	else:
		var targer_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
		skin.global_rotation.y = lerp_angle(skin.rotation.y, targer_angle, rotation_speed * delta)
		
	if not is_attacking:
	# Animation
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

		# Mémoriser si on était en l'air pour détecter l'atterrissage
		was_in_air = is_currently_in_air
	
	
	
func _perform_attack():
	if is_attacking:
		return

	is_attacking = true

	if is_aiming:
		anim_player.play("1H_Ranged_Shoot")
	else:
		var melee_attacks = [
			"1H_Melee_Attack_Chop",
			"1H_Melee_Attack_Slice_Diagonal",
			"1H_Melee_Attack_Slice_Horizontal"
		]
		var selected_attack = melee_attacks[randi() % melee_attacks.size()]
		anim_player.play(selected_attack)
		
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
