/* ElevatorRequests
 * Author: tomclima
 * Creation date: 11/3/26
 */
MACHINE
    ElevatorRequests

INCLUDES
    ElevatorPanels
    
SETS
    IMMEDIATE_REQUESTS = {request_close, request_open, request_none};

    REQUEST_DIRECTIONS = {request_up, request_down, request_same}
    
CONSTANTS
    FLOOR_REQUEST

PROPERTIES
    FLOOR_REQUEST = FLOORS * FLOORS * REQUEST_DIRECTIONS

VARIABLES
    request_list,
    request_immediate

INVARIANT
    request_list : seq(FLOOR_REQUEST) &
    request_immediate : IMMEDIATE_REQUESTS

INITIALISATION
    request_list := [] ||
    request_immediate := request_none




END
