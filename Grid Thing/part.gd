extends RigidBody2D

var grid:Grid = Grid.create(Vector2i(8,8), Vector2(30,30));
var force:Vector2 = Vector2(0, -.05)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("click"):
		var keys:Array[int] = grid.pointKey(get_local_mouse_position() + grid.com)
		var key:int = keys[0]
		if key != -1:
			force.y *= -1
			grid.assign(key, (grid.read(key) + 1) % 2)
			queue_redraw()
	apply_force(force.rotated(rotation), (position + Vector2(-5,-5)).rotated(rotation))
	apply_force((force*-1).rotated(rotation), (position + Vector2(5,5)).rotated(rotation))

func _draw():
	for i in grid.area:
		var color:Color = "Red"
		if grid.blocks.read(i) == 1:
			color = "Yellow"
		var point:Vector2 = grid.blockLength*Vector2(grid.decode(i)) - grid.com
		draw_rect(Rect2(point, grid.blockLength), color)
		draw_rect(Rect2(point, grid.blockLength), "black", false, .1)
	print("Draw complete")
