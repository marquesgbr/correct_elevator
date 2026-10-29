/* ElevatorContext
 * Author: tomclima
 * Creation date: 10/27/26
 */
MACHINE
    ElevatorContext
    

CONSTANTS 
    MAX_FLOOR,
    MIN_FLOOR,
    MAX_CAPACITY
    
PROPERTIES
    MAX_CAPACITY : NAT &
    MAX_FLOOR : INTEGER &
    MAX_FLOOR >= 1 &
    
    /*Define specific constants*/
    MIN_FLOOR = 1 &
    MAX_FLOOR = 3 &
    MAX_CAPACITY = 450
    
    

END
