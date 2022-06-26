extends Node2D;

class_name Chain

func Variables():
	pass;

onready var player = get_parent();
onready var hook = $Hook;
onready var zelda = $Zelda;

var linkObj = preload("res://Objects/Link.tscn");
var points = [Point.new()];
var links = [Link.new()];
var totalLinkCount = 10; #calculated
export var maxChainLength = 120.0; #overwritten in inspector
var minChainLength;
var currentChainMax;
var currentChainLength;
export var deployDuration = .5;  #overwritten in inspector
export var permLinks = 0;
var deployedLinks = 0;
var timeSinceFired = 0; #calculated
var HOOK = 1;
var HAND = 1;
var DEPLOY = 1;
var RETRACT = -1;

export var offsetX = 24.0;
var playerPos = Vector2(offsetX, 0);

var currentState = ChainState.Ready;

enum ChainState \
{
	Ready,
	Firing,
	Deployed,
	Retracting,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	totalLinkCount = HOOK + ceil((maxChainLength - offsetX - hook.height) / Link.maxHeight);
	
	minChainLength = offsetX + (permLinks * Link.maxHeight) + hook.height;
	currentChainLength = minChainLength;
	hook.hookSpeed = (maxChainLength - minChainLength) / deployDuration;
	permLinks += HOOK;
	
	SetReadyState();
	
	hook.z_index = totalLinkCount;
#	zelda.z_index = totalLinkCount + 1;

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
	hook.CheckHookCollision();
	if(hook.isHooked):
		rotation = GetHookAngle(); 
		ClampPlayer(delta);
	elif(currentState == ChainState.Ready):
		rotation = (get_global_mouse_position() - global_position).angle();
	else:
		var neededRotation = (get_global_mouse_position() - global_position).angle();
		var difference = neededRotation - rotation;
#		rotation = lerp(rotation, neededRotation, (abs(difference) / PI));
		var amount = difference / (2 * PI);
		#TODO: do math
		rotation_degrees += amount;

func ClampPlayer(delta):
	var distFromAnchor = player.global_position - hook.anchorPos;
	distFromAnchor = distFromAnchor.clamped(currentChainLength);
	player.global_position = distFromAnchor + hook.anchorPos;
#	player.move_and_slide(pullForce * Vector2(cos(rotation), sin(rotation)), GetChainDirection());
#	player.move_and_slide(CalcPullForce() * Vector2(cos(rotation), sin(rotation)).normalized(), Vector2(0, -1));

func LerpChain(delta, direction):
	hook.MoveHook(delta, direction);
	currentChainLength += delta * hook.hookSpeed * direction;
	if(currentChainLength < currentChainMax):
		RemoveLink();
	if(currentChainLength > currentChainMax):
		AddLink();
	LerpStep(delta);
	UpdateLinks();

func LerpStep(delta):
	var distBetween = currentChainMax - offsetX - hook.height;
	var stepBetween = 0 if(links.size() == HOOK) else distBetween / (links.size() - HOOK);
	points.back().position = playerPos;
	for i in range(HOOK, points.size() - HAND):
#		points[i].position = Vector2(i * stepBetween, 0);
		points[i].position = lerp(points[i].position, Vector2(i * stepBetween,0), .1);

func DeployChainStep(delta):
	timeSinceFired += delta;
	hook.Disable(false);
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
	points.front().position.x += Link.maxHeight;
	for i in range(points.size() - HOOK, 0, -1):
		points[i].position = points[i - 1].position;
	currentChainLength += Link.maxHeight;
	UpdateLinks();

func AddLink():
	points.back().ChangeLock(false);
	var newPoint = Point.new();
	newPoint.InitPoint(playerPos);
	var link = linkObj.instance();
	link.SetLink(points.back(), newPoint, links.size());
	link.z_index = totalLinkCount - links.size();
	add_child(link);
	points.push_back(newPoint);
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
	for i in range(points.size() - HOOK):
		points[i].position = points[i+1].position;
	currentChainLength -= Link.maxHeight;
	RemoveLink();

func RemoveLink():
	remove_child(links.back());
	links.pop_back();
	points.pop_back();
	points.back().ChangeLock(true);
	points.back().position = playerPos;
	deployedLinks += RETRACT; 
	CalcMaxChainLength();

func InitChain():
# Clear the current chain
	while (links.size() != HOOK):
		RemoveLink();
# Reinitialize Hook as the first link
	hook.Reset(playerPos);
	links = [hook];
	points = [hook.linkHead, hook.linkFeet];
# Add in other permanent links
	for i in range(permLinks - HOOK):
		ForceDeployLink();
# Reassign values
	CalcMaxChainLength();
	currentChainLength = minChainLength;
	deployedLinks = permLinks;

func ReleaseHook():
	hook.Release();

func SetReadyState():
	currentState = ChainState.Ready;
	InitChain();
	GameController.DebugPrint("currentState = Ready");

func SetFiringState():
	timeSinceFired = 0;
	currentState = ChainState.Firing;
	GameController.DebugPrint("currentState = Firing");

func SetDeployedState():
	currentState = ChainState.Deployed;
	GameController.DebugPrint("currentState = Deployed");

func SetRetractState():
	timeSinceFired = 0;
	currentState = ChainState.Retracting;
	GameController.DebugPrint("currentState = Retracting");

func GetChainDirection():
	return (points.front().position - points.back().position).normalized();

func GetHookAngle():
	return (hook.global_position - global_position).angle();

func CalcMaxChainLength():
	currentChainMax = offsetX + ((links.size() - HOOK) * Link.maxHeight) + hook.height;
	if(currentChainMax > maxChainLength):
		currentChainMax = maxChainLength;

func SimulateMotion(delta):
	if(currentState == ChainState.Ready):
		return;
	UpdatePoints(delta);
	for i in range(100):
		UpdateLinks();

func UpdatePoints(delta):
	var downDir = Vector2(sin(rotation), cos(rotation)).normalized();
	for point in points:
		point.Update(delta, downDir);

func UpdateLinks():
	for i in range(links.size()):
		links[i].linkHead = points[i];
		links[i].linkFeet = points[i + 1];
		links[i].Update();
