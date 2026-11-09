MACHINE
	ElevatorRequests

SEES ElevatorContext

INCLUDES
	ElevatorPanels

/* These panel operations are promoted through the request layer so
	higher-level machines (ElevatorMaintenance and ElevatorControl mainly) can update LEDs, read/write button
	and display states, and complete blink timers. Request state remains
	owned by this machine. */
PROMOTES
	press_dir_button,
	release_dir_button,

	press_floor_button,
	release_floor_button,

	press_door_button,
	release_door_button,

	set_floor_led,
	set_dir_led,
	set_door_led,

	change_excess_weight,
	change_maintenance_indicator,

	blink_floor_led,
	blink_dir_led,
	blink_door_led,
	blink_floor_led_twice_and_switch_off,
	blink_dir_led_twice_and_switch_off,
	blink_floor_led_twice_and_keep_on,

	complete_floor_led_blink,
	complete_floor_led_blink_and_keep_on,
	complete_dir_led_blink,

	all_leds_off,
	clear_all_buttons,

	set_panel_floor,
	set_panel_direction,
	update_panel_display,
	show_panel_broken,
	clear_panel_broken,

	get_panel_floor,
	get_panel_direction,

	is_panel_broken,
	is_dir_button_pressed,
	is_floor_button_pressed,
	is_door_button_pressed,
	
	get_dir_led,
	get_floor_led,
	get_door_led,
	are_all_leds_inactive

VARIABLES
	/* Active requests are kept separately by origin and direction. */
	internal_requests,
	up_requests,
	down_requests

INVARIANT
	/* Request and LED updates are paired in the operations below. */
	internal_requests <: MIN_FLOOR..MAX_FLOOR &
	up_requests <: MIN_FLOOR..(MAX_FLOOR - 1) &
	down_requests <: (MIN_FLOOR + 1)..MAX_FLOOR &
	internal_requests <: FLOORS &
	up_requests <: FLOORS &
	down_requests <: FLOORS

INITIALISATION
	/* No request is active when the system starts. */
	internal_requests := {} ||
	up_requests := {} ||
	down_requests := {}

OPERATIONS

	/* Registration. These are the integration points planned for
	   ElevatorControl: a valid panel event creates a request and activates
	   its corresponding panel LED. */
	register_internal_request(target_floor) =
	PRE
		target_floor : MIN_FLOOR..MAX_FLOOR
	THEN
		internal_requests := internal_requests \/ {target_floor} ||
		set_floor_led(target_floor, button_led_active)
	END;

	register_up_request(target_floor) =
	PRE
		target_floor : MIN_FLOOR..(MAX_FLOOR - 1)
	THEN
		up_requests := up_requests \/ {target_floor} ||
		set_dir_led(target_floor, button_dir_up, button_led_active)
	END;

	register_down_request(target_floor) =
	PRE
		target_floor : (MIN_FLOOR + 1)..MAX_FLOOR
	THEN
		down_requests := down_requests \/ {target_floor} ||
		set_dir_led(target_floor, button_dir_down, button_led_active)
	END;

	/* Service completion. RequestService or ElevatorControl can use these when
	   the cabin reaches the requested floor. The request and LED are cleared
	   together. */
	serve_internal_request(target_floor) =
	PRE
		target_floor : internal_requests
	THEN
		internal_requests := internal_requests - {target_floor} ||
		set_floor_led(target_floor, button_led_inactive)
	END;

	serve_up_request(target_floor) =
	PRE
		target_floor : up_requests
	THEN
		up_requests := up_requests - {target_floor} ||
		set_dir_led(target_floor, button_dir_up, button_led_inactive)
	END;

	serve_down_request(target_floor) =
	PRE
		target_floor : down_requests
	THEN
		down_requests := down_requests - {target_floor} ||
		set_dir_led(target_floor, button_dir_down, button_led_inactive)
	END;

	/* Explicit cancellation. Control logic and maintenance use these when an
	   active request must be removed. */
	cancel_internal_request(target_floor) =
	PRE
		target_floor : internal_requests
	THEN
		internal_requests := internal_requests - {target_floor} ||
		set_floor_led(target_floor, button_led_inactive)
	END;

	cancel_up_request(target_floor) =
	PRE
		target_floor : up_requests
	THEN
		up_requests := up_requests - {target_floor} ||
		set_dir_led(target_floor, button_dir_up, button_led_inactive)
	END;

	cancel_down_request(target_floor) =
	PRE
		target_floor : down_requests
	THEN
		down_requests := down_requests - {target_floor} ||
		set_dir_led(target_floor, button_dir_down, button_led_inactive)
	END;

	/* Hold cancellation. The last internal request is never removed: its LED
	   is blinked and remains active as required by HLR-005. */
	cancel_internal_by_hold(target_floor) =
	PRE
		target_floor : internal_requests &
		card(internal_requests) > 1
	THEN
		internal_requests := internal_requests - {target_floor} ||
		set_floor_led(target_floor, button_led_inactive)
	END;

	blink_last_internal_request(target_floor) =
	PRE
		target_floor : internal_requests &
		card(internal_requests) = 1
	THEN
		blink_floor_led_twice_and_keep_on(target_floor)
	END;

	cancel_up_by_hold(target_floor) =
	PRE
		target_floor : up_requests
	THEN
		up_requests := up_requests - {target_floor} ||
		set_dir_led(target_floor, button_dir_up, button_led_inactive)
	END;

	cancel_down_by_hold(target_floor) =
	PRE
		target_floor : down_requests
	THEN
		down_requests := down_requests - {target_floor} ||
		set_dir_led(target_floor, button_dir_down, button_led_inactive)
	END;

	/* Queries used by RequestService and by ElevatorControl during the
	   planned integration of request selection and movement. */
	res <-- has_active_requests =
	BEGIN
		IF internal_requests /= {} or up_requests /= {} or down_requests /= {} THEN
			res := TRUE
		ELSE
			res := FALSE
		END
	END;

	res <-- has_internal_requests =
	BEGIN
		IF internal_requests /= {} THEN
			res := TRUE
		ELSE
			res := FALSE
		END
	END;

	res <-- has_up_requests =
	BEGIN
		IF up_requests /= {} THEN
			res := TRUE
		ELSE
			res := FALSE
		END
	END;

	res <-- has_down_requests =
	BEGIN
		IF down_requests /= {} THEN
			res := TRUE
		ELSE
			res := FALSE
		END
	END;

	res <-- has_requests_in_direction(curr_fl, ddir) =
	PRE
		curr_fl : FLOORS &
		ddir : BUTTON_DIR_OPTIONS
	THEN
		IF ddir = button_dir_up THEN
			res := bool(
 				(internal_requests \/ up_requests) /\ ((curr_fl + 1)..MAX_FLOOR) /= {}
 			)
		ELSE
			res := bool(
				(internal_requests \/ down_requests) /\ (MIN_FLOOR..(curr_fl - 1)) /= {}
			)
		END
	END;

	/* Maintenance reset. It removes every active request and turns off every
	   panel LED in one operation. */
	cancel_all_requests =
	BEGIN
		internal_requests := {} ||
		up_requests := {} ||
		down_requests := {} ||
		all_leds_off
	END

END
