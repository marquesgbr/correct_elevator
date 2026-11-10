/* ElevatorMaintenance
 * Author: paulancg
 * Creation date: 05/11/2026
 */
MACHINE
    ElevatorMaintenance

SEES
    ElevatorContext,
    CabinState

VARIABLES
    key_inserted,
    maintenance_mode

INVARIANT
    key_inserted : BOOL &
    maintenance_mode : BOOL &
    (maintenance_mode = TRUE => key_inserted = TRUE)

INITIALISATION
    key_inserted := FALSE ||
    maintenance_mode := FALSE

OPERATIONS

    insert_key =
    PRE
        key_inserted = FALSE
    THEN
        key_inserted := TRUE
    END;

    enter_maintenance =
    PRE
        key_inserted = TRUE &
        maintenance_mode = FALSE &
        curr_state = rest
    THEN
        maintenance_mode := TRUE
    END;

    remove_key =
    PRE
        key_inserted = TRUE &
        curr_state = rest
    THEN
        key_inserted := FALSE ||
        maintenance_mode := FALSE
    END

END
