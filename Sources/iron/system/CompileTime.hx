// Based on https://github.com/jasononeil/compiletime
package iron.system;

import haxe.macro.Context;

class CompileTime {

    macro public static function importPackage(path:String, ?recursive:Bool = true, ?ignore : Array<String>, ?classPaths : Array<String>) {
        haxe.macro.Compiler.include(path, recursive, ignore, classPaths);
        return toExpr(0);
    }

    #if macro
    static function toExpr(v:Dynamic) {
        return Context.makeExpr(v, Context.currentPos());
    }
    #end
}
