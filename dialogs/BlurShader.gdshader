shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount: hint_range(0.0, 5.0, 0.1) = 4;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 result = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount).rgb;
	COLOR.rgb = result;
	COLOR.rgb = vec3(result.r / 3.0, result.g / 3.0, result.b / 3.0);
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
