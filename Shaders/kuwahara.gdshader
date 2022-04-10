shader_type canvas_item;

uniform int kernal_size = 5;
uniform float pixel_scale = 1.0;

struct region {
	vec4 mean;
	float variance;
};

region calc_region(ivec2 lower, ivec2 upper, int samples, sampler2D tex, vec2 uv){
	region r;
	vec4 sum = vec4(0.0);
	vec4 square_sum = vec4(0.0);
	
	ivec2 texture_size = textureSize(tex, 0);
	vec2 pixel_size = 1.0 / vec2(texture_size) * pixel_scale;
	
	for(int x = lower.x; x <= upper.x; ++x){
		for(int y = lower.y; y <= upper.y; ++y){
			vec2 offset = pixel_size * vec2(float(x),float(y));
			vec4 sample = texture(tex, uv + offset);
			
			sum += sample;
			square_sum += sample * sample;
		}
	}
	
	r.mean = sum / float(samples);
	r.variance = length(abs((square_sum / float(samples)) - (r.mean * r.mean)));
	
	return r;
}

void fragment(){
	int upper = (kernal_size-1)/2;
	int lower = -upper;
	int samples = (upper + 1) * (upper + 1);
	
	region a = calc_region(ivec2(lower), ivec2(0), samples, TEXTURE, UV);
	region b = calc_region(ivec2(0,lower), ivec2(upper, 0), samples, TEXTURE, UV);
	region c = calc_region(ivec2(lower,0), ivec2(0, upper), samples, TEXTURE, UV);
	region d = calc_region(ivec2(0), ivec2(upper), samples, TEXTURE, UV);
	
	vec4 color = a.mean;
	float minimum_variance = a.variance;
	
	// Test Region B
	float blend = step(b.variance, minimum_variance);
	color = mix(color, b.mean, blend);
	// Test Region C
	blend = step(c.variance, minimum_variance);
	color = mix(color, c.mean, blend);
	// Test Region D
	blend = step(d.variance, minimum_variance);
	color = mix(color, d.mean, blend);
	
	COLOR = color;
}