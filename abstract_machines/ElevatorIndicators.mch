MACHINE
	ElevatorIndicators

SEES ElevatorContext

INCLUDES
	CabinCapacity,
	ElevatorMaintenance

PROMOTES
	complete_floor_led_blink,
	complete_floor_led_blink_and_keep_on,
	complete_dir_led_blink,
	open_automatically,
	finish_opening,
	close_automatically,
	finish_closing,
	open_immediately,
	close_immediately,
	reset_immediate_commands,
	is_door_open,
	is_door_closed,
	select_next_request,
	has_selected_request,
	is_overweight,
	can_move

SETS
	DISPLAY_DIRECTIONS = {display_up, display_down, display_stop}

VARIABLES
	internal_display_floor,
	internal_display_direction,
	internal_overweight_indicator,
	internal_maintenance_indicator,
	internal_stopped_indicator,
	internal_broken_indicator,
	external_display_floor,
	external_display_direction,
	external_maintenance_indicator,
	external_stopped_indicator,
	external_broken_indicator

INVARIANT
	internal_display_floor : MIN_FLOOR..MAX_FLOOR &
	internal_display_direction : DISPLAY_DIRECTIONS &
	internal_overweight_indicator : BOOL &
	internal_maintenance_indicator : BOOL &
	internal_stopped_indicator : BOOL &
	internal_broken_indicator : BOOL &
	external_display_floor : MIN_FLOOR..MAX_FLOOR &
	external_display_direction : DISPLAY_DIRECTIONS &
	external_maintenance_indicator : BOOL &
	external_stopped_indicator : BOOL &
	external_broken_indicator : BOOL &
	(internal_display_floor = curr_floor) &
	(external_display_floor = curr_floor) &
	(internal_overweight_indicator = exceeds_capacity) &
	(internal_maintenance_indicator = maintenance_mode)

INITIALISATION
	internal_display_floor := MIN_FLOOR ||
	internal_display_direction := display_stop ||
	internal_overweight_indicator := FALSE ||
	internal_maintenance_indicator := FALSE ||
	internal_stopped_indicator := TRUE ||
	internal_broken_indicator := FALSE ||
	external_display_floor := MIN_FLOOR ||
	external_display_direction := display_stop ||
	external_maintenance_indicator := FALSE ||
	external_stopped_indicator := TRUE ||
	external_broken_indicator := FALSE

OPERATIONS
	update_displays =
	BEGIN
		internal_display_floor := curr_floor ||
		external_display_floor := curr_floor ||
		internal_overweight_indicator := exceeds_capacity ||
		internal_maintenance_indicator := maintenance_mode ||
		external_maintenance_indicator := maintenance_mode ||
		IF curr_state = moving_up THEN
			internal_display_direction := display_up ||
			external_display_direction := display_up ||
			internal_stopped_indicator := FALSE ||
			external_stopped_indicator := FALSE
		ELSIF curr_state = moving_down THEN
			internal_display_direction := display_down ||
			external_display_direction := display_down ||
			internal_stopped_indicator := FALSE ||
			external_stopped_indicator := FALSE
		ELSE
			internal_display_direction := display_stop ||
			external_display_direction := display_stop ||
			internal_stopped_indicator := TRUE ||
			external_stopped_indicator := TRUE
		END
	END;

	show_overweight =
	PRE
		exceeds_capacity = TRUE
	THEN
		internal_overweight_indicator := TRUE
	END;

	hide_overweight =
	PRE
		exceeds_capacity = FALSE
	THEN
		internal_overweight_indicator := FALSE
	END;

	show_maintenance =
	PRE
		maintenance_mode = TRUE
	THEN
		internal_maintenance_indicator := TRUE ||
		external_maintenance_indicator := TRUE
	END;

	hide_maintenance =
	PRE
		maintenance_mode = FALSE
	THEN
		internal_maintenance_indicator := FALSE ||
		external_maintenance_indicator := FALSE
	END;

	show_stopped_or_broken =
	BEGIN
		external_stopped_indicator := TRUE ||
		external_broken_indicator := TRUE
	END;

	hide_stopped_or_broken =
	BEGIN
		external_stopped_indicator := FALSE ||
		external_broken_indicator := FALSE
	END

END
