extends Control
## As Configurações (hub-start/02): os volumes, o Sair da conta e, só em depuração, o
## Apagar progresso.

const RESET_TEXT := "Apagar progresso"
const CONFIRM_TEXT := "Toque de novo para apagar"
const LABEL_FONT := 24
const SLIDER_HEIGHT := 48
const TRACK_HEIGHT := 8
const GRABBER_SIZE := 36

var _busy: bool = false

@onready var _volumes: VBoxContainer = %Volumes
@onready var _logout_button: Button = %LogoutButton
@onready var _reset_button: Button = %ResetButton
@onready var _error_label: Label = %ErrorLabel
@onready var _back_button: Button = %BackButton
@onready var _confirm_timer: Timer = %ConfirmTimer


func _ready() -> void:
	_add_volume("Música", AudioSettings.music_volume(), AudioSettings.set_music_volume)
	_add_volume("Sons", AudioSettings.sounds_volume(), AudioSettings.set_sounds_volume)
	_reset_button.visible = OS.is_debug_build()
	_logout_button.pressed.connect(_logout)
	_reset_button.pressed.connect(_reset)
	_back_button.pressed.connect(Router.back)
	_confirm_timer.timeout.connect(_disarm)


func handle_back() -> bool:
	return _busy


func _add_volume(title: String, volume: float, store: Callable) -> void:
	var header := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.theme_type_variation = &"BoldLabel"
	label.add_theme_font_size_override(&"font_size", LABEL_FONT)
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(label)
	var percent := Label.new()
	percent.theme_type_variation = &"SecondaryLabel"
	percent.add_theme_font_size_override(&"font_size", LABEL_FONT)
	header.add_child(percent)
	_volumes.add_child(header)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = roundf(volume * 100.0)
	slider.custom_minimum_size.y = SLIDER_HEIGHT
	_paint_slider(slider)
	_volumes.add_child(slider)
	percent.text = "%d%%" % int(slider.value)
	slider.value_changed.connect(func(value: float) -> void:
		percent.text = "%d%%" % int(value)
		store.call(value / 100.0))


func _paint_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = UiPalette.TRACK
	track.set_corner_radius_all(TRACK_HEIGHT)
	track.content_margin_top = TRACK_HEIGHT / 2.0
	track.content_margin_bottom = TRACK_HEIGHT / 2.0
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = UiPalette.ACCENT
	slider.add_theme_stylebox_override(&"slider", track)
	slider.add_theme_stylebox_override(&"grabber_area", fill)
	slider.add_theme_stylebox_override(&"grabber_area_highlight", fill)
	var grabber := _circle(UiPalette.TEXT)
	slider.add_theme_icon_override(&"grabber", grabber)
	slider.add_theme_icon_override(&"grabber_highlight", grabber)
	slider.add_theme_icon_override(&"grabber_disabled", grabber)


static func _circle(color: Color) -> ImageTexture:
	var image := Image.create_empty(GRABBER_SIZE, GRABBER_SIZE, false, Image.FORMAT_RGBA8)
	var radius := GRABBER_SIZE / 2.0
	for y: int in GRABBER_SIZE:
		for x: int in GRABBER_SIZE:
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(radius, radius))
			var dot := color
			dot.a = clampf(radius - distance, 0.0, 1.0)
			image.set_pixel(x, y, dot)
	return ImageTexture.create_from_image(image)


func _logout() -> void:
	_busy = true
	_logout_button.disabled = true
	await Session.logout()
	Router.go_to(&"login")


func _reset() -> void:
	if _confirm_timer.is_stopped():
		_reset_button.text = CONFIRM_TEXT
		_error_label.hide()
		_confirm_timer.start()
		return
	_confirm_timer.stop()
	_busy = true
	_reset_button.disabled = true
	var result: Result = await Session.reset_progress()
	if result.ok:
		result = await Home.start()
	if result.ok:
		return
	_busy = false
	_reset_button.disabled = false
	_disarm()
	_error_label.text = result.error
	_error_label.show()


func _disarm() -> void:
	_reset_button.text = RESET_TEXT
