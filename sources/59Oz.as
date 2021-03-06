package {
    import flash.display.*;
    import flash.events.*;
    [SWF(width = "465", height = "465", frameRate = "60")]
    
    public class Cloth extends Sprite {
        private var r:Renderer;
        private var clt:Model;
        private var c:Model;
        private var vs:Vector.<Vtx>;
        private var ss:Vector.<Spring>;
        private var numVertices:uint;
        private var numFaces:uint;
        private var numSprings:uint;
        private var w:uint;
        private var h:uint;
        private var cnt:uint;
        
        public function Cloth():void {
            if (stage) init();
            else addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        private function init(e:Event = null):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            reset();
            stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent = null):void {
                if (vs[0].fix) vs[0].fix = false;
                else if (vs[w * h - 1].fix) vs[w * h - 1].fix = false;
                else if (vs[w - 1].fix) vs[w - 1].fix = false;
                else if (vs[w * h - w].fix) vs[w * h - w].fix = false;
            });
        }
        
        private function reset():void {
            removeEventListener(Event.ENTER_FRAME, loop);
            cnt = 0;
            r = new Renderer(465, 465);
            r.ambient(0.6, 0.6, 0.6);
            r.light(0).directional(0, -2, 0, 1, 1, 1);
            addChild(r.image);
            c = new Model();
            c.toCylinder(1, 128, 24);
            var i:int;
            var j:int;
            clt = new Model();
            w = 32;
            h = 32;
            numVertices = w * h;
            vs = new Vector.<Vtx>(numVertices, true);
            clt.vertices = new Vector.<Vertex>(numVertices, true);
            for (i = 0; i < w; i++) {
                for (j = 0; j < h; j++) {
                    var index:uint = j * w + i;
                    clt.vertices[index] = new Vertex(i * 4 - (w - 1) * 2, 60, j * 4 - (h - 1) * 2);
                    vs[index] = new Vtx(clt.vertices[index].pos);
                }
            }
            vs[0].fix = vs[w - 1].fix = vs[w * h - w].fix = vs[w * h - 1].fix = true;
            numFaces = (w - 1) * (h - 1) * 2;
            clt.faces = new Vector.<Vector.<uint>>(numFaces, true);
            var face:uint = 0;
            for (i = 0; i < w - 1; i++) {
                for (j = 0; j < h - 1; j++) {
                    index = j * w + i;
                    clt.faces[face] = new Vector.<uint>(3, true);
                    clt.faces[face][0] = index;
                    clt.faces[face][1] = index + 1;
                    clt.faces[face++][2] = index + w + 1;
                    clt.faces[face] = new Vector.<uint>(3, true);
                    clt.faces[face][0] = index;
                    clt.faces[face][1] = index + w + 1;
                    clt.faces[face++][2] = index + w;
                }
            }
            var spring:uint = 0;
            ss = new Vector.<Spring>();
            for (i = 0; i < w; i++) {
                for (j = 0; j < h; j++) {
                    index = j * w + i;
                    if(i < w - 1) ss[spring++] = new Spring(vs[index], vs[index + 1]);
                    if(j < h - 1) ss[spring++] = new Spring(vs[index], vs[index + w]);
                    if(i < w - 2) ss[spring++] = new Spring(vs[index], vs[index + 2]);
                    if(j < h - 2) ss[spring++] = new Spring(vs[index], vs[index + w * 2]);
                    if(i < w - 1 && j < h - 1) ss[spring++] = new Spring(vs[index], vs[index + w + 1]);
                    if(i > 0 && j < h - 1) ss[spring++] = new Spring(vs[index], vs[index + w - 1]);
                }
            }
            numSprings = spring;
            addEventListener(Event.ENTER_FRAME, loop);
        }
        
        private function loop(e:Event = null):void {
            cnt++;
            var theta:Number = mouseX / 50;
            r.lookAt(new Vec3D(Math.cos(theta) * 150, 150, Math.sin(theta) * 150), new Vec3D(), new Vec3D(0, 1, 0));
            move();
            if (cnt % 2 == 0) return;
            r.beginScene(0);
            r.material(0.2, 0.8, 0, 0, 0, 1, 0.2, 0.2);
            r.enableCulling(false);
            clt.render(r);
            r.enableCulling(true);
            r.material(0.2, 0.8, 0.6, 8, 0, 0.6, 0.6, 0.6);
            r.push();
            r.translate(0, 20, 5);
            r.scale(1, 10, 10);
            r.rotateZ(Math.PI / 2);
            c.render(r);
            r.pop();
            r.push();
            r.translate(0, -20, 0);
            r.scale(10, 10, 1);
            r.rotateX(Math.PI / 2);
            c.render(r);
            r.pop();
            r.endScene();
        }
        
        private function move():void {
            var i:int;
            for (i = 0; i < numSprings; i++) ss[i].move();
            for (i = 0; i < numVertices; i++) vs[i].move();
            if (vs[0].pos.y < -500) reset();
        }
    }
}

class Vtx {
    public var pos:Vec3D;
    public var vel:Vec3D;
    public var fix:Boolean;
    
    public function Vtx(pos:Vec3D) {
        this.pos = pos;
        vel = new Vec3D();
        fix = false;
    }
    
    public function move():void {
        vel.y -= 0.05;
        if (fix) vel.setVector(0, 0, 0);
        pollX(20, 5, 15);
        pollZ(0, -20, 15);
        pos.addEqual(vel);
    }
    
    private function abs(a:Number):Number {
        return a > 0 ? a : -a;
    }
    
    public function sphere(x:Number, y:Number, z:Number, r:Number):void {
        var dx:Number = pos.x - x;
        var dy:Number = pos.y - y;
        var dz:Number = pos.z - z;
        var len:Number = dx * dx + dy * dy + dz * dz;
        if (len < r * r) {
            len = Math.sqrt(len);
            var p:Number = r - len;
            len = 1 / len;
            dx *= len;
            dy *= len;
            dz *= len;
            var d:Number = vel.x * dx + vel.y * dy + vel.z * dz;
            if (d > 0) d = 0;
            vel.x -= dx * d;
            vel.y -= dy * d;
            vel.z -= dz * d;
        }
    }
    
    public function pollX(y:Number, z:Number, r:Number):void {
        var dy:Number = pos.y - y;
        var dz:Number = pos.z - z;
        var len:Number = dy * dy + dz * dz;
        if (len < r * r) {
            len = Math.sqrt(len);
            var p:Number = r - len;
            len = 1 / len;
            dy *= len;
            dz *= len;
            var d:Number = vel.y * dy + vel.z * dz;
            if (d > 0) d = 0;
            vel.y -= dy * d;
            vel.z -= dz * d;
        }
    }
    
    public function pollZ(x:Number, y:Number, r:Number):void {
        var dx:Number = pos.x - x;
        var dy:Number = pos.y - y;
        var len:Number = dx * dx + dy * dy;
        if (len < r * r) {
            len = Math.sqrt(len);
            var p:Number = r - len;
            len = 1 / len;
            dx *= len;
            dy *= len;
            var d:Number = vel.x * dx + vel.y * dy;
            if (d > 0) d = 0;
            vel.x -= dx * d;
            vel.y -= dy * d;
        }
    }
}

class Spring {
    private var v1:Vtx;
    private var v2:Vtx;
    private var rest:Number;
    
    public function Spring(v1:Vtx, v2:Vtx) {
        this.v1 = v1;
        this.v2 = v2;
        rest = v2.pos.sub(v1.pos).length();
    }
    
    public function move():void {
        var k1:Number = 0.5;
        var k2:Number = 0.5;
        if (v1.fix) k1 = 0, k2 = 1;
        if (v2.fix) k1 = 1, k2 = 0;
        var dx:Number = v1.pos.x - v2.pos.x;
        var dy:Number = v1.pos.y - v2.pos.y;
        var dz:Number = v1.pos.z - v2.pos.z;
        var len:Number = Math.sqrt(dx * dx + dy * dy + dz * dz);
        var p:Number = rest - len;
        len = 1 / len;
        p = len * (p * 0.6 + (dx * (v2.vel.x - v1.vel.x) + dy * (v2.vel.y - v1.vel.y) + dz * (v2.vel.z - v1.vel.z)) * len);
        dx *= p;
        dy *= p;
        dz *= p;
        v1.vel.x += dx * k1;
        v1.vel.y += dy * k1;
        v1.vel.z += dz * k1;
        v2.vel.x -= dx * k2;
        v2.vel.y -= dy * k2;
        v2.vel.z -= dz * k2;
    }
}

import flash.display.*;

class Renderer {
    private var img:BitmapData;
    private var fBuffer:Vector.<uint>;
    private var zBuffer:Vector.<Number>;
    private var bitmap:Bitmap;
    
    private var width:uint;
    private var height:uint;
    private var aspect:Number;
    private var width2:uint;
    private var height2:uint;
    private var size:uint;
    private var near:uint;
    private var far:uint;
    
    private var cameraPosition:Vec3D;
    private var cameraTarget:Vec3D;
    private var cameraUp:Vec3D;
    
    private var worldMatrix:Mat4x4;
    private var viewMatrix:Mat4x4;
    private var projectionMatrix:Mat4x4;
    
    private var numStacks:int;
    private var stack:Vector.<Mat4x4>;
    private var color:uint;
    
    private var amb:Number;
    private var dif:Number;
    private var spc:Number;
    private var shn:Number;
    private var emi:Number;
    private var r:Number;
    private var g:Number;
    private var b:Number;
    
    private var lights:Vector.<Light>;
    private var ambr:Number;
    private var ambg:Number;
    private var ambb:Number;
    
    private var culling:Boolean;
    
    public function Renderer(width:uint, height:uint) {
        img = new BitmapData(width, height, false, 0);
        bitmap = new Bitmap(img);
        this.width = width;
        this.height = height;
        aspect = height / width;
        size = width * height;
        width2 = width >> 1;
        height2 = height >> 1;
        numStacks = 0;
        zBuffer = new Vector.<Number>(size, true);
        fBuffer = new Vector.<uint>(size, true);
        lights = new Vector.<Light>(8, true);
        for (var i:int = 0; i < 8; i++) lights[i] = new Light();
        stack = new Vector.<Mat4x4>(64, true);
        worldMatrix = new Mat4x4();
        viewMatrix = new Mat4x4();
        projectionMatrix = new Mat4x4();
        
        // system initialization
        lookAt(new Vec3D(0, 0, 50),  new Vec3D(0, 0, 0), new Vec3D(0, 1, 0));
        perspective(60 * Math.PI / 180, 5, 5000);
        ambient(0.2, 0.2, 0.2);
        light(0).directional(0, 0, 1, 1, 1, 1);
        material(0.8, 0.8, 0, 0, 0, 1, 1, 1);
    }
    
    public function get image():Bitmap {
        return bitmap;
    }
    
    public function push():void {
        if(numStacks < 32) {
            stack[numStacks] = new Mat4x4(
                worldMatrix.e00, worldMatrix.e01, worldMatrix.e02, worldMatrix.e03,
                worldMatrix.e10, worldMatrix.e11, worldMatrix.e12, worldMatrix.e13,
                worldMatrix.e20, worldMatrix.e21, worldMatrix.e22, worldMatrix.e23,
                worldMatrix.e30, worldMatrix.e31, worldMatrix.e32, worldMatrix.e33);
            numStacks++;
        }
    }
    
    public function pop():void {
        if (numStacks > 0) {
            numStacks--;
            worldMatrix = stack[numStacks];
        }
    }
    
    public function rotateX(theta:Number):void {
        var temp:Mat4x4 = new Mat4x4();
        temp.rotateX(theta);
        temp.mulEqualMatrix(worldMatrix);
        worldMatrix = temp;
    }
    
    public function rotateY(theta:Number):void {
        var temp:Mat4x4 = new Mat4x4();
        temp.rotateY(theta);
        temp.mulEqualMatrix(worldMatrix);
        worldMatrix = temp;
    }
    
    public function rotateZ(theta:Number):void {
        var temp:Mat4x4 = new Mat4x4();
        temp.rotateZ(theta);
        temp.mulEqualMatrix(worldMatrix);
        worldMatrix = temp;
    }
    
    public function scale(sx:Number, sy:Number, sz:Number):void {
        var temp:Mat4x4 = new Mat4x4();
        temp.scale(sx, sy, sz);
        temp.mulEqualMatrix(worldMatrix);
        worldMatrix = temp;
    }
    
    public function translate(tx:Number, ty:Number, tz:Number):void {
        var temp:Mat4x4 = new Mat4x4();
        temp.translate(tx, ty, tz);
        temp.mulEqualMatrix(worldMatrix);
        worldMatrix = temp;
    }
    
    public function enableCulling(enable:Boolean):void {
        culling = enable;
    }
    
    public function beginScene(background:uint):void {
        for (var i:int = 0; i < size; i++) {
            fBuffer[i] = background;
            zBuffer[i] = 0;
        }
        worldMatrix.identity();
    }
    
    public function renderPolygon(v1:Vertex, v2:Vertex, v3:Vertex):void {
        v1.worldPos.setVector(v1.pos.x, v1.pos.y, v1.pos.z);
        worldMatrix.mulEqualVector(v1.worldPos);
        v2.worldPos.setVector(v2.pos.x, v2.pos.y, v2.pos.z);
        worldMatrix.mulEqualVector(v2.worldPos);
        v3.worldPos.setVector(v3.pos.x, v3.pos.y, v3.pos.z);
        worldMatrix.mulEqualVector(v3.worldPos);
        
        lighting(v1, v2, v3);
        
        v1.viewPos.setVector(v1.worldPos.x, v1.worldPos.y, v1.worldPos.z);
        viewMatrix.mulEqualVector(v1.viewPos);
        v2.viewPos.setVector(v2.worldPos.x, v2.worldPos.y, v2.worldPos.z);
        viewMatrix.mulEqualVector(v2.viewPos);
        v3.viewPos.setVector(v3.worldPos.x, v3.worldPos.y, v3.worldPos.z);
        viewMatrix.mulEqualVector(v3.viewPos);
        
        clipPolygonDepth(v1, v2, v3, 0);
    }
    
    public function light(id:uint):Light {
        return lights[id];
    }
    
    public function ambient(r:Number, g:Number, b:Number):void {
        ambr = r;
        ambg = g;
        ambb = b;
    }
    
    public function material(ambient:Number, diffuse:Number, specular:Number,
        shininess:Number, emission:Number, r:Number, g:Number, b:Number):void {
        amb = ambient;
        dif = diffuse;
        spc = specular;
        shn = shininess;
        emi = emission;
        this.r = r;
        this.g = g;
        this.b = b;
    }
    
    private function lighting(v1:Vertex, v2:Vertex, v3:Vertex):void {
        // simple lighting
        var cr:Number = amb * ambr * r;
        var cg:Number = amb * ambg * g;
        var cb:Number = amb * ambb * b;
        const nor:Vec3D = v2.worldPos.sub(v1.worldPos).cross(v3.worldPos.sub(v2.worldPos));
        nor.normalize();
        const view:Vec3D = cameraTarget.sub(cameraPosition);
        view.normalize();
        const ref:Vec3D = new Vec3D();
        for (var i:int = 0; i < 8; i++) {
            const light:Light = lights[i];
            if (light.type == Light.DISABLED) continue;
            const lr:Number = light.r;
            const lg:Number = light.g;
            const lb:Number = light.b;
            switch(light.type) {
                case Light.DIRECTIONAL: // directional light
                var dot:Number = light.dir.dot(nor) * dif;
                if (!culling && dot < 0) dot = -dot;
                if (dot > 0) {
                    cr += r * lr * dot;
                    cg += g * lg * dot;
                    cb += b * lb * dot;
                }
                if (spc > 0) {
                    // calc reflection vector and specular
                    // ref = vec - 2 * (nor * vec) * nor
                    var dots:Number = 2 * nor.dot(view);
                    ref.setVector(view.x - nor.x * dots, view.y - nor.y * dots, view.z - nor.z * dots);
                    dots = -light.dir.dot(ref);
                    if (dots > 0) {
                        dots = Math.pow(dots, shn) * spc;
                        cr += lr * dots;
                        cg += lg * dots;
                        cb += lb * dots;
                    }
                }
                break;
            }
        }
        if (cr > 1) cr = 1;
        if (cg > 1) cg = 1;
        if (cb > 1) cb = 1;
        color = (cr * 0xff) << 16 | (cg * 0xff) << 8 | (cb * 0xff);
    }
    
    private function clipPolygonDepth(v1:Vertex, v2:Vertex, v3:Vertex, step:int):void {
        var flag:int;
        var c1:Vertex;
        var c2:Vertex;
        switch(step) {
        case 0:// near
            flag = 0;
            if (v1.viewPos.z < near) flag |= 1;
            if (v2.viewPos.z < near) flag |= 2;
            if (v3.viewPos.z < near) flag |= 4;
            if (flag != 0) {
                switch (flag) {
                case 1:// 1
                    c1 = interpolate(v1, v2, (near - v1.viewPos.z) / (v2.viewPos.z - v1.viewPos.z), false);
                    c2 = interpolate(v1, v3, (near - v1.viewPos.z) / (v3.viewPos.z - v1.viewPos.z), false);
                    c1.viewPos.z = near;
                    c2.viewPos.z = near;
                    clipPolygonDepth(c1, v2, v3, 1);
                    clipPolygonDepth(c1, v3, c2, 1);
                    return;
                case 2:// 2
                    c1 = interpolate(v2, v3, (near - v2.viewPos.z) / (v3.viewPos.z - v2.viewPos.z), false);
                    c2 = interpolate(v2, v1, (near - v2.viewPos.z) / (v1.viewPos.z - v2.viewPos.z), false);
                    c1.viewPos.z = near;
                    c2.viewPos.z = near;
                    clipPolygonDepth(c1, v3, v1, 1);
                    clipPolygonDepth(c1, v1, c2, 1);
                    return;
                case 3:// 1 2
                    c1 = interpolate(v1, v3, (near - v1.viewPos.z) / (v3.viewPos.z - v1.viewPos.z), false);
                    c2 = interpolate(v2, v3, (near - v2.viewPos.z) / (v3.viewPos.z - v2.viewPos.z), false);
                    c1.viewPos.z = near;
                    c2.viewPos.z = near;
                    clipPolygonDepth(c1, c2, v3, 1);
                    return;
                case 4:// 3
                    c1 = interpolate(v3, v1, (near - v3.viewPos.z) / (v1.viewPos.z - v3.viewPos.z), false);
                    c2 = interpolate(v3, v2, (near - v3.viewPos.z) / (v2.viewPos.z - v3.viewPos.z), false);
                    c1.viewPos.z = near;
                    c2.viewPos.z = near;
                    clipPolygonDepth(c1, v1, v2, 1);
                    clipPolygonDepth(c1, v2, c2, 1);
                    return;
                case 5:// 3 1
                    c1 = interpolate(v3, v2, (near - v3.viewPos.z) / (v2.viewPos.z - v3.viewPos.z), false);
                    c2 = interpolate(v1, v2, (near - v1.viewPos.z) / (v2.viewPos.z - v1.viewPos.z), false);
                    c1.viewPos.z = near;
                    c2.viewPos.z = near;
                    clipPolygonDepth(c1, c2, v2, 1);
                    return;
                case 6:// 2 3
                    c1 = interpolate(v2, v1, (near - v2.viewPos.z) / (v1.viewPos.z - v2.viewPos.z), false);
                    c2 = interpolate(v3, v1, (near - v3.viewPos.z) / (v1.viewPos.z - v3.viewPos.z), false);
                    c1.viewPos.z = near;
                    c2.viewPos.z = near;
                    clipPolygonDepth(c1, c2, v1, 1);
                    return;
                case 7:// 1 2 3
                    return;
                }
            }
        case 1:// far
            flag = 0;
            if (v1.viewPos.z > far) flag |= 1;
            if (v2.viewPos.z > far) flag |= 2;
            if (v3.viewPos.z > far) flag |= 4;
            if (flag != 0) {
                switch (flag) {
                case 1:// 1
                    c1 = interpolate(v1, v2, (far - v1.viewPos.z) / (v2.viewPos.z - v1.viewPos.z), false);
                    c2 = interpolate(v1, v3, (far - v1.viewPos.z) / (v3.viewPos.z - v1.viewPos.z), false);
                    c1.viewPos.z = far;
                    c2.viewPos.z = far;
                    clipPolygonScreen(c1, v2, v3, 0);
                    clipPolygonScreen(c1, v3, c2, 0);
                    return;
                case 2:// 2
                    c1 = interpolate(v2, v3, (far - v2.viewPos.z) / (v3.viewPos.z - v2.viewPos.z), false);
                    c2 = interpolate(v2, v1, (far - v2.viewPos.z) / (v1.viewPos.z - v2.viewPos.z), false);
                    c1.viewPos.z = far;
                    c2.viewPos.z = far;
                    clipPolygonScreen(c1, v3, v1, 0);
                    clipPolygonScreen(c1, v1, c2, 0);
                    return;
                case 3:// 1 2
                    c1 = interpolate(v1, v3, (far - v1.viewPos.z) / (v3.viewPos.z - v1.viewPos.z), false);
                    c2 = interpolate(v2, v3, (far - v2.viewPos.z) / (v3.viewPos.z - v2.viewPos.z), false);
                    c1.viewPos.z = far;
                    c2.viewPos.z = far;
                    clipPolygonScreen(c1, c2, v3, 0);
                    return;
                case 4:// 3
                    c1 = interpolate(v3, v1, (far - v3.viewPos.z) / (v1.viewPos.z - v3.viewPos.z), false);
                    c2 = interpolate(v3, v2, (far - v3.viewPos.z) / (v2.viewPos.z - v3.viewPos.z), false);
                    c1.viewPos.z = far;
                    c2.viewPos.z = far;
                    clipPolygonScreen(c1, v1, v2, 0);
                    clipPolygonScreen(c1, v2, c2, 0);
                    return;
                case 5:// 3 1
                    c1 = interpolate(v3, v2, (far - v3.viewPos.z) / (v2.viewPos.z - v3.viewPos.z), false);
                    c2 = interpolate(v1, v2, (far - v1.viewPos.z) / (v2.viewPos.z - v1.viewPos.z), false);
                    c1.viewPos.z = far;
                    c2.viewPos.z = far;
                    clipPolygonScreen(c1, c2, v2, 0);
                    return;
                case 6:// 2 3
                    c1 = interpolate(v2, v1, (far - v2.viewPos.z) / (v1.viewPos.z - v2.viewPos.z), false);
                    c2 = interpolate(v3, v1, (far - v3.viewPos.z) / (v1.viewPos.z - v3.viewPos.z), false);
                    c1.viewPos.z = far;
                    c2.viewPos.z = far;
                    clipPolygonScreen(c1, c2, v1, 0);
                    return;
                case 7:// 1 2 3
                    return;
                }
            }
        }
        clipPolygonScreen(v1, v2, v3, 0);
    }
    
    private function clipPolygonScreen(v1:Vertex, v2:Vertex, v3:Vertex, step:int):void {
        var flag:int;
        var c1:Vertex;
        var c2:Vertex;
        switch(step) {
        case 0:// left
            { // transform
                var invW:Number;
                v1.projPos.setVector(v1.viewPos.x, v1.viewPos.y, v1.viewPos.z, 1);
                projectionMatrix.mulEqualVector(v1.projPos);
                invW = 1 / v1.projPos.w;
                v1.projPos.x *= invW;
                v1.projPos.y *= invW;
                v1.projPos.z = invW;
                v1.projPos.x = width2 + v1.projPos.x * width2 >> 0;
                v1.projPos.y = height2 - v1.projPos.y * height2 >> 0;
                
                v2.projPos.setVector(v2.viewPos.x, v2.viewPos.y, v2.viewPos.z);
                projectionMatrix.mulEqualVector(v2.projPos);
                invW = 1 / v2.projPos.w;
                v2.projPos.x *= invW;
                v2.projPos.y *= invW;
                v2.projPos.z = invW;
                v2.projPos.x = width2 + v2.projPos.x * width2 >> 0;
                v2.projPos.y = height2 - v2.projPos.y * height2 >> 0;
                
                v3.projPos.setVector(v3.viewPos.x, v3.viewPos.y, v3.viewPos.z);
                projectionMatrix.mulEqualVector(v3.projPos);
                invW = 1 / v3.projPos.w;
                v3.projPos.x *= invW;
                v3.projPos.y *= invW;
                v3.projPos.z = invW;
                v3.projPos.x = width2 + v3.projPos.x * width2 >> 0;
                v3.projPos.y = height2 - v3.projPos.y * height2 >> 0;
                
                // culling
                if (culling && (v3.projPos.x - v1.projPos.x) * (v2.projPos.y - v1.projPos.y) -
                (v3.projPos.y - v1.projPos.y) * (v2.projPos.x - v1.projPos.x) < 0) return;
                
                // TODO:Lighting
            }
            flag = 0;
            if (v1.projPos.x < 0) flag |= 1;
            if (v2.projPos.x < 0) flag |= 2;
            if (v3.projPos.x < 0) flag |= 4;
            if (flag != 0) {
                switch (flag) {
                case 1:// 1
                    c1 = interpolate(v1, v2, -v1.projPos.x / (v2.projPos.x - v1.projPos.x), true);
                    c2 = interpolate(v1, v3, -v1.projPos.x / (v3.projPos.x - v1.projPos.x), true);
                    c1.projPos.x = 0;
                    c2.projPos.x = 0;
                    clipPolygonScreen(c1, v2, v3, 1);
                    clipPolygonScreen(c1, v3, c2, 1);
                    return;
                case 2:// 2
                    c1 = interpolate(v2, v3, -v2.projPos.x / (v3.projPos.x - v2.projPos.x), true);
                    c2 = interpolate(v2, v1, -v2.projPos.x / (v1.projPos.x - v2.projPos.x), true);
                    c1.projPos.x = 0;
                    c2.projPos.x = 0;
                    clipPolygonScreen(c1, v3, v1, 1);
                    clipPolygonScreen(c1, v1, c2, 1);
                    return;
                case 3:// 1 2
                    c1 = interpolate(v1, v3, -v1.projPos.x / (v3.projPos.x - v1.projPos.x), true);
                    c2 = interpolate(v2, v3, -v2.projPos.x / (v3.projPos.x - v2.projPos.x), true);
                    c1.projPos.x = 0;
                    c2.projPos.x = 0;
                    clipPolygonScreen(c1, c2, v3, 1);
                    return;
                case 4:// 3
                    c1 = interpolate(v3, v1, -v3.projPos.x / (v1.projPos.x - v3.projPos.x), true);
                    c2 = interpolate(v3, v2, -v3.projPos.x / (v2.projPos.x - v3.projPos.x), true);
                    c1.projPos.x = 0;
                    c2.projPos.x = 0;
                    clipPolygonScreen(c1, v1, v2, 1);
                    clipPolygonScreen(c1, v2, c2, 1);
                    return;
                case 5:// 3 1
                    c1 = interpolate(v3, v2, -v3.projPos.x / (v2.projPos.x - v3.projPos.x), true);
                    c2 = interpolate(v1, v2, -v1.projPos.x / (v2.projPos.x - v1.projPos.x), true);
                    c1.projPos.x = 0;
                    c2.projPos.x = 0;
                    clipPolygonScreen(c1, c2, v2, 1);
                    return;
                case 6:// 2 3
                    c1 = interpolate(v2, v1, -v2.projPos.x / (v1.projPos.x - v2.projPos.x), true);
                    c2 = interpolate(v3, v1, -v3.projPos.x / (v1.projPos.x - v3.projPos.x), true);
                    c1.projPos.x = 0;
                    c2.projPos.x = 0;
                    clipPolygonScreen(c1, c2, v1, 1);
                    return;
                case 7:// 1 2 3
                    return;
                }
            }
        case 1:// right
            flag = 0;
            if (v1.projPos.x > width) flag |= 1;
            if (v2.projPos.x > width) flag |= 2;
            if (v3.projPos.x > width) flag |= 4;
            if (flag != 0) {
                switch (flag) {
                case 1:// 1
                    c1 = interpolate(v1, v2, (width - v1.projPos.x) / (v2.projPos.x - v1.projPos.x), true);
                    c2 = interpolate(v1, v3, (width - v1.projPos.x) / (v3.projPos.x - v1.projPos.x), true);
                    c1.projPos.x = width;
                    c2.projPos.x = width;
                    clipPolygonScreen(c1, v2, v3, 2);
                    clipPolygonScreen(c1, v3, c2, 2);
                    return;
                case 2:// 2
                    c1 = interpolate(v2, v3, (width - v2.projPos.x) / (v3.projPos.x - v2.projPos.x), true);
                    c2 = interpolate(v2, v1, (width - v2.projPos.x) / (v1.projPos.x - v2.projPos.x), true);
                    c1.projPos.x = width;
                    c2.projPos.x = width;
                    clipPolygonScreen(c1, v3, v1, 2);
                    clipPolygonScreen(c1, v1, c2, 2);
                    return;
                case 3:// 1 2
                    c1 = interpolate(v1, v3, (width - v1.projPos.x) / (v3.projPos.x - v1.projPos.x), true);
                    c2 = interpolate(v2, v3, (width - v2.projPos.x) / (v3.projPos.x - v2.projPos.x), true);
                    c1.projPos.x = width;
                    c2.projPos.x = width;
                    clipPolygonScreen(c1, c2, v3, 2);
                    return;
                case 4:// 3
                    c1 = interpolate(v3, v1, (width - v3.projPos.x) / (v1.projPos.x - v3.projPos.x), true);
                    c2 = interpolate(v3, v2, (width - v3.projPos.x) / (v2.projPos.x - v3.projPos.x), true);
                    c1.projPos.x = width;
                    c2.projPos.x = width;
                    clipPolygonScreen(c1, v1, v2, 2);
                    clipPolygonScreen(c1, v2, c2, 2);
                    return;
                case 5:// 3 1
                    c1 = interpolate(v3, v2, (width - v3.projPos.x) / (v2.projPos.x - v3.projPos.x), true);
                    c2 = interpolate(v1, v2, (width - v1.projPos.x) / (v2.projPos.x - v1.projPos.x), true);
                    c1.projPos.x = width;
                    c2.projPos.x = width;
                    clipPolygonScreen(c1, c2, v2, 2);
                    return;
                case 6:// 2 3
                    c1 = interpolate(v2, v1, (width - v2.projPos.x) / (v1.projPos.x - v2.projPos.x), true);
                    c2 = interpolate(v3, v1, (width - v3.projPos.x) / (v1.projPos.x - v3.projPos.x), true);
                    c1.projPos.x = width;
                    c2.projPos.x = width;
                    clipPolygonScreen(c1, c2, v1, 2);
                    return;
                case 7:// 1 2 3
                    return;
                }
            }
        case 2:// top
            flag = 0;
            if (v1.projPos.y < 0) flag |= 1;
            if (v2.projPos.y < 0) flag |= 2;
            if (v3.projPos.y < 0) flag |= 4;
            if (flag != 0) {
                switch (flag) {
                case 1:// 1
                    c1 = interpolate(v1, v2, -v1.projPos.y / (v2.projPos.y - v1.projPos.y), true);
                    c2 = interpolate(v1, v3, -v1.projPos.y / (v3.projPos.y - v1.projPos.y), true);
                    c1.projPos.y = 0;
                    c2.projPos.y = 0;
                    clipPolygonScreen(c1, v2, v3, 3);
                    clipPolygonScreen(c1, v3, c2, 3);
                    return;
                case 2:// 2
                    c1 = interpolate(v2, v3, -v2.projPos.y / (v3.projPos.y - v2.projPos.y), true);
                    c2 = interpolate(v2, v1, -v2.projPos.y / (v1.projPos.y - v2.projPos.y), true);
                    c1.projPos.y = 0;
                    c2.projPos.y = 0;
                    clipPolygonScreen(c1, v3, v1, 3);
                    clipPolygonScreen(c1, v1, c2, 3);
                    return;
                case 3:// 1 2
                    c1 = interpolate(v1, v3, -v1.projPos.y / (v3.projPos.y - v1.projPos.y), true);
                    c2 = interpolate(v2, v3, -v2.projPos.y / (v3.projPos.y - v2.projPos.y), true);
                    c1.projPos.y = 0;
                    c2.projPos.y = 0;
                    clipPolygonScreen(c1, c2, v3, 3);
                    return;
                case 4:// 3
                    c1 = interpolate(v3, v1, -v3.projPos.y / (v1.projPos.y - v3.projPos.y), true);
                    c2 = interpolate(v3, v2, -v3.projPos.y / (v2.projPos.y - v3.projPos.y), true);
                    c1.projPos.y = 0;
                    c2.projPos.y = 0;
                    clipPolygonScreen(c1, v1, v2, 3);
                    clipPolygonScreen(c1, v2, c2, 3);
                    return;
                case 5:// 3 1
                    c1 = interpolate(v3, v2, -v3.projPos.y / (v2.projPos.y - v3.projPos.y), true);
                    c2 = interpolate(v1, v2, -v1.projPos.y / (v2.projPos.y - v1.projPos.y), true);
                    c1.projPos.y = 0;
                    c2.projPos.y = 0;
                    clipPolygonScreen(c1, c2, v2, 3);
                    return;
                case 6:// 2 3
                    c1 = interpolate(v2, v1, -v2.projPos.y / (v1.projPos.y - v2.projPos.y), true);
                    c2 = interpolate(v3, v1, -v3.projPos.y / (v1.projPos.y - v3.projPos.y), true);
                    c1.projPos.y = 0;
                    c2.projPos.y = 0;
                    clipPolygonScreen(c1, c2, v1, 3);
                    return;
                case 7:// 1 2 3
                    return;
                }
            }
        case 3:// bottom
            flag = 0;
            if (v1.projPos.y > height) flag |= 1;
            if (v2.projPos.y > height) flag |= 2;
            if (v3.projPos.y > height) flag |= 4;
            if (flag != 0) {
                switch (flag) {
                case 1:// 1
                    c1 = interpolate(v1, v2, (height - v1.projPos.y) / (v2.projPos.y - v1.projPos.y), true);
                    c2 = interpolate(v1, v3, (height - v1.projPos.y) / (v3.projPos.y - v1.projPos.y), true);
                    c1.projPos.y = height;
                    c2.projPos.y = height;
                    renderTriangle(c1, v2, v3);
                    renderTriangle(c1, v3, c2);
                    return;
                case 2:// 2
                    c1 = interpolate(v2, v3, (height - v2.projPos.y) / (v3.projPos.y - v2.projPos.y), true);
                    c2 = interpolate(v2, v1, (height - v2.projPos.y) / (v1.projPos.y - v2.projPos.y), true);
                    c1.projPos.y = height;
                    c2.projPos.y = height;
                    renderTriangle(c1, v3, v1);
                    renderTriangle(c1, v1, c2);
                    return;
                case 3:// 1 2
                    c1 = interpolate(v1, v3, (height - v1.projPos.y) / (v3.projPos.y - v1.projPos.y), true);
                    c2 = interpolate(v2, v3, (height - v2.projPos.y) / (v3.projPos.y - v2.projPos.y), true);
                    c1.projPos.y = height;
                    c2.projPos.y = height;
                    renderTriangle(c1, c2, v3);
                    return;
                case 4:// 3
                    c1 = interpolate(v3, v1, (height - v3.projPos.y) / (v1.projPos.y - v3.projPos.y), true);
                    c2 = interpolate(v3, v2, (height - v3.projPos.y) / (v2.projPos.y - v3.projPos.y), true);
                    c1.projPos.y = height;
                    c2.projPos.y = height;
                    renderTriangle(c1, v1, v2);
                    renderTriangle(c1, v2, c2);
                    return;
                case 5:// 3 1
                    c1 = interpolate(v3, v2, (height - v3.projPos.y) / (v2.projPos.y - v3.projPos.y), true);
                    c2 = interpolate(v1, v2, (height - v1.projPos.y) / (v2.projPos.y - v1.projPos.y), true);
                    c1.projPos.y = height;
                    c2.projPos.y = height;
                    renderTriangle(c1, c2, v2);
                    return;
                case 6:// 2 3
                    c1 = interpolate(v2, v1, (height - v2.projPos.y) / (v1.projPos.y - v2.projPos.y), true);
                    c2 = interpolate(v3, v1, (height - v3.projPos.y) / (v1.projPos.y - v3.projPos.y), true);
                    c1.projPos.y = height;
                    c2.projPos.y = height;
                    renderTriangle(c1, c2, v1);
                    return;
                case 7:// 1 2 3
                    return;
                }
            }
        }
        renderTriangle(v1, v2, v3);
    }
    
    private function interpolate(v1:Vertex, v2:Vertex, t:Number, screen:Boolean):Vertex {
        var v3:Vertex = new Vertex();
        // v3.worldPos.x = v1.worldPos.x + (v2.worldPos.x - v1.worldPos.x) * t;
        // v3.worldPos.y = v1.worldPos.y + (v2.worldPos.y - v1.worldPos.y) * t;
        // v3.worldPos.z = v1.worldPos.z + (v2.worldPos.z - v1.worldPos.z) * t;
        if(screen) {
            v3.projPos.x = (v1.projPos.x + (v2.projPos.x - v1.projPos.x) * t) >> 0;
            v3.projPos.y = (v1.projPos.y + (v2.projPos.y - v1.projPos.y) * t) >> 0;
            v3.projPos.z = v1.projPos.z + (v2.projPos.z - v1.projPos.z) * t;
        } else {
            v3.viewPos.x = v1.viewPos.x + (v2.viewPos.x - v1.viewPos.x) * t;
            v3.viewPos.y = v1.viewPos.y + (v2.viewPos.y - v1.viewPos.y) * t;
            v3.viewPos.z = v1.viewPos.z + (v2.viewPos.z - v1.viewPos.z) * t;
        }
        return v3;
    }
    
    private function renderTriangle(v1:Vertex, v2:Vertex, v3:Vertex):void {
        var top:Vec3D;
        var left:Vec3D;
        var right:Vec3D;
        if (v1.projPos.y < v2.projPos.y) {
            if (v2.projPos.y < v3.projPos.y) {
                top = v1.projPos;
                left = v2.projPos;
                right = v3.projPos;
            } else if (v1.projPos.y < v3.projPos.y) {
                top = v1.projPos;
                left = v3.projPos;
                right = v2.projPos;
            } else {
                top = v3.projPos;
                left = v1.projPos;
                right = v2.projPos;
            }
        } else {
            if (v2.projPos.y > v3.projPos.y) {
                top = v3.projPos;
                left = v2.projPos;
                right = v1.projPos;
            } else if (v1.projPos.y > v3.projPos.y) {
                top = v2.projPos;
                left = v3.projPos;
                right = v1.projPos;
            } else {
                top = v2.projPos;
                left = v1.projPos;
                right = v3.projPos;
            }
        }
        var min:int = top.y + 0.5;
        var mid:int = left.y + 0.5;
        var max:int = right.y + 0.5;
        if ((left.x - top.x) / (left.y - top.y) > (right.x - top.x) / (right.y - top.y)) {
            var temp:Vec3D = left;
            left = right;
            right = temp;
        }
        if (min == max) return;
        renderFlat(top, left, right, min, mid, max);
    }
    
    private function renderFlat(top:Vec3D, left:Vec3D, right:Vec3D, min:int, mid:int, max:int):void {
        var invLength:Number;
        const zBuffer:Vector.<Number> = this.zBuffer;
        const fBuffer:Vector.<uint> = this.fBuffer;
        
        // thickness
        var t:Number = (right.x - top.x) * (left.y - top.y) - (left.x - top.x) * (right.y - top.y);
        if (t == 0) return;
        t = 1 / t;
        
        // in scanline
        var lLength:int = left.y - top.y;
        var rLength:int = right.y - top.y;
        var lineZ:Number;
        const addLineZ:Number = ((right.z - top.z) * lLength - (left.z - top.z) * rLength) * t * 0xffffff;
        
        // left data
        var lY:int = left.y;
        invLength = 1 / lLength;
        var lX:Number = top.x;
        var lAddX:Number = (left.x - top.x) * invLength;
        var lZ:Number = top.z;
        var lAddZ:Number = (left.z - top.z) * invLength;
        
        // right data
        var rY:int = right.y;
        invLength = 1 / rLength;
        var rX:Number = top.x;
        var rAddX:Number = (right.x - top.x) * invLength;
        var rZ:Number = top.z;
        var rAddZ:Number = (right.z - top.z) * invLength;
        
        var y:int = min;
        var offset:int = min * width;
        
        while (y < max) {
            if (y == mid) {
                // flip left and right
                if (lY == rY)
                    return;
                if (y == lY) {
                    lLength = right.y - left.y;
                    invLength = 1 / lLength;
                    lX = left.x;
                    lAddX = (right.x - left.x) * invLength;
                    lZ = left.z;
                    lAddZ = (right.z - left.z) * invLength;
                }
                if (y == rY) {
                    rLength = left.y - right.y;
                    invLength = 1 / rLength;
                    rX = right.x;
                    rAddX = (left.x - right.x) * invLength;
                    rZ = right.z;
                    rAddZ = (left.z - right.z) * invLength;
                }
            }
            const ilx:int = lX;
            const irx:int = rX;
            if (irx - ilx > 0) {
                lineZ = lZ * 0xffffff;
                var pix:int = offset + ilx;
                const end:int = offset + irx;
                while (pix < end) {
                    if (zBuffer[pix] < lineZ) {
                        fBuffer[pix] = color;
                        zBuffer[pix] = lineZ;
                    }
                    pix++;
                    lineZ += addLineZ;
                }
            }
            lX += lAddX;
            rX += rAddX;
            lZ += lAddZ;
            rZ += rAddZ;
            offset += width;
            y++;
        }
    }
    
    public function renderPoint(vertex:Vec3D):void {
        worldMatrix.mulEqualVector(vertex);
        viewMatrix.mulEqualVector(vertex);
        projectionMatrix.mulEqualVector(vertex);
        var invW:Number = 1 / vertex.w;
        vertex.x *= invW;
        vertex.y *= invW;
        vertex.z *= invW;
        vertex.x = (width2 + vertex.x * width2) >> 0;
        vertex.y = (height2 + vertex.y * height2) >> 0;
        if (vertex.x >= 0 && vertex.x < width && vertex.y >= 0 && vertex.y < height) {
            var index:uint = vertex.y * width + vertex.x;
            fBuffer[index] = 0xffffff;
        }
    }
    
    public function endScene():void {
        img.setVector(img.rect, fBuffer);
    }
    
    public function lookAt(position:Vec3D, target:Vec3D, up:Vec3D):void {
        cameraPosition = position;
        cameraTarget = target;
        cameraUp = up;
        var axisZ:Vec3D = cameraTarget.sub(cameraPosition);
        axisZ.normalize();
        var axisX:Vec3D = cameraUp.cross(axisZ);
        axisX.normalize();
        var axisY:Vec3D = axisZ.cross(axisX);
        viewMatrix.e00 = axisX.x;
        viewMatrix.e01 = axisY.x;
        viewMatrix.e02 = axisZ.x;
        viewMatrix.e03 = 0;
        viewMatrix.e10 = axisX.y;
        viewMatrix.e11 = axisY.y;
        viewMatrix.e12 = axisZ.y;
        viewMatrix.e13 = 0;
        viewMatrix.e20 = axisX.z;
        viewMatrix.e21 = axisY.z;
        viewMatrix.e22 = axisZ.z;
        viewMatrix.e23 = 0;
        viewMatrix.e30 = -axisX.dot(cameraPosition);
        viewMatrix.e31 = -axisY.dot(cameraPosition);
        viewMatrix.e32 = -axisZ.dot(cameraPosition);
        viewMatrix.e33 = 1;
    }
    
    public function perspective(fovY:Number, near:Number, far:Number):void {
        this.near = near;
        this.far = far;
        var h:Number = Math.cos(fovY * 0.5) / Math.sin(fovY * 0.5);
        var w:Number = h * aspect;
        var ffn:Number = far / (far - near);
        projectionMatrix.e00 = w;
        projectionMatrix.e01 = 0;
        projectionMatrix.e02 = 0;
        projectionMatrix.e03 = 0;
        projectionMatrix.e10 = 0;
        projectionMatrix.e11 = h;
        projectionMatrix.e12 = 0;
        projectionMatrix.e13 = 0;
        projectionMatrix.e20 = 0;
        projectionMatrix.e21 = 0;
        projectionMatrix.e22 = ffn;
        projectionMatrix.e23 = 1;
        projectionMatrix.e30 = 0;
        projectionMatrix.e31 = 0;
        projectionMatrix.e32 = -near * ffn;
        projectionMatrix.e33 = 0;
    }
}

class Light {
    public static const DISABLED:uint = 0;
    public static const DIRECTIONAL:uint = 1;
    public var dir:Vec3D;
    public var pos:Vec3D;
    public var r:Number;
    public var g:Number;
    public var b:Number;
    public var type:uint;
    public function Light() {
        type = DISABLED;
        dir = new Vec3D();
        pos = new Vec3D();
    }
    
    public function directional(dx:Number, dy:Number, dz:Number, r:Number, g:Number, b:Number):void {
        type = DIRECTIONAL;
        dir.setVector(dx, dy, dz);
        dir.normalize();
        this.r = r;
        this.g = g;
        this.b = b;
    }
    
    public function disable():void {
        type = DISABLED;
    }
}

class Model {
    public var vertices:Vector.<Vertex>;
    public var faces:Vector.<Vector.<uint>>;
    public function Model() {
        vertices = new Vector.<Vertex>();
        faces = new Vector.<Vector.<uint>>();
    }
    
    public function toBox(w:Number, h:Number, d:Number):void {
        vertices = new Vector.<Vertex>(8, true);
        vertices[0] = new Vertex(-w, -h, -d);
        vertices[1] = new Vertex(w, -h, -d);
        vertices[2] = new Vertex(w, -h, d);
        vertices[3] = new Vertex(-w, -h, d);
        vertices[4] = new Vertex(-w, h, -d);
        vertices[5] = new Vertex(w, h, -d);
        vertices[6] = new Vertex(w, h, d);
        vertices[7] = new Vertex(-w, h, d);
        faces = new Vector.<Vector.<uint>>(12, true);
        for (var i:int = 0; i < 12; i++)
            faces[i] = new Vector.<uint>(3, true);
        faces[0][0] = 0;
        faces[0][1] = 1;
        faces[0][2] = 2;
        faces[1][0] = 0;
        faces[1][1] = 2;
        faces[1][2] = 3;
        faces[2][0] = 7;
        faces[2][1] = 6;
        faces[2][2] = 5;
        faces[3][0] = 7;
        faces[3][1] = 5;
        faces[3][2] = 4;
        faces[4][0] = 4;
        faces[4][1] = 5;
        faces[4][2] = 1;
        faces[5][0] = 4;
        faces[5][1] = 1;
        faces[5][2] = 0;
        faces[6][0] = 6;
        faces[6][1] = 7;
        faces[6][2] = 3;
        faces[7][0] = 6;
        faces[7][1] = 3;
        faces[7][2] = 2;
        faces[8][0] = 5;
        faces[8][1] = 6;
        faces[8][2] = 2;
        faces[9][0] = 5;
        faces[9][1] = 2;
        faces[9][2] = 1;
        faces[10][0] = 7;
        faces[10][1] = 4;
        faces[10][2] = 0;
        faces[11][0] = 7;
        faces[11][1] = 0;
        faces[11][2] = 3;
    }
    
    public function toCylinder(r:Number, h:Number, div:uint):void {
        var num:uint = div * 2;
        vertices = new Vector.<Vertex>(num, true);
        faces = new Vector.<Vector.<uint>>(num, true);
        var ang:Number = 0;
        var dAng:Number = Math.PI / div * 2;
        for (var i:int = 0; i < div; i++) {
            var x:Number = r * Math.cos(ang);
            var z:Number = r * Math.sin(ang);
            vertices[i] = new Vertex(x, h, z);
            vertices[i + div] = new Vertex(x, -h, z);
            faces[i] = new Vector.<uint>(3, true);
            faces[i][0] = i;
            faces[i][1] = i + div;
            faces[i][2] = (i + 1) % div + div;
            faces[i + div] = new Vector.<uint>(3, true);
            faces[i + div][0] = i;
            faces[i + div][1] = (i + 1) % div + div;
            faces[i + div][2] = (i + 1) % div;
            ang += dAng;
        }
    }
    
    public function render(renderer:Renderer):void {
        for (var i:int = 0; i < faces.length; i++)
            renderer.renderPolygon(vertices[faces[i][0]], vertices[faces[i][1]], vertices[faces[i][2]]);
    }
}

class Vertex {
    public var pos:Vec3D;
    public var worldPos:Vec3D;
    public var viewPos:Vec3D;
    public var projPos:Vec3D;
    
    public function Vertex(x:Number = 0, y:Number = 0, z:Number = 0):void {
        pos = new Vec3D(x, y, z);
        worldPos = new Vec3D();
        viewPos = new Vec3D();
        projPos = new Vec3D();
    }
}

class Vec3D {
    /*
     * [x y z w]
     */
    public var x:Number;
    public var y:Number;
    public var z:Number;
    public var w:Number;
    
    public function Vec3D(x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 0) {
        setVector(x, y, z, w);
    }
    
    public function setVector(x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 0):void {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }
    
    public function add(v:Vec3D):Vec3D {
        return new Vec3D(x + v.x, y + v.y, z + v.z);
    }
    
    public function addEqual(v:Vec3D):void {
        x += v.x;
        y += v.y;
        z += v.z;
    }
    
    public function sub(v:Vec3D):Vec3D {
        return new Vec3D(x - v.x, y - v.y, z - v.z);
    }
    
    public function subEqual(v:Vec3D):void {
        x -= v.x;
        y -= v.y;
        z -= v.z;
    }
    
    public function mul(s:Number):Vec3D {
        return new Vec3D(x * s, y * s, z * s);
    }
    
    public function mulEqual(s:Number):void {
        x *= s;
        y *= s;
        z *= s;
    }
    
    public function dot(v:Vec3D):Number {
        return x * v.x + y * v.y + z * v.z;
    }
    
    public function cross(v:Vec3D):Vec3D {
        return new Vec3D(y * v.z - z * v.y, z * v.x - x * v.z, x * v.y - y * v.x);
    }
    
    public function length():Number {
        return Math.sqrt(x * x + y * y + z * z);
    }
    
    public function normalize():void {
        var length:Number = length();
        if (length != 0 && length != 1) {
            length = 1 / length;
            x *= length;
            y *= length;
            z *= length;
        }
    }
}

class Mat4x4 {
    /*
     * [e00 e01 e02 e03]
     * [e10 e11 e12 e13]
     * [e20 e21 e22 e23]
     * [e30 e31 e32 e33]
     */
    public var e00:Number;
    public var e01:Number;
    public var e02:Number;
    public var e03:Number;
    public var e10:Number;
    public var e11:Number;
    public var e12:Number;
    public var e13:Number;
    public var e20:Number;
    public var e21:Number;
    public var e22:Number;
    public var e23:Number;
    public var e30:Number;
    public var e31:Number;
    public var e32:Number;
    public var e33:Number;
    
    public function Mat4x4(e00:Number = 1, e01:Number = 0, e02:Number = 0, e03:Number = 0,
        e10:Number = 0, e11:Number = 1, e12:Number = 0, e13:Number = 0,
        e20:Number = 0, e21:Number = 0, e22:Number = 1, e23:Number = 0,
        e30:Number = 0, e31:Number = 0, e32:Number = 0, e33:Number = 1) {
        setMatrix(e00, e01, e02, e03, e10, e11, e12, e13,
            e20, e21, e22, e23, e30, e31, e32, e33);
    }
    
    public function identity():void {
        setMatrix();
    }
    
    
    public function setMatrix(e00:Number = 1, e01:Number = 0, e02:Number = 0, e03:Number = 0,
        e10:Number = 0, e11:Number = 1, e12:Number = 0, e13:Number = 0,
        e20:Number = 0, e21:Number = 0, e22:Number = 1, e23:Number = 0,
        e30:Number = 0, e31:Number = 0, e32:Number = 0, e33:Number = 1):void {
        this.e00 = e00;
        this.e01 = e01;
        this.e02 = e02;
        this.e03 = e03;
        this.e10 = e10;
        this.e11 = e11;
        this.e12 = e12;
        this.e13 = e13;
        this.e20 = e20;
        this.e21 = e21;
        this.e22 = e22;
        this.e23 = e23;
        this.e30 = e30;
        this.e31 = e31;
        this.e32 = e32;
        this.e33 = e33;
    }
    
    public function rotateX(theta:Number):void {
        var sin:Number = Math.sin(theta);
        var cos:Number = Math.cos(theta);
        var m:Mat4x4 = new Mat4x4();
        m.e11 = cos;
        m.e12 = sin;
        m.e21 = -sin;
        m.e22 = cos;
        mulEqualMatrix(m);
    }
    
    public function rotateY(theta:Number):void {
        var sin:Number = Math.sin(theta);
        var cos:Number = Math.cos(theta);
        var m:Mat4x4 = new Mat4x4();
        m.e00 = cos;
        m.e02 = sin;
        m.e20 = -sin;
        m.e22 = cos;
        mulEqualMatrix(m);
    }
    
    public function rotateZ(theta:Number):void {
        var sin:Number = Math.sin(theta);
        var cos:Number = Math.cos(theta);
        var m:Mat4x4 = new Mat4x4();
        m.e00 = cos;
        m.e01 = -sin;
        m.e10 = sin;
        m.e11 = cos;
        mulEqualMatrix(m);
    }
    
    public function translate(tx:Number, ty:Number, tz:Number):void {
        var m:Mat4x4 = new Mat4x4();
        m.e30 = tx;
        m.e31 = ty;
        m.e32 = tz;
        mulEqualMatrix(m);
    }
    
    public function scale(sx:Number, sy:Number, sz:Number):void {
        var m:Mat4x4 = new Mat4x4();
        m.e00 = sx;
        m.e11 = sy;
        m.e22 = sz;
        mulEqualMatrix(m);
    }
    
    public function mulMatrix(m:Mat4x4):Mat4x4 {
        var t11:Number = e00 * m.e00 + e01 * m.e10 + e02 * m.e20 + e03 * m.e30;
        var t12:Number = e00 * m.e01 + e01 * m.e11 + e02 * m.e21 + e03 * m.e31;
        var t13:Number = e00 * m.e02 + e01 * m.e12 + e02 * m.e22 + e03 * m.e32;
        var t14:Number = e00 * m.e03 + e01 * m.e13 + e02 * m.e23 + e03 * m.e33;
        var t21:Number = e10 * m.e00 + e11 * m.e10 + e12 * m.e20 + e13 * m.e30;
        var t22:Number = e10 * m.e01 + e11 * m.e11 + e12 * m.e21 + e13 * m.e31;
        var t23:Number = e10 * m.e02 + e11 * m.e12 + e12 * m.e22 + e13 * m.e32;
        var t24:Number = e10 * m.e03 + e11 * m.e13 + e12 * m.e23 + e13 * m.e33;
        var t31:Number = e20 * m.e00 + e21 * m.e10 + e22 * m.e20 + e23 * m.e30;
        var t32:Number = e20 * m.e01 + e21 * m.e11 + e22 * m.e21 + e23 * m.e31;
        var t33:Number = e20 * m.e02 + e21 * m.e12 + e22 * m.e22 + e23 * m.e32;
        var t34:Number = e20 * m.e03 + e21 * m.e13 + e22 * m.e23 + e23 * m.e33;
        var t41:Number = e30 * m.e00 + e31 * m.e10 + e32 * m.e20 + e33 * m.e30;
        var t42:Number = e30 * m.e01 + e31 * m.e11 + e32 * m.e21 + e33 * m.e31;
        var t43:Number = e30 * m.e02 + e31 * m.e12 + e32 * m.e22 + e33 * m.e32;
        var t44:Number = e30 * m.e03 + e31 * m.e13 + e32 * m.e23 + e33 * m.e33;
        return new Mat4x4(t11, t12, t13, t14, t21, t22, t23, t24, t31, t32, t33, t34, t41,
                t42, t43, t44);
    }
    
    public function mulEqualMatrix(m:Mat4x4):void {
        var t11:Number = e00 * m.e00 + e01 * m.e10 + e02 * m.e20 + e03 * m.e30;
        var t12:Number = e00 * m.e01 + e01 * m.e11 + e02 * m.e21 + e03 * m.e31;
        var t13:Number = e00 * m.e02 + e01 * m.e12 + e02 * m.e22 + e03 * m.e32;
        var t14:Number = e00 * m.e03 + e01 * m.e13 + e02 * m.e23 + e03 * m.e33;
        var t21:Number = e10 * m.e00 + e11 * m.e10 + e12 * m.e20 + e13 * m.e30;
        var t22:Number = e10 * m.e01 + e11 * m.e11 + e12 * m.e21 + e13 * m.e31;
        var t23:Number = e10 * m.e02 + e11 * m.e12 + e12 * m.e22 + e13 * m.e32;
        var t24:Number = e10 * m.e03 + e11 * m.e13 + e12 * m.e23 + e13 * m.e33;
        var t31:Number = e20 * m.e00 + e21 * m.e10 + e22 * m.e20 + e23 * m.e30;
        var t32:Number = e20 * m.e01 + e21 * m.e11 + e22 * m.e21 + e23 * m.e31;
        var t33:Number = e20 * m.e02 + e21 * m.e12 + e22 * m.e22 + e23 * m.e32;
        var t34:Number = e20 * m.e03 + e21 * m.e13 + e22 * m.e23 + e23 * m.e33;
        var t41:Number = e30 * m.e00 + e31 * m.e10 + e32 * m.e20 + e33 * m.e30;
        var t42:Number = e30 * m.e01 + e31 * m.e11 + e32 * m.e21 + e33 * m.e31;
        var t43:Number = e30 * m.e02 + e31 * m.e12 + e32 * m.e22 + e33 * m.e32;
        var t44:Number = e30 * m.e03 + e31 * m.e13 + e32 * m.e23 + e33 * m.e33;
        setMatrix(t11, t12, t13, t14, t21, t22, t23, t24, t31, t32, t33, t34, t41,
                t42, t43, t44);
    }
    
    public function mulVector(v:Vec3D):Vec3D {
        return new Vec3D(e00 * v.x + e10 * v.y + e20 * v.z + e30,
                    e01 * v.x + e11 * v.y + e21 * v.z + e31,
                    e02 * v.x + e12 * v.y + e22 * v.z + e32,
                    e03 * v.x + e13 * v.y + e23 * v.z + e33);
    }
    
    public function mulEqualVector(v:Vec3D):void {
        v.setVector(e00 * v.x + e10 * v.y + e20 * v.z + e30,
                    e01 * v.x + e11 * v.y + e21 * v.z + e31,
                    e02 * v.x + e12 * v.y + e22 * v.z + e32,
                    e03 * v.x + e13 * v.y + e23 * v.z + e33);
    }
}