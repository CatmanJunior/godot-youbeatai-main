extends Sprite2D

@onready var viewport_container: SubViewportContainer = $SubViewportContainer
@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var animation_tree: AnimationTree = $SubViewportContainer/SubViewport/Klappy/model/AnimationTree

var _lightweight: bool = false
var _elapsed: float = 0.0
var _normal_materials: Dictionary[MeshInstance3D, Array] = {}
var _light_materials: Dictionary[MeshInstance3D, Array] = {}

func _ready() -> void:
	EventBus.performance_quality_changed.connect(_on_quality_changed)
	visibility_changed.connect(_on_visibility_changed)
	_on_quality_changed(GameState.lightweight_graphics)
	_on_visibility_changed()

func _process(delta: float) -> void:
	if not _lightweight or not is_visible_in_tree():
		return
	_elapsed += delta
	if _elapsed >= 1.0 / 30.0:
		_elapsed = fmod(_elapsed, 1.0 / 30.0)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _on_quality_changed(lightweight: bool) -> void:
	_lightweight = lightweight
	viewport_container.stretch_shrink = 2 if lightweight else 1
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if lightweight else SubViewport.UPDATE_WHEN_VISIBLE
	if lightweight and _light_materials.is_empty():
		_cache_materials()
	for mesh: MeshInstance3D in _normal_materials:
		var materials: Array = _light_materials[mesh] if lightweight else _normal_materials[mesh]
		for surface: int in range(materials.size()):
			mesh.set_surface_override_material(surface, materials[surface])

func _on_visibility_changed() -> void:
	animation_tree.active = is_visible_in_tree()
	if not is_visible_in_tree():
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	elif not _lightweight:
		viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE

func _cache_materials() -> void:
	for node: Node in viewport.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var normal: Array[Material] = []
		var light: Array[Material] = []
		for surface: int in range(mesh.get_surface_override_material_count()):
			var material: Material = mesh.get_surface_override_material(surface)
			normal.append(material)
			var cheaper: Material = material
			if material is StandardMaterial3D:
				var copy: StandardMaterial3D = material.duplicate() as StandardMaterial3D
				copy.normal_enabled = false
				copy.ao_enabled = false
				copy.heightmap_enabled = false
				cheaper = copy
			light.append(cheaper)
		_normal_materials[mesh] = normal
		_light_materials[mesh] = light
