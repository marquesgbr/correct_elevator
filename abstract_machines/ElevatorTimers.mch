MACHINE
	ElevatorTimers

SEES ElevatorContext

INCLUDES
	ElevatorIndicators

PROMOTES
	update_displays,
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

VARIABLES
	button_hold_timer,
	door_open_timer,
	signal_timer,
	button_hold_active,
	door_open_active,
	signal_active,
	button_hold_expired,
	door_open_expired

INVARIANT
	button_hold_timer : 0..3 &
	door_open_timer : 0..120 &
	signal_timer : 0..2 &
	button_hold_active : BOOL &
	door_open_active : BOOL &
	signal_active : BOOL &
	button_hold_expired : BOOL &
	door_open_expired : BOOL

INITIALISATION
	button_hold_timer := 0 ||
	door_open_timer := 0 ||
	signal_timer := 0 ||
	button_hold_active := FALSE ||
	door_open_active := FALSE ||
	signal_active := FALSE ||
	button_hold_expired := FALSE ||
	door_open_expired := FALSE

OPERATIONS

	/* Timer-facing completion operations. The pending sets are owned by
	   ElevatorPanels; the timer only decides when a pending blink finishes. */
	complete_pending_floor_blink(ffloor) =
	PRE
		ffloor : FLOORS &
		ffloor : pending_floor_blink_off
	THEN
		complete_floor_led_blink(ffloor)
	END;

	complete_pending_floor_blink_and_keep_on(ffloor) =
	PRE
		ffloor : FLOORS &
		ffloor : pending_floor_blink_on
	THEN
		complete_floor_led_blink_and_keep_on(ffloor)
	END;

	complete_pending_dir_blink(ffloor, ddir) =
	PRE
		ffloor : FLOORS &
		ddir : BUTTON_DIR_OPTIONS &
		(ffloor, ddir) : BUTTONS_IN_FLOORS &
		(ffloor, ddir) : pending_dir_blink_off &
		(ddir = button_dir_up => ffloor < MAX_FLOOR) &
		(ddir = button_dir_down => ffloor > MIN_FLOOR)
	THEN
		complete_dir_led_blink(ffloor, ddir)
	END;
	tick =
	BEGIN
		IF button_hold_active = TRUE & button_hold_timer < 3 THEN
			button_hold_timer := button_hold_timer + 1
		END ||
		IF door_open_active = TRUE & door_open_timer < 120 THEN
			door_open_timer := door_open_timer + 1
		END ||
		IF signal_active = TRUE & signal_timer < 2 THEN
			signal_timer := signal_timer + 1
		END
	END;

	tick_and_update_displays =
	BEGIN
		IF button_hold_active = TRUE & button_hold_timer < 3 THEN
			button_hold_timer := button_hold_timer + 1
		END ||
		IF door_open_active = TRUE & door_open_timer < 120 THEN
			door_open_timer := door_open_timer + 1
		END ||
		IF signal_active = TRUE & signal_timer < 2 THEN
			signal_timer := signal_timer + 1
		END ||
		update_displays
	END;

	start_button_hold_timer =
	BEGIN
		button_hold_timer := 0 ||
		button_hold_active := TRUE ||
		button_hold_expired := FALSE
	END;

	stop_button_hold_timer =
	BEGIN
		button_hold_timer := 0 ||
		button_hold_active := FALSE
	END;

	expire_button_hold_timer =
	PRE
		button_hold_active = TRUE &
		button_hold_timer = 3
	THEN
		button_hold_active := FALSE ||
		button_hold_expired := TRUE
	END;

	start_door_open_timer =
	BEGIN
		door_open_timer := 0 ||
		door_open_active := TRUE ||
		door_open_expired := FALSE
	END;

	stop_door_open_timer =
	BEGIN
		door_open_timer := 0 ||
		door_open_active := FALSE
	END;

	expire_door_open_timer =
	PRE
		door_open_active = TRUE &
		door_open_timer = 120
	THEN
		door_open_active := FALSE ||
		door_open_expired := TRUE ||
		show_stopped_or_broken
	END;

	start_signal_timer =
	BEGIN
		signal_timer := 0 ||
		signal_active := TRUE
	END;

	stop_signal_timer =
	BEGIN
		signal_timer := 0 ||
		signal_active := FALSE
	END;

	blink_led_twice =
	BEGIN
		signal_timer := 0 ||
		signal_active := TRUE
	END;

	res <-- is_button_hold_expired =
	BEGIN
		res := button_hold_expired
	END;

	res <-- is_door_timer_expired =
	BEGIN
		res := door_open_expired
	END

END
