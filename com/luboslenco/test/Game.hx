package com.luboslenco.test;

import wings.math.Vec3;
import wings.wxd.events.UpdateEvent;
import wings.wxd.Time;
import wings.w3d.cameras.PerspectiveCamera;
import wings.w3d.meshes.Mesh;
import wings.w3d.meshes.CubeGeometry;
import wings.w3d.scene.Model;
import wings.w3d.materials.TextureMaterial;
import wings.w3d.Scene;
import wings.Root;

class Game {

    var model:Model;

    public function new() {

        // Create a camera at position x = 0, y = 1, z = 3
        var camera = new PerspectiveCamera(new Vec3(0, 1, 3));

        // Look down 15 degrees
        camera.pitch(-15);

        // Create empty scene
        var scene = new Scene(camera);
        Root.addChild(scene);

        // Create cube geometry of size 1x1x1
        var geometry = new CubeGeometry(1, 1, 1);

        // Create material with default shader and box texture
        var material = new TextureMaterial(R.shader, R.box);

        // Create cube mesh
        var mesh = new Mesh(geometry, material);

        // Create model that renders cube mesh
        model = new Model(mesh);

        // Set shader uniforms(you can write your own glsl shaders)
        // Default shader needs model-view-projection matrix
        model.setMat4(model.mvpMatrix);

        // Add cube to scene
        scene.addChild(model);

        // Listen to update event
        Root.addEvent(new UpdateEvent(onUpdate));
    }

    function onUpdate() {

        // Rotate cube on Y axis
        model.rotateY(Time.delta * 0.001);
    }
}
