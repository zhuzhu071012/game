## A Control holding an actionable Dice Roller
@tool
@icon("./dice_roller_control.svg")
class_name DiceRollerControl
extends SubViewportContainer

const dice_roller_scene = preload("../dice_roller/dice_roller.tscn")

var _dice_set: Array[Resource] = []
var _roller_color: Color = Color.DARK_GREEN
var _roller_size := Vector3(9, 12, 5)
var _interactive := true

## The set of dices to be thrown. If empty, a default set will be used.
@export var dice_set: Array[Resource] = []:
	set(new_value):
		_dice_set = new_value.duplicate()
		dice_set = _dice_set
		_apply_runtime_configuration()

## Color of the rolling box
@export var roller_color: Color = Color.DARK_GREEN:
	set(new_value):
		_roller_color = new_value
		roller_color = _roller_color
		_apply_runtime_configuration()

## Box roller size. x and z are width and depth of the floor, y is the ceiling.
##
## Small floors may not let the dices to finnish the roll.
## Big floors make dices look so small.
@export var roller_size := Vector3(9, 12, 5):
	set(new_value):
		_roller_size = new_value
		roller_size = _roller_size
		_apply_runtime_configuration()

## When true user may start a roll by left clicking
## or a quick roll by right clicking
@export var interactive := true:
	set(new_value):
		_interactive = new_value
		interactive = _interactive
		_apply_runtime_configuration()

## Triggered when a roll simumation starts
signal roll_started()
## Triggered once the roll animation finishes
signal roll_finnished(int)

var roller = null
var viewport: SubViewport = null

func _init():
	# Expand the viewport to cover the control
	stretch = true
	_dice_set = dice_set.duplicate()
	_roller_color = roller_color
	_roller_size = roller_size
	_interactive = interactive

func _ready():
	viewport = SubViewport.new()
	viewport.transparent_bg = true
	add_child(viewport)
	roller = dice_roller_scene.instantiate()
	viewport.add_child(roller)
	roller.roll_finnished.connect(
		func(value): roll_finnished.emit(value)
	)
	roller.roll_started.connect(
		func(): roll_started.emit()
	)
	_apply_runtime_configuration()

func _apply_runtime_configuration() -> void:
	if roller == null:
		return
	roller.roller_color = _roller_color
	roller.roller_size = _roller_size
	roller.interactive = _interactive
	roller.dice_set = _dice_set.duplicate()

func configure_runtime(new_dice_set: Array, new_roller_color: Color, new_roller_size: Vector3, new_interactive: bool) -> void:
	_dice_set.clear()
	for dice_def in new_dice_set:
		_dice_set.append(dice_def)
	_roller_color = new_roller_color
	_roller_size = new_roller_size
	_interactive = new_interactive
	dice_set = _dice_set
	roller_color = _roller_color
	roller_size = _roller_size
	interactive = _interactive
	_apply_runtime_configuration()

## Start a physics simulated roll
func roll():
	roller.roll()

## Start a quick roll, that just rotates to a computer generated result
func quick_roll():
	roller.quick_roll()

## Rotate the dices to a externally given result
func show_faces(result: Array[int]):
	roller.show_faces(result)

## Returns a dictionary with individual dice results,
## having dice names as keys
func per_dice_result():
	if not roller:
		return {}
	return roller.per_dice_result()
