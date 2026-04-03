extends Node
class_name AudioManager

const SAMPLE_RATE: int = 22050
const PLAYER_POOL_SIZE: int = 12
const SETTINGS_PATH: String = "user://audio_settings.cfg"
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const DEFAULT_LEVELS: Dictionary = {"master": 0.82, "music": 0.58, "sfx": 0.86}

var _players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer
var _next_player_index: int = 0
var _streams: Dictionary = {}
var _volume_levels: Dictionary = DEFAULT_LEVELS.duplicate(true)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_ensure_players()
	_ensure_bgm_player()
	_build_stream_library()
	_load_settings()
	_start_bgm()

func play_ui(sound_id: String) -> void:
	_play_registered_stream(sound_id)

func play_event_spawn(event_id: String, event_defs: Dictionary) -> void:
	_play_registered_stream("event_%s_open" % _event_profile(event_id, event_defs), -3.5)

func play_event_open(event_id: String, event_defs: Dictionary) -> void:
	_play_registered_stream("event_%s_open" % _event_profile(event_id, event_defs))

func play_event_result(event_id: String, event_defs: Dictionary, outcome: String) -> void:
	var suffix: String = "success"
	match outcome:
		"fail":
			suffix = "fail"
		"expired":
			suffix = "expire"
	var profile: String = _event_profile(event_id, event_defs)
	var sound_id: String = "event_%s_%s" % [profile, suffix]
	if not _streams.has(sound_id):
		sound_id = "event_crisis_%s" % suffix
	_play_registered_stream(sound_id)

func get_volume_level(channel_id: String) -> float:
	return clampf(float(_volume_levels.get(channel_id, DEFAULT_LEVELS.get(channel_id, 1.0))), 0.0, 1.0)

func set_volume_level(channel_id: String, level: float, persist: bool = true) -> void:
	if not DEFAULT_LEVELS.has(channel_id):
		return
	_volume_levels[channel_id] = clampf(level, 0.0, 1.0)
	_apply_volume_level(channel_id)
	if persist:
		save_settings()

func reset_volume_levels() -> void:
	for key_variant in DEFAULT_LEVELS.keys():
		var key: String = str(key_variant)
		_volume_levels[key] = float(DEFAULT_LEVELS[key_variant])
	_apply_all_volume_levels()
	save_settings()

func save_settings() -> void:
	var config := ConfigFile.new()
	for key_variant in DEFAULT_LEVELS.keys():
		var key: String = str(key_variant)
		config.set_value("audio", key, get_volume_level(key))
	config.save(SETTINGS_PATH)

func _load_settings() -> void:
	var config := ConfigFile.new()
	var err: int = config.load(SETTINGS_PATH)
	for key_variant in DEFAULT_LEVELS.keys():
		var key: String = str(key_variant)
		var fallback: float = float(DEFAULT_LEVELS[key_variant])
		_volume_levels[key] = clampf(float(config.get_value("audio", key, fallback)), 0.0, 1.0) if err == OK else fallback
	_apply_all_volume_levels()

func _ensure_buses() -> void:
	if AudioServer.get_bus_index(BUS_MASTER) == -1:
		return
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)

func _ensure_bus(bus_name: String) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		index = AudioServer.get_bus_count()
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, BUS_MASTER)

func _ensure_players() -> void:
	if not _players.is_empty():
		return
	for _index in range(PLAYER_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_players.append(player)

func _ensure_bgm_player() -> void:
	if _bgm_player != null:
		return
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_MUSIC
	add_child(_bgm_player)

func _start_bgm() -> void:
	if _bgm_player == null:
		return
	var bgm_stream: AudioStream = _streams.get("bgm_main", null) as AudioStream
	if bgm_stream == null:
		return
	if _bgm_player.stream != bgm_stream:
		_bgm_player.stream = bgm_stream
	if not _bgm_player.playing:
		_bgm_player.play()

func _apply_all_volume_levels() -> void:
	for key_variant in DEFAULT_LEVELS.keys():
		_apply_volume_level(str(key_variant))

func _apply_volume_level(channel_id: String) -> void:
	var bus_name: String = _bus_name_for_channel(channel_id)
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_name.is_empty() or bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, _level_to_db(get_volume_level(channel_id)))

func _bus_name_for_channel(channel_id: String) -> String:
	match channel_id:
		"master":
			return BUS_MASTER
		"music":
			return BUS_MUSIC
		"sfx":
			return BUS_SFX
	return ""

func _level_to_db(level: float) -> float:
	if level <= 0.001:
		return -80.0
	return linear_to_db(level)

func _build_stream_library() -> void:
	if not _streams.is_empty():
		return
	_register_stream("button", _dual(680.0, 920.0, 0.022, 0.036, 0.17), -8.0)
	_register_stream("panel_open", _sweep(360.0, 760.0, 0.085, 0.16), -7.0)
	_register_stream("panel_close", _sweep(820.0, 380.0, 0.072, 0.14), -8.5)
	_register_stream("card_focus", _dual(510.0, 690.0, 0.024, 0.042, 0.16), -9.0)
	_register_stream("card_flip", _dual(340.0, 920.0, 0.022, 0.040, 0.18), -7.0)
	_register_stream("collect_all", _triple([520.0, 760.0, 980.0], [0.024, 0.032, 0.056], 0.20), -6.0)
	_register_stream("assign_ok", _triple([430.0, 620.0, 880.0], [0.026, 0.034, 0.048], 0.20), -5.5)
	_register_stream("assign_fail", _buzz(220.0, 0.092, 0.18), -5.0)
	_register_stream("remove", _dual(540.0, 360.0, 0.028, 0.046, 0.15), -8.0)
	_register_stream("confirm", _triple([390.0, 520.0, 780.0], [0.030, 0.036, 0.060], 0.18), -6.0)
	_register_event_profile("crisis", [260.0, 190.0], [0.050, 0.060], [320.0, 460.0, 600.0], [200.0, 160.0], [240.0, 170.0], -7.5)
	_register_event_profile("relation", [420.0, 560.0], [0.042, 0.052], [520.0, 700.0, 880.0], [370.0, 250.0], [320.0, 220.0], -8.0)
	_register_event_profile("omen", [720.0, 980.0], [0.034, 0.046], [620.0, 860.0, 1180.0], [560.0, 260.0], [420.0, 250.0], -8.0)
	_register_event_profile("opportunity", [500.0, 760.0], [0.034, 0.046], [560.0, 760.0, 980.0], [460.0, 280.0], [380.0, 240.0], -7.0)
	_register_event_profile("dream", [300.0, 460.0], [0.050, 0.058], [350.0, 520.0, 700.0], [230.0, 170.0], [280.0, 190.0], -8.5)
	_register_event_profile("military", [180.0, 240.0], [0.032, 0.040], [220.0, 320.0, 440.0], [150.0, 110.0], [200.0, 130.0], -7.0)
	_register_event_profile("strategist", [480.0, 720.0], [0.030, 0.042], [520.0, 820.0, 1120.0], [420.0, 230.0], [340.0, 210.0], -7.5)
	_streams["bgm_main"] = _build_bgm_stream()

func _register_event_profile(profile: String, open_notes: Array, open_lengths: Array, success_notes: Array, fail_notes: Array, expire_notes: Array, volume_db: float) -> void:
	_register_stream("event_%s_open" % profile, _triple(open_notes, open_lengths, 0.18), volume_db)
	_register_stream("event_%s_success" % profile, _triple(success_notes, [0.030, 0.040, 0.060], 0.20), volume_db + 0.5)
	_register_stream("event_%s_fail" % profile, _dual(float(fail_notes[0]), float(fail_notes[1]), 0.050, 0.070, 0.18), volume_db + 1.5)
	_register_stream("event_%s_expire" % profile, _dual(float(expire_notes[0]), float(expire_notes[1]), 0.034, 0.062, 0.16), volume_db + 0.5)

func _register_stream(sound_id: String, stream: AudioStreamWAV, volume_db: float) -> void:
	_streams[sound_id] = stream
	_streams["%s:volume" % sound_id] = volume_db

func _play_registered_stream(sound_id: String, volume_offset_db: float = 0.0) -> void:
	if sound_id.is_empty() or not _streams.has(sound_id):
		return
	var player: AudioStreamPlayer = _next_player()
	player.stop()
	player.stream = _streams[sound_id] as AudioStream
	player.volume_db = float(_streams.get("%s:volume" % sound_id, -16.0)) + volume_offset_db
	player.play()

func _next_player() -> AudioStreamPlayer:
	if _players.is_empty():
		_ensure_players()
	var player: AudioStreamPlayer = _players[_next_player_index % _players.size()]
	_next_player_index += 1
	return player

func _event_profile(event_id: String, event_defs: Dictionary) -> String:
	if event_id == "tutorial_patrol_gap":
		return "military"
	if event_id == "tutorial_strategist_descends":
		return "strategist"
	if not event_defs.has(event_id):
		return "crisis"
	var event_data = event_defs[event_id]
	var category: String = str(event_data.category)
	var tags: Array[String] = []
	for tag_variant in event_data.tags:
		tags.append(str(tag_variant))
	if tags.has("military") or tags.has("discipline"):
		return "military"
	if category == "dream" or tags.has("rest") or tags.has("mind"):
		return "dream"
	if category == "omen" or tags.has("naval") or tags.has("research") or tags.has("intel") or tags.has("document"):
		return "omen"
	if category == "relation" or category == "rumor" or tags.has("relation") or tags.has("rumor"):
		return "relation"
	if category == "opportunity" or tags.has("search") or tags.has("recruit"):
		return "opportunity"
	if tags.has("scheme"):
		return "strategist"
	return "crisis"
func _dual(freq_a: float, freq_b: float, duration_a: float, duration_b: float, amplitude: float) -> AudioStreamWAV:
	var samples: Array = []
	_append_tone(samples, freq_a, duration_a, amplitude)
	_append_tone(samples, freq_b, duration_b, amplitude * 0.88)
	return _make_stream(samples)

func _triple(frequencies: Array, durations: Array, amplitude: float) -> AudioStreamWAV:
	var samples: Array = []
	var count: int = mini(frequencies.size(), durations.size())
	for index in range(count):
		var weight: float = maxf(0.72, 1.0 - float(index) * 0.08)
		_append_tone(samples, float(frequencies[index]), float(durations[index]), amplitude * weight)
	return _make_stream(samples)

func _sweep(freq_from: float, freq_to: float, duration: float, amplitude: float) -> AudioStreamWAV:
	var samples: Array = []
	var frame_count: int = maxi(1, int(round(duration * float(SAMPLE_RATE))))
	var phase: float = 0.0
	for frame in range(frame_count):
		var progress: float = float(frame) / float(maxi(frame_count - 1, 1))
		var current_freq: float = lerpf(freq_from, freq_to, progress)
		phase += TAU * current_freq / float(SAMPLE_RATE)
		var sample: float = sin(phase) * 0.78 + sin(phase * 0.5) * 0.22
		samples.append(sample * amplitude * _env(progress, 0.12, 0.24))
	return _make_stream(samples)

func _buzz(freq: float, duration: float, amplitude: float) -> AudioStreamWAV:
	var samples: Array = []
	var frame_count: int = maxi(1, int(round(duration * float(SAMPLE_RATE))))
	for frame in range(frame_count):
		var t: float = float(frame) / float(SAMPLE_RATE)
		var progress: float = float(frame) / float(maxi(frame_count - 1, 1))
		var carrier: float = sign(sin(TAU * freq * t)) * 0.62
		var overtone: float = sin(TAU * freq * 1.5 * t) * 0.24
		var undertone: float = sin(TAU * (freq * 0.5 + 17.0) * t) * 0.14
		samples.append((carrier + overtone + undertone) * amplitude * _env(progress, 0.04, 0.30))
	return _make_stream(samples)

func _build_bgm_stream() -> AudioStreamWAV:
	var duration: float = 14.0
	var frame_count: int = int(round(duration * float(SAMPLE_RATE)))
	var melody: Array = [196.0, 220.0, 261.63, 293.66, 329.63, 293.66, 261.63, 220.0, 196.0, 220.0, 293.66, 329.63, 392.0, 329.63, 293.66, 220.0]
	var step_duration: float = duration / float(melody.size())
	var samples: Array = []
	for frame in range(frame_count):
		var t: float = float(frame) / float(SAMPLE_RATE)
		var sample: float = sin(TAU * 98.0 * t) * (0.072 + 0.024 * sin(TAU * 0.05 * t))
		sample += sin(TAU * 49.0 * t) * 0.020
		sample += sin(TAU * 392.0 * t) * (0.010 + 0.008 * sin(TAU * 0.09 * t))
		for note_index in range(melody.size()):
			var note_start: float = float(note_index) * step_duration
			var dt: float = t - note_start
			if dt < 0.0 or dt > step_duration * 1.32:
				continue
			var attack: float = clampf(dt / 0.12, 0.0, 1.0)
			var decay: float = maxf(0.0, 1.0 - dt / (step_duration * 1.32))
			var env: float = attack * decay * decay
			var freq: float = float(melody[note_index])
			sample += sin(TAU * freq * dt) * 0.058 * env
			sample += sin(TAU * freq * 2.0 * dt) * 0.014 * env
		samples.append(sample * 0.55)
	var stream: AudioStreamWAV = _make_stream(samples, 0.78)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	return stream

func _append_tone(samples: Array, freq: float, duration: float, amplitude: float) -> void:
	var frame_count: int = maxi(1, int(round(duration * float(SAMPLE_RATE))))
	for frame in range(frame_count):
		var t: float = float(frame) / float(SAMPLE_RATE)
		var progress: float = float(frame) / float(maxi(frame_count - 1, 1))
		var sample: float = sin(TAU * freq * t) * 0.76
		sample += sin(TAU * freq * 2.0 * t) * 0.18
		sample += sin(TAU * freq * 0.5 * t) * 0.06
		samples.append(sample * amplitude * _env(progress, 0.10, 0.22))

func _env(progress: float, attack_ratio: float, release_ratio: float) -> float:
	if progress < attack_ratio:
		return clampf(progress / maxf(attack_ratio, 0.001), 0.0, 1.0)
	if progress > 1.0 - release_ratio:
		return clampf((1.0 - progress) / maxf(release_ratio, 0.001), 0.0, 1.0)
	return 1.0

func _make_stream(samples: Array, target_peak: float = 0.92) -> AudioStreamWAV:
	var peak: float = 0.0
	for sample_variant in samples:
		peak = maxf(peak, absf(float(sample_variant)))
	var gain: float = 1.0
	if peak > 0.001:
		gain = target_peak / peak
	var pcm_bytes := PackedByteArray()
	pcm_bytes.resize(samples.size() * 2)
	for index in range(samples.size()):
		var clamped: float = clampf(float(samples[index]) * gain, -1.0, 1.0)
		var pcm_value: int = int(round(clamped * 32767.0))
		if pcm_value < 0:
			pcm_value += 65536
		pcm_bytes[index * 2] = pcm_value & 0xFF
		pcm_bytes[index * 2 + 1] = (pcm_value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm_bytes
	return stream