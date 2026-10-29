/* CabinState
 * Author: tomclima
 * Creation date: 10/27/26
 */
MACHINE
    CabinState
SEES ElevatorContext

SETS 
    CABIN_STATES = {rest, moving_up, moving_down};
    MOVEMENT_DIRECTIONS = {up, down, stop}
    
VARIABLES
    curr_floor,
    curr_state

INVARIANT
    curr_floor : INTEGER & 
    curr_floor <= MAX_FLOOR &
    curr_floor >= MIN_FLOOR &
    
    curr_state : CABIN_STATES &
    
    (curr_floor = MAX_FLOOR => curr_state /= moving_up) &
    (curr_floor = MIN_FLOOR => curr_state /= moving_down)

INITIALISATION
    curr_floor := MIN_FLOOR ||
    curr_state := rest
    
OPERATIONS
    change_direction(direction) =
    PRE
        direction : MOVEMENT_DIRECTIONS &
        (direction /= stop => curr_state = rest) &
        (direction = up => curr_floor < MAX_FLOOR) &
        (curr_floor = MAX_FLOOR => direction /= up) &
        
        (direction = down => curr_floor > MIN_FLOOR)
        
    THEN
        IF direction = up THEN 
            curr_state := moving_up
        ELSIF direction = down THEN 
            curr_state := moving_down
        ELSE curr_state := rest
        END
    END;
    
    move_cabin =
    PRE
    (curr_state = moving_up & curr_floor < MAX_FLOOR) or
    (curr_state = moving_down & curr_floor > MIN_FLOOR)
    THEN
        IF curr_state = moving_up & curr_floor < MAX_FLOOR THEN
            curr_floor := curr_floor + 1 ||
            IF curr_floor +1 = MAX_FLOOR THEN
                curr_state := rest
            END
                
        ELSIF curr_state = moving_down & curr_floor > MIN_FLOOR THEN
            curr_floor := curr_floor -1 ||
            IF curr_floor -1 = MIN_FLOOR THEN
                curr_state := rest
            END
        END    
    END
        

END