// Msgpack parser with typed arrays
// Based on https://github.com/aaulia/msgpack-haxe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
package iron.system;

// import haxe.Int64;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Eof;
import iron.data.SceneFormat;

//@:expose
class ArmPack {

	public static inline function decode(b:Bytes):Dynamic {
		var i = new BytesInput(b);
		i.bigEndian = true;
		return read(i);
	}

	static function read(i:BytesInput):Dynamic {
		try {
			var b = i.readByte();
			switch (b) {
				// null
				case 0xc0: return null;

				// boolean
				case 0xc2: return false;
				case 0xc3: return true;

				// binary
				case 0xc4: return i.read(i.readByte());
				case 0xc5: return i.read(i.readUInt16());
				case 0xc6: return i.read(i.readInt32());

				// floating point
				case 0xca: return i.readFloat();
				case 0xcb: return i.readDouble();
				
				// unsigned int
				case 0xcc: return i.readByte();
				case 0xcd: return i.readUInt16();
				case 0xce: return i.readInt32();
				// case 0xcf: throw "UInt64 not supported";

				// signed int
				case 0xd0: return i.readInt8();
				case 0xd1: return i.readInt16();
				case 0xd2: return i.readInt32();
				// case 0xd3: {
					// var high = i.readInt32();
					// var low = i.readInt32();
					// return Int64.make(high, low);
				// }

				// string
				case 0xd9: return i.readString(i.readByte());
				case 0xda: return i.readString(i.readUInt16());
				case 0xdb: return i.readString(i.readInt32());

				// array 16, 32
				case 0xdc: return readArray(i, i.readUInt16());
				case 0xdd: return readArray(i, i.readInt32());

				// map 16, 32
				case 0xde: return readMap(i, i.readUInt16());
				case 0xdf: return readMap(i, i.readInt32());

				default: {
					if (b < 0x80) return b; // positive fix num
					else if (b < 0x90) return readMap(i, (0xf & b)); // fix map
					else if (b < 0xa0) return readArray(i, (0xf & b)); // fix array
					else if (b < 0xc0) return i.readString(0x1f & b); // fix string
					else if (b > 0xdf) return 0xffffff00 | b; // negative fix num
				}
			}
		}
		catch (e:Eof) {}
		return null;
	}

	static function readArray(i:BytesInput, length:Int):Dynamic {
		var b = i.readByte();
		i.position--;

		// Typed float32
		if (b == 0xca) {
			i.position++;
			var a = new TFloat32Array(length);
			// var a = new js.html.Float32Array(length);
			for (x in 0...length) a[x] = i.readFloat();
			return a;
		}
		// Typed int32
		else if (b == 0xd2) {
			i.position++;
			var a = new TUint32Array(length);
			// var a = new js.html.Uint32Array(length);
			for (x in 0...length) a[x] = i.readInt32();
			return a;
		}
		// Dynamic type-value
		else {
			var a:Array<Dynamic> = [];
			for(x in 0...length) a.push(read(i));
			return a;
		}
	}

	static function readMap(i:BytesInput, length:Int):Dynamic {
		var out = {};
		for (n in 0...length) {
			var k = read(i);
			var v = read(i);
			Reflect.setField(out, Std.string(k), v);
		}
		return out;	
	}
}
