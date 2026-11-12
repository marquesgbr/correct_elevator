/* ElevatorTimers
 * Author: tomclima
 * Creation date: 11/6/26
 *
 * Owns only timer state. It exposes expiry flags; it does not cancel
 * requests, change panels, or command the cabin. Those reactions belong
 * to ElevatorControl.
 */
MACHINE
    ElevatorTimers
    
SEES
    ElevatorContext,
    CabinDoor,
    ElevatorMaintenance

CONSTANTS
    BUTTON_HOLD_LIMIT,
    DOOR_OPEN_LIMIT

PROPERTIES
    BUTTON_HOLD_LIMIT : INTEGER &
    BUTTON_HOLD_LIMIT = 3 &
    DOOR_OPEN_LIMIT : INTEGER &
    DOOR_OPEN_LIMIT = 120 

VARIABLES
    button_dir_timer,
    button_floor_timer,
    door_open_timer,
    cabin_broken

INVARIANT
    button_dir_timer : BUTTONS_IN_FLOORS --> 0..BUTTON_HOLD_LIMIT &
    button_floor_timer : FLOORS --> 0..BUTTON_HOLD_LIMIT &
    door_open_timer : 0..DOOR_OPEN_LIMIT &
    cabin_broken : BOOL

ASSERTIONS
    dom(button_dir_timer) = BUTTONS_IN_FLOORS &
    dom(button_floor_timer) = FLOORS

INITIALISATION
    button_dir_timer := BUTTONS_IN_FLOORS * {0} ||
    button_floor_timer := FLOORS * {0} ||
    door_open_timer := 0 ||
    cabin_broken := FALSE
    
OPERATIONS
    

    
    
    
    increase_button_dir_timer(ffloor, ddir) =
    PRE
        ffloor : FLOORS &
        ddir : BUTTON_DIR_OPTIONS &
        (ffloor, ddir) : BUTTONS_IN_FLOORS &
        button_dir_timer(ffloor, ddir) < BUTTON_HOLD_LIMIT &
        cabin_broken = FALSE &
        maintenance_mode = FALSE
    THEN
        button_dir_timer(ffloor, ddir) := button_dir_timer(ffloor, ddir) + 1
    END;
    
    
    update_button_dir_timers(active_dir) =
    PRE
        active_dir <: BUTTONS_IN_FLOORS
    THEN
        button_dir_timer :=
            button_dir_timer <+
            %bb.(bb : {xx | xx : active_dir &
                            button_dir_timer(xx) < BUTTON_HOLD_LIMIT} |
                    button_dir_timer(bb) + 1)
    END;

    update_button_floor_timers(active_floor) =
    PRE
        active_floor <: FLOORS
    THEN
        button_floor_timer :=
            button_floor_timer <+
            %ff.(ff : {xx | xx : active_floor &
                            button_floor_timer(xx) < BUTTON_HOLD_LIMIT} |
                    button_floor_timer(ff) + 1)
    END;
    
    increase_button_floor_timer(ffloor) =
    PRE
        ffloor : FLOORS &
        button_floor_timer(ffloor) < BUTTON_HOLD_LIMIT &
        cabin_broken = FALSE &
        maintenance_mode = FALSE
    THEN
        button_floor_timer(ffloor) := button_floor_timer(ffloor) + 1
    END;
    
    reset_button_dir_timer(ffloor, ddir) =
    PRE
        ffloor : FLOORS &
        ddir : BUTTON_DIR_OPTIONS &
        (ffloor, ddir) : BUTTONS_IN_FLOORS
    THEN
        button_dir_timer(ffloor, ddir) := 0
    END;

    reset_button_floor_timer(ffloor) =
    PRE
        ffloor : FLOORS
    THEN
        button_floor_timer(ffloor) := 0
    END;

    /* Used when closing the door: reset the open timer and clear the broken
       latch atomically, even if the old door state is still open. */
    reset_open_door_timer_and_clear_broken =
    BEGIN
        door_open_timer := 0 ||
        cabin_broken := FALSE
    END;
    
    tick(active_dir, active_floor) =
    PRE
        active_dir <: BUTTONS_IN_FLOORS &
        active_floor <: FLOORS &
        cabin_broken = FALSE &
        maintenance_mode = FALSE
    THEN
        button_dir_timer :=
            button_dir_timer <+
            %bb.(bb : {xx | xx : active_dir &
                            button_dir_timer(xx) < BUTTON_HOLD_LIMIT} |
                    button_dir_timer(bb) + 1) ||

        button_floor_timer :=
            button_floor_timer <+
            %ff.(ff : {xx | xx : active_floor &
                            button_floor_timer(xx) < BUTTON_HOLD_LIMIT} |
                    button_floor_timer(ff) + 1) ||

        IF door_state = door_open & door_open_timer < DOOR_OPEN_LIMIT THEN
            door_open_timer := door_open_timer + 1 ||
            IF door_open_timer + 1 >= DOOR_OPEN_LIMIT THEN
                cabin_broken := TRUE
            END
        END
    END;

    set_cabin_broken = 
    PRE
        door_open_timer >= DOOR_OPEN_LIMIT &
        cabin_broken = FALSE
    THEN
        cabin_broken := TRUE
    END;
    
    unset_cabin_broken = 
    PRE
        door_open_timer < DOOR_OPEN_LIMIT &
        cabin_broken = TRUE
    THEN
        cabin_broken := FALSE
        END
    

END