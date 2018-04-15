package iron.data;

#if js

class Wasm {
	public var exports:Dynamic;	

	public static inline function instance(blob:kha.Blob, importObject:Dynamic = null):Wasm {
		return new Wasm(blob, importObject);
	}

	function new(blob:kha.Blob, importObject:Dynamic) {
		// Switch to WebAssembly.instantiateStreaming when available
		var data = blob.toBytes().getData();
		untyped __js__('var module = new WebAssembly.Module({0});', data);
		if (importObject == null) {
			untyped __js__('{0} = new WebAssembly.Instance(module).exports;', exports);
		}
		else {
			untyped __js__('{0} = new WebAssembly.Instance(module, {1}).exports;', exports, importObject);
		}
	}

	var mem:kha.arrays.Float32Array = null;

	public function getMemory(size:Int):kha.arrays.Float32Array {
		if (mem == null) {
			untyped __js__('{0} = new Float32Array({1}.memory.buffer, {1}.getMemory(), {2});', mem, exports, size);
		}
		return mem;
	}
}

#end
