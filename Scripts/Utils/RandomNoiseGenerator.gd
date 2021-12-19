extends Reference
class_name RandomNoiseGenerator

# Noise functions and Noise based random number generator based on talks from GDC's Math for programmers

const PG = PoolVector2Array([
	Vector2(1,1), Vector2(-1,1),
	Vector2(1,-1), Vector2(-1,-1),
	Vector2(0, 1), Vector2(1,0),
	Vector2(0, -1), Vector2(-1, 0)
])

const MAX_INT = 4294967295
const MAX_FLOAT = 4294967295.0

var _state:int = 0
var _seed:int = 0

func _init(noise_seed:int = 0):
	_seed = noise_seed

func seed(noise_seed:int = _seed):
	_state = 0
	_seed = noise_seed

# Util functions
func _smooth(i:float, factor:float = 1.0) -> float:
	var ii = int(i)
	var f = i - ii
	var smoothf = (f*f*(3.0-2.0*f))
	if factor >= 1.0:
		return ii + smoothf
	elif factor <= 0.0:
		return ii + f
	return ii + lerp(f, smoothf, factor)

# Functions that do not modify state

func inoise(i:int, noise_seed:int = _seed) -> int:
	i *= 0xb5297a4d
	i += noise_seed
	i ^= i >> 8
	i += 0x68e31da4
	i ^= i << 8
	i *= 0x1b56c4e9
	i ^= i >> 8
	return i % MAX_INT

func inoise_2d(x:int, y:int, noise_seed:int = _seed) -> int:
	return inoise(x + (198491317 * y), noise_seed)
func inoise_3d(x:int, y:int, z:int, noise_seed:int = _seed) -> int:
	return inoise(x + (198491317 * y) + (6542989 * z), noise_seed)
func inoise_4d(x:int, y:int, z:int, w:int, noise_seed:int = _seed) -> int:
	return inoise(x + (198491317 * y) + (6542989 * z) + (92399 * w), noise_seed)

func noise(i:float, noise_seed:int = _seed) -> float:
	return float(inoise(i, noise_seed))/MAX_FLOAT * 2.0 - 1.0
func noise_2d(x:float, y:float, noise_seed:int = _seed) -> float:
	return float(inoise_2d(x,y,noise_seed))/MAX_FLOAT * 2.0 - 1.0
func noise_3d(x:float, y:float, z:float, noise_seed:int = _seed) -> float:
	return float(inoise_3d(x,y,z,noise_seed))/MAX_FLOAT * 2.0 - 1.0
func noise_4d(x:float, y:float, z:float, w:float, noise_seed:int = _seed) -> float:
	return float(inoise_4d(x,y,z,w,noise_seed))/MAX_FLOAT * 2.0 - 1.0

func random_direction_2d(x:float,y:float, noise_seed:int = _seed) -> Vector2:
	var theta = noise_2d(x, y, noise_seed) * PI
	return Vector2(cos(theta), sin(theta)).normalized()

func jitter_2d(x:float, y:float, factor:float = 1.0, noise_seed:int = _seed) -> Vector2:
	var res = random_direction_2d(x,y, noise_seed) * noise_2d(x,y, noise_seed) * factor
	return Vector2(x, y) + res

func perlin_2d(x:float, y:float, smoothing:float = 1.0, width:int = MAX_INT, height:int = MAX_INT, noise_seed:int = _seed) -> float:
	var ix:int = int(x)
	var iy:int = int(y)
	var nx:int = (ix + 1)
	var ny:int = (iy + 1)
	
	# get corner gradients
	var g1 = PG[inoise_2d(ix % width, iy % height, noise_seed) % 8]
	var g2 = PG[inoise_2d(nx % width, iy % height, noise_seed) % 8]
	var g3 = PG[inoise_2d(ix % width, ny % height, noise_seed) % 8]
	var g4 = PG[inoise_2d(nx % width, ny % height, noise_seed) % 8]
	
	# get direction to corners from current position
	
	var d1 = Vector2(x-ix, y-iy)
	var d2 = Vector2(x-nx, y-iy)
	var d3 = Vector2(x-ix, y-ny)
	var d4 = Vector2(x-nx, y-ny)
	
	# compare the directions vs gradients
	var v1 = d1.dot(g1)
	var v2 = d2.dot(g2)
	var v3 = d3.dot(g3)
	var v4 = d4.dot(g4)
	
	var sx = _smooth(x-ix, smoothing)
	var sy = _smooth(y-iy, smoothing)
	
	# Bilinear interpolate towards the actual direction
	var l1 = lerp(v1, v2, sx)
	var l2 = lerp(v3, v4, sx)
	return clamp(lerp(l1, l2, sy), -1, 1)

func value_noise(i:float, smoothing:float = 1.0, width:int = MAX_INT, noise_seed:int = _seed) -> float:
	var a = noise(i, noise_seed)
	var b = noise((int(i)+1) % width, noise_seed)
	return lerp(a, b, _smooth(i-int(i), smoothing))

func value_noise_2d(x:float, y:float, smoothing:float = 1.0, width:int = MAX_INT, height:int = MAX_INT, noise_seed:int = _seed) -> float:
	var ix:int = int(x) % width
	var iy:int = int(y) % height
	var nx:int = (ix + 1) % width
	var ny:int = (iy + 1) % height
	var v1 = noise_2d(ix, iy, noise_seed)
	var v2 = noise_2d(nx, iy, noise_seed)
	var v3 = noise_2d(ix, ny, noise_seed)
	var v4 = noise_2d(nx, ny, noise_seed)
	
	var sx = _smooth(x-int(x), smoothing)
	var sy = _smooth(y-int(y), smoothing)
	
	var l1 = lerp(v1, v2, sx)
	var l2 = lerp(v3, v4, sx)
	return clamp(lerp(l1, l2, sy), -1, 1)

# Functions that modify state
func randi() -> int:
	var val = inoise(_state, _seed)
	_state += 1
	return val

func randf() -> float:
	var val = noise(_state, _seed)
	_state += 1
	return val

func rand_range(minimum:float, maximum:float):
	var val = (self.randf() + 1.0) * 0.5 # convert to 0 - 1
	return val * (maximum - minimum) + minimum

func probability(percentage:float) -> bool:
	return self.rand_range(0, 100) < percentage

func randomize():
	self.seed(OS.get_system_time_msecs())

func pick_rand(arr:Array):
	return arr[self.randi() % arr.size()]

func weighted_random(weights:PoolRealArray) -> int:
	# Given an of array of weights, choose a random index
	var total_weight:float = 0
	var weight_sums:Array
	for w in weights:
		total_weight += w
		weight_sums.append(total_weight)
	
	var weight = self.rand_range(0,total_weight)
	return weight_sums.bsearch(weight, true)
