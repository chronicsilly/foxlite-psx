package foxlite.group;

import foxlite.group.FoxTypedGroup;
import foxlite.FoxBasic;

#if foxlite_polymod
class FoxGroup extends FoxTypedGroup #if !foxlite_polymod <FoxBasic> #end {}
#else
typedef FoxGroup = FoxTypedGroup<FoxBasic>;
#end