/* ElevatorMaintenance
 * Author: paulancg
 * Creation date: 05/11/2026
 */
MACHINE
    ElevatorMaintenance
    
SEES
    ElevatorContext
    
INCLUDES
    CabinState, ElevatorRequests

VARIABLES
    key_inserted, 
    maintanance_mode
    
INVARIANT
    key_inserted : BOOL & maintanance_mode : BOOL &
    (maintanance_mode = TRUE => internal_requests = {} & up_requests = {} & down_requests = {}) &    
    (maintanance_mode = TRUE => panel_curr_direction = panel_dir_inactive & panel_curr_floor = -1)
INITIALISATION
    key_inserted := FALSE || 
    maintanance_mode := FALSE
END
