MACHINE
    ElevatorPanels

SEES
    ElevatorContext

SETS
    /* Shared panel states used by request, door and display machines. */
    /* panel_dir_broken_elevator is a panel display state: it tells the
       user that the elevator is stopped/broken (HLR-007), without being
       confused with an inactive button LED. */
    PANEL_DIR_STATES = {panel_dir_inactive, panel_dir_up, panel_dir_down, panel_dir_broken_elevator};
    BUTTON_DIR_OPTIONS = {button_dir_up, button_dir_down};
    BUTTON_DOOR_OPTIONS = {button_door_close, button_door_open};
    BUTTON_LED_STATES = {button_led_active, button_led_inactive, button_led_blinking};
    BUTTON_PRESS_STATES = {button_press, button_released}

CONSTANTS
    /* Shared floor domains and valid external direction-button positions. */
    FLOORS,
    BUTTONS_IN_FLOORS

PROPERTIES
    FLOORS = MIN_FLOOR .. MAX_FLOOR &
    FLOORS /= {} &
    BUTTONS_IN_FLOORS = FLOORS * BUTTON_DIR_OPTIONS &
    BUTTONS_IN_FLOORS /= {}

VARIABLES
    /* Function-valued state: each button is indexed by floor and/or type. */
    button_dir_led,
    button_dir_press,

    button_floor_led,
    button_floor_press,
    
    button_door_led,
    button_door_press,

    panel_curr_floor,
    panel_curr_direction,
    excess_weight_indicator,

    pending_floor_blink_off,
    pending_floor_blink_on,
    pending_dir_blink_off

INVARIANT
    button_dir_led : BUTTONS_IN_FLOORS --> BUTTON_LED_STATES &
    button_dir_press : BUTTONS_IN_FLOORS --> BUTTON_PRESS_STATES &

    button_floor_led : FLOORS --> BUTTON_LED_STATES &
    button_floor_press : FLOORS --> BUTTON_PRESS_STATES &

    button_door_led : BUTTON_DOOR_OPTIONS --> BUTTON_LED_STATES &
    button_door_press : BUTTON_DOOR_OPTIONS --> BUTTON_PRESS_STATES &

    panel_curr_floor : FLOORS \/ {-1} &
    panel_curr_direction : PANEL_DIR_STATES &
    excess_weight_indicator : BOOL &

    pending_floor_blink_off <: FLOORS &
    pending_floor_blink_on <: FLOORS &
    pending_floor_blink_off /\ pending_floor_blink_on = {} &
    pending_dir_blink_off <: BUTTONS_IN_FLOORS

INITIALISATION
    /* All controls start released and all LEDs start inactive. */
    button_dir_led := BUTTONS_IN_FLOORS * {button_led_inactive} ||
    button_dir_press := BUTTONS_IN_FLOORS * {button_released} ||

    button_floor_led := FLOORS * {button_led_inactive} ||
    button_floor_press := FLOORS * {button_released} ||

    button_door_led := BUTTON_DOOR_OPTIONS * {button_led_inactive} ||
    button_door_press := BUTTON_DOOR_OPTIONS * {button_released} ||

    panel_curr_floor := MIN_FLOOR ||
    panel_curr_direction := panel_dir_inactive ||
    excess_weight_indicator := FALSE ||
    
    pending_floor_blink_off := {} ||
    pending_floor_blink_on := {} ||
    pending_dir_blink_off := {}

OPERATIONS

    /* Button input. ElevatorControl calls these for physical button events;
       request registration is handled by ElevatorRequests. */
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

     /* LED control. ElevatorRequests uses these operations to keep panel
         indications synchronized with active requests. */
    set_dir_led(ffloor, ddir, lstate) =
        PRE
            ffloor : FLOORS &
            ddir : BUTTON_DIR_OPTIONS &
            (ffloor, ddir) : BUTTONS_IN_FLOORS &
            (ddir = button_dir_up => ffloor < MAX_FLOOR) &
            (ddir = button_dir_down => ffloor > MIN_FLOOR) &
            lstate : BUTTON_LED_STATES
        THEN
            button_dir_led(ffloor, ddir) := lstate ||
            pending_dir_blink_off := pending_dir_blink_off - {ffloor |-> ddir}
        END;

    set_floor_led(ffloor, lstate) =
        PRE
            ffloor : FLOORS &
            lstate : BUTTON_LED_STATES
        THEN
            button_floor_led(ffloor) := lstate ||
            pending_floor_blink_off := pending_floor_blink_off - {ffloor} ||
            pending_floor_blink_on := pending_floor_blink_on - {ffloor}
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
            button_dir_led(ffloor, ddir) := button_led_blinking ||
            pending_dir_blink_off := pending_dir_blink_off - {ffloor |-> ddir}
        END;

    blink_floor_led(ffloor) =
        PRE
            ffloor : FLOORS
        THEN
            button_floor_led(ffloor) := button_led_blinking ||
            pending_floor_blink_off := pending_floor_blink_off - {ffloor} ||
            pending_floor_blink_on := pending_floor_blink_on - {ffloor}
        END;

    blink_door_led(dbutton) =
        PRE
            dbutton : BUTTON_DOOR_OPTIONS
        THEN
            button_door_led(dbutton) := button_led_blinking
        END;

     /* Bulk and exceptional LED operations. ElevatorMaintenance uses the
         combined operations so blink-and-off is a single call. */
    all_leds_off =
        BEGIN
            button_dir_led := BUTTONS_IN_FLOORS * {button_led_inactive} ||
            button_floor_led := FLOORS * {button_led_inactive} ||
            button_door_led := BUTTON_DOOR_OPTIONS * {button_led_inactive} ||
            pending_floor_blink_off := {} ||
            pending_floor_blink_on := {} ||
            pending_dir_blink_off := {}
        END;

    clear_all_buttons =
        BEGIN
            button_dir_press := BUTTONS_IN_FLOORS * {button_released} ||
            button_floor_press := FLOORS * {button_released} ||
            button_door_press := BUTTON_DOOR_OPTIONS * {button_released}
        END;

    blink_floor_led_twice_and_switch_off(ffloor) =
        PRE
            ffloor : FLOORS
        THEN
            button_floor_led(ffloor) := button_led_blinking ||
            pending_floor_blink_off := pending_floor_blink_off \/ {ffloor} ||
            pending_floor_blink_on := pending_floor_blink_on - {ffloor}
        END;

    blink_floor_led_twice_and_keep_on(ffloor) =
        PRE
            ffloor : FLOORS
        THEN
            button_floor_led(ffloor) := button_led_blinking ||
            pending_floor_blink_on := pending_floor_blink_on \/ {ffloor} ||
            pending_floor_blink_off := pending_floor_blink_off - {ffloor}
        END;

    complete_floor_led_blink(ffloor) =
        PRE
            ffloor : FLOORS &
            ffloor : pending_floor_blink_off
        THEN
            button_floor_led(ffloor) := button_led_inactive ||
            pending_floor_blink_off := pending_floor_blink_off - {ffloor}
        END;

    complete_floor_led_blink_and_keep_on(ffloor) =
        PRE
            ffloor : FLOORS &
            ffloor : pending_floor_blink_on
        THEN
            button_floor_led(ffloor) := button_led_active ||
            pending_floor_blink_on := pending_floor_blink_on - {ffloor}
        END;

    blink_dir_led_twice_and_switch_off(ffloor, ddir) =
        PRE
            ffloor : FLOORS &
            ddir : BUTTON_DIR_OPTIONS &
            (ffloor, ddir) : BUTTONS_IN_FLOORS &
            (ddir = button_dir_up => ffloor < MAX_FLOOR) &
            (ddir = button_dir_down => ffloor > MIN_FLOOR)
        THEN
            button_dir_led(ffloor, ddir) := button_led_blinking ||
            pending_dir_blink_off := pending_dir_blink_off \/ {ffloor |-> ddir}
        END;

    complete_dir_led_blink(ffloor, ddir) =
        PRE
            ffloor : FLOORS &
            ddir : BUTTON_DIR_OPTIONS &
            (ffloor, ddir) : BUTTONS_IN_FLOORS &
            (ffloor, ddir) : pending_dir_blink_off &
            (ddir = button_dir_up => ffloor < MAX_FLOOR) &
            (ddir = button_dir_down => ffloor > MIN_FLOOR)
        THEN
            button_dir_led(ffloor, ddir) := button_led_inactive ||
            pending_dir_blink_off := pending_dir_blink_off - {ffloor |-> ddir}
        END;

     /* Display state. ElevatorControl uses these to mirror the cabin
         floor/direction and the overweight condition on the panel display. */
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

    /* HLR-007: show/clear the stopped-or-broken elevator symbol. The
       two-minute door-open condition is handled by ElevatorTimers. */
    show_panel_broken =
        BEGIN
            panel_curr_direction := panel_dir_broken_elevator
        END;

    clear_panel_broken =
        BEGIN
            panel_curr_direction := panel_dir_inactive
        END;

    change_excess_weight(on_off) =
        PRE
            on_off : BOOL
        THEN
            excess_weight_indicator := on_off
        END;

    res <-- get_panel_floor =
        BEGIN
            res := panel_curr_floor
        END;

    res <-- get_panel_direction =
        BEGIN
            res := panel_curr_direction
        END;

    res <-- is_panel_broken =
        BEGIN
            res := bool(panel_curr_direction = panel_dir_broken_elevator)
        END;

    res <-- is_excess_weight_on =
        BEGIN
            res := excess_weight_indicator
        END;

    /* Read-only queries used by request processing and control logic. */
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
