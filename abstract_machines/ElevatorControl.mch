/* ElevatorControl
 * Creation date: 11/8/26
 *
 * Top-level contract and orchestration machine.
 * Invariants cover HLR-001 through HLR-009. HLR-010 remains a
 * temporal/optimisation property for refinement or model checking.
 */
 
MACHINE
    ElevatorControl

SEES
    ElevatorContext

INCLUDES
    RequestService,
    CabinDoor,
    ElevatorMaintenance,
    ElevatorTimers

CONSTANTS
    panel_direction_of

PROPERTIES
    panel_direction_of : CABIN_STATES --> PANEL_DIR_STATES &
    panel_direction_of =
        {rest |-> panel_dir_inactive} \/
        {moving_up |-> panel_dir_up} \/
        {moving_down |-> panel_dir_down}

VARIABLES
    door_state_changed,
    floor_button_unprocessed,
    dir_button_unprocessed
    


INVARIANT
    
    door_state_changed : BOOL &
    floor_button_unprocessed : FIN(FLOORS) & 
    dir_button_unprocessed : FIN(BUTTONS_IN_FLOORS) &


    /* HLR-001 / HLR-003 / HLR-007: displayed floor and direction. */
    panel_curr_floor = curr_floor &
    (
        (cabin_broken = FALSE => panel_curr_direction = panel_direction_of(curr_state)) &
        (cabin_broken = TRUE  => panel_curr_direction = panel_dir_broken_elevator)
    ) &
    (cabin_broken = TRUE => door_open_timer >= DOOR_OPEN_LIMIT) &

    /* HLR-003: the cabin may only move with the door closed. */
    (curr_state /= rest => door_state = door_closed) &

    /* HLR-004: LED/request correspondence. Blinking is permitted as a
       non-inactive state, but an active LED always implies an active request. */
    !(ffloor).(
        ffloor : FLOORS =>
        (
            (button_floor_led(ffloor) = button_led_active => ffloor : internal_requests) &
            (ffloor : internal_requests => button_floor_led(ffloor) /= button_led_inactive)
        )
    ) &
    !(ffloor).(
        ffloor : MIN_FLOOR..(MAX_FLOOR - 1) =>
        (
            (button_dir_led(ffloor, button_dir_up) = button_led_active => ffloor : up_requests) &
            (ffloor : up_requests => button_dir_led(ffloor, button_dir_up) /= button_led_inactive)
        )
    ) &
    !(ffloor).(
        ffloor : (MIN_FLOOR + 1)..MAX_FLOOR =>
        (
            (button_dir_led(ffloor, button_dir_down) = button_led_active => ffloor : down_requests) &
            (ffloor : down_requests => button_dir_led(ffloor, button_dir_down) /= button_led_inactive)
        )
    ) &

    /* HLR-005: a blinking-to-on internal LED still has its request active. */
    pending_floor_blink_on <: internal_requests &

    /* HLR-006: a pending next-floor stop has no selected request. */
    (stop_at_next_floor_requested = TRUE => curr_active_request = NO_REQUEST) &

    /* HLR-008: maintenance state, request cancellation and warning display. */
    (maintenance_mode = TRUE => curr_state = rest) &
    (maintenance_mode = TRUE => internal_requests = {}) &
    (maintenance_mode = TRUE => up_requests = {}) &
    (maintenance_mode = TRUE => down_requests = {}) &
    (maintenance_indicator = maintenance_mode) &

    /* HLR-009: overweight display and movement prohibition. */
    (excess_weight_indicator = exceeds_capacity) &
    (exceeds_capacity = TRUE => curr_state = rest)

ASSERTIONS
    !(ffloor).(
        ffloor : MIN_FLOOR..(MAX_FLOOR - 1) =>
        (ffloor, button_dir_up) : BUTTONS_IN_FLOORS
    ) &
    !(ffloor).(
        ffloor : (MIN_FLOOR + 1)..MAX_FLOOR =>
        (ffloor, button_dir_down) : BUTTONS_IN_FLOORS
    )

INITIALISATION
    door_state_changed := FALSE ||
    floor_button_unprocessed := {} ||
    dir_button_unprocessed := {}
    

OPERATIONS
    /* Refresh the shared panel display from the cabin state. */
    refresh_display =
        PRE
            cabin_broken = FALSE
        THEN
            update_panel_display(curr_floor, panel_direction_of(curr_state))
        END;

    /* HLR-007: show the broken symbol and latch the broken state together. */
    mark_broken =
        PRE
            cabin_broken = FALSE &
            door_open_timer >= DOOR_OPEN_LIMIT
        THEN
            set_cabin_broken ||
            show_panel_broken
        END;

    /* HLR-007: clear the broken state and restore the normal display. */
    clear_broken =
        PRE
            cabin_broken = TRUE &
            door_open_timer < DOOR_OPEN_LIMIT
        THEN
            unset_cabin_broken ||
            update_panel_display(curr_floor, panel_direction_of(curr_state))
        END;

    /* Time step. Control reads which buttons are pressed and passes the
       active button sets to the timer machine. */
    advance_time =
        PRE
            cabin_broken = FALSE &
            maintenance_mode = FALSE &
            floor_button_unprocessed = {} &
            dir_button_unprocessed = {}
            
        THEN
            tick(
                {bb | bb : BUTTONS_IN_FLOORS &
                        button_dir_press(bb) = button_press &
                        bb : (up_requests * {button_dir_up})}
                \/
                {bb | bb : BUTTONS_IN_FLOORS &
                        button_dir_press(bb) = button_press &
                        bb : (down_requests * {button_dir_down})},
                {ff | ff : FLOORS &
                        button_floor_press(ff) = button_press &
                        ff : internal_requests}
            ) || 
            door_state_changed := FALSE ||
            IF BUTTON_HOLD_LIMIT : ran(button_floor_timer) THEN
                floor_button_unprocessed := 
                floor_button_unprocessed \/ {ff |
                    ff : FLOORS &
                    button_floor_timer(ff) >= BUTTON_HOLD_LIMIT}
            END ||
            IF BUTTON_HOLD_LIMIT : ran(button_dir_timer) THEN
                dir_button_unprocessed := 
                dir_button_unprocessed \/ {bb |
                    bb : BUTTONS_IN_FLOORS &
                    button_dir_timer(bb) >= BUTTON_HOLD_LIMIT}
            END ||
            IF pending_floor_blink_on /= {}  THEN
                complete_floor_led_blink_and_keep_on(min(pending_floor_blink_on))
                END
        END;
        
    

    /* ------------------------------------------------------------------
       Request dispatch and travel.
       ------------------------------------------------------------------ */

    /* Choose the next active request when the cabin is idle. */
    select_request =
        PRE
            curr_active_request = NO_REQUEST &
            stop_at_next_floor_requested = FALSE &
            (internal_requests \/ up_requests \/ down_requests) /= {} &
            curr_state = rest &
            maintenance_mode = FALSE &
            exceeds_capacity = FALSE
        THEN
            select_next_request
        END;

    /* Start moving toward the selected target only with the door closed. */
    start_travel =
        PRE
            curr_active_request /= NO_REQUEST &
            curr_active_request /= curr_floor &
            stop_at_next_floor_requested = FALSE &
            curr_state = rest &
            door_state = door_closed &
            maintenance_mode = FALSE &
            exceeds_capacity = FALSE
        THEN
            IF curr_active_request > curr_floor THEN
                start_moving(up)
            ELSE
                start_moving(down)
            END
        END;

    /* Move one floor while the selected target is still ahead. */
    move_travel =
        PRE
            curr_state /= rest &
            curr_active_request /= NO_REQUEST &
            curr_active_request /= curr_floor &
            stop_at_next_floor_requested = FALSE &
            door_state = door_closed &
            maintenance_mode = FALSE &
            exceeds_capacity = FALSE
        THEN
            move_one_floor
        END;

    /* Stop when the selected target has been reached. */
    stop_at_target =
        PRE
            curr_active_request = curr_floor &
            curr_state /= rest
        THEN
            stop_cabin
        END;

    /* Serve all requests at the selected floor and clear the active target. */
    serve_target =
        PRE
            curr_active_request = curr_floor &
            curr_state = rest
        THEN
            serve_active_request
        END;

    /* HLR-006: after cancelling the active target while moving, stop at the
       next floor in the current direction. */
    advance_to_cancellation_stop =
        PRE
            stop_at_next_floor_requested = TRUE &
            curr_state /= rest &
            door_state = door_closed
        THEN
            stop_at_next_floor
        END;

    /* HLR-009: weight changes update capacity and the excess-weight
       indicator together. Weight is only allowed while stopped. */
    add_passenger_weight(ww) =
        PRE
            ww : NAT &
            ww + curr_weight : NAT &
            curr_state = rest
        THEN
            add_cabin_weight(ww)
        END;

    remove_passenger_weight(ww) =
        PRE
            ww : NAT &
            ww <= curr_weight &
            curr_weight - ww : NAT &
            curr_state = rest
        THEN
            remove_cabin_weight(ww)
        END;

    /* Two-phase internal request: record the press, then register. */
    press_internal(ffloor) =
        PRE
            ffloor : FLOORS &
            maintenance_mode = FALSE &
            button_floor_press(ffloor) = button_released
        THEN
            press_floor_button(ffloor) ||
            floor_button_unprocessed := floor_button_unprocessed \/ {ffloor}
        END;
            
    
    register_internal(ffloor) =
        PRE
            ffloor : FLOORS &
            button_floor_press(ffloor) = button_press &
            button_floor_timer(ffloor) /= BUTTON_HOLD_LIMIT &
            maintenance_mode = FALSE &
            ffloor : floor_button_unprocessed 
        THEN
            register_internal_request(ffloor) ||
            floor_button_unprocessed := floor_button_unprocessed - {ffloor}
        END;

    release_internal(ffloor) =
        PRE
            ffloor : FLOORS &
            ffloor /: floor_button_unprocessed &
            button_floor_press(ffloor) = button_press 
            
        THEN
            release_floor_button(ffloor) ||
            reset_button_floor_timer(ffloor) 
        END;

    /* Two-phase external up request. */
    press_up(ffloor) =
        PRE
            ffloor : MIN_FLOOR..(MAX_FLOOR - 1) &
            maintenance_mode = FALSE &
            button_dir_press(ffloor, button_dir_up) = button_released
        THEN
            press_dir_button(ffloor, button_dir_up) ||
            dir_button_unprocessed := dir_button_unprocessed \/ {(ffloor |-> button_dir_up)}
        END;

    register_up(ffloor) =
        PRE
            ffloor : MIN_FLOOR..(MAX_FLOOR - 1) &
            button_dir_press(ffloor, button_dir_up) = button_press &
            button_dir_timer(ffloor, button_dir_up) /= BUTTON_HOLD_LIMIT &
            maintenance_mode = FALSE &
            (ffloor |-> button_dir_up) : dir_button_unprocessed
        THEN
            register_up_request(ffloor) ||
            dir_button_unprocessed := dir_button_unprocessed - {(ffloor |-> button_dir_up)}
        END;

    release_up(ffloor) =
        PRE
            ffloor : MIN_FLOOR..(MAX_FLOOR - 1) &
            (ffloor |-> button_dir_up) /: dir_button_unprocessed &
            button_dir_press(ffloor, button_dir_up) = button_press
        THEN
            release_dir_button(ffloor, button_dir_up) ||
            reset_button_dir_timer(ffloor, button_dir_up)
        END;

    /* Two-phase external down request. */
    press_down(ffloor) =
        PRE
            ffloor : (MIN_FLOOR + 1)..MAX_FLOOR &
            maintenance_mode = FALSE &
            button_dir_press(ffloor, button_dir_down) = button_released
        THEN
            press_dir_button(ffloor, button_dir_down) ||
            dir_button_unprocessed := dir_button_unprocessed \/ {(ffloor |-> button_dir_down)}
        END;

    register_down(ffloor) =
        PRE
            ffloor : (MIN_FLOOR + 1)..MAX_FLOOR &
            button_dir_press(ffloor, button_dir_down) = button_press &
            button_dir_timer(ffloor, button_dir_down) /= BUTTON_HOLD_LIMIT &
            maintenance_mode = FALSE &
            (ffloor |-> button_dir_down) : dir_button_unprocessed
        THEN
            register_down_request(ffloor) ||
            dir_button_unprocessed := dir_button_unprocessed - {(ffloor |-> button_dir_down)}
        END;

    release_down(ffloor) =
        PRE
            ffloor : (MIN_FLOOR + 1)..MAX_FLOOR &
            (ffloor |-> button_dir_down) /: dir_button_unprocessed &
            button_dir_press(ffloor, button_dir_down) = button_press
        THEN
            release_dir_button(ffloor, button_dir_down) ||
            reset_button_dir_timer(ffloor, button_dir_down)
        END;

    /* HLR-005: cancel a non-last internal request after the hold time. */
    cancel_internal_by_time(ffloor) =
        PRE
            ffloor : FLOORS &
            button_floor_timer(ffloor) = BUTTON_HOLD_LIMIT &
            button_floor_press(ffloor) = button_press &
            maintenance_mode = FALSE &
            ffloor : internal_requests &
            card(internal_requests) > 1 &
            ffloor : floor_button_unprocessed
        THEN
            cancel_internal_hold(ffloor) ||
            reset_button_floor_timer(ffloor) ||
            floor_button_unprocessed := floor_button_unprocessed - {ffloor}
        END;

    /* HLR-005: reject cancellation of the last internal request. */
    reject_last_internal_by_time(ffloor) =
        PRE
            ffloor : FLOORS &
            button_floor_timer(ffloor) = BUTTON_HOLD_LIMIT &
            maintenance_mode = FALSE &
            ffloor : internal_requests &
            card(internal_requests) = 1 &
            ffloor /: pending_floor_blink_on &
            ffloor /: pending_floor_blink_off 
        THEN
            reject_last_internal_hold(ffloor) ||
            reset_button_floor_timer(ffloor) ||
            floor_button_unprocessed := floor_button_unprocessed - {ffloor}
        END;

    /* HLR-005: cancel an external up request after the hold time. */
    cancel_up_by_time(ffloor) =
        PRE
            ffloor : MIN_FLOOR..(MAX_FLOOR - 1) &
            button_dir_timer(ffloor, button_dir_up) = BUTTON_HOLD_LIMIT &
            button_dir_press(ffloor, button_dir_up) = button_press &
            maintenance_mode = FALSE &
            ffloor : up_requests &
            (ffloor |-> button_dir_up) : dir_button_unprocessed
        THEN
            cancel_up_hold(ffloor) ||
            reset_button_dir_timer(ffloor, button_dir_up) ||
            dir_button_unprocessed := dir_button_unprocessed - {(ffloor |-> button_dir_up)}
        END;

    /* HLR-005: cancel an external down request after the hold time. */
    cancel_down_by_time(ffloor) =
        PRE
            ffloor : (MIN_FLOOR + 1)..MAX_FLOOR &
            button_dir_timer(ffloor, button_dir_down) = BUTTON_HOLD_LIMIT &
            button_dir_press(ffloor, button_dir_down) = button_press &
            maintenance_mode = FALSE &
            ffloor : down_requests &
            (ffloor |-> button_dir_down) : dir_button_unprocessed
        THEN
            cancel_down_hold(ffloor) ||
            reset_button_dir_timer(ffloor, button_dir_down) ||
            dir_button_unprocessed := dir_button_unprocessed - {(ffloor |-> button_dir_down)}
        END;

    /* HLR-003: automatic door operations preserve moving => closed. */
    open_door_automatically =
        PRE
            curr_state = rest &
            door_state = door_closed &
            door_state_changed = FALSE
        THEN
            open_automatically ||
            door_state_changed := TRUE
        END;

    close_door_automatically =
        PRE
            door_state = door_open &
            door_state_changed = FALSE
        THEN
            close_automatically ||
            door_state_changed := TRUE
            
        END;

    /* HLR-003: immediate door commands only while the cabin is stopped. */
    open_door_immediately =
        PRE
            curr_state = rest &
            door_state = door_closed &
            button_door_press(button_door_open) = button_press &
            door_state_changed = FALSE
        THEN
            open_immediately ||
            door_state_changed := TRUE
        END;

    close_door_immediately =
        PRE
            curr_state = rest &
            door_state = door_open &
            button_door_press(button_door_close) = button_press &
            door_state_changed = FALSE
        THEN
            close_immediately ||
            door_state_changed := TRUE
        END

END
