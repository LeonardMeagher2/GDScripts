shader_type canvas_item;

const mat4 yuv = mat4(
	vec4(0.299, -0.14713, 0.615, 0.0),
	vec4(0.587, -0.2886, -0.436, 0.0),
	vec4(0.615,  0.5149,   -0.1, 0.0),
	vec4(  0.0,     0.0,    0.0, 1.0)
);

uniform sampler2D LUT;

varying vec4 t1;
varying vec4 t2;
varying vec4 t3;

float yuv_threshold(vec4 yuv1, vec4 yuv2){
	const vec4 yuv_threshold = vec4(0.188235294, 0.02745098, 0.023529412, 0.1);
	const vec4 yuv_offset = vec4(0.0, 0.5, 0.5, 0.0);
	
	bvec4 res = greaterThan(abs((yuv1 + yuv_offset) - (yuv2 + yuv_offset)), yuv_threshold);
	
	return float(res.x || res.y || res.z || res.w);
}

void vertex(){
	t1 = UV.xxxy + vec4(-TEXTURE_PIXEL_SIZE.x, 0.0, TEXTURE_PIXEL_SIZE.x, -TEXTURE_PIXEL_SIZE.y);
	t2 = UV.xxxy + vec4(-TEXTURE_PIXEL_SIZE.x, 0.0, TEXTURE_PIXEL_SIZE.x, 0.0);
	t3 = UV.xxxy + vec4(-TEXTURE_PIXEL_SIZE.x, 0.0, TEXTURE_PIXEL_SIZE.x, TEXTURE_PIXEL_SIZE.y);
}

void fragment() {
	vec2 image_size = 1.0/TEXTURE_PIXEL_SIZE;
	vec2 fp = fract(UV * image_size);
	vec2 quad = sign(-0.5 + fp);
	
	vec4 p1 = texture(TEXTURE, UV);
	vec4 p2 = texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * quad);
	vec4 p3 = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0) * quad);
	vec4 p4 = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y) * quad);
	
	vec4 w1 = yuv * texture(TEXTURE, t1.xw); // -1 , -1
	vec4 w2 = yuv * texture(TEXTURE, t1.yw); //  0 , -1
	vec4 w3 = yuv * texture(TEXTURE, t1.zw); //  1 , -1
	
	vec4 w4 = yuv * texture(TEXTURE, t2.xw); // -1 ,  0
	vec4 w5 = yuv * texture(TEXTURE, t2.yw); //  0 ,  0
	vec4 w6 = yuv * texture(TEXTURE, t2.zw); //  1 ,  0
	
	vec4 w7 = yuv * texture(TEXTURE, t3.xw); // -1 ,  1
	vec4 w8 = yuv * texture(TEXTURE, t3.yw); //  0 ,  1
	vec4 w9 = yuv * texture(TEXTURE, t3.zw); //  1 ,  1
		
	vec3 pattern_1 = vec3(yuv_threshold(w5, w1), yuv_threshold(w5 ,w2), yuv_threshold(w5, w3));
	vec3 pattern_2 = vec3(yuv_threshold(w5, w4), 0.0, yuv_threshold(w5, w6));
	vec3 pattern_3 = vec3(yuv_threshold(w5, w7), yuv_threshold(w5, w8), yuv_threshold(w5, w9));
	vec4 _cross = vec4(yuv_threshold(w4, w2), yuv_threshold(w2, w6), yuv_threshold(w8, w4), yuv_threshold(w6, w8));
	
	vec2 index;
	index.x =	dot(pattern_1, vec3(1, 2, 4)) +
				dot(pattern_2, vec3(8, 0, 16)) +
				dot(pattern_3, vec3(32, 64, 128));
	index.y =	dot(_cross, vec4(1, 2, 4, 8));
	
	index.y *= 9.0;
	index.y += dot(floor(fp * 3.0), vec2(1.0, 3.0));
	
	vec2 _step = 1.0 / vec2(256.0, 144.0);
	vec2 offset = _step / 2.0;
	vec4 weights = texture(LUT, index * _step + offset);
	float sum = dot(weights, vec4(1.0));
	vec4 tmp = weights/sum;
	
	vec4 res = tmp.x * p1;
	res += tmp.y * p2;
	res += tmp.z * p3;
	res += tmp.w * p4;
	
	COLOR = res;
}
