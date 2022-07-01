extends Node2D

class_name GameController

export var gameSpeed = 1.0;
onready var debugText = $UILayer/Control/DebugText;
onready var player = $Player;
const debug = true;

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
	debugText.text = "Game Time (x"+str(gameSpeed)+"): " + str("%0.2f" % (Clock.now - Clock.start)) + "s";
	AddText(debugText,"Player State: " + player.PlayerState.keys()[player.currentState]);
	AddText(debugText,"Chain State: " + chain.ChainState.keys()[chain.currentState]);
	AddText(debugText,"Hook State: " + str(hook.isHooked));
	AddText(debugText,"Chain Length [" + str(chain.minChainLength)+", " + str(chain.maxChainLength) + "]: " + str("%0.0f" % chain.currentChainLength)+"/"+str(chain.currentChainMax));
	AddText(debugText,"Link Count: [" + str(chain.links.size()) + "/" + str(chain.totalLinkCount)+"]");
	AddText(debugText,"TimeSinceFired: " + str("%0.2f" % chain.timeSinceFired));
	AddText(debugText,"Rotation: " + str("%0.5f" % chain.rotation) + " [" + str("%4.2f" % chain.rotation_degrees) + "]");
	AddText(debugText);
	var hookNode = get_node(chain.spring.node_a);
	var playerNode = get_node(chain.spring.node_b);
	AddText(debugText, "Chain.spring node_a: " + PosAsStr(hookNode.global_position));
	AddText(debugText);
	#PointPositions(debugText);
	LinkPositions(debugText);
	
func PointPositions(debugText):
	for point in chain.points:
		AddText(debugText, PosAsStr(point.position));

func LinkPositions(debugText):
	for link in chain.links:
		AddText(debugText,"Idx " + str(link.idx) + ": S:" \
		+ str(link.height) + "; H:" + PosAsStr(link.linkHead.position) +\
		 " F:" + PosAsStr(link.linkFeet.position));

static func DebugPrint(string):
	if(debug):
		print("%8.2f" % (Clock.now - Clock.start) +": "+string);

func AddText(os, newText = ""):
	os.text += "\n" + newText;
	
func PosAsStr(pos):
	return "(" + str("%0.2f" % pos.x) +", "+ str("%0.2f" % pos.y) + ")";
