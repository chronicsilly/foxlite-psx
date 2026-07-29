package foxlite.funkin;

#if foxlite_polymod
import funkin.modding.base.ScriptedFlxSprite;

class FoxExtendableSprite extends ScriptedFlxSprite {}
#else
typedef FoxExtendableSprite = flixel.FlxSprite;
#end

enum Bruh0 {} // Add literally any valid statement so HScript can properly close the preprocessor (Polymod 1.8.0)