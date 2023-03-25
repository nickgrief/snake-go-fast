extends Node2D

const CELL_SIZE := 8
const CELL_SCENE := preload('res://cell.tscn')

const GRID_SIZE := 32

var cell_grid: Array

var viewport_rect: Rect2

var step_time := 0.2

var snake_direction := Vector2.RIGHT
var new_snake_direction: Vector2
var snake_position: Vector2
var snake_parts := []

var food_timer_default := 5
var food_timer: int

var ate := false

var music_files := []

func _ready() -> void:
  music_files = dir_contents('res://music')

  var audio_stream = load_mp3('res://music/' + music_files[randi_range(0, len(music_files) - 1)])
  $music_player.stream = audio_stream
  $music_player.play()

  viewport_rect = get_viewport_rect()
  cell_grid = create_grid()
  food_timer = food_timer_default
  new_snake_direction = snake_direction
  spawn_food()
  spawn_snake()
  game_loop()

func load_mp3(path):
    var file = FileAccess.open(path, FileAccess.READ)
    var sound = AudioStreamMP3.new()
    sound.data = file.get_buffer(file.get_length())
    return sound


func dir_contents(path):
  var files := []
  var dir = DirAccess.open(path)
  if dir:
    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
      if dir.current_is_dir():
        print("Found directory: " + file_name)
      else:
        if (!file_name.ends_with('import')):
          files.append(file_name)
        print("Found file: " + file_name)
      file_name = dir.get_next()
  else:
    print("An error occurred when trying to access the path.")
  return files

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed('right'):
    new_snake_direction = Vector2.RIGHT
  if event.is_action_pressed('left'):
    new_snake_direction = Vector2.LEFT
  if event.is_action_pressed('up'):
    new_snake_direction = Vector2.UP
  if event.is_action_pressed('down'):
    new_snake_direction = Vector2.DOWN

func game_loop():
  var status := move_snake()

  await get_tree().create_timer(step_time).timeout

  if status:
    game_loop()
  else:
    get_tree().reload_current_scene()

func spawn_food():
  var food_position := Vector2.INF
  while (food_position == Vector2.INF):
    food_position = get_food_position()

  set_cell(food_position, CellState.state.FOOD)

func get_food_position() -> Vector2:
  var new_position = Vector2(randi_range(0, GRID_SIZE - 1), randi_range(0, GRID_SIZE - 1))
  if (get_cell(new_position).current_state != CellState.state.EMPTY):
    return Vector2.INF
  return new_position

func move_snake() -> bool:
  var next_position := snake_position + new_snake_direction

  if (len(snake_parts) > 0 and snake_parts[0] == next_position):
    next_position = snake_position + snake_direction
  else:
    snake_direction = new_snake_direction

  if (next_position.x < 0):
    next_position.x = GRID_SIZE - 1
  if (next_position.x >= GRID_SIZE):
    next_position.x = 0
  if (next_position.y < 0):
    next_position.y = GRID_SIZE - 1
  if (next_position.y >= GRID_SIZE):
    next_position.y = 0

  if (get_cell(next_position).current_state == CellState.state.FOOD):
    ate = true
    spawn_food()
    spawn_food()
    $eat_player.play(0.025)
    $eat_player.pitch_scale *= 1.05
    $walk_player.pitch_scale *= 1.05
    $music_player.pitch_scale *= 1.05
    snake_parts.push_front(snake_position)
    step_time *= 0.9

  if len(snake_parts) > 0:
    if not ate:
      set_cell(snake_parts.pop_back(), CellState.state.EMPTY)
      snake_parts.push_front(snake_position)
    set_cell(snake_position, CellState.state.BODY)
  else:
    set_cell(snake_position, CellState.state.EMPTY)
  ate = false


  if (get_cell(next_position).current_state == CellState.state.BODY
    or get_cell(next_position).current_state == CellState.state.HEAD):
    get_tree().reload_current_scene()

  snake_position = next_position
  $walk_player.play()
  set_cell(snake_position, CellState.state.HEAD)
  get_cell(snake_position).sprite.rotation = snake_direction.angle()

  return true

func set_cell(position: Vector2, state: CellState.state):
  get_cell(position).set_state(state)

func spawn_snake():
  snake_position = Vector2(floor(GRID_SIZE / 2), floor(GRID_SIZE / 2))
  get_cell(snake_position).set_state(CellState.state.HEAD)

func get_cell(position: Vector2) -> Cell:
  return cell_grid[position.y][position.x]

func create_cell(position: Vector2) -> Cell:
  var cell := CELL_SCENE.instantiate()
  cell.position = position
  add_child(cell)
  return cell

func create_grid() -> Array:
  var new_cell_grid := []
  for i in range(GRID_SIZE):
    var new_row := []
    for j in range(GRID_SIZE):
      new_row.append(create_cell(Vector2(j * CELL_SIZE + CELL_SIZE / 2, i * CELL_SIZE + CELL_SIZE / 2)))
    new_cell_grid.append(new_row)
  return new_cell_grid

func _on_music_player_finished() -> void:
  var audio_stream = load_mp3('res://music/' + music_files[randi_range(0, len(music_files) - 1)])
  $music_player.stream = audio_stream
  $music_player.play()
