extends Node

var start = 0;
var now = 0;


# Called when the node enters the scene tree for the first time.
func _ready():
	start = OS.get_unix_time();
	now = OS.get_unix_time();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	now += delta; 
