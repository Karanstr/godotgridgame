extends RigidBody2D

var grid:Grid = Grid.create(Vector2i(8,8), Vector2(30,30));
var force:Vector2 = Vector2(0, -.05);

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(grid.dimensions.x):
		grid.assign(i, 1)
		add_child(_makeColBox(i, grid.blockLength))
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("click"):
		var keys:Array[int] = grid.pointKey(get_local_mouse_position() + grid.com)
		var key:int = keys[0]
		if key != -1:
			force.y *= -1
			var newVal:int = (grid.read(key) + 1) % 2;
			if newVal == 1:
				add_child(_makeColBox(key, grid.blockLength))
			else:
				get_node(String.num_int64(key)).queue_free()
			grid.assign(key, newVal)
			print(grid._rowToBits(0, [0,1]))
			queue_redraw()
	#apply_force(force.rotated(rotation), (position + Vector2(-5,-5)).rotated(rotation))
	#apply_force((force*-1).rotated(rotation), (position + Vector2(5,5)).rotated(rotation))

func _draw():
	for i in grid.area:
		var color:Color = "Red"
		var rect:Rect2 = _makeRectFromKey(i, grid.blockLength)
		if grid.blocks.read(i) == 1:
			color = "Yellow"
		draw_rect(rect, color)
		draw_rect(rect, "black", false, .1)
	print("Draw complete")

func _keyToPoint(key):
	return grid.blockLength*Vector2(grid.decode(key)) - grid.com

func _makeRectFromKey(key, size):
	return Rect2(_keyToPoint(key), size)

func _makeColBox(key:int, size:Vector2):
	var colShape = CollisionShape2D.new()
	colShape.shape = RectangleShape2D.new()
	colShape.position = _keyToPoint(key) + size/2;
	colShape.shape.size = size;
	colShape.name = String.num_int64(key);
	return colShape
