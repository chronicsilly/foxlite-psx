package foxlite.funkin;

#if foxlite_polymod
import funkin.modding.base.ScriptedFlxSprite;

class FoxExtendableSprite extends ScriptedFlxSprite {}
#else
typedef FoxExtendableSprite = flixel.FlxSprite;
#end