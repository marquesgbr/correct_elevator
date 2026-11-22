# ElevatorControl VisB visualisation

Open `elevator.json` in ProB2-UI's VisB view while `ElevatorControl` is loaded.

Files:

- `elevator.json` — VisB item/event definitions.
- `elevator.svg` — drawing of the shaft, call buttons, and per-floor display panels.
- `elevator_closed.png` — cabin image used when `door_state = door_closed`.
- `elevator_open.jpeg` — cabin image used when `door_state = door_open`.

## What is shown

- The cabin moves between floors according to `curr_floor`.
- The cabin image switches between the closed and open door images according to
  `door_state`.
- Each floor has its own external call panel:
  - floor 1: up button;
  - floor 2: up and down buttons;
  - floor 3: down button.
- A lit green call button means the corresponding request is active
  (`up_requests` or `down_requests`). An amber ring means the physical button is
  currently pressed.
- The cabin panel shows the internal floor buttons 1–3 and the door buttons.
  Internal floor LEDs are lit from `internal_requests`; door-button LEDs follow
  `button_door_led`. Again, an amber ring means the button is pressed.
- Each floor has an identical copy of the car display panel showing
  `panel_curr_floor` and `panel_curr_direction`.

## What is intentionally not shown

- Maintenance mode and maintenance indicators.
- LED blinking animations. Requests are shown as lit while they are active.
- Door-button LEDs and panel maintenance/broken animation details.
- Weight/excess-capacity indicators.

## Interaction

The bottom control strip binds these operations to clicks:

`advance_time`, `select_request`, `start_travel`, `move_travel`,
`stop_at_target`, `serve_target`, `open_door_automatically`,
`close_door_automatically`.

Each control button is only shown while its operation precondition is true. For
example, `select_request` is hidden until a request exists, and `start_travel`
is hidden until a target is selected and the door is closed.

Clicking an external call button executes `press_up` / `press_down`.
Clicking a cabin floor button executes `press_internal`; clicking a cabin door
button executes `press_door`. The button then shows its amber pressed ring.

After pressing a button, a green `REG` action appears whenever the
corresponding `register_internal`, `register_up`, or `register_down` operation
is enabled. Clicking `REG` registers the request; the action then disappears and
the green request LED turns on.

Release still uses the model's `release_*` operations from ProB's Events pane.

## Command-line export

From a ProB installation that contains `probcli`:

```sh
probcli ElevatorControl.mch \
  -init \
  -visb visb/elevator.json elevator_visb.html
```

For an existing trace:

```sh
probcli ElevatorControl.mch \
  -trace_replay json serve_to_last_floor.prob2trace \
  -visb visb/elevator.json elevator_trace_visb.html
```
