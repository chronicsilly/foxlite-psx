package foxlite.system;

import foxlite.system.FoxDrawTreeNode;
import haxe.ds.BalancedTree;

#if !foxlite_polymod
typedef FoxDrawTree = BalancedTree<String, FoxDrawTreeNode>;
#else
// Typedef not supported in polymod...
class FoxDrawTree {}
#end

enum Bruh5 {} // Stop script parsing errors in polymod