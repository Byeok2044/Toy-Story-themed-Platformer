extends ProgressBar

# This function will be called by the Boss's signal
func _on_boss_health_changed(current_health: int, max_health: int) -> void:
	self.max_value = max_health
	self.value = current_health
