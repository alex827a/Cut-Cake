class_name ToneFactory
extends RefCounted

static func create_cake_stack_sound() -> AudioStreamWAV:
	return _create_stack_like_sound(0.16, 0.004, 0.085)

static func create_gentle_win_sound() -> AudioStreamWAV:
	return _create_soft_chord(PackedFloat32Array([392.0, 493.88, 587.33]), 0.24, 0.16)

static func create_gentle_lose_sound() -> AudioStreamWAV:
	return _create_soft_chord(PackedFloat32Array([220.0, 196.0]), 0.28, 0.12)

static func create_menu_click_sound() -> AudioStreamWAV:
	const SAMPLE_RATE := 44100
	const DURATION_SECONDS := 0.1
	var sample_count := maxi(1, int(round(SAMPLE_RATE * DURATION_SECONDS)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var fade_in_samples := maxi(1, int(round(SAMPLE_RATE * 0.004)))
	var fade_out_samples := maxi(1, int(round(SAMPLE_RATE * 0.06)))

	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var low := sin(TAU * 280.0 * t) * exp(-t * 24.0) * 0.18
		var mid := sin(TAU * 420.0 * t) * exp(-t * 18.0) * 0.11
		var sample_value := low + mid
		var envelope := 1.0
		if i < fade_in_samples:
			envelope = float(i) / fade_in_samples
		var samples_from_end := sample_count - i
		if samples_from_end < fade_out_samples:
			envelope = minf(envelope, float(samples_from_end) / fade_out_samples)
		var filtered := tanh(sample_value * 1.1) * envelope * 0.34
		var pcm_value := int(clamp(filtered, -1.0, 1.0) * 32767.0)
		data[i * 2] = pcm_value & 0xff
		data[i * 2 + 1] = (pcm_value >> 8) & 0xff

	return _create_stream(data, SAMPLE_RATE)

static func create_cake_slice_sound() -> AudioStreamWAV:
	const SAMPLE_RATE := 44100
	const DURATION_SECONDS := 0.16
	var sample_count := maxi(1, int(round(SAMPLE_RATE * DURATION_SECONDS)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var fade_in_samples := maxi(1, int(round(SAMPLE_RATE * 0.003)))
	var fade_out_samples := maxi(1, int(round(SAMPLE_RATE * 0.085)))

	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var wet_body := sin(TAU * 170.0 * t) * exp(-t * 15.0) * 0.24
		var soft_slice := sin(TAU * 420.0 * t) * exp(-t * 21.0) * 0.11
		var airy_scrape := sin(TAU * 760.0 * t) * exp(-t * 30.0) * 0.045
		var tail := sin(TAU * 120.0 * t) * exp(-t * 9.0) * 0.08
		var wobble := sin(TAU * 34.0 * t) * exp(-t * 12.0) * 0.03
		var sample_value := wet_body + soft_slice + airy_scrape + tail + wobble
		var envelope := 1.0
		if i < fade_in_samples:
			envelope = float(i) / fade_in_samples
		var samples_from_end := sample_count - i
		if samples_from_end < fade_out_samples:
			envelope = minf(envelope, float(samples_from_end) / fade_out_samples)
		var filtered := tanh(sample_value * 1.05) * envelope * 0.42
		var pcm_value := int(clamp(filtered, -1.0, 1.0) * 32767.0)
		data[i * 2] = pcm_value & 0xff
		data[i * 2 + 1] = (pcm_value >> 8) & 0xff

	return _create_stream(data, SAMPLE_RATE)

static func _create_stack_like_sound(duration_seconds: float, fade_in_seconds: float, fade_out_seconds: float) -> AudioStreamWAV:
	const SAMPLE_RATE := 44100
	var sample_count := maxi(1, int(round(SAMPLE_RATE * duration_seconds)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var fade_in_samples := maxi(1, int(round(SAMPLE_RATE * fade_in_seconds)))
	var fade_out_samples := maxi(1, int(round(SAMPLE_RATE * fade_out_seconds)))

	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var thump := sin(TAU * 180.0 * t) * exp(-t * 26.0) * 0.32
		var body := sin(TAU * 520.0 * t) * exp(-t * 13.0) * 0.18
		var sparkle := sin(TAU * 860.0 * t) * exp(-t * 19.0) * 0.08
		var sample_value := thump + body + sparkle
		var envelope := 1.0
		if i < fade_in_samples:
			envelope = float(i) / fade_in_samples
		var samples_from_end := sample_count - i
		if samples_from_end < fade_out_samples:
			envelope = minf(envelope, float(samples_from_end) / fade_out_samples)
		var filtered := tanh(sample_value * 1.35) * envelope * 0.42
		var pcm_value := int(clamp(filtered, -1.0, 1.0) * 32767.0)
		data[i * 2] = pcm_value & 0xff
		data[i * 2 + 1] = (pcm_value >> 8) & 0xff

	return _create_stream(data, SAMPLE_RATE)

static func _create_soft_chord(frequencies: PackedFloat32Array, duration_seconds: float, amplitude: float) -> AudioStreamWAV:
	const SAMPLE_RATE := 44100
	var sample_count := maxi(1, int(round(SAMPLE_RATE * duration_seconds)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var fade_in_samples := maxi(1, int(round(SAMPLE_RATE * 0.008)))
	var fade_out_samples := maxi(1, int(round(SAMPLE_RATE * 0.12)))

	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var sample_value := 0.0
		for tone_index in range(frequencies.size()):
			var detune := 1.0 + (tone_index * 0.0035)
			sample_value += sin(TAU * frequencies[tone_index] * detune * t) * exp(-t * (5.5 + tone_index))
		sample_value /= maxf(1.0, float(frequencies.size()))

		var envelope := 1.0
		if i < fade_in_samples:
			envelope = float(i) / fade_in_samples
		var samples_from_end := sample_count - i
		if samples_from_end < fade_out_samples:
			envelope = minf(envelope, float(samples_from_end) / fade_out_samples)
		var filtered := tanh(sample_value * 0.9) * envelope * amplitude
		var pcm_value := int(clamp(filtered, -1.0, 1.0) * 32767.0)
		data[i * 2] = pcm_value & 0xff
		data[i * 2 + 1] = (pcm_value >> 8) & 0xff

	return _create_stream(data, SAMPLE_RATE)

static func _create_stream(data: PackedByteArray, sample_rate: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
