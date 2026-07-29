
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
2. **Create a new mod folder (can have any name), move** `foxlite_softcoded.json` **inside, rename it to** `_polymod_meta.json`
3. That's it, you now have it installed!

Now you're ready to go!

___(TODO: Add documentation and code snippets)___

## Setting up for Haxelib (dev)
1. Clone this repository to a directory
2. On a terminal, type:
```bash
haxelib dev foxlite <your directory>
```
3. Include it in your haxeflixel `Project.xml` by adding `<haxelib name="foxlite"/>` under `<project>`
