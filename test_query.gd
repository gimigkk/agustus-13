extends SceneTree
func _init():
    var query = PhysicsPointQueryParameters2D.new()
    print("Has canvas_instance_id: ", "canvas_instance_id" in query)
    quit()
