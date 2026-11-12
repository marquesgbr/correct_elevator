/* CabinDoor
 * Author: tomclima
 * Creation date: 11/3/26
 */
MACHINE
    CabinDoor

SEES
    CabinState

SETS 
    DOOR_STATES = {door_open, door_closed}

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
            door_state = door_closed
        THEN
            door_state := door_open
        END;

    close_immediately =
        PRE
            curr_state = rest &
            door_state = door_open
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
        END


END
