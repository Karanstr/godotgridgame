extends RigidBody2D

#Store each chunk as a pointmass, do same thing as we did with chunks and rect pointmasses
var chunkPointMasses:Dictionary = {}

func _process(_delta):
	pass

#region Physics Stuff



#endregion

#region Chunk Management

func addChunk(name):
	add_child(GridFactory.createChunk(name))

func updateMass(newMass:int, newCOM:Vector2):
	mass = newMass
	center_of_mass = newCOM

#endregion
#
