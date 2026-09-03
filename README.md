<p width="100%" align="center">
<img src="https://github.com/dwdvIl/foxlite/blob/master/assets/images/foxlite.png?raw=true" alt="Foxlite logo concept by WafflesFox" width="512" />
</p>

Foxlite is a hardware-accelerated 3D renderer made in Haxe that aims to leverage Flixel's and Lime's capabilities to beyond what's intended.
Its main feature it's its open and flexible rendering pipeline, designed to render from the simplest of scenes to full-on Forward+ graphics.

### Foxlite is still on its early stage!
Many things can change throughout its lifecycle, many things are way too simple or limited, and many things can break! If you want to request or add a feature, we welcome you to doing so!

## Features

- [x] ***Really easy setup:*** It takes inspiration from flixel's way of setting up scenes, plus my own ideas for less confusing code; It's very easy to get started!
 - [x] ***Multi-platform support:*** Runs anywhere. Mobile, web browsers, desktop environments and probably consoles aswell. It uses a comprehensive polyfill system to add parity between OpenGL and OpenGL ES.
 - [x] ***glTF Support:*** Foxlite supports most of the GLTF 2.0 specification, so you can load models, animations, armatures and lights! It also supports ***binary glTF (.glb)*** and ***embedded glTF***.
 - [x] ***Completely open Rendering Pipeline:*** About 90% of Foxlite is made of classes that use instanced implementations for rendering, meaning you can create custom classes and assign them to anything to suit your graphical needs.
 - [x] ***Dynamic lights and shadows, and.. Area lights?:*** Foxlite supports area lights... What?? What do you mean they can *"change shape"*? Area lights can indeed change their shape at runtime! Anywhere from a sphere, to a cube, to a cylinder to a hexagon and more!
 - [x] ***Cool Material system:*** Unlike Godot, Foxlite materials aren't determined by a shader, instead materials push values to *a* shader, this means you can swap shaders at any point and use the same material! Materials also include their own custom settable environment as well, such as sky textures and fog distances and colors!
	Materials are also part of Foxlite's batching system, meaning grouping meshes into the same material can help performance.
 - [x] ***Skeletal animations and instancing:*** Animated models and millions of polygons on screen!
 - [x] ***Motion vectors and Forward+ shaders:*** Want to go nuts and add motion blur and raytracing to your game? You're more than welcome to do so!
 - [x] ***Easy render pass system:*** Foxlite has a robust render pass system that's very easy to setup and work around it. It uses a similar approach to how ShaderToy and Minecraft Shaders have multiple buffer/composite stages, but you can filter what model to render on what stage aswell! (Psst, I heard you can also use a global material and shader for all objects in the render pass aswell)
 - [x] ***Custom Animation Engine:*** Made from the ground up, it's designed to be a very easy way of creating animations in Foxlite, this also includes ***Animation Layering*** and 3 mix nodes to suit the very basics! This animation engine can also be used to animate **any object** using its very handy linking system!

	*And for those who only want to use this animation engine and forget about the renderer, you can do it aswell! It's completely standalone!* 
 - [x] And more!


### TODOS
- [ ] Cubemap rendering for passes and shadows as well (Point light and Area light)
- [ ] Use a general texture projector system for shadows (reduces varying count for old GPUs)
- [ ] Simplify custom shaders (QOL improvements like function overriding)
- [ ] Frustum culling
- [ ] Physics engine implementation (considered: [box3d](https://github.com/erincatto/box3d))
- [ ] Away3D's AWD1/2 models support
- [ ] Foxlite Godot export plugin

## Requirements

- haxe (>=4.0.0)

- lime

- openfl

- flixel

  

### Setup guides:

  

[Haxeflixel Setup](https://haxeflixel.com/documentation/getting-started/)

  
  

## Installation

  

Install it via haxelib:

```bash

haxelib install foxlite

```

  

On your `Project.xml`, under `<project>` add this line:

```xml

<haxelib name="foxlite"/>

```

  

## Installing FoxLite for V-Slice

1. Clone this repository to your V-Slice `mods` folder

2.  **Create a new mod folder (can have any name), move**  `foxlite_softcoded.json`  **inside, rename it to**  `_polymod_meta.json`

3. That's it, you now have it installed!

  
  ## Guides
Currently, there's not a lot of guides because I'm the only one developing this focusing more on the code, but people have made some to help you get started.

- You can check the [Codename Engine discord server](https://discord.com/invite/D7ZqGtbqtE), we're mostly active there 

Also check out the [API Docs!](https://dwdvil.github.io/foxlite-api-docs/)
  

## Setting up for Haxelib (dev)

1. Clone this repository to a directory

2. On a terminal, type:

```bash

haxelib dev foxlite <your directory>

```

3. Include it in your haxeflixel `Project.xml` by adding `<haxelib name="foxlite"/>` under `<project>`

  

## License

  

FoxLite is free, open source software licensed under the [MIT License](https://github.com/dwdvIl/foxlite/blob/master/LICENSE)
