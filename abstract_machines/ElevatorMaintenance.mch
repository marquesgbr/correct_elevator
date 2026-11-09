/* ElevatorMaintenance
 * Author: paulancg
 * Creation date: 05/11/2026
 */
MACHINE
    ElevatorMaintenance
    
SEES
    ElevatorContext, CabinState, ElevatorRequests
    


VARIABLES
    key_inserted, 
    maintenance_mode
    
INVARIANT
    key_inserted : BOOL & maintenance_mode : BOOL &
    key_inserted = maintenance_mode
INITIALISATION
    key_inserted := FALSE || 
    maintenance_mode := FALSE
    
OPERATIONS
    insert_key =
    PRE
        cabin_state = rest &
        key_inserted = FALSE &
        maintenance_mode = FALSE
    THEN
        key_inserted := TRUE ||
        maintenance_mode := TRUE
        END;
        
    remove_key =
    PRE
        cabin_state = rest &
        key_inserted = TRUE &
        maintenance_mode = TRUE
    THEN
        key_inserted := FALSE ||
        maintenance_mode := FALSE 
        END

END
