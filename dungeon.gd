extends Node2D

@export var tilemap: TileMap
@export var map_size: Vector2i = Vector2i(75, 75) 
@export var max_rooms: int =7
@export var room_min_size: Vector2i = Vector2i(10, 10)
@export var room_max_size: Vector2i = Vector2i(20, 20)
@export var player: CharacterBody2D

const FLOOR_TILE_ID = 0  
const WALL_TILE_ID = 1

var player_start_pos: Vector2 

@export var enemy_scenes: Array  
@export var boss_scene: PackedScene  

var boss_room: Rect2i 
var grid = [] 

func _ready():
	generate_grid()
	generate_dungeon()
	set_walls()    
	if player:
		player.position = player_start_pos

func generate_grid():
	grid = []
	for x in range(map_size.x*4):
		grid.append([])
		for y in range(map_size.y*4):
			grid[x].append(WALL_TILE_ID)  


func generate_dungeon():
	var rooms = []
	var distances = [] 

	var distance = 0
	var max_distance = -1
	for i in range(max_rooms):
		var room_size = Vector2i(
			randi_range(room_min_size.x, room_max_size.x),
			randi_range(room_min_size.y, room_max_size.y)
		)
		var room_pos = Vector2i(
			randi_range(map_size.x, map_size.x *3- room_size.x - 1),
			randi_range(map_size.y, map_size.y * 3 - room_size.y - 1)
		)

		var new_room = Rect2i(room_pos, room_size)
		print(new_room.position)
		if is_room_valid(new_room, rooms):
			rooms.append(new_room)

			spawn_enemies_in_room(new_room)

			if rooms.size() > 1:
				create_corridor(rooms[-2].get_center(), new_room.get_center())

	if rooms.size() > 0:
		player_start_pos = rooms[0].get_center() * 16  

	boss_room = get_farthest_room_from_player(rooms)
	print()
	print(player_start_pos)
	print(boss_room.get_center())
	for room in rooms:
		print(Vector2(room.position).distance_to(player_start_pos))
	
	var i = 0
	var dir = player_start_pos.direction_to(Vector2(boss_room.get_center()*16))
	var new_boss_size = boss_room.size * 2
	print()
	print(player_start_pos)
	print(boss_room.get_center() * 16)
	while true:
		var new_boss_pos = Vector2i(
				boss_room.position.x + new_boss_size.x / 2 *sign(dir.x),
				boss_room.position.y + new_boss_size.y / 2 * sign(dir.y)
			)
		boss_room = Rect2i(new_boss_pos, new_boss_size)
		
		if is_room_valid(boss_room, rooms):
			break
		
	rooms.append(boss_room)
	print()
	print(player_start_pos)
	print(boss_room.get_center() * 15)
	for room in rooms:
		carve_room(room)
	var closest_room = get_closest_room_from_room(boss_room, rooms)
	create_corridor(closest_room.get_center(),boss_room.get_center() )

	apply_tiles()

	spawn_boss_in_room(boss_room)
func get_farthest_room_from_player(rooms: Array) -> Rect2i:
	var farthest_room: Rect2i
	var max_distance = -1
	var set = 0
	for i in range(rooms.size()):
		var distance = Vector2(rooms[i].get_center()*16).distance_to(player_start_pos)
		if distance > max_distance:
			max_distance = distance
			farthest_room = rooms[i]
			set = i
	rooms.remove_at(set)
	return farthest_room

func get_closest_room_from_room(room, rooms: Array) -> Rect2i:
	var farthest_room: Rect2i
	var min_distance = 100000000

	for r in rooms.slice(0, rooms.size()-2):
		
		print("ROOM %s" % (r.get_center()*16))
		var distance = Vector2(r.get_center()*16).distance_to(room.get_center()*16)
		if distance < min_distance:
			
			min_distance = distance
			farthest_room = r
	print("FARTHEST %s" % (farthest_room.get_center()*16))
	return farthest_room
func spawn_enemies_in_room(room: Rect2i):
	var enemy_scene = enemy_scenes[randi_range(0, enemy_scenes.size() - 1)]
	var num_enemies = randi_range(3, 8)  
	room = room.grow(-1)
	for i in range(num_enemies):
		var enemy = enemy_scene.instantiate()
		var spawn_pos = Vector2(
			randi_range(room.position.x, room.end.x),
			randi_range(room.position.y, room.end.y)
		)
		enemy.position = spawn_pos * 16  
		add_child(enemy)

func spawn_boss_in_room(room: Rect2i):
	var boss = boss_scene.instantiate()
	var boss_pos = room.get_center() * 16 
	boss.position = boss_pos
	add_child(boss)

func is_room_valid(room: Rect2i, existing_rooms: Array) -> bool:
	for r in existing_rooms:
		if r.grow(1).intersects(room):
			return false
	return true

func carve_room(room: Rect2i):
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			grid[x][y] = FLOOR_TILE_ID  

func create_corridor(start: Vector2i, end: Vector2i, corridor_width: int = 3):
	var pos = start
	while pos.x != end.x:
		for offset in range(-corridor_width / 2, corridor_width / 2 + 1):
			grid[pos.x][pos.y+offset] = FLOOR_TILE_ID
		pos.x += signi(end.x - pos.x)
	
	while pos.y != end.y:
		for offset in range(-corridor_width / 2, corridor_width / 2):
			grid[pos.x+offset][pos.y] = FLOOR_TILE_ID
		pos.y += signi(end.y - pos.y)



func apply_tiles():
	for x in range(map_size.x*4):
		for y in range(map_size.y*4):
			if grid[x][y] == 0:
				tilemap.set_cell(0, Vector2i(x, y), grid[x][y], Vector2i(3, 2))
			elif grid[x][y] == 1:
				tilemap.set_cell(0, Vector2i(x, y), grid[x][y], Vector2i(7, 1))
			elif grid[x][y] == 2:
				tilemap.set_cell(0, Vector2i(x, y), grid[x][y], Vector2i(7,7))

func set_walls():
	for x in range(1, map_size.x *4 - 1):
		for y in range(1, map_size.y *4 - 1):
			if grid[x][y] == WALL_TILE_ID:
				if has_adjacent_floor(x, y):
					tilemap.set_cell(0, Vector2i(x, y), WALL_TILE_ID, Vector2i(0, 0))

func has_adjacent_floor(x: int, y: int) -> bool:
	return (grid[x+1][y] == FLOOR_TILE_ID or grid[x-1][y] == FLOOR_TILE_ID or
			grid[x][y+1] == FLOOR_TILE_ID or grid[x][y-1] == FLOOR_TILE_ID)
