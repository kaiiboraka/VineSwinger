extends Node2D

class_name GameController

export var gameSpeed = 1.0;
onready var debugText = $UILayer/Control/DebugText;
onready var player = $Player;
const debug = false;

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
	if (debug):
		UpdateDebugText();
	
	
func UpdateDebugText():
	debugText.text = "Debug Text";
	AddText(debugText,"Player State: " + player.PlayerState.keys()[player.currentState]);
	AddText(debugText,"Chain State: " + chain.ChainState.keys()[chain.currentState]);
	AddText(debugText,"Hook State: " + str(hook.isHooked));
	AddText(debugText,"Max Chain Length: " + str(chain.linkCount));
	AddText(debugText,"CurrChain Length: " + str(chain.links.size()));
#	for point in chain.points:
#		AddText(debugText, str(point.position));
	for link in chain.links:
		AddText(debugText,"Idx " + str(link.idx) + ": S:" \
		+ str(link.height) + "; H:" + PosAsStr(link.linkHead.position) +\
		 " F:" + PosAsStr(link.linkFeet.position));

func AddText(os, newText):
	os.text += "\n" + newText;
	
func PosAsStr(pos):
	return "(" + str("%0.2f" % pos.x) +", "+ str("%0.2f" % pos.y) + ")";
