package iron.data;

#if js

class Wasm {

	public var exports: Dynamic;

	public static function instance(blob: kha.Blob, importObject: Dynamic = null): Wasm {
		var exports : Dynamic = (importObject == null) ? {} : importObject.exports;
		return new Wasm(
			new js.lib.webassembly.Instance(
				new js.lib.webassembly.Module(blob.toBytes().getData()),
				exports
			).exports
		);
	}

	#if kha_html5_js
	public static function instantiateStreaming(blob: kha.Blob, importObject: Dynamic = null, done: Wasm->Void) {
		js.lib.WebAssembly.instantiateStreaming(new js.html.Response(blob.toBytes().getData(), {
			headers: new js.html.Headers({"Content-Type": "application/wasm"})
		} ), importObject ).then( m -> done(new Wasm(m.instance.exports)));
	}
	#end

	function new( exports : Dynamic ) {
		this.exports = exports;
	}

	public function getString(i: Int): String { // Retrieve string from memory pointer
		var mem = getMemory(i, 32);
		var s = "";
		for (i in 0...32) { mem[i] == 0 ? break : s += String.fromCharCode(mem[i]); }
		return s;
	}

	public inline function getMemory(offset: Int, length: Int): js.lib.Uint8Array {
		return new js.lib.Uint8Array(exports.memory.buffer, offset, length);
	}

	public inline function getMemoryF32(offset: Int, length: Int): kha.arrays.Float32Array {
		return new kha.arrays.Float32Array(exports.memory.buffer).subarray( offset, length );
	}

	public inline function getMemoryU32(offset: Int, length: Int): kha.arrays.Uint32Array {
		return new kha.arrays.Uint32Array(exports.memory.buffer).subarray(offset, length);
	}
}

#end
