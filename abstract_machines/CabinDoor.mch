/* CabinDoor
 * Author: tomclima
 * Creation date: 11/3/26
 */
MACHINE
    CabinDoor

INCLUDES 
    CabinState,
    ElevatorPanels

SETS 
    DOOR_STATES = {door_open, door_closed, door_maintenance}

VARIABLES
    door_state
    
INVARIANT
    door_state : DOOR_STATES

INITIALISATION
    door_state := door_open

OPERATIONS

    /* ---------------------------------------------------------
       Automatic door operations
       --------------------------------------------------------- */

    open_automatically =
        PRE
            curr_state = rest &
            door_state = door_closed
        THEN
            door_state := door_open
        END;

    close_automatically =
        PRE
            door_state = door_open
        THEN
            door_state := door_closed
        END;

    /* ---------------------------------------------------------
       Immediate door operations (HLR-003)

       The cabin state and the door-button state come from the
       INCLUDEd CabinState and ElevatorPanels machines.
       --------------------------------------------------------- */

    open_immediately =
        PRE
            curr_state = rest &
            door_state = door_closed &
            button_door_press(button_door_open) = button_press
        THEN
            door_state := door_open
        END;

    close_immediately =
        PRE
            curr_state = rest &
            door_state = door_open &
            button_door_press(button_door_close) = button_press
        THEN
            door_state := door_closed
        END;

    /* ---------------------------------------------------------
       Maintenance state
       --------------------------------------------------------- */

    enter_door_maintenance =
        PRE
            curr_state = rest &
            door_state = door_closed
        THEN
            door_state := door_maintenance
        END;

    exit_door_maintenance =
        PRE
            door_state = door_maintenance
        THEN
            door_state := door_closed
        END;

    /* ---------------------------------------------------------
       Query operations
       --------------------------------------------------------- */

    res <-- get_door_state =
        BEGIN
            res := door_state
        END;

    res <-- is_door_open =
        BEGIN
            res := bool(door_state = door_open)
        END;

    res <-- is_door_closed =
        BEGIN
            res := bool(door_state = door_closed)
        END;

    res <-- is_door_in_maintenance =
        BEGIN
            res := bool(door_state = door_maintenance)
        END

END
