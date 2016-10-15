package iron.system;

class CompileTime {

	macro public static function importPackage(path:String) {
		haxe.macro.Compiler.include(path);
		return toExpr(0);
	}

	#if macro
	static function toExpr(v:Dynamic) {
		return haxe.macro.Context.makeExpr(v, haxe.macro.Context.currentPos());
	}
	#end
}
