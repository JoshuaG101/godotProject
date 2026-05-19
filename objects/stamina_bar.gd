extends ProgressBar
class_name StaminaBar

var change_value_tween: Tween

func setup_bar(max_val: float):
	# Removed modulate.a = 0.0 so it is fully visible from the start
	value = max_val
	max_value = max_val
	$ProgressBar.value = max_val
	$ProgressBar.max_value = max_val
	
func change_value(new_value: float):
	value = new_value
	
	if change_value_tween:
		change_value_tween.kill()
	change_value_tween = create_tween()
	
	# Smoothly animate the underlying catch-up progress bar
	change_value_tween.tween_property($ProgressBar, "value", new_value, 0.35).set_trans(Tween.TRANS_SINE)
