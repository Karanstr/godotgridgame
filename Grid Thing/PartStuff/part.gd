extends RigidBody2D

var grid:Grid = Grid.create(Vector2i(8,8), Vector2(30,30), 2);

func _ready():
	for i in range(grid.dimensions.x):
		if (i != 1):
			grid.assign(i, 1)
	grid.reCacheMeshes([0, 1])
	_updatePhysicsMeshes(1)
	pass

func _process(_delta):
	if Input.is_action_just_pressed("click"):
		var keys:Array[int] = grid.pointToKey(get_local_mouse_position() + grid.com)
		var key:int = keys[0]
		if key != -1:
			var oldVal:int = grid.read(key)
			var newVal:int = 1 if oldVal == 0 else 0;
			grid.assign(key, newVal)
			grid.reCacheMeshes([oldVal, newVal]);
			_updatePhysicsMeshes(1)
			queue_redraw()

func applyBetterForce(force:Vector2, positionRelativeToCom:Vector2):
	apply_force(force.rotated(rotation), position + positionRelativeToCom.rotated(rotation))

func alignMesh(mesh:Rect2i):
	var alignedRect:Rect2 = Rect2(mesh)
	alignedRect.position *= grid.blockLength
	alignedRect.position -= grid.com
	alignedRect.size *= grid.blockLength
	return alignedRect

func _updatePhysicsMeshes(blockType:int):
	get_node("CollisionHead").free()
	var newHead:Node2D = Node2D.new();
	newHead.name = "CollisionHead"
	add_child(newHead)
	var curHead:Node2D = get_node("CollisionHead");
	for mesh in grid.cachedMeshes[blockType]:
		var colBox:CollisionShape2D = _makeColBox(alignMesh(mesh));
		curHead.add_child(colBox)

func _draw():
	for blockMeshes in grid.cachedMeshes.size():
		var color:Color;
		match blockMeshes:
			0: color = "Red"
			1: color = "Yellow"
			2: color = "Green"
			3: color = "Blue"
		for rect in grid.cachedMeshes[blockMeshes].size():
			var alignedRect:Rect2 = alignMesh(grid.cachedMeshes[blockMeshes][rect])
			draw_rect(alignedRect, color)
			draw_rect(alignedRect, "black", false, 1)
	print("Draw complete")

func _makeColBox(rectMesh:Rect2):
	var colShape = CollisionShape2D.new()
	colShape.shape = RectangleShape2D.new()
	colShape.position = rectMesh.position + rectMesh.size/2;
	colShape.shape.size = rectMesh.size;
	return colShape

