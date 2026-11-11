/* RequestService
 * Author: tomclima
 * Creation date: 11/5/26
 */
MACHINE
    RequestService

SEES
    ElevatorContext

INCLUDES
    CabinState,
    ElevatorRequests,
    CabinCapacity

PROMOTES
    change_direction,
    move_cabin,
    get_current_floor,
    get_movement_state,
    get_direction,
    is_moving,
    is_stopped,

    update_panel_display,
    show_panel_broken,
    complete_floor_led_blink_and_keep_on,
    press_floor_button,
    release_floor_button,
    press_dir_button,
    release_dir_button,
    press_door_button,
    release_door_button,

    register_internal_request,
    register_up_request,
    register_down_request

CONSTANTS
    NO_REQUEST

PROPERTIES
    NO_REQUEST : INTEGER &
    NO_REQUEST = MIN_FLOOR - 1 &
    NO_REQUEST < MIN_FLOOR

VARIABLES
    curr_active_request,
    sweep_direction,
    stop_at_next_floor_requested

INVARIANT
    sweep_direction : MOVEMENT_DIRECTIONS - {stop} &

    curr_active_request : FLOORS \/ {NO_REQUEST} &

    (curr_active_request /= NO_REQUEST =>
        curr_active_request : (internal_requests \/ up_requests \/ down_requests)) &

    stop_at_next_floor_requested : BOOL &
    (
        stop_at_next_floor_requested = TRUE =>
            curr_active_request = NO_REQUEST
    )

INITIALISATION
    sweep_direction := up ||
    curr_active_request := NO_REQUEST ||
    stop_at_next_floor_requested := FALSE

OPERATIONS

  /*Scan selection*/
    select_next_request =
        PRE
            (internal_requests \/ up_requests \/ down_requests) /= {} &
            curr_active_request = NO_REQUEST &
            stop_at_next_floor_requested = FALSE
        THEN
            ANY
                requests_upwards,
                requests_downwards
            WHERE
                requests_upwards <: FLOORS &
                requests_upwards : FIN(FLOORS) &
                requests_upwards = {req | req : (internal_requests \/ up_requests \/ down_requests) & req >= curr_floor} &
                
                requests_downwards <: FLOORS &
                requests_downwards : FIN(FLOORS) &
                requests_downwards = {req | req : (internal_requests \/ up_requests \/ down_requests) & req <= curr_floor} &
                requests_upwards \/ requests_downwards = (internal_requests \/ up_requests \/ down_requests)
            THEN
                IF sweep_direction = up THEN
                    IF requests_upwards /= {} THEN
                        curr_active_request := min(requests_upwards)
                    ELSE
                        curr_active_request := max(requests_downwards) ||
                        sweep_direction := down
                    END
                ELSE
                    IF requests_downwards /= {} THEN
                        curr_active_request := max(requests_downwards)
                    ELSE
                        curr_active_request := min(requests_upwards) ||
                        sweep_direction := up
                    END
                END
            END
        END;

    /* Motion primitives. Cabin state and panel display are updated in the
       same operation so the display invariant is preserved. */
    start_moving(ddir) =
        PRE
            ddir : MOVEMENT_DIRECTIONS - {stop} &
            curr_state = rest &
            curr_active_request /= NO_REQUEST &
            curr_active_request /= curr_floor &
            stop_at_next_floor_requested = FALSE &
            (ddir = up => curr_floor < MAX_FLOOR) &
            (ddir = down => curr_floor > MIN_FLOOR)
        THEN
            change_direction(ddir) ||
            IF ddir = up THEN
                update_panel_display(curr_floor, panel_dir_up)
            ELSE
                update_panel_display(curr_floor, panel_dir_down)
            END
        END;

    move_one_floor =
        PRE
            ((curr_state = moving_up & curr_floor < MAX_FLOOR) or
             (curr_state = moving_down & curr_floor > MIN_FLOOR)) &
            stop_at_next_floor_requested = FALSE
        THEN
            move_cabin ||
            IF curr_state = moving_up THEN
                IF curr_floor + 1 = MAX_FLOOR THEN
                    update_panel_display(curr_floor + 1, panel_dir_inactive)
                ELSE
                    update_panel_display(curr_floor + 1, panel_dir_up)
                END
            ELSE
                IF curr_floor - 1 = MIN_FLOOR THEN
                    update_panel_display(curr_floor - 1, panel_dir_inactive)
                ELSE
                    update_panel_display(curr_floor - 1, panel_dir_down)
                END
            END
        END;

    stop_cabin =
        PRE
            curr_state /= rest
        THEN
            change_direction(stop) ||
            update_panel_display(curr_floor, panel_dir_inactive)
        END;

    serve_active_request =
        PRE
            curr_active_request /= NO_REQUEST &
            curr_state = rest &
            curr_active_request = curr_floor
        THEN
            serve_floor_requests(curr_active_request) ||
            curr_active_request := NO_REQUEST ||
            stop_at_next_floor_requested := FALSE
        END;

    /* HLR-009: weight updates are only allowed while the cabin is stopped.
       The capacity flag and the internal excess-weight indicator are updated
       in the same operation. */
    add_cabin_weight(ww) =
        PRE
            ww : NAT &
            ww + curr_weight : NAT &
            curr_state = rest
        THEN
            add_weight(ww) ||
            change_excess_weight(bool(curr_weight + ww > MAX_CAPACITY))
        END;

    remove_cabin_weight(ww) =
        PRE
            ww : NAT &
            ww <= curr_weight &
            curr_weight - ww : NAT &
            curr_state = rest
        THEN
            remove_weight(ww) ||
            change_excess_weight(bool(curr_weight - ww > MAX_CAPACITY))
        END;

    /* Lifecycle operation to be called after the active request has been
       served or cancelled. If the cabin is still moving and no request
       remains, HLR-006 requires it to stop at the next floor. The actual
       stop is performed by stop_at_next_floor when that floor is reached. */
    clear_active_request =
        PRE
            curr_active_request /= NO_REQUEST
        THEN
            curr_active_request := NO_REQUEST ||
            IF curr_state /= rest THEN
                stop_at_next_floor_requested := TRUE
            ELSE
                stop_at_next_floor_requested := FALSE
            END
        END;

    /* HLR-006: move exactly one floor and stop there. The panel display is
       updated with the post-move floor. */
    stop_at_next_floor =
        PRE
            stop_at_next_floor_requested = TRUE &
            curr_state /= rest
        THEN
            advance_and_stop ||
            IF curr_state = moving_up THEN
                update_panel_display(curr_floor + 1, panel_dir_inactive)
            ELSE
                update_panel_display(curr_floor - 1, panel_dir_inactive)
            END ||
            stop_at_next_floor_requested := FALSE
        END;

    cancel_internal_hold(ffloor) =
        PRE
            ffloor : internal_requests &
            card(internal_requests) > 1
        THEN
            cancel_internal_by_hold(ffloor) ||
            IF curr_active_request = ffloor THEN
                curr_active_request := NO_REQUEST
            END ||
            IF curr_active_request = ffloor & curr_state /= rest THEN
                stop_at_next_floor_requested := TRUE
            ELSIF curr_active_request = ffloor THEN
                stop_at_next_floor_requested := FALSE
            END
        END;

    cancel_up_hold(ffloor) =
        PRE
            ffloor : up_requests
        THEN
            cancel_up_by_hold(ffloor) ||
            IF curr_active_request = ffloor THEN
                curr_active_request := NO_REQUEST
            END ||
            IF curr_active_request = ffloor & curr_state /= rest THEN
                stop_at_next_floor_requested := TRUE
            ELSIF curr_active_request = ffloor THEN
                stop_at_next_floor_requested := FALSE
            END
        END;

    cancel_down_hold(ffloor) =
        PRE
            ffloor : down_requests
        THEN
            cancel_down_by_hold(ffloor) ||
            IF curr_active_request = ffloor THEN
                curr_active_request := NO_REQUEST
            END ||
            IF curr_active_request = ffloor & curr_state /= rest THEN
                stop_at_next_floor_requested := TRUE
            ELSIF curr_active_request = ffloor THEN
                stop_at_next_floor_requested := FALSE
            END
        END;

    reject_last_internal_hold(ffloor) =
        PRE
            ffloor : internal_requests &
            card(internal_requests) = 1
        THEN
            blink_last_internal_request(ffloor)
        END;

    res <-- get_active_request =
        BEGIN
            res := curr_active_request
        END;

    res <-- get_sweep_direction =
        BEGIN
            res := sweep_direction
        END;

    res <-- should_stop_at_next_floor =
        BEGIN
            res := stop_at_next_floor_requested
        END

END
