extends Node2D;

class_name Chain

func Variables():
	pass;

# Objects/Scene Varaibles
onready var player = get_parent();
onready var hook = player.find_node("Hook");
onready var zelda = $Zelda;
onready var spring = $Spring;
var linkObj = preload("res://Objects/Link.tscn");

# Inspector Variables
export var maxChainLength = 120.0;
export var deployDuration = .5;
export var permLinks = 0;
export var offsetX = 24.0;
export var linkScale = Vector2(0.25, 0.25);
export var hookScale = Vector2(0.25, 0.25);
export var zeldaScale = Vector2(0.75, 0.75);

# Default Variables
var playerPos = Vector2(offsetX, 0);
var currentState = ChainState.Ready;
var maxLinkHeight = 12;
var deployedLinks = 0;
var timeSinceFired = 0; #calculated
var totalLinkCount = 10; #calculated
var minChainLength;
var currentChainMax;
var currentChainLength;
var links = [];

# Constants
const HAND = 1;
const DEPLOY = 1;
const RETRACT = -1;

enum ChainState \
{
	Ready,
	Firing,
	Deployed,
	Retracting,
}

# like Awake() first
func _init():
	pass;

# like Start() second
# Called when the node enters the scene tree for the first time.
func _ready():
	GameController.DebugPrint("Found Hook:" + hook.name);
	hook.scale = hookScale;
	hook.height = (12 * hookScale.x);
	zelda.scale = zeldaScale;
	zelda.position.x = zelda.texture.get_height() * zeldaScale.x;
	maxLinkHeight = 24 * linkScale.x;
	totalLinkCount = ceil((maxChainLength - offsetX) / maxLinkHeight);
	
	minChainLength = offsetX + (permLinks * maxLinkHeight) + hook.height;
	currentChainLength = minChainLength;
	hook.hookSpeed = (maxChainLength - minChainLength) / deployDuration;
	
	spring.node_a = player.get_path();
	spring.node_b = hook.get_path();
	
	SetReadyState();
	
	hook.z_index = totalLinkCount + 1;
#	zelda.z_index = totalLinkCount + 1;

func _draw():
	var inv = get_global_transform().affine_inverse();
	draw_set_transform(inv.get_origin(), inv.get_rotation(), inv.get_scale());

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	UpdateChain(delta);
	SimulateMotion(delta);
	LateUpdate(delta);

func PullTrigger():
	if (currentState == ChainState.Ready):
		SetFiringState();
	else:
		SetRetractState();

func UpdateChain(delta):
	match currentState:
		ChainState.Firing:
			DeployChainStep(delta);
		ChainState.Deployed:
			if (!hook.isHooked):
				SetRetractState();
		ChainState.Retracting:
			RetractChainStep(delta);

func LateUpdate(delta):
	if(hook.isHooked):
		rotation = GetHookAngle(); 
#		ClampPlayer(delta);
	elif(currentState == ChainState.Ready):
		rotation = (get_global_mouse_position() - global_position).angle();
		hook.rotation = rotation;
	else:
		var neededRotation = (get_global_mouse_position() - global_position).angle();
		var difference = neededRotation - rotation;
#		rotation = lerp(rotation, neededRotation, (abs(difference) / PI));
		var amount = difference / (2 * PI);
		#TODO: do math
		rotation_degrees += amount;
		hook.rotation = rotation;

func ClampPlayer(delta):
	var distFromAnchor = player.global_position - hook.anchorPos;
	distFromAnchor = distFromAnchor.clamped(currentChainLength);
	player.global_position = distFromAnchor + hook.anchorPos;
	
func LerpChain(delta, direction):
	currentChainLength += delta * hook.hookSpeed * direction;
	if(currentChainLength < currentChainMax && links.size() > permLinks):
		RemoveLink();
	if(currentChainLength > currentChainMax && links.size() < totalLinkCount):
		AddLink();
	LerpStep(delta);
	UpdateLinks();

func LerpStep(delta):
	if(links.empty()):
		return;
	var distBetween = currentChainMax - offsetX - hook.height;
	var stepBetween = distBetween / links.size();
	links.back().linkFeet.position = playerPos;
	QuantumEntangle();
	for i in range(links.size()):
		links[i].linkHead.position = lerp(links[i].linkHead.position, Vector2(i * stepBetween,0), .1);

func DeployChainStep(delta):
	timeSinceFired += delta;
	if (links.size() < totalLinkCount || currentChainLength < currentChainMax):
		LerpChain(delta, DEPLOY);
	else:
		GameController.DebugPrint("SetDeployState");
		if(!hook.isHooked):
			SetRetractState();
		else:
			SetDeployedState();

func ForceDeployLink():
	AddLink();
	hook.position.x += maxLinkHeight;
	for i in range(links.size() - HAND, -1, -1):
		links[i].linkHead.position = links[i - 1].linkHead.position;
#	points.front().position.x += Link.maxHeight;
#	for i in range(points.size() - HOOK, 0, -1):
#		points[i].position = points[i - 1].position;
	currentChainLength += maxLinkHeight;
	UpdateLinks();

func AddLink():
	var newLinkHeadPt;
	if(links.empty()):
		newLinkHeadPt = Point.new();
		newLinkHeadPt.InitPoint(playerPos);
	else:
		links.back().linkFeet.ChangeLock(false);
		newLinkHeadPt = links.back().linkFeet;
	var newPoint = Point.new();
	newPoint.InitPoint(playerPos);
	var link = linkObj.instance();
	link.scale = linkScale;
	link.SetLink(newLinkHeadPt, newPoint, links.size());
	link.z_index = totalLinkCount - links.size();
	add_child(link);
	links.push_back(link);
	deployedLinks += DEPLOY;
	CalcMaxChainLength();

func RetractChainStep(delta):
	delta *= hook.pullSpeed;
	timeSinceFired += delta;
	if(links.size() != permLinks || currentChainLength >= minChainLength):
		LerpChain(delta, RETRACT);
	else:
		SetReadyState();

func ForceRetractLink():
	for i in range(links.size() - HAND):
		links[i].linkHead.position = links[i+1].linkHead.position;
#	for i in range(points.size() - HOOK):
#		points[i].position = points[i+1].position;
	currentChainLength -= maxLinkHeight;
	RemoveLink();

func RemoveLink():
	remove_child(links.back());
	links.pop_back();
	if(!links.empty()):
		links.back().linkFeet.ChangeLock(true);
		links.back().linkFeet.position = playerPos;
	deployedLinks += RETRACT; 
	CalcMaxChainLength();

func QuantumEntangle():
	links.front().linkHead.position = (hook.global_position - global_position).rotated(-rotation);#Not yet rotated???

# MUST KEEP USED IN PLAYER!!!!
func ReleaseHook():
	hook.Release();

func InitChain():
	hook.Reset(playerPos);
# Clear the current chain
	while (!links.empty()):
		RemoveLink();
# Reinitialize Hook as the first link
	hook.position = playerPos;
	links = [];
# Add in other permanent links
	for i in range(permLinks):
		ForceDeployLink();
# Reassign values
	CalcMaxChainLength();
	currentChainLength = minChainLength;
	deployedLinks = permLinks;

func SetReadyState():
	currentState = ChainState.Ready;
	InitChain();
	GameController.DebugPrint("currentState = Ready");

func SetFiringState():
	timeSinceFired = 0;
	currentState = ChainState.Firing;
	hook.MoveHook(hook.hookSpeed, DEPLOY);
	hook.Disable(false);
	GameController.DebugPrint("currentState = Firing");

func SetDeployedState():
	currentState = ChainState.Deployed;
	GameController.DebugPrint("currentState = Deployed");

func SetRetractState():
	timeSinceFired = 0;
	currentState = ChainState.Retracting;
	hook.MoveHook(hook.pullSpeed, RETRACT);
	GameController.DebugPrint("currentState = Retracting");

func GetChainDirection():
	return (hook.position - links.back().linkFeet.position).normalized();

func GetHookAngle():
	return (hook.global_position - global_position).angle();

func CalcMaxChainLength():
	currentChainMax = offsetX + (links.size() * maxLinkHeight);
	spring.length = currentChainMax;
	if(currentChainMax > maxChainLength):
		currentChainMax = maxChainLength;

func SimulateMotion(delta):
	if(currentState == ChainState.Ready || links.empty()):
		return;
	QuantumEntangle();
#	for i in range(100):
	UpdateLinkPoints(delta);
	UpdateLinks();

func UpdateLinkPoints(delta):
	var downDir = Vector2(sin(rotation), cos(rotation)).normalized();
	links.front().linkHead.Update(delta, downDir);
	for link in links:
		link.linkFeet.Update(delta, downDir);

func UpdateLinks():
	for link in links:
		link.Update();
