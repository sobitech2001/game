extends Node2D

const W := 480.0
const H := 854.0

var rng := RandomNumberGenerator.new()
var ship_x := W * 0.5
var ship_y := H - 115.0
var target_x := W * 0.5
var touching := false

var objects: Array[Dictionary] = []
var stars: Array[Vector3] = []
var elapsed := 0.0
var score := 0
var lives := 3
var spawn_timer := 0.0
var game_over := false
var started := false
var best_score := 0
var hit_flash := 0.0

func _ready() -> void:
    rng.randomize()
    for i in range(90):
        stars.append(Vector3(rng.randf_range(0, W), rng.randf_range(0, H), rng.randf_range(35, 150)))
    set_process(true)

func _process(delta: float) -> void:
    if not started or game_over:
        queue_redraw()
        return

    elapsed += delta
    hit_flash = maxf(0.0, hit_flash - delta)
    # Smooth, gradual difficulty ramp. Capped to keep the game playable.
    var difficulty := minf(elapsed / 210.0, 1.0)
    var world_speed := 205.0 + difficulty * 145.0
    var spawn_interval := maxf(0.43, 1.05 - difficulty * 0.48)

    for i in range(stars.size()):
        var s: Vector3 = stars[i]
        s.y += s.z * delta * (0.55 + difficulty * 0.45)
        if s.y > H:
            s.x = rng.randf_range(0, W)
            s.y = -4
        stars[i] = s

    ship_x = move_toward(ship_x, target_x, 1100.0 * delta)
    ship_x = clampf(ship_x, 34.0, W - 34.0)

    spawn_timer += delta
    if spawn_timer >= spawn_interval:
        spawn_timer = 0.0
        _spawn_obstacle(world_speed)

    for i in range(objects.size() - 1, -1, -1):
        var obj := objects[i]
        obj.pos.y += obj.speed * delta
        objects[i] = obj
        if obj.pos.y > H + 70:
            if obj.kind == "rock" or obj.kind == "enemy":
                score += 10
            objects.remove_at(i)
            continue

        if _collides(obj):
            if obj.kind == "rock" or obj.kind == "enemy":
                objects.remove_at(i)
                _take_hit()
                if game_over:
                    break

    score += int(delta * 3.0)
    queue_redraw()

func _spawn_obstacle(base_speed: float) -> void:
    var difficulty := minf(elapsed / 210.0, 1.0)
    var x := rng.randf_range(38.0, W - 38.0)
    var roll := rng.randf()
    var kind := "rock"
    if roll < 0.22 + difficulty * 0.12:
        kind = "enemy"
    elif roll < 0.34 + difficulty * 0.15:
        kind = "gate"

    if kind == "gate":
        # A horizontal energy barrier with one safe gap.
        var gap_center := rng.randf_range(100.0, W - 100.0)
        var gap_width := maxf(112.0, 175.0 - difficulty * 45.0)
        objects.append({"kind":"gate", "pos":Vector2(gap_center, -35), "speed":base_speed * 0.88, "gap":gap_width})
    else:
        objects.append({"kind":kind, "pos":Vector2(x, -35), "speed":base_speed * rng.randf_range(0.88, 1.13), "r":rng.randf_range(17.0, 26.0), "phase":rng.randf_range(0, TAU)})

func _collides(obj: Dictionary) -> bool:
    var p: Vector2 = obj.pos
    if obj.kind == "gate":
        var gap: float = obj.gap
        var left_edge := p.x - gap * 0.5
        var right_edge := p.x + gap * 0.5
        if absf(p.y - ship_y) < 24.0:
            return ship_x < left_edge - 17.0 or ship_x > right_edge + 17.0
        return false
    var r: float = obj.r
    var moving_x := p.x
    if obj.kind == "enemy":
        moving_x += sin(elapsed * 2.2 + obj.phase) * 38.0
    return Vector2(ship_x, ship_y).distance_to(Vector2(moving_x, p.y)) < r + 19.0

func _take_hit() -> void:
    lives -= 1
    hit_flash = 0.22
    if lives <= 0:
        game_over = true
        best_score = maxi(best_score, score)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if game_over:
                _restart()
                return
            started = true
            touching = true
            target_x = event.position.x
        else:
            touching = false
    elif event is InputEventScreenDrag:
        touching = true
        target_x = event.position.x
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if game_over:
                _restart()
                return
            started = true
            touching = true
            target_x = event.position.x
        else:
            touching = false
    elif event is InputEventMouseMotion and touching:
        target_x = event.position.x

func _restart() -> void:
    objects.clear()
    elapsed = 0.0
    score = 0
    lives = 3
    spawn_timer = 0.0
    game_over = false
    started = true
    ship_x = W * 0.5
    target_x = ship_x

func _draw() -> void:
    draw_rect(Rect2(0, 0, W, H), Color("#07101f"))
    # Starfield
    for s in stars:
        var alpha := clampf(s.z / 150.0, 0.25, 0.9)
        draw_circle(Vector2(s.x, s.y), 1.0 + s.z / 100.0, Color(0.55, 0.78, 1.0, alpha))

    # Subtle side rails
    draw_line(Vector2(12, 0), Vector2(12, H), Color(0.12, 0.28, 0.45, 0.45), 2.0)
    draw_line(Vector2(W - 12, 0), Vector2(W - 12, H), Color(0.12, 0.28, 0.45, 0.45), 2.0)

    # HUD
    _draw_text("SCORE", Vector2(24, 42), 17, Color("#9bb8d5"))
    _draw_text(str(score), Vector2(24, 78), 31, Color.WHITE)
    _draw_text("BEST  " + str(best_score), Vector2(W - 24, 43), 17, Color("#ffd166"), HORIZONTAL_ALIGNMENT_RIGHT)
    _draw_text("♥  " + str(lives), Vector2(W - 24, 78), 25, Color("#ff647c"), HORIZONTAL_ALIGNMENT_RIGHT)

    for obj in objects:
        var p: Vector2 = obj.pos
        if obj.kind == "rock":
            var r: float = obj.r
            draw_circle(p, r, Color("#9aa5b1"))
            draw_circle(p + Vector2(-r*0.25, -r*0.2), r*0.42, Color("#647487"))
            draw_arc(p, r + 2, 0, TAU, 32, Color("#d0d9e2"), 2.0)
        elif obj.kind == "enemy":
            var ex := p.x + sin(elapsed * 2.2 + obj.phase) * 38.0
            var pts := PackedVector2Array([Vector2(ex, p.y + 22), Vector2(ex - 23, p.y - 15), Vector2(ex, p.y - 8), Vector2(ex + 23, p.y - 15)])
            draw_colored_polygon(pts, Color("#ff5368"))
            draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color("#ffc1ca"), 2.0)
            draw_circle(Vector2(ex, p.y + 4), 5, Color("#ffd166"))
        elif obj.kind == "gate":
            var gap: float = obj.gap
            var left := p.x - gap * 0.5
            var right := p.x + gap * 0.5
            draw_rect(Rect2(0, p.y - 8, maxf(0, left), 16), Color("#a33cff"))
            draw_rect(Rect2(right, p.y - 8, W - right, 16), Color("#a33cff"))
            draw_line(Vector2(0, p.y - 8), Vector2(left, p.y - 8), Color("#e2b7ff"), 2)
            draw_line(Vector2(right, p.y - 8), Vector2(W, p.y - 8), Color("#e2b7ff"), 2)

    _draw_ship(Vector2(ship_x, ship_y))

    if hit_flash > 0:
        draw_rect(Rect2(0, 0, W, H), Color(1, 0.15, 0.2, hit_flash * 0.35))

    if not started:
        draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.03, 0.08, 0.58))
        _draw_text("STAR DODGE", Vector2(W/2, H*0.39), 42, Color("#63e6ff"), HORIZONTAL_ALIGNMENT_CENTER)
        _draw_text("HOLD & DRAG TO MOVE", Vector2(W/2, H*0.46), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
        _draw_text("Tap to start", Vector2(W/2, H*0.56), 22, Color("#ffd166"), HORIZONTAL_ALIGNMENT_CENTER)

    if game_over:
        draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.02, 0.06, 0.78))
        _draw_text("MISSION FAILED", Vector2(W/2, H*0.42), 37, Color("#ff647c"), HORIZONTAL_ALIGNMENT_CENTER)
        _draw_text("SCORE  " + str(score), Vector2(W/2, H*0.49), 27, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
        _draw_text("Tap anywhere to try again", Vector2(W/2, H*0.57), 19, Color("#ffd166"), HORIZONTAL_ALIGNMENT_CENTER)

func _draw_ship(center: Vector2) -> void:
    var body := PackedVector2Array([
        center + Vector2(0, -31),
        center + Vector2(-23, 23),
        center + Vector2(-8, 17),
        center + Vector2(0, 25),
        center + Vector2(8, 17),
        center + Vector2(23, 23)
    ])
    draw_colored_polygon(body, Color("#55e6ff"))
    draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[4], body[5], body[0]]), Color("#d8fbff"), 2.0)
    draw_circle(center + Vector2(0, -5), 7, Color("#163b66"))
    draw_circle(center + Vector2(0, 27), 5 + rng.randf() * 0.5, Color("#ffb347"))
    draw_circle(center + Vector2(0, 30), 3, Color("#fff0a6"))

func _draw_text(value: String, pos: Vector2, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
    var font := ThemeDB.fallback_font
    draw_string(font, pos, value, align, -1, size, color)
