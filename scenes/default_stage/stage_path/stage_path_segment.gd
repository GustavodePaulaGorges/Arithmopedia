class_name StagePathSegment
extends Resource

enum Kind { LINEAR, BIFURCATION }

@export var kind: Kind = Kind.LINEAR
@export var path: NodePath = NodePath("")
@export var top_path: NodePath = NodePath("")
@export var bottom_path: NodePath = NodePath("")
