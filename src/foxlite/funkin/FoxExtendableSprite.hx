package foxlite.funkin;

#if polymod
import funkin.modding.base.ScriptedFlxSprite;
class FoxExtendableSprite extends ScriptedFlxSprite {}
#elseif cne
typedef FoxExtendableSprite = funkin.backend.FunkinSprite;
#else
typedef FoxExtendableSprite = flixel.FlxSprite;
#end