extends RigidBody2D

var grid:Grid = Grid.create(Vector2i(8,8), Vector2(50,50), 2);

func _ready():
	center_of_mass = grid.com 
	for i in range(grid.area):
		grid.assign(i, 1)
	grid.reCacheMeshes([0, 1]); #Initial Caching
	_addPhysicsMeshes(1)
	queue_redraw()
	pass

func _process(_delta):
	if (grid.com != center_of_mass):
		queue_redraw()
		grid.com = center_of_mass
	if Input.is_action_just_pressed("click"):
		var keys:Array[int] = grid.pointToKey(get_local_mouse_position())
		var key:int = keys[0]
		if key != -1:
			var oldVal:int = grid.read(key)
			var newVal:int = 1 if oldVal == 0 else 0;
			grid.assign(key, newVal)
			_updateMeshes([oldVal, newVal])
			queue_redraw()
			applyBetterForce(Vector2(100,0), Vector2(0, -5))
			applyBetterForce(Vector2(100,0), Vector2(0, 5))

func applyBetterForce(force:Vector2, offset:Vector2):
	apply_force(force.rotated(rotation), position + (center_of_mass + offset).rotated(rotation))

func alignMesh(mesh:Rect2i):
	var alignedRect:Rect2 = Rect2(mesh)
	alignedRect.position *= grid.blockLength
	alignedRect.size *= grid.blockLength
	return alignedRect

func _updateMeshes(changedVals:Array[int]):
	for change in changedVals:
		if (change == 1):
			_removePhysicsMeshes(change)
	grid.reCacheMeshes(changedVals);
	for change in changedVals:
		if (change == 1):
			_addPhysicsMeshes(change)

func encodeMeshName(meshNum, blockType):
	return String.num_int64((meshNum << grid.blocks.packSize) + blockType)

func _removePhysicsMeshes(blockType:int):
	for meshNum in grid.cachedMeshes[blockType].size():
		get_node(encodeMeshName(meshNum, blockType)).free()

func _addPhysicsMeshes(blockType:int):
	for meshNum in grid.cachedMeshes[blockType].size():
		var mesh = grid.cachedMeshes[blockType][meshNum]
		var colBox:CollisionShape2D = _makeColBox(alignMesh(mesh));
		colBox.name = encodeMeshName(meshNum, blockType)
		add_child(colBox)

func _draw():
	for blockMeshes in grid.cachedMeshes.size():
		if (blockMeshes != 0):
			var color:Color;
			match blockMeshes:
				1: color = "Yellow"
				2: color = "Green"
				3: color = "Blue"
			for rect in grid.cachedMeshes[blockMeshes].size():
				var alignedRect:Rect2 = alignMesh(grid.cachedMeshes[blockMeshes][rect])
				draw_rect(alignedRect, color)
	draw_rect(Rect2(center_of_mass, grid.length/50), 'blue', true) #Display COM
	print("Draw complete")

func _makeColBox(rectMesh:Rect2):
	var colShape = CollisionShape2D.new();
	colShape.shape = RectangleShape2D.new();
	colShape.position = rectMesh.position + rectMesh.size/2;
	colShape.shape.size = rectMesh.size;
	return colShape
