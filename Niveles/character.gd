extends CharacterBody2D

const SPEED = 150.0

# Usamos get_node de forma más segura
@onready var sprite = get_node("AnimatedSprite2D")

func _physics_process(_delta):
	# 1. Definimos dirección
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Movimiento básico
	velocity = direction * SPEED
	move_and_slide()

	# 3. Animaciones (Asegúrate de que los nombres coincidan)
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				sprite.play("CaminarDerecha")
			else:
				sprite.play("CaminarIzquierda")
		else:
			if direction.y > 0:
				sprite.play("CaminarAbajo")
			else:
				sprite.play("CaminarArriba")
	else:
		sprite.play("Quieto")
