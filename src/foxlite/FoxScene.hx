package foxlite;

import flixel.util.FlxColor;
import foxlite.FoxBasic;
import foxlite.FoxCamera;
import foxlite.funkin.FoxExtendableSprite;
import foxlite.funkin.PolymodUtils;
import foxlite.group.FoxGroup;
import foxlite.group.FoxTypedGroup;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import foxlite.renderer.FoxRenderer;
import foxlite.flixel.FlxTypedSignalImpl;
import foxlite.system.FoxDrawTree;
import foxlite.system.FoxDrawTreeNode;
import foxlite.texture.FoxFramebuffer;
import foxlite.texture.FoxTexture;
import haxe.ds.BalancedTree;
import haxe.ds.StringMap;
import lime.math.Vector2;
import openfl.display3D.Context3D;
import openfl.geom.Vector3D;

class FoxScene extends FoxExtendableSprite {

	/**
		Scene render targets.
		You can add multiple of them and use them in your passes / shaders.
	*/
	public var renderTargets:Map<String, FoxFramebuffer> = new StringMap();
	
	/**
		Scene output target, this will be used as `pixels` for the sprite.

		For it to take effect, see `setOutputDisplay()`
	**/
	public var output:String = "default";
	
	/**
		This is the color index for the `colorBuffers` render target.
		Must be set to 0 if MRTs are not supported.

		For it to take effect, see `setOutputDisplay()`
	**/
	public var outputColorIndex:Int = 0;

	public var foxGroup:FoxTypedGroup<FoxBasic> = #if !foxlite_polymod new FoxGroup(); #else PolymodUtils.getFoxGroup(); #end
	public var foxCameras:Array<FoxCamera> = [];

	/**
		The scene environment.

		This is just a holder object for global environment variables, such as sky textures.
		Note: Subject to change in the future.
	**/
	public var environment:{skyTexture:FoxTexture, skyOffset:Vector2, fogColor:Vector3D, ambientLight:FlxColor} = {
		skyTexture: null,
		skyOffset: new Vector2(),
		fogColor: new Vector3D(),
		ambientLight: FlxColor.WHITE
	};

	/**
	* An array of `BalancedTree` containing sorted `FoxDrawTree` for drawing.
	* It is calculated per frame and processed per camera.
	*
	* Draw groups consist of a collection of materials and meshes that can be drawn at once in a target.
	* This target must exist on the scene as a `FoxFramebuffer` in the `renderTargets` map.
	*
	* You can sort materials by priority for each group, but later groups will be draw called after previous ones.
	* 
	* Draw groups are meant to be used for post-processing, offscreen rendering and shadow passes. 
	* For example rendering a single mesh to a noise texture and then using that texture in the next group.
	*/
	public var drawGroups #if !foxlite_polymod : Array<FoxDrawTree> #end = [new BalancedTree()];

	public var __width:Float = 0;
	public var __height:Float = 0;
	public var timeScale:Float = 1.0;

	public var context:Context3D;

	public var onFramebufferResized:FlxTypedSignalImpl<(width:Int, height:Int)->Void> = new FlxTypedSignalImpl();
	public var onPreDraw:FlxTypedSignalImpl<()->Void> = new FlxTypedSignalImpl();
	public var onPostDraw:FlxTypedSignalImpl<()->Void> = new FlxTypedSignalImpl();

	public function new(width:Int, height:Int) {
		super();
		context = FoxRenderer.getContext();
		flipY = true; // Flixel uses flipped Y UVs, so we flip it
		foxGroup.scene = this;

		setupBuffers(width, height); 
	}

	public inline function add(member:FoxBasic):FoxBasic {
		return foxGroup.add(member);
	}

	public inline function insert(pos:Int, member:FoxBasic):FoxBasic {
		return foxGroup.insert(pos, member);
	}

	public inline function remove(member:FoxBasic, splice:Bool=true):FoxBasic {
		return foxGroup.remove(member, splice);
	}

	// Setup default back buffer
	public function setupBuffers(width:Int, height:Int) {
		if(__width == width && __height == height) return;
		__width = width;
		__height = height;

		var backBuffer:FoxFramebuffer = renderTargets.get("default");
		
		if(backBuffer == null) {
			backBuffer = FoxFramebuffer.create3D(width, height, true);
			renderTargets.set("default", backBuffer);
		}
		else backBuffer.resize(width, height);
		
		setOutputDisplay(output, outputColorIndex);

		onFramebufferResized.dispatch(width, height);
	}

	/**

	**/
	public function setOutputDisplay(bufferName:String, colorIdx:Int=0) {
		pixels = renderTargets.get(bufferName)?.colorBuffers[colorIdx]?.asBitmapData();
		output = bufferName;
		outputColorIndex = colorIdx;
	}

	// Stop culling
	public override function isOnScreen(?camera):Bool {
		return true;
	}

	public override function update(elapsed:Float) {
		elapsed *= timeScale;
		super.update(elapsed);

		for(cam in foxCameras) if(cam.active) cam.update(elapsed);

		var __removals:Array<FoxBasic> = [];
		for(member in foxGroup.members) {
			if(member.__destroyed) {
				__removals.push(member);
				continue;
			}
			if(member.active) member.update(elapsed);
		}

		while(__removals.length > 0) remove(__removals.pop());
	}

	public override function draw() {
		FoxRenderer.begin();
		onPreDraw.dispatch();

		// Prepare draw groups
		if(FoxRenderer.mustRebuildDrawGroups) buildDrawGroups();

		for(cam in foxCameras) {
			if(!cam.visible) continue;
			cam.lightData.clearLights();
			cam.scene = this;
			// Draw call for our members before actual rendering
			for(m in foxGroup.members) if(m.visible) m.draw(cam);

			cam.lightData.prepareLights(cam);
			cam.render(drawGroups);
		}

		onPostDraw.dispatch();
		FoxRenderer.backToFlixel();
		super.draw();
	}

	/**
		Adds a draw group to the `drawGroups` list

		@returns the new draw group index
	**/
	public inline function addDrawGroup():Int {
		return drawGroups.push(new BalancedTree()) - 1;
	}

	/**
	* Computes the draw groups indexed by materials.
	*
	* Helps reducing draw calls and state switches, also makes sequential post-processing easier.
	*/
	public function buildDrawGroups():Array<FoxDrawTree> {
		for(g in drawGroups) g.clear(); 
		for(m in foxGroup.members) if(m.visible) m.pushDrawData(this);
		return drawGroups;
	}

	/**
		Adds a material along with a mesh to be drawn by `groups`, providing a `FoxObject` for transforms.

		If the material already exists in the group, the mesh is added to its draw tree instead.

		Intended for internal use, make sure you know what you're doing if you're using this!
	**/

	// This function can and will thrash a lot of memory because it's creating nodes every time
	// A good practice would be to recycle them, but that would require creating a custom BalancedTree and tree nodes
	// And as you may know at this point, HScript really doesn't like too many instructions in loops
	// so, this is a sacrifice we make to stick to the bare metal
	public function addToDrawGroups(material:FoxMaterial, mesh:FoxMesh, groups:Array<Int>, member:FoxModel) {
		for(g in groups) {
			var tree = drawGroups[g];
			if(tree == null) continue;

			// If node exists, get it
			// otherwise add it to the tree
			var node = tree.get(material.__tid);
			if(node == null) {
				node = new FoxDrawTreeNode(material);
				tree.set(material.__tid, node);
				FoxRenderer.allocationsThisFrame += 2; // 2 to account for balancing processing inside tree.set()
			}
					
			node.meshes.push(mesh);
			node.models.push(member);
		}
	}
	
	public function disposeBuffers() {
		for(target in renderTargets) target?.destroy(true);
		renderTargets.clear();
	}

	public override function destroy() {
		while(foxCameras.length > 0) {
			var cam = foxCameras.pop();
			cam.destroy();
		}
		foxGroup.destroy();
		disposeBuffers();
		super.destroy();
	}
}