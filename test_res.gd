extends SceneTree
func _init():
    print("PNG Exists: ", ResourceLoader.exists("res://assets/ui/placeholder_decorated_letter.png"))
    print("File Exists: ", FileAccess.file_exists("res://assets/ui/placeholder_decorated_letter.png"))
    quit()
