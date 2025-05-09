@tool
class_name __OProjectSettings__
extends Node

static func create_settings() -> void:
	if not ProjectSettings.has_setting("OsirisasUiExtension/toast/duration"):
		ProjectSettings.set_setting("OsirisasUiExtension/toast/duration", 1.8)
		ProjectSettings.set_initial_value("OsirisasUiExtension/toast/duration", 1.8)
		ProjectSettings.add_property_info({
			"name": "OsirisasUiExtension/toast/duration",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.1,10.0,0.1",
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_EDITOR_BASIC_SETTING
		})
	
	if not ProjectSettings.has_setting("OsirisasUiExtension/toast/enabled"):
		ProjectSettings.set_setting("OsirisasUiExtension/toast/enabled", true)
		ProjectSettings.set_initial_value("OsirisasUiExtension/toast/enabled", true)
		ProjectSettings.add_property_info({
			"name": "OsirisasUiExtension/toast/enabled",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_EDITOR_BASIC_SETTING
		})
	
	ProjectSettings.save()
