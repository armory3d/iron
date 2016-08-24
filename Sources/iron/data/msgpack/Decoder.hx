package iron.data.msgpack;

import haxe.Int64;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Eof;

using Reflect;

enum DecodeOption {
	AsMap;
	AsObject;
}

private class Pair {

	public var k (default, null) : Dynamic;
	public var v (default, null) : Dynamic;

	public function new(k, v)
	{
		this.k = k;
		this.v = v;
	}
}

class Decoder {
	var o:Dynamic;

	public function new(b:Bytes, option:DecodeOption) {
		var i       = new BytesInput(b);
		i.bigEndian = true;
		o           = decode(i, option);
	}

	function decode(i:BytesInput, option:DecodeOption):Dynamic {
		try {
			var b = i.readByte();
			switch (b) {
				// null
				case 0xc0: return null;

				// boolean
				case 0xc2: return false;
				case 0xc3: return true;

				// binary
				case 0xc4: return i.read(i.readByte  ());
				case 0xc5: return i.read(i.readUInt16());
				case 0xc6: return i.read(i.readInt32 ());

				// floating point
				case 0xca: return i.readFloat ();
				case 0xcb: return i.readDouble();
				
				// unsigned int
				case 0xcc: return i.readByte  ();
				case 0xcd: return i.readUInt16();
				case 0xce: return i.readInt32 ();
				case 0xcf: throw "UInt64 not supported";

				// signed int
				case 0xd0: return i.readInt8 ();
				case 0xd1: return i.readInt16();
				case 0xd2: return i.readInt32();
				case 0xd3: return readInt64(i);

				// string
				case 0xd9: return i.readString(i.readByte  ());
				case 0xda: return i.readString(i.readUInt16());
				case 0xdb: return i.readString(i.readInt32 ());

				// array 16, 32
				case 0xdc: return readArray(i, i.readUInt16(), option);
				case 0xdd: return readArray(i, i.readInt32 (), option);

				// map 16, 32
				case 0xde: return readMap(i, i.readUInt16(), option);
				case 0xdf: return readMap(i, i.readInt32 (), option);

				default  : {
					if (b < 0x80) {	return b;                               } else // positive fix num
					if (b < 0x90) { return readMap  (i, (0xf & b), option); } else // fix map
					if (b < 0xa0) { return readArray(i, (0xf & b), option); } else // fix array
					if (b < 0xc0) { return i.readString(0x1f & b);          } else // fix string
					if (b > 0xdf) { return 0xffffff00 | b;                  }      // negative fix num
				}
			}
		} catch (e:Eof) {}
		return null;
	}

	function readInt64(i:BytesInput){
		var high = i.readInt32();
		var low = i.readInt32();
		return Int64.make(high, low);
	}

	function readArray(i:BytesInput, length:Int, option:DecodeOption) {
		var a = [];
		for(x in 0...length) {
			a.push(decode(i, option));
		}
		return a;
	}

	function readMap(i:BytesInput, length:Int, option:DecodeOption):Dynamic {
		switch (option) {
			case DecodeOption.AsObject:
				var out = {};
				for (n in 0...length) {
					var k = decode(i, option);
					var v = decode(i, option);
					Reflect.setField(out, Std.string(k), v);
				}

				return out;

			case DecodeOption.AsMap:
				var pairs = [];
				for (n in 0...length) {
					var k = decode(i, option);
					var v = decode(i, option);
					pairs.push(new Pair(k, v));
				}

				if (pairs.length == 0)
					return new StringMap();

				switch(Type.typeof(pairs[0].k))
				{
					case TInt:
						var out = new IntMap();
						for (p in pairs){
							switch(Type.typeof(p.k)){
								case TInt:
								default:  
									throw "Error: Mixed key type when decoding IntMap";
							}
							
							if (out.exists(p.k)) 
								throw 'Error: Duplicate keys found => ${p.k}';

							out.set(p.k, p.v);
						}

						return out;

					case TClass(c) if (Type.getClassName(c) == "String"):
						var out = new StringMap();
						for (p in pairs){
							switch(Type.typeof(p.k)){
								case TClass(c) if (Type.getClassName(c) == "String"):
								default: 
									throw "Error: Mixed key type when decoding StringMap";
							}

							if (out.exists(p.k)) 
								throw 'Error: Duplicate keys found => ${p.k}';
							
							out.set(p.k, p.v);
						}

						return out;

					default:
						throw "Error: Unsupported key Type";
				}
		}

		throw "Should not get here";
	}

	public inline function getResult() {
		return o;
	}
}
