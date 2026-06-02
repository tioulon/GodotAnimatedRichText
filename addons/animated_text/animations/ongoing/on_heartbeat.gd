## Heartbeat — a double-thump scale pulse (lub-dub) with a rest between beats.
## Distinct from OnPulse/OnBreathe which are smooth single sines.
@tool
class_name OnHeartbeat
extends OngoingAnimation

@export var amount: float = 0.18
@export var bpm: float = 60.0          ## beats per minute

func _init() -> void:
	resource_name = "OnHeartbeat"

func apply(mod: CharMod, time: float, _idx: int, _total: int) -> void:
	var period := 60.0 / maxf(bpm, 1.0)
	var p: float = fmod(time, period) / period      # 0..1 within one beat
	# two quick thumps early in the cycle, then flat rest
	var beat := 0.0
	if p < 0.12:
		beat = sin(p / 0.12 * PI)
	elif p < 0.30:
		beat = sin((p - 0.18) / 0.12 * PI) * 0.6
	var s := 1.0 + maxf(beat, 0.0) * amount
	mod.scale *= Vector2(s, s)
