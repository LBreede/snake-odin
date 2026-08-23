package main

import "core:fmt"
import rl "vendor:raylib"

SNAKE_LENGTH: int : 256

SQUARE_SIZE: i32 : 32
SQUARE_SIZE_F :: f32(SQUARE_SIZE)

ATLAS_SIZE := [2]f32{3, 5}

SCREEN_WIDTH: i32 : 1024
SCREEN_HEIGHT: i32 : 768

WIDTH: i32 : SCREEN_WIDTH / SQUARE_SIZE
HEIGHT: i32 : SCREEN_HEIGHT / SQUARE_SIZE

// Version

VERSION_MAJOR :: 0
VERSION_MINOR :: 1
VERSION_PATCH :: 0

// UI rendering

PADDING: i32 : 10
FONT_BIG: i32 : 40
FONT_MEDIUM: i32 : 30
FONT_SMALL: i32 : 20

Snake :: struct {
	position: [2]f32,
	size:     [2]f32,
	speed:    [2]f32,
}

Food :: struct {
	position: [2]f32,
	size:     [2]f32,
	active:   bool,
	uv:       [2]f32,
}

frames_counter := 0
game_over := false
pause := false

fruit := Food{}
snake := [SNAKE_LENGTH]Snake{}
snake_position := [SNAKE_LENGTH][2]f32{}
tile_uvs := [WIDTH * HEIGHT][2]f32{}

counter_tail := 0
score := 0
allow_move := false

high_score := 0
texture: rl.Texture2D

Direction :: enum {
	NORTH,
	EAST,
	SOUTH,
	WEST,
}

direction_from_vec2 :: proc(v: [2]f32) -> Direction {
	switch v {
	case {1, 0}:
		return .EAST
	case {0, 1}:
		return .SOUTH
	case {-1, 0}:
		return .WEST
	case {0, -1}:
		return .NORTH
	case {0, 0}:
		// FIXME: head and tail are on the same tile on init
		return .NORTH
	case:
		// FIXME: crash here instead
		fmt.printf("ERROR: invalid vector: (%f, %f)\n", v.x, v.y)
		return .NORTH
	}
}

rotation_from_direction :: proc(d: Direction) -> f32 {
	switch d {
	case .EAST:
		return 0
	case .SOUTH:
		return 90
	case .WEST:
		return 180
	case .NORTH:
		return 270
	case:
		fmt.printf("UNREACHABLE: unknown direction: %s\n", d)
		return 0 // @Unreachable: Make this illegal
	}
}

init_game :: proc() {
	frames_counter = 0
	game_over = false
	pause = false

	// Tail counter starts at 2 for better graphics
	counter_tail = 2
	score = 0
	allow_move = false

	for i := 0; i < SNAKE_LENGTH; i += 1 {
		snake[i].position = {f32(WIDTH / 2) * 32, f32(HEIGHT / 2) * 32}
		snake[i].size = {SQUARE_SIZE_F, SQUARE_SIZE_F}
		snake[i].speed = {SQUARE_SIZE_F, 0}
	}

	for i := 0; i < SNAKE_LENGTH; i += 1 {
		snake_position[i] = [2]f32{0.0, 0.0}
	}

	for i: i32 = 0; i < WIDTH * HEIGHT; i += 1 {
		x := i % WIDTH
		y := i / WIDTH

		uv: [2]f32
		// Make space for score and version
		if (x < 12 && y < 4) || (x > WIDTH - 3 && y < 1) {
			uv = {0, 5} * SQUARE_SIZE_F
		} else {
			// @Hardcode: Texture uvs are not discovered but
			u := f32(rl.GetRandomValue(0, 2) * SQUARE_SIZE)
			v := f32(rl.GetRandomValue(5, 7) * SQUARE_SIZE)
			uv = {u, v}
		}
		tile_uvs[i] = uv
	}

	fruit.size = {SQUARE_SIZE_F, SQUARE_SIZE_F}
	fruit.active = false
}

update_game :: proc() {
	if !game_over {
		if (rl.IsKeyPressed(.P)) {pause = !pause}

		if !pause {
			// Player control
			if rl.IsKeyPressed(.D) && (snake[0].speed.x == 0) && allow_move {
				snake[0].speed = {SQUARE_SIZE_F, 0}
				allow_move = false
			}
			if rl.IsKeyPressed(.A) && (snake[0].speed.x == 0) && allow_move {
				snake[0].speed = {f32(-SQUARE_SIZE), 0}
				allow_move = false
			}
			if rl.IsKeyPressed(.W) && (snake[0].speed.y == 0) && allow_move {
				snake[0].speed = {0, f32(-SQUARE_SIZE)}
				allow_move = false
			}
			if rl.IsKeyPressed(.S) && (snake[0].speed.y == 0) && allow_move {
				snake[0].speed = {0, SQUARE_SIZE_F}
				allow_move = false
			}

			// Snake movement
			for i := 0; i < counter_tail; i += 1 {
				snake_position[i] = snake[i].position
			}

			if (frames_counter % 5) == 0 {
				for i := 0; i < counter_tail; i += 1 {
					if i == 0 {
						snake[0].position.x += snake[0].speed.x
						snake[0].position.y += snake[0].speed.y
						allow_move = true
					} else {
						snake[i].position = snake_position[i - 1]
					}
				}
			}

			// Wall behavious
			if snake[0].position.x >= f32(SCREEN_WIDTH) ||
			   snake[0].position.y >= f32(SCREEN_HEIGHT) ||
			   snake[0].position.x < 0 ||
			   snake[0].position.y < 0 {
				game_over = true
			}

			// Collision with yourself
			for i := 1; i < counter_tail; i += 1 {
				if snake[0].position.x == snake[i].position.x &&
				   snake[0].position.y == snake[i].position.y {
					game_over = true
				}
			}

			// Fruit position calculation
			if !fruit.active {
				fruit.active = true
				fruit.position = {
					f32(rl.GetRandomValue(0, SCREEN_WIDTH / SQUARE_SIZE - 1) * SQUARE_SIZE),
					f32(rl.GetRandomValue(0, SCREEN_HEIGHT / SQUARE_SIZE - 1) * SQUARE_SIZE),
				}
				fruit.uv = {f32(rl.GetRandomValue(0, 2)), f32(rl.GetRandomValue(2, 3))}

				for i := 0; i < counter_tail; i += 1 {
					for fruit.position.x == snake[i].position.x &&
					    fruit.position.y == snake[i].position.y {
						fruit.position = {
							f32(
								rl.GetRandomValue(0, SCREEN_WIDTH / SQUARE_SIZE - 1) * SQUARE_SIZE,
							),
							f32(
								rl.GetRandomValue(0, SCREEN_HEIGHT / SQUARE_SIZE - 1) *
								SQUARE_SIZE,
							),
						}
						i = 0
					}
				}
			}

			// Collision
			if snake[0].position.x < (fruit.position.x + fruit.size.x) &&
			   (snake[0].position.x + snake[0].size.x) > fruit.position.x &&
			   snake[0].position.y < (fruit.position.y + fruit.size.y) &&
			   (snake[0].position.y + snake[0].size.y) > fruit.position.y {
				snake[counter_tail].position = snake_position[counter_tail - 1]
				counter_tail += 1
				score += 1
				high_score = max(score, high_score)
				fruit.active = false
			}

			frames_counter += 1
		}
	} else {
		if rl.IsKeyPressed(.ENTER) {
			init_game()
			game_over = false
		}
	}
}

draw_game :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.RAYWHITE)

	if !game_over {

		source := rl.Rectangle{0, 0, SQUARE_SIZE_F, SQUARE_SIZE_F}

		for i: i32 = 0; i < WIDTH * HEIGHT; i += 1 {
			source.x = tile_uvs[i].x
			source.y = tile_uvs[i].y
			position := [2]f32{f32(i % WIDTH * SQUARE_SIZE), f32(i / WIDTH * SQUARE_SIZE)}
			rl.DrawTextureRec(texture, source, position, rl.WHITE)
		}

		dest := rl.Rectangle{0, 0, SQUARE_SIZE_F, SQUARE_SIZE_F}
		half_square := SQUARE_SIZE_F / 2
		origin := [2]f32{half_square, half_square}
		rotation := f32(0)

		// Draw text
		text := rl.TextFormat("Score: %d\nHighscore: %d", score, high_score)
		rl.DrawText(text, PADDING, PADDING, FONT_BIG, rl.BLACK)

		// Draw snake
		for i := 0; i < counter_tail; i += 1 {

			dest.x = snake[i].position.x + half_square
			dest.y = snake[i].position.y + half_square

			// Pick correct texture and rotation
			if i == 0 {
				p1 := snake[i].position / SQUARE_SIZE_F
				p2 := snake[i + 1].position / SQUARE_SIZE_F
				p := p1 - p2
				rotation = rotation_from_direction(direction_from_vec2(p))

				source.x = SQUARE_SIZE_F * 2
				source.y = SQUARE_SIZE_F * 1
			} else if i == counter_tail - 1 {
				p0 := snake[i - 1].position / SQUARE_SIZE_F
				p1 := snake[i].position / SQUARE_SIZE_F
				p := p0 - p1
				rotation = rotation_from_direction(direction_from_vec2(p))

				source.x = SQUARE_SIZE_F * 0
				source.y = SQUARE_SIZE_F * 1
			} else {
				p0 := snake[i - 1].position / SQUARE_SIZE_F
				p1 := snake[i].position / SQUARE_SIZE_F
				p2 := snake[i + 1].position / SQUARE_SIZE_F

				p01 := p0 - p1
				p12 := p1 - p2

				d01 := direction_from_vec2(p01)
				d12 := direction_from_vec2(p12)

				if d01 == d12 {
					source.x = SQUARE_SIZE_F * 1
					source.y = SQUARE_SIZE_F * 1

					rotation = rotation_from_direction(direction_from_vec2(p01))
				} else {
					// pick snake turn texture at (3, 1)
					source.x = SQUARE_SIZE_F * 3
					source.y = SQUARE_SIZE_F * 1

					rotation_offset: f32
					switch ([2]Direction{d01, d12}) {
					case {.EAST, .NORTH}, {.SOUTH, .EAST}, {.WEST, .SOUTH}, {.NORTH, .WEST}:
						rotation_offset = -90
					case {.NORTH, .EAST}, {.EAST, .SOUTH}, {.SOUTH, .WEST}, {.WEST, .NORTH}:
						rotation_offset = 180
					// Any other combination is either impossibe e.g. {.NORTH, .SOUTH}
					// Or already handled in the if-statement (`d01 == d02`)
					case:
						fmt.printf(
							"ERROR: illegal combination of directions: {%s, %s}\n",
							d01,
							d12,
						)
						rotation_offset = 0
					}
					// The above `rotation_offset` values are based on `p01`.
					// If we were using `p12`, the angles would be slightly different.
					rotation = rotation_from_direction(direction_from_vec2(p01)) + rotation_offset

				}

			}
			rl.DrawTexturePro(texture, source, dest, origin, rotation, rl.WHITE)

		}

		// Draw fruit to pick
		source.x = fruit.uv.x * SQUARE_SIZE_F
		source.y = fruit.uv.y * SQUARE_SIZE_F
		rl.DrawTextureRec(texture, source, fruit.position, rl.WHITE)

		if pause {
			font_size := FONT_SMALL
			text := rl.TextFormat("v%d.%d.%d", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH)
			rl.DrawText(
				text,
				SCREEN_WIDTH - rl.MeasureText(text, font_size) - PADDING,
				PADDING,
				font_size,
				rl.BLACK,
			)

			font_size = FONT_BIG
			text = "GAME PAUSED"
			rl.DrawText(
				text,
				SCREEN_WIDTH / 2 - rl.MeasureText(text, font_size) / 2,
				SCREEN_HEIGHT / 2 - font_size,
				font_size,
				rl.BLACK,
			)
		}

	} else {
		// Restart screen
		text: cstring = "PRESS [ENTER] TO PLAY AGAIN"
		font_size := FONT_MEDIUM
		color := rl.GRAY
		rl.DrawText(
			text,
			SCREEN_WIDTH / 2 - rl.MeasureText(text, font_size) / 2,
			SCREEN_HEIGHT / 2 - font_size,
			font_size,
			color,
		)

		font_size = FONT_BIG
		text = rl.TextFormat("Score: %d\nHighscore: %d", score, high_score)
		rl.DrawText(text, PADDING, PADDING, font_size, color)

		// Version number
		text = rl.TextFormat("v%d.%d.%d", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH)
		font_size = FONT_SMALL
		rl.DrawText(
			text,
			SCREEN_WIDTH - rl.MeasureText(text, font_size) - PADDING,
			PADDING,
			font_size,
			color,
		)

		// Credits
		credits := []cstring {
			"Programming by Lennart Breede",
			"Art by Alexandra Setijo-Joesoef",
		}
		for text, index in credits {
			rl.DrawText(
				text,
				SCREEN_WIDTH / 2 - rl.MeasureText(text, font_size) / 2,
				SCREEN_HEIGHT - 2 * i32(index + 1) * font_size - PADDING,
				font_size,
				color,
			)
		}
	}

	rl.EndDrawing()
}

unload_game :: proc() {}

update_draw_frame :: proc() {
	update_game()
	draw_game()
}

main :: proc() {
	title := fmt.ctprintf("Snake v%d.%d.%d", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH)
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, title)
	defer rl.CloseWindow()

	texture = rl.LoadTexture("assets/textures/atlas.png")
	defer rl.UnloadTexture(texture)

	init_game()
	defer unload_game()

	rl.SetTargetFPS(60)
	for !rl.WindowShouldClose() {
		update_draw_frame()
	}
}
