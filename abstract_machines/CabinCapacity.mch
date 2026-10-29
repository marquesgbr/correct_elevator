/*
 * CabinCapacity
 * Author: tomclima
 * Creation date: 10/27/26
 */

MACHINE
    CabinCapacity

CONSTANTS
    MAX_CAPACITY

PROPERTIES
    MAX_CAPACITY : NAT &
    MAX_CAPACITY > 0 &
    MAX_CAPACITY = 450

VARIABLES
    exceeds_capacity,
    curr_weight

INVARIANT
    curr_weight : NAT &
    exceeds_capacity : BOOL &
    ((curr_weight > MAX_CAPACITY) <=> (exceeds_capacity = TRUE))

INITIALISATION
    curr_weight := 0 ||
    exceeds_capacity := FALSE

OPERATIONS
    add_weight(ww) =
    PRE
        ww : NAT &
        exceeds_capacity = FALSE &
        curr_weight <= MAX_CAPACITY &
        /*Precondition to help the prover*/
        curr_weight + ww : NAT
    THEN
        curr_weight := curr_weight + ww ||
        IF curr_weight + ww > MAX_CAPACITY THEN
            exceeds_capacity := TRUE
        END
    END;

    remove_weight(ww) =
    PRE
        ww : NAT &
        curr_weight >= ww
    THEN
        curr_weight := curr_weight - ww ||
        IF curr_weight - ww <= MAX_CAPACITY THEN
            exceeds_capacity := FALSE
        END
    END

END
