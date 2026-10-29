MACHINE
    CabinCapacity

CONSTANTS
    MAX_CAPACITY

PROPERTIES
    MAX_CAPACITY : NAT

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
            IF curr_weight + ww > MAX_CAPACITY THEN
                exceeds_capacity := TRUE
            ELSE
                exceeds_capacity := FALSE
            END
        END;

    remove_weight(ww) =
        PRE 
            ww : NAT &
            ww <= curr_weight
        THEN
            curr_weight := curr_weight - ww ||
            IF curr_weight - ww > MAX_CAPACITY THEN
                exceeds_capacity := TRUE
            ELSE
                exceeds_capacity := FALSE
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
            IF exceeds_capacity = FALSE THEN
                res := TRUE
            ELSE
                res := FALSE
            END
        END

END