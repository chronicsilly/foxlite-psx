package foxlite;

import foxlite.FoxBasic;
import foxlite.FoxCamera;
import foxlite.funkin.FoxExtendableSprite;
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

	public var members:Map<String, FoxBasic> = new StringMap();
	public var foxCameras:Array<FoxCamera> = [];

	public final onMemberAdded:FlxTypedSignalImpl<(member:FoxBasic)->Void> = new FlxTypedSignalImpl();
	public final onMemberRemoved:FlxTypedSignalImpl<(member:FoxBasic)->Void> = new FlxTypedSignalImpl();

	/**
		The scene environment.

		This is just a holder object for global environment variables, such as sky textures.
		Note: Subject to change in the future.
	**/
	public var environment:{skyTexture:FoxTexture, skyOffset:Vector2, fogColor:Vector3D} = {
		skyTexture: null,
		skyOffset: new Vector2(),
		fogColor: new Vector3D()
	};

	/**
		The sorted members by process priority.

		This is only used exclusively for this 3D manager, useful for global managers and such.
	**/
	public var sortedMembers:Array<FoxBasic> = [];
	public var __needsSorting:Bool = true;

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

	private var __removals:Array<FoxBasic> = [];

	public var __width:Float = 0;
	public var __height:Float = 0;
	public var timeScale:Float = 1.0;

	public var context:Context3D;

	public function new(width:Int, height:Int) {
		super();
		context = FoxRenderer.getContext();
		flipY = true; // Flixel uses flipped Y UVs, so we flip it

		setupBuffers(width, height); 
	}

	// We can only have ONE name identifier per member
	// So if it already exists, add a postfix
	public function getAvailableName(name:String):String {
		var repeat = 0;
		var origName = name;
		while(members.exists(name)) {
			repeat += 1;
			name = origName + "@" + repeat;
		}
		return name;
	}

	/**
		@returns The available name for this member
	**/
	public function add(member:FoxBasic):String {
		if(member == null || sortedMembers.contains(member)) return null;

		var name = getAvailableName(member.name);
		member.scene = this;
		member._name = name;
		members.set(name, member);
		sortedMembers.push(member);
		onMemberAdded.dispatch(member);

		__needsSorting = true;
		FoxRenderer.mustRebuildDrawGroups = true;
		return name;
	}

	public function remove(member:FoxBasic, destroy:Bool=false):Void {
		if(member == null) return;
		var name = member.name;
		members.remove(name);
		sortedMembers.remove(member);
		__needsSorting = true;
		FoxRenderer.mustRebuildDrawGroups = true;
		if(destroy) member.destroy();
		onMemberRemoved.dispatch(member);
	}

	public function removeByName(memberName:String, destroy:Bool=false):Void {
		var member = members.get(memberName);
		remove(member, destroy);
	}

	public function rename(member:FoxBasic, name:String) {
		var newName = getAvailableName(name);
		if(newName != name) {
			// Name wasn't available so we recieved a change
			member._name = name;
		}
		members.remove(member.name);
		members.set(newName, member);
	}

	// Setup default back buffer
	public function setupBuffers(width:Int, height:Int) {
		__width = width;
		__height = height;

		var backBuffer:FoxFramebuffer = renderTargets.get("default");
		
		if(backBuffer == null) {
			backBuffer = FoxFramebuffer.create3D(width, height, true);
			renderTargets.set("default", backBuffer);
		}
		else backBuffer.resize(width, height);
		
		setOutputDisplay(output, outputColorIndex);

		onFrameBufferResized();
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

		// Sort members by process priority, this also affects the draw order in some way
		if(__needsSorting) {
			sortedMembers.sort((a, b) -> {
				return b.priority - a.priority; // High ones first
			});
			__needsSorting = false;
		}
		

		for(member in sortedMembers) {
			if(member.__destroyed) {
				__removals.push(member);
				continue;
			}
			if(member.active) member.update(elapsed);
		}

		while(__removals.length > 0) remove(__removals.pop());
	}

	public override function draw() {
		onPreDraw();
		FoxRenderer.begin();

		// Prepare draw groups
		if(FoxRenderer.mustRebuildDrawGroups) buildDrawGroups();

		for(cam in foxCameras) {
			if(!cam.visible) continue;
			cam.lightData.clearLights();
			cam.scene = this;
			// Draw call for our members before actual rendering
			for(m in sortedMembers) if(m.visible) m.draw(cam);

			cam.lightData.prepareLights(cam);
			cam.render(drawGroups);
		}

		onPostDraw();
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
		for(m in sortedMembers) if(m.visible) m.pushDrawData(this);
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
		var memberList = [];
		for(member in members.keys()) memberList.push(member);
		while(memberList.length > 0) removeByName(memberList.pop());
		disposeBuffers();
		super.destroy();
	}

	public function onPreDraw():Void {
		for(m in members) m.onScenePreDraw();
	}
	public function onPostDraw():Void {
		//for(m in members) m.onScenePostDraw(); // disabled for less overhead for now
	}
	public function onFrameBufferResized():Void {}
}