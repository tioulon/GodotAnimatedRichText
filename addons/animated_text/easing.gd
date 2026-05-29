## Easing — shared easing function library.
##
## Used by all animation resources. Static so there's zero per-instance cost.
## Animations can also supply a custom Curve which overrides the enum.
@tool
class_name ATEasing
extends RefCounted

enum Type {
	LINEAR,
	IN_QUAD, OUT_QUAD, IN_OUT_QUAD,
	IN_CUBIC, OUT_CUBIC, IN_OUT_CUBIC,
	IN_QUART, OUT_QUART, IN_OUT_QUART,
	IN_EXPO, OUT_EXPO, IN_OUT_EXPO,
	OUT_BOUNCE, IN_BOUNCE,
	OUT_ELASTIC, IN_ELASTIC,
	IN_BACK, OUT_BACK, IN_OUT_BACK,
	OUT_SINE, IN_SINE, IN_OUT_SINE,
}

## Apply an easing Type to a normalized [0..1] value.
static func apply(t: float, type: Type) -> float:
	t = clampf(t, 0.0, 1.0)
	match type:
		Type.LINEAR:       return t
		Type.IN_QUAD:      return t * t
		Type.OUT_QUAD:     return t * (2.0 - t)
		Type.IN_OUT_QUAD:  return 2.0*t*t if t < 0.5 else -1.0 + (4.0 - 2.0*t)*t
		Type.IN_CUBIC:     return t*t*t
		Type.OUT_CUBIC:    var u := 1.0-t; return 1.0 - u*u*u
		Type.IN_OUT_CUBIC: return 4.0*t*t*t if t < 0.5 else 1.0 - pow(-2.0*t+2.0,3.0)*0.5
		Type.IN_QUART:     return t*t*t*t
		Type.OUT_QUART:    var u := 1.0-t; return 1.0 - u*u*u*u
		Type.IN_OUT_QUART: return 8.0*t*t*t*t if t < 0.5 else 1.0 - pow(-2.0*t+2.0,4.0)*0.5
		Type.IN_EXPO:      return 0.0 if t == 0.0 else pow(2.0, 10.0*t - 10.0)
		Type.OUT_EXPO:     return 1.0 if t == 1.0 else 1.0 - pow(2.0, -10.0*t)
		Type.IN_OUT_EXPO:
			if t == 0.0: return 0.0
			if t == 1.0: return 1.0
			return pow(2.0, 20.0*t-10.0)*0.5 if t < 0.5 else (2.0 - pow(2.0,-20.0*t+10.0))*0.5
		Type.OUT_BOUNCE:   return _bounce(t)
		Type.IN_BOUNCE:    return 1.0 - _bounce(1.0 - t)
		Type.OUT_ELASTIC:  return _elastic(t)
		Type.IN_ELASTIC:   return 1.0 - _elastic(1.0 - t)
		Type.IN_BACK:      var c := 1.70158; return (c+1.0)*t*t*t - c*t*t
		Type.OUT_BACK:     var c := 1.70158; var u := t-1.0; return 1.0 + (c+1.0)*u*u*u + c*u*u
		Type.IN_OUT_BACK:
			var c1 := 1.70158; var c2 := c1*1.525
			if t < 0.5: return (pow(2.0*t,2.0)*((c2+1.0)*2.0*t - c2))*0.5
			return (pow(2.0*t-2.0,2.0)*((c2+1.0)*(2.0*t-2.0)+c2)+2.0)*0.5
		Type.OUT_SINE:     return sin(t * PI * 0.5)
		Type.IN_SINE:      return 1.0 - cos(t * PI * 0.5)
		Type.IN_OUT_SINE:  return -(cos(PI*t) - 1.0) * 0.5
	return t

## Resolve easing: a custom curve takes priority over the enum type.
static func resolve(t: float, type: Type, curve: Curve) -> float:
	if curve:
		return curve.sample(clampf(t, 0.0, 1.0))
	return apply(t, type)

static func _bounce(t: float) -> float:
	var n1 := 7.5625; var d1 := 2.75
	if t < 1.0/d1: return n1*t*t
	elif t < 2.0/d1: t -= 1.5/d1;  return n1*t*t + 0.75
	elif t < 2.5/d1: t -= 2.25/d1; return n1*t*t + 0.9375
	else: t -= 2.625/d1; return n1*t*t + 0.984375

static func _elastic(t: float) -> float:
	if t <= 0.0: return 0.0
	if t >= 1.0: return 1.0
	return pow(2.0, -10.0*t) * sin((t*10.0 - 0.75) * (TAU/3.0)) + 1.0
