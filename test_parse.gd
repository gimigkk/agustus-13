extends SceneTree
func _init():
    var script = load("res://scripts/letter_manager.gd").new()
    script.load_messages()
    var data = script.get_letter_data(2)
    print("Letter 2 Image Path: ", data.get("image", ""))
    print("FileAccess Exists: ", FileAccess.file_exists(data.get("image", "")))
    print("ResourceLoader Exists: ", ResourceLoader.exists(data.get("image", "")))
    quit()
