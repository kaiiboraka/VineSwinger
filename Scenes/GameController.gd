extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var gameSpeed = 1.0;
onready var debugText = $UILayer/Control/DebugText;
onready var player = $Player;

var chain;
var hook;

# Called when the node enters the scene tree for the first time.
func _ready():
	Engine.time_scale = gameSpeed;
	chain = player.chain;
	hook = chain.hook;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	UpdateDebugText();
	
	
func UpdateDebugText():
	var outText = "Debug Text";
	outText += "\nPlayer State: " + player.PlayerState.keys()[player.currentState];
	outText += "\nChain State: " + chain.ChainState.keys()[chain.currentState];
	outText += "\nHook State: " + str(hook.isHooked);
	debugText.text = outText;
	
