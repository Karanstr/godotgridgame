extends RigidBody2D

#region Chunk Management

func addChunk(chunkName):
	add_child(ObjectManager.createChunk(chunkName, []))

func updateMass(newMass:int, newCOM:Vector2):
	mass = newMass
	center_of_mass = newCOM

#endregion
#
