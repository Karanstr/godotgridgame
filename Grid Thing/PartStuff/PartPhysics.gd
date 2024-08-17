extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func applyBetterForce(force:Vector2, offset:Vector2):
	apply_force(force.rotated(rotation), position + offset.rotated(rotation))



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
