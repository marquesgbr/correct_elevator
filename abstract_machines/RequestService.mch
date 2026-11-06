/* RequestService
 * Author: tomclima
 * Creation date: 11/5/26
 */
MACHINE
    RequestService

INCLUDES 
    CabinState, ElevatorRequests

CONSTANTS
    NO_REQUEST
PROPERTIES
    NO_REQUEST = -1 

VARIABLES
    curr_active_request,
    sweep_direction

INVARIANT
    sweep_direction : MOVEMENT_DIRECTIONS - {stop} &
    curr_active_request : (internal_requests \/ up_requests \/ down_requests) \/ {NO_REQUEST}
    
INITIALISATION
    sweep_direction := up ||
    curr_active_request := NO_REQUEST
    
OPERATIONS
     select_next_request =
    PRE
        (internal_requests \/ up_requests \/ down_requests) /= {} &
        curr_active_request = NO_REQUEST
    THEN
        ANY
            requests_upwards,
            requests_downwards
        WHERE
            requests_upwards <: (internal_requests \/ up_requests \/ down_requests) &
            requests_upwards = {req | req : (internal_requests \/ up_requests \/ down_requests) & req >= curr_floor} &
            requests_downwards <: (internal_requests \/ up_requests \/ down_requests) &
            requests_downwards = {req | req : (internal_requests \/ up_requests \/ down_requests) & req >= curr_floor}
        THEN
            IF sweep_direction = up  THEN
                IF requests_upwards /= {} THEN
                    curr_active_request := min(requests_upwards)
                ELSE
                    curr_active_request := max(requests_downwards) ||
                    sweep_direction := down
                END
            
            ELSIF sweep_direction = down  THEN
                IF requests_downwards /= {} THEN
                    curr_active_request := max(requests_downwards)
                ELSE
                    curr_active_request := min(requests_upwards) ||
                    sweep_direction := up
                END
            END
        END
    END
    

   
    
    
    
END
