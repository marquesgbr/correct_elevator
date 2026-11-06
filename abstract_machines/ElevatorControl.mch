MACHINE
	ElevatorControl

SEES ElevatorContext

INCLUDES
	ElevatorTimers

VARIABLES
	control_enabled

INVARIANT
	control_enabled : BOOL &
	(exceeds_capacity = TRUE => curr_state = rest) &
	(maintenance_mode = TRUE => curr_state = rest) &
	(curr_state /= rest => door_state = DOOR_CLOSED)

INITIALISATION
	control_enabled := FALSE

OPERATIONS
	start_control =
	BEGIN
		control_enabled := TRUE
	END;

	stop_control =
	PRE
		curr_state = rest
	THEN
		control_enabled := FALSE
	END;

	system_tick =
	PRE
		control_enabled = TRUE
	THEN
		tick_and_update_displays
	END;

	refresh_indicators =
	BEGIN
		update_displays
	END;

	res <-- can_control_move =
	BEGIN
		IF control_enabled = TRUE &
		   exceeds_capacity = FALSE &
		   maintenance_mode = FALSE &
		   door_state = DOOR_CLOSED THEN
			res := TRUE
		ELSE
			res := FALSE
		END
	END

END
