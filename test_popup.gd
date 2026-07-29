extends SceneTree
func _init():
    var popup = preload("res://scenes/ui/letter_popup.tscn").instantiate()
    print("Popup Instantiated")
    quit()
