shader_type spatial;
render_mode cull_disabled, skip_vertex_transform;

uniform sampler2D texture_albedo:hint_white;
uniform vec4 albedo:hint_color = vec4(1.0);
uniform vec4 front_region = vec4(0.0);
uniform vec4 side_region = vec4(0.0);
uniform vec4 back_region = vec4(0.0);
uniform vec2 uv_offset = vec2(0.0);

vec3 srgb(vec3 rgb){
	return mix(pow((rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),rgb.rgb * (1.0 / 12.92),lessThan(rgb.rgb,vec3(0.04045)));
}

bool alpha_dither(float x, float y, float alpha){
	int _x = int(x) % 4;
	int _y = int(y) % 4;
	int index = _x + _y * 4;
	float limit = 0.0;

	if (_x < 8) {
		if (index == 0) limit = 0.0625;
		if (index == 1) limit = 0.5625;
		if (index == 2) limit = 0.1875;
		if (index == 3) limit = 0.6875;
		if (index == 4) limit = 0.8125;
		if (index == 5) limit = 0.3125;
		if (index == 6) limit = 0.9375;
		if (index == 7) limit = 0.4375;
		if (index == 8) limit = 0.25;
		if (index == 9) limit = 0.75;
		if (index == 10) limit = 0.125;
		if (index == 11) limit = 0.625;
		if (index == 12) limit = 0.99;
		if (index == 13) limit = 0.5;
		if (index == 14) limit = 0.875;
		if (index == 15) limit = 0.375;
	}
	return alpha < limit;
}

varying flat float angle;
varying flat float side_dot;

void vertex(){
	
	mat4 world_matrix = mat4(CAMERA_MATRIX[0],WORLD_MATRIX[1],vec4(normalize(cross(CAMERA_MATRIX[0].xyz,WORLD_MATRIX[1].xyz)), 0.0),WORLD_MATRIX[3]);
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * world_matrix;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(WORLD_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, 1.0, 0.0, 0.0),vec4(0.0, 0.0, length(WORLD_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	
	vec3 camera_dir = (inverse(world_matrix) * vec4(0.0,0.0,-1.0,0.0)).xyz;
	vec3 view_dir = (inverse(WORLD_MATRIX) * vec4(0.0, 0.0, -1.0,0.0)).xyz;
	vec3 side_dir = (inverse(WORLD_MATRIX) * vec4(-1.0, 0.0, 0.0 ,0.0)).xyz;
	angle = acos(dot(normalize(camera_dir), normalize(view_dir)));
	side_dot = dot(normalize(camera_dir), normalize(side_dir));
	
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    NORMAL = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

vec2 region_to_uv(vec2 uv, vec4 region, vec2 size){
	return uv * (region.zw / vec2(size)) + (region.xy / vec2(size)) + (uv_offset / size);
}

void fragment(){
	vec2 texture_size = vec2(textureSize(texture_albedo, 0));
	
	vec4 color;
	
	if (angle > radians(135.0)){
		color = texture(texture_albedo,region_to_uv(UV, back_region, texture_size));
	}else if (angle > radians(45.0)){
		if (side_dot > 0.0){
			color = texture(texture_albedo, region_to_uv(vec2(1.0-UV.x,UV.y), side_region, texture_size));
		}else{
			color = texture(texture_albedo, region_to_uv(UV, side_region, texture_size));
		}
	}else{
		color = texture(texture_albedo, region_to_uv(UV, front_region, texture_size));
	}
	color *= albedo * COLOR;
	ALBEDO = srgb(color.rgb);
	
	if (alpha_dither(FRAGCOORD.x, FRAGCOORD.y, color.a)){
		discard;
	}
}