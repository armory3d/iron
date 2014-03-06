package com.luboslenco.test;

import kha.graphics.Texture;
import kha.Font;
import wings.wxd.Assets;
import wings.w3d.materials.Shader;
import wings.w3d.materials.VertexStructure;
import wings.w3d.meshes.Geometry;

class R {

	public static var font:Font;
	public static var shader:Shader;
	
	public function new() {

		font = Assets.getFont("Arial", 18);
		wings.w2d.ui.Theme.FONT = font;


		var struct = new VertexStructure();
		struct.addFloat3("vertexPosition");
		struct.addFloat2("texturePosition");
		struct.addFloat3("normalPosition");
		Geometry.structure = struct;

		shader = new Shader("default.frag", "default.vert", struct);
		shader.addConstantMat4("mvpMatrix");
		shader.addTexture("tex");
	}	
}
