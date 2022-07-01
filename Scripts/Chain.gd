extends Node2D;

class_name Chain

func Variables():
	pass;

# Objects/Scene Varaibles
onready var player = get_parent();
onready var hook = $Hook;
onready var zelda = $Zelda;
onready var spring = $Spring;
var linkObj = preload("res://Objects/Link.tscn");

# Inspector Variables
export var maxChainLength = 200.0;
export var deployDuration = .2;
export var retractDuration = .2;
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
var links = [Link.new()];

# Constants
const HOOK = 1;
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
	hook.scale = hookScale;
	hook.height = (12 * hookScale.x);
	zelda.scale = zeldaScale;
	zelda.position.x = zelda.texture.get_height() * zeldaScale.x;
	maxLinkHeight = 24 * linkScale.x;
	totalLinkCount = HOOK + ceil((maxChainLength - offsetX - hook.height) / maxLinkHeight);
	
	minChainLength = offsetX + (permLinks * maxLinkHeight) + hook.height;
	currentChainLength = minChainLength;
	hook.hookSpeed = (maxChainLength - minChainLength) / deployDuration;
	hook.pullSpeed = (maxChainLength - minChainLength) / retractDuration;
	permLinks += HOOK;
	
	spring.node_b = hook.kb2d.get_path();
	spring.node_a = player.get_path();
	
	SetReadyState();
	
	hook.z_index = totalLinkCount;
#	zelda.z_index = totalLinkCount + 1;

func _draw():
	var inv = get_global_transform().affine_inverse();
	draw_set_transform(inv.get_origin(), inv.get_rotation(), inv.get_scale());

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	UpdateChain(delta);
	SimulateMotion(delta);
	LateUpdate(delta);
	update();

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
	currentChainLength += delta * direction;
	if(currentChainLength < currentChainMax && links.size() > permLinks):
		RemoveLink();
	if(currentChainLength > currentChainMax && links.size() < totalLinkCount):
		AddLink();
	LerpStep(delta);
	UpdateLinks();

func LerpStep(delta):
	var distBetween = currentChainMax - offsetX - hook.height;
	var stepBetween = 0 if(links.size() == HOOK) else distBetween / (links.size() - HOOK);
	links.back().linkFeet.position = playerPos;
	for i in range(links.size() - HAND):
#		links[i].linkFeet.position = Vector2(i * stepBetween, 0);
		links[i].linkFeet.position = lerp(links[i].linkFeet.position, Vector2(i * stepBetween,0), .1);

func DeployChainStep(delta):
	delta *= hook.hookSpeed;
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
	hook.linkHead.position.x += maxLinkHeight;
	for i in range(links.size() - HOOK, 0, -1):
		links[i].linkHead.position = links[i - 1].linkHead.position;
#	points.front().position.x += Link.maxHeight;
#	for i in range(points.size() - HOOK, 0, -1):
#		points[i].position = points[i - 1].position;
	currentChainLength += maxLinkHeight;
	UpdateLinks();

func AddLink():
	links.back().linkFeet.ChangeLock(false);
	var newPoint = Point.new();
	newPoint.InitPoint(playerPos);
	var link = linkObj.instance();
	link.scale = linkScale;
	link.SetLink(links.back().linkFeet, newPoint, links.size());
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
	links.back().linkFeet.ChangeLock(true);
	links.back().linkFeet.position = playerPos;
	deployedLinks += RETRACT; 
	CalcMaxChainLength();

func InitChain():
# Clear the current chain
	while (links.size() != HOOK):
		RemoveLink();
# Reinitialize Hook as the first link
	hook.Reset(playerPos);
	links = [hook];
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
	return (links.front().linkHead.position - links.back().linkFeet.position).normalized();

func GetHookAngle():
	return (hook.global_position - global_position).angle();

func CalcMaxChainLength():
	currentChainMax = offsetX + ((links.size() - HOOK) * maxLinkHeight
	) + hook.height;
	if(currentChainMax > maxChainLength):
		currentChainMax = maxChainLength;

func SimulateMotion(delta):
	if(currentState == ChainState.Ready):
		return;
	UpdateLinkPoints(delta);
	for i in range(100):
		UpdateLinks();

func UpdateLinkPoints(delta):
	var downDir = Vector2(sin(rotation), cos(rotation)).normalized();
	links.front().linkHead.Update(delta, downDir);
	for link in links:
		link.linkFeet.Update(delta, downDir);

func UpdateLinks():
	for i in range(links.size()):
#		links[i].linkHead = points[i];
#		links[i].linkFeet = points[i + 1];
		links[i].Update();
