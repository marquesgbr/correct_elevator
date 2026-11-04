MACHINE
    ElevatorPanels

SEES
    ElevatorContext

SETS
    PANEL_DIR_STATES = {panel_dir_inactive, panel_dir_up, panel_dir_down};
    BUTTON_DIR_OPTIONS = {button_dir_up, button_dir_down};
    BUTTON_DOOR_OPTIONS = {button_door_close, button_door_open};
    BUTTON_LED_STATES = {button_led_active, button_led_inactive, button_led_blinking};
    BUTTON_PRESS_STATES = {button_press, button_released}

CONSTANTS
    FLOORS,
    BUTTONS_IN_FLOORS

PROPERTIES
    FLOORS = MIN_FLOOR .. MAX_FLOOR &
    BUTTONS_IN_FLOORS = FLOORS * BUTTON_DIR_OPTIONS

VARIABLES
    button_dir_led,
    button_dir_press,
    button_floor_led,
    button_floor_press,
    button_door_led,
    button_door_press,
    panel_curr_floor,
    panel_curr_direction

INVARIANT
    button_dir_led : BUTTONS_IN_FLOORS --> BUTTON_LED_STATES &
    button_dir_press : BUTTONS_IN_FLOORS --> BUTTON_PRESS_STATES &
    button_floor_led : FLOORS --> BUTTON_LED_STATES &
    button_floor_press : FLOORS --> BUTTON_PRESS_STATES &
    button_door_led : BUTTON_DOOR_OPTIONS --> BUTTON_LED_STATES &
    button_door_press : BUTTON_DOOR_OPTIONS --> BUTTON_PRESS_STATES &
    panel_curr_floor : FLOORS \/ {-1} &
    panel_curr_direction : PANEL_DIR_STATES

INITIALISATION
    button_dir_led := BUTTONS_IN_FLOORS * {button_led_inactive} ||
    button_dir_press := BUTTONS_IN_FLOORS * {button_released} ||
    button_floor_led := FLOORS * {button_led_inactive} ||
    button_floor_press := FLOORS * {button_released} ||
    button_door_led := BUTTON_DOOR_OPTIONS * {button_led_inactive} ||
    button_door_press := BUTTON_DOOR_OPTIONS * {button_released} ||
    panel_curr_floor := MIN_FLOOR ||
    panel_curr_direction := panel_dir_inactive

OPERATIONS

    press_dir_button(ffloor, ddir) =
        PRE
            ffloor : FLOORS &
            ddir : BUTTON_DIR_OPTIONS &
            (ffloor, ddir) : BUTTONS_IN_FLOORS &
            (ddir = button_dir_up => ffloor < MAX_FLOOR) &
            (ddir = button_dir_down => ffloor > MIN_FLOOR)
        THEN
            button_dir_press(ffloor, ddir) := button_press
        END;

    release_dir_button(ffloor, ddir) =
        PRE
            ffloor : FLOORS &
            ddir : BUTTON_DIR_OPTIONS &
            (ffloor, ddir) : BUTTONS_IN_FLOORS &
            (ddir = button_dir_up => ffloor < MAX_FLOOR) &
            (ddir = button_dir_down => ffloor > MIN_FLOOR)
        THEN
            button_dir_press(ffloor, ddir) := button_released
        END;

    press_floor_button(ffloor) =
        PRE
            ffloor : FLOORS
        THEN
            button_floor_press(ffloor) := button_press
        END;

    release_floor_button(ffloor) =
        PRE
            ffloor : FLOORS
        THEN
            button_floor_press(ffloor) := button_released
        END;

    press_door_button(dbutton) =
        PRE
            dbutton : BUTTON_DOOR_OPTIONS
        THEN
            button_door_press(dbutton) := button_press
        END;

    release_door_button(dbutton) =
        PRE
            dbutton : BUTTON_DOOR_OPTIONS
        THEN
            button_door_press(dbutton) := button_released
        END;

    set_dir_led(ffloor, ddir, lstate) =
        PRE
            ffloor : FLOORS &
            ddir : BUTTON_DIR_OPTIONS &
            (ffloor, ddir) : BUTTONS_IN_FLOORS &
            (ddir = button_dir_up => ffloor < MAX_FLOOR) &
            (ddir = button_dir_down => ffloor > MIN_FLOOR) &
            lstate : BUTTON_LED_STATES
        THEN
            button_dir_led(ffloor, ddir) := lstate
        END;

    set_floor_led(ffloor, lstate) =
        PRE
            ffloor : FLOORS &
            lstate : BUTTON_LED_STATES
        THEN
            button_floor_led(ffloor) := lstate
        END;

    set_door_led(dbutton, lstate) =
        PRE
            dbutton : BUTTON_DOOR_OPTIONS &
            lstate : BUTTON_LED_STATES
        THEN
            button_door_led(dbutton) := lstate
        END;

    blink_dir_led(ffloor, ddir) =
        PRE
            ffloor : FLOORS &
            ddir : BUTTON_DIR_OPTIONS &
            (ffloor, ddir) : BUTTONS_IN_FLOORS &
            (ddir = button_dir_up => ffloor < MAX_FLOOR) &
            (ddir = button_dir_down => ffloor > MIN_FLOOR)
        THEN
            button_dir_led(ffloor, ddir) := button_led_blinking
        END;

    blink_floor_led(ffloor) =
        PRE
            ffloor : FLOORS
        THEN
            button_floor_led(ffloor) := button_led_blinking
        END;

    blink_door_led(dbutton) =
        PRE
            dbutton : BUTTON_DOOR_OPTIONS
        THEN
            button_door_led(dbutton) := button_led_blinking
        END;

    all_leds_off =
        BEGIN
            button_dir_led := BUTTONS_IN_FLOORS * {button_led_inactive} ||
            button_floor_led := FLOORS * {button_led_inactive} ||
            button_door_led := BUTTON_DOOR_OPTIONS * {button_led_inactive}
        END;

    set_panel_floor(ffloor) =
        PRE
            ffloor : FLOORS \/ {-1}
        THEN
            panel_curr_floor := ffloor
        END;

    set_panel_direction(ddir) =
        PRE
            ddir : PANEL_DIR_STATES
        THEN
            panel_curr_direction := ddir
        END;

    update_panel_display(ffloor, ddir) =
        PRE
            ffloor : FLOORS \/ {-1} &
            ddir : PANEL_DIR_STATES
        THEN
            panel_curr_floor := ffloor ||
            panel_curr_direction := ddir
        END;

    res <-- get_panel_floor =
        BEGIN
            res := panel_curr_floor
        END;

    res <-- get_panel_direction =
        BEGIN
            res := panel_curr_direction
        END;

    res <-- is_dir_button_pressed(ffloor, ddir) =
        PRE
            ffloor : FLOORS &
            ddir : BUTTON_DIR_OPTIONS &
            (ffloor, ddir) : BUTTONS_IN_FLOORS &
            (ddir = button_dir_up => ffloor < MAX_FLOOR) &
            (ddir = button_dir_down => ffloor > MIN_FLOOR)
        THEN
            res := bool(button_dir_press(ffloor, ddir) = button_press)
        END;

    res <-- is_floor_button_pressed(ffloor) =
        PRE
            ffloor : FLOORS
        THEN
            res := bool(button_floor_press(ffloor) = button_press)
        END;

    res <-- is_door_button_pressed(dbutton) =
        PRE
            dbutton : BUTTON_DOOR_OPTIONS
        THEN
            res := bool(button_door_press(dbutton) = button_press)
        END;

    res <-- get_dir_led(ffloor, ddir) =
        PRE
            ffloor : FLOORS &
            ddir : BUTTON_DIR_OPTIONS &
            (ffloor, ddir) : BUTTONS_IN_FLOORS &
            (ddir = button_dir_up => ffloor < MAX_FLOOR) &
            (ddir = button_dir_down => ffloor > MIN_FLOOR)
        THEN
            res := button_dir_led(ffloor, ddir)
        END;

    res <-- get_floor_led(ffloor) =
        PRE
            ffloor : FLOORS
        THEN
            res := button_floor_led(ffloor)
        END;

    res <-- get_door_led(dbutton) =
        PRE
            dbutton : BUTTON_DOOR_OPTIONS
        THEN
            res := button_door_led(dbutton)
        END;

    res <-- are_all_leds_inactive =
        BEGIN
            res := bool(
                button_dir_led = BUTTONS_IN_FLOORS * {button_led_inactive} &
                button_floor_led = FLOORS * {button_led_inactive} &
                button_door_led = BUTTON_DOOR_OPTIONS * {button_led_inactive}
            )
        END

END
