MACHINE
    CabinCapacity
    
SEES ElevatorContext

VARIABLES
    curr_weight,
    exceeds_capacity

INVARIANT
    curr_weight : NAT &
    exceeds_capacity : BOOL &
    ((curr_weight > MAX_CAPACITY) <=> (exceeds_capacity = TRUE))

INITIALISATION
    curr_weight := 0 ||
    exceeds_capacity := FALSE

OPERATIONS

    /* ---------------------------------------------------------
       State Update Operations (Adicionar / Remover Peso)
       --------------------------------------------------------- */
       
    add_weight(ww) =
        PRE 
            ww : NAT &
            /*Pre condition to help prover*/
            ww + curr_weight : NAT
        THEN
            curr_weight := curr_weight + ww ||
            exceeds_capacity := bool(curr_weight + ww > MAX_CAPACITY)
        END;

    remove_weight(ww) =
        PRE 
            ww : NAT &
            ww <= curr_weight &
            curr_weight - ww : NAT 
        THEN
            IF curr_weight - ww >= 0 THEN
                curr_weight := curr_weight - ww ||
                exceeds_capacity := bool(curr_weight - ww > MAX_CAPACITY)
            END
        END;

    /* ---------------------------------------------------------
       Query Operations (Consultas)
       --------------------------------------------------------- */


    res <-- is_overweight =
        BEGIN
            res := exceeds_capacity
        END;


    res <-- can_move =
        BEGIN
            res := bool(not(exceeds_capacity = TRUE))
        END

END