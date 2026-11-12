/* ElevatorContext
 * Author: tomclima
 * Creation date: 10/27/26
 */
MACHINE
    ElevatorContext

SETS
    BUTTON_DIR_OPTIONS = {button_dir_up, button_dir_down}

CONSTANTS
    MAX_FLOOR,
    MIN_FLOOR,
    MAX_CAPACITY,
    FLOORS,
    BUTTONS_IN_FLOORS

PROPERTIES
    MAX_CAPACITY : INTEGER &
    MAX_FLOOR : INTEGER &
    MAX_FLOOR >= 1 &

    MIN_FLOOR = 1 &
    MAX_FLOOR = 3 &
    MAX_CAPACITY = 450 &

    FLOORS = MIN_FLOOR..MAX_FLOOR &
    FLOORS /= {} &
    BUTTONS_IN_FLOORS =
        (MIN_FLOOR..(MAX_FLOOR - 1)) * {button_dir_up} \/
        ((MIN_FLOOR + 1)..MAX_FLOOR) * {button_dir_down} &
    BUTTONS_IN_FLOORS /= {} &
    FLOORS : FIN(FLOORS) &
    BUTTONS_IN_FLOORS : FIN(BUTTONS_IN_FLOORS)

END
