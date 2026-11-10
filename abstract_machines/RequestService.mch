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
    ElevatorRequests

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

    /* Lifecycle operation to be called after the active request has been
       served or cancelled. If the cabin is still moving and no request
       remains, HLR-006 requires it to stop at the next floor. The actual
       stop is performed by stop_at_next_floor when that floor is reached. */
    clear_active_request =
        PRE
            curr_active_request /= NO_REQUEST
        THEN
            curr_active_request := NO_REQUEST ||
            IF
                (curr_state /= rest) &
                ((internal_requests \/ up_requests \/ down_requests) = {})
            THEN
                stop_at_next_floor_requested := TRUE
            ELSE
                stop_at_next_floor_requested := FALSE
            END
        END;

    /* Called by ElevatorControl after the cabin has moved to the next floor.
       change_direction(stop) sets the cabin state to rest. */
    stop_at_next_floor =
        PRE
            stop_at_next_floor_requested = TRUE
        THEN
            change_direction(stop) ||
            stop_at_next_floor_requested := FALSE
        END;

    cancel_internal_hold(ffloor) =
        PRE
            ffloor : internal_requests &
            card(internal_requests) > 1
        THEN
            cancel_internal_by_hold(ffloor)
        END;

    cancel_up_hold(ffloor) =
        PRE
            ffloor : up_requests
        THEN
            cancel_up_by_hold(ffloor)
        END;

    cancel_down_hold(ffloor) =
        PRE
            ffloor : down_requests
        THEN
            cancel_down_by_hold(ffloor)
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
