extends Node2D;

class_name Chain
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var linkObj = preload("res://Objects/Link.tscn");
var points = [Point.new()];
var links = [Link.new()];
var linkCount = 10; #calculated
export var chainLength = 120; #overwritten in inspector
export var deployDuration = .5;  #overwritten in inspector
export var trailingLinks = 1;  #overwritten in inspector
var timeSinceFired = 0; #calculated

onready var player = get_parent();
onready var hook = $Hook;
onready var zelda = $Zelda;
const playerPos = Vector2(12, 0);

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
	hook.hookSpeed = chainLength / deployDuration;
	linkCount = ceil((chainLength - playerPos.x) / Link.maxHeight);
	trailingLinks += 1;
	SetReadyState();
#	zelda.z_index = linkCount + 1;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	UpdateChain(delta);
	SimulateMotion(delta);
	LateUpdate(delta);


func UpdateChain(delta):
	match currentState:
		ChainState.Firing:
			FireChainStep(delta);
		ChainState.Deployed:
			if (!hook.isHooked):
				SetRetractState();
				timeSinceFired = 0;
		ChainState.Retracting:
			PullChainStep(delta);
			
func LateUpdate(delta):
	hook.CheckHookCollision();
	if(hook.isHooked):
		rotation = GetHookAngle(); 
		ClampPlayer(delta);
	else:#if(currentState == ChainState.Ready):
		rotation = (get_global_mouse_position() - global_position).angle();

func PullTrigger():
	timeSinceFired = 0;
	if (currentState == ChainState.Ready):
		SetShootState();
	else:
		SetRetractState();

func FireChainStep(delta):
	timeSinceFired += delta;
	hook.ShootHook(delta);
	if(timeSinceFired >= (deployDuration / linkCount) * (links.size() - trailingLinks)):
		if(links.size() < linkCount):
			DeployLink();
		else:
			SetDeployedState();

func PullChainStep(delta):
	timeSinceFired += delta;
	
	if (!hook.isHooked):
#		player.move_and_slide(pullForce * Vector2(cos(rotation), sin(rotation)), GetChainDirection());
#		player.move_and_slide(CalcPullForce() * Vector2(cos(rotation), sin(rotation)).normalized(), Vector2(0, -1));
#	else:
		ReleaseHook();
	
	if(timeSinceFired >= (deployDuration / linkCount) * (linkCount - links.size() - trailingLinks)):
		if(links.size() != trailingLinks):
			RetractLink();
		else:
			SetReadyState();
	
func ClampPlayer(delta):
	var distFromAnchor = player.global_position - hook.anchorPos;
	#d=
	var currMax = Link.maxHeight * links.size();
	distFromAnchor = distFromAnchor.clamped(currMax);
	player.global_position = distFromAnchor + hook.anchorPos;
	#player.global_position = points.back().global_position;
#	var anchorAngle = Vector2(cos(rotation), sin(rotation)).normalized();
#	if (distFromAnchor > GetMaxChainLength()):
#		player.move_and_slide(distFromAnchor  * anchorAngle * 10, Vector2(0, -1));

func RetractLink():
	for i in range(points.size() - 1):
		points[i].position = points[i+1].position;
	RemoveLink();
	if(links.size() == trailingLinks):
		SetReadyState();
	UpdateLinks();

func RemoveLink():
	remove_child(links.back());
	links.pop_back();
	points.pop_back();
	points.back().ChangeLock(true);
	points.back().position = playerPos;

func DeployLink():
	points.back().ChangeLock(false); #on 0,back is the hook
	var i = points.size() - 1;
	while(i > 0):
		points[i].position = points[i - 1].position;
		i -= 1;
	points.front().position.x += Link.maxHeight;
	AddLink();
	UpdateLinks();

func AddLink():
	var newPoint = Point.new();
	newPoint.InitPoint(playerPos + Vector2.ZERO);
	var link = linkObj.instance();
	link.SetLink(points.back(), newPoint, links.size());
	link.z_index = linkCount - links.size();
	add_child(link);
	points.push_back(newPoint);
	links.push_back(link);
	

func GetChainDirection():
	return (points.front().position - points.back().position).normalized();

func GetHookAngle():
	return (hook.global_position - global_position).angle()

func SetReadyState():
	while (links.size() != 1):
		RemoveLink();
	currentState = ChainState.Ready;
	var hookPos = Vector2(playerPos.x + hook.height, playerPos.y);
	hook.linkHead.InitPoint(hookPos);
	hook.idx = 0;
	hook.linkFeet.InitPoint(playerPos);
	hook.rotation = 0;
	hook.position = hook.GetCenter();#Vector2(zelda.texture.get_height() + (hook.height / 2),0);
	links = [hook];
	points = [hook.linkHead, hook.linkFeet];
	for i in range(trailingLinks - 1):
		DeployLink();
	hook.z_index = linkCount;
	hook.Release();

func SetShootState():
	currentState = ChainState.Firing;

func SetDeployedState():
	currentState = ChainState.Deployed;

func SetRetractState():
	currentState = ChainState.Retracting;

func ReleaseHook():
	hook.Release();
	
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
