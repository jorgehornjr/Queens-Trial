shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/tutorial_ink_reveal.gdshaderinc"

void fragment() {
	COLOR.a *= book_ink_mask(SCREEN_UV);
}
