shader_type spatial;

uniform bool enabled = true;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform sampler2D LUT;

const float pixel_scale = 3.0;
const vec3 yuv_threshold = vec3(0.188235294, 0.02745098, 0.023529412);
const mat3 yuv = mat3(vec3(0.299, -0.14713, 0.615), vec3(0.587, -0.2886, -0.436), vec3(0.615, 0.5149, -0.1));
const vec3 yuv_offset = vec3(0.0, 0.5, 0.5);

float diff(vec3 yuv1, vec3 yuv2){
	bvec3 res = greaterThan(abs((yuv1 + yuv_offset) - (yuv2 + yuv_offset)), yuv_threshold);
	return float(res.x || res.y || res.z);
}

varying vec4 t1;
varying vec4 t2;
varying vec4 t3;

void vertex(){
	vec2 pixel_size = 1.0/vec2(textureSize(texture_albedo, 0));
	t1 = UV.xxxy + vec4(-pixel_size.x, 0.0, pixel_size.x, -pixel_size.y);
	t2 = UV.xxxy + vec4(-pixel_size.x, 0.0, pixel_size.x, 0.0);
	t3 = UV.xxxy + vec4(-pixel_size.x, 0.0, pixel_size.x, pixel_size.y);
}

void fragment(){
	
	vec3 p1 = texture(texture_albedo, UV).rgb;
	vec3 res = p1;
	if (enabled){
		float lod = 0.0;
		vec3 w1 = yuv * texture(texture_albedo, t1.xw).rgb; // -1 , -1
		vec3 w2 = yuv * texture(texture_albedo, t1.yw).rgb; //  0 , -1
		vec3 w3 = yuv * texture(texture_albedo, t1.zw).rgb; //  1 , -1
		
		vec3 w4 = yuv * texture(texture_albedo, t2.xw).rgb; // -1 ,  0
		vec3 w5 = yuv * texture(texture_albedo, t2.yw).rgb; //  0 ,  0
		vec3 w6 = yuv * texture(texture_albedo, t2.zw).rgb; //  1 ,  0
		
		vec3 w7 = yuv * texture(texture_albedo, t3.xw).rgb; // -1 ,  1
		vec3 w8 = yuv * texture(texture_albedo, t3.yw).rgb; //  0 ,  1
		vec3 w9 = yuv * texture(texture_albedo, t3.zw).rgb; //  1 ,  1
		
		vec3 pattern_1 = vec3(diff(w5,w1), diff(w5,w2), diff(w5, w3));
		vec3 pattern_2 = vec3(diff(w5, w4), 0.0, diff(w5, w6));
		vec3 pattern_3 = vec3(diff(w5, w7), diff(w5, w8), diff(w5, w9));
		vec4 _cross = vec4(diff(w4, w2), diff(w2, w6), diff(w8, w4), diff(w6, w8));
		
		vec2 image_size = vec2(textureSize(texture_albedo, 0));
		vec2 pixel_size = (1.0/image_size) * 0.99;
		vec2 fp = fract(UV * image_size);
		vec2 quad = sign(-0.5 + fp);
		
		vec2 index;
		index.x =	dot(pattern_1, vec3(1, 2, 4)) +
					dot(pattern_2, vec3(8, 0, 16)) +
					dot(pattern_3, vec3(32, 64, 128));
		index.y =	dot(_cross, vec4(1, 2, 4, 8));
		
		index.y *= (pixel_scale*pixel_scale);
		index.y += dot(floor(fp * pixel_scale), vec2(1.0, pixel_scale));
		
		
		vec3 p2 = texture(texture_albedo, UV + pixel_size * quad).rgb;
		vec3 p3 = texture(texture_albedo, UV + vec2(pixel_size.x, 0.0) * quad).rgb;
		vec3 p4 = texture(texture_albedo, UV + vec2(0.0, pixel_size.y) * quad).rgb;
		
		vec2 _step = 1.0 / vec2(256.0, 16.0 * (pixel_scale * pixel_scale));
		vec2 offset = _step / 2.0;
		vec4 weights = texture(LUT, index * _step + offset);
		float sum = dot(weights, vec4(1.0));
		vec4 tmp = weights/sum;
		res = tmp.x * p1.xyz;
		res += tmp.y * p2.xyz;
		res += tmp.z * p3.xyz;
		res += tmp.w * p4.xyz;
		
	}
	ALBEDO = res;
}