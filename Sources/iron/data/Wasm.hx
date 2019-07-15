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

	public function getString(i:Int):String { // Retrieve string from memory pointer
		var mem = getMemory(i, 32);
		var s = "";
		for (i in 0...32) mem[i] == 0 ? break : s += String.fromCharCode(mem[i]);
		return s;
	}

	public function getMemory(offset:Int, length:Int):js.lib.Uint8Array {
		return untyped __js__('new Uint8Array({0}.memory.buffer, {1}, {2});', exports, offset, length);
	}

	public function getMemoryF32(offset:Int, length:Int):kha.arrays.Float32Array {
		return untyped __js__('new Float32Array({0}.memory.buffer, {1}, {2});', exports, offset, length);
	}

	public function getMemoryU32(offset:Int, length:Int):kha.arrays.Uint32Array {
		return untyped __js__('new Uint32Array({0}.memory.buffer, {1}, {2});', exports, offset, length);
	}
}

#end
