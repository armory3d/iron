package iron.data;
import haxe.io.BytesInput;
import haxe.zip.Reader;
import iron.data.SceneFormat;

// Global data list and asynchronous data loading
class Data {

	public static var cachedSceneRaws:Map<String, TSceneFormat> = new Map();
	public static var cachedMeshes:Map<String, MeshData> = new Map();
	public static var cachedLamps:Map<String, LampData> = new Map();
	public static var cachedCameras:Map<String, CameraData> = new Map();
	public static var cachedMaterials:Map<String, MaterialData> = new Map();
	public static var cachedParticles:Map<String, ParticleData> = new Map();
	public static var cachedWorlds:Map<String, WorldData> = new Map();
	// public static var cachedGreasePencils:Map<String, GreasePencilData> = new Map();
	public static var cachedShaders:Map<String, ShaderData> = new Map();

	public static var cachedBlobs:Map<String, kha.Blob> = new Map();
	public static var cachedImages:Map<String, kha.Image> = new Map();
	public static var cachedSounds:Map<String, kha.Sound> = new Map();
	public static var cachedVideos:Map<String, kha.Video> = new Map();
	public static var cachedFonts:Map<String, kha.Font> = new Map();

	#if arm_published
	static var dataPath = './data/';
	#else
	static var dataPath = '';
	#end

	public function new() { }

	public static function deleteAll() {
		for (c in cachedMeshes) c.delete();
		cachedMeshes = new Map();
		for (c in cachedShaders) c.delete();
		cachedShaders = new Map();
		cachedSceneRaws = new Map();
		cachedLamps = new Map();
		cachedCameras = new Map();
		cachedMaterials = new Map();
		cachedParticles = new Map();
		cachedWorlds = new Map();
		// cachedGreasePencils = new Map();
		if (RenderPath.active != null) RenderPath.active.unload();

		for (c in cachedBlobs) c.unload();
		cachedBlobs = new Map();
		for (c in cachedImages) c.unload();
		cachedImages = new Map();
		for (c in cachedSounds) c.unload();
		cachedSounds = new Map();
		for (c in cachedVideos) c.unload();
		cachedVideos = new Map();
		for (c in cachedFonts) c.unload();
		cachedFonts = new Map();
	}

	// Experimental scene patching
	public static function clearSceneData() {
		cachedSceneRaws = new Map();
		cachedMeshes = new Map(); // Delete data
		cachedLamps = new Map();
		cachedMaterials = new Map();
		cachedCameras = new Map();
		cachedParticles = new Map();
		cachedWorlds = new Map();
		// cachedGreasePencils = new Map();
		cachedShaders = new Map(); // Slow
		cachedBlobs = new Map();
	}

	static var loadingMeshes:Map<String, Array<MeshData->Void>> = new Map();
	public static function getMesh(file:String, name:String, done:MeshData->Void) {
		var handle = file + name;
		var cached = cachedMeshes.get(handle);
		if (cached != null) { done(cached); return; }

		var loading = loadingMeshes.get(handle);
		if (loading != null) { loading.push(done); return; }

		loadingMeshes.set(file + name, [done]);

		MeshData.parse(file, name, function(b:MeshData) {
			cachedMeshes.set(file + name, b);
			b.handle = handle;
			for (f in loadingMeshes.get(file + name)) f(b);
			loadingMeshes.remove(file + name);
		});
	}

	public static function deleteMesh(handle:String) {
		// Remove cached mesh
		var mesh = cachedMeshes.get(handle);
		if (mesh == null) return;
		mesh.delete();
		cachedMeshes.remove(handle);
	}

	static var loadingLamps:Map<String, Array<LampData->Void>> = new Map();
	public static function getLamp(file:String, name:String, done:LampData->Void) {
		var cached = cachedLamps.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingLamps.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingLamps.set(file + name, [done]);

		LampData.parse(file, name, function(b:LampData) {
			cachedLamps.set(file + name, b);
			for (f in loadingLamps.get(file + name)) f(b);
			loadingLamps.remove(file + name);
		});
	}

	static var loadingCameras:Map<String, Array<CameraData->Void>> = new Map();
	public static function getCamera(file:String, name:String, done:CameraData->Void) {
		var cached = cachedCameras.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingCameras.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingCameras.set(file + name, [done]);

		CameraData.parse(file, name, function(b:CameraData) {
			cachedCameras.set(file + name, b);
			for (f in loadingCameras.get(file + name)) f(b);
			loadingCameras.remove(file + name);
		});
	}

	static var loadingMaterials:Map<String, Array<MaterialData->Void>> = new Map();
	public static function getMaterial(file:String, name:String, done:MaterialData->Void) {
		var cached = cachedMaterials.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingMaterials.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingMaterials.set(file + name, [done]);

		MaterialData.parse(file, name, function(b:MaterialData) {
			cachedMaterials.set(file + name, b);
			for (f in loadingMaterials.get(file + name)) f(b);
			loadingMaterials.remove(file + name);
		});
	}

	static var loadingParticles:Map<String, Array<ParticleData->Void>> = new Map();
	public static function getParticle(file:String, name:String, done:ParticleData->Void) {
		var cached = cachedParticles.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingParticles.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingParticles.set(file + name, [done]);

		ParticleData.parse(file, name, function(b:ParticleData) {
			cachedParticles.set(file + name, b);
			for (f in loadingParticles.get(file + name)) f(b);
			loadingParticles.remove(file + name);
		});
	}

	static var loadingWorlds:Map<String, Array<WorldData->Void>> = new Map();
	public static function getWorld(file:String, name:String, done:WorldData->Void) {
		if (name == null) { done(null); return; } // No world defined in scene

		var cached = cachedWorlds.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingWorlds.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingWorlds.set(file + name, [done]);

		WorldData.parse(file, name, function(b:WorldData) {
			cachedWorlds.set(file + name, b);
			for (f in loadingWorlds.get(file + name)) f(b);
			loadingWorlds.remove(file + name);
		});
	}

	// static var loadingGreasePencils:Map<String, Array<GreasePencilData->Void>> = new Map();
	// public static function getGreasePencil(file:String, name:String, done:GreasePencilData->Void) {
	// 	var cached = cachedGreasePencils.get(file + name);
	// 	if (cached != null) { done(cached); return; }

	// 	var loading = loadingGreasePencils.get(file + name);
	// 	if (loading != null) { loading.push(done); return; }

	// 	loadingGreasePencils.set(file + name, [done]);

	// 	GreasePencilData.parse(file, name, function(b:GreasePencilData) {
	// 		cachedGreasePencils.set(file + name, b);
	// 		for (f in loadingGreasePencils.get(file + name)) f(b);
	// 		loadingGreasePencils.remove(file + name);
	// 	});
	// }

	static var loadingShaders:Map<String, Array<ShaderData->Void>> = new Map();
	public static function getShader(file:String, name:String, overrideContext:TShaderOverride, done:ShaderData->Void) {
		// Only one context override per shader data for now
		var cacheName = name;
		if (overrideContext != null) cacheName += "2";
		var cached = cachedShaders.get(cacheName); // Shader must have unique name
		if (cached != null) { done(cached); return; }

		var loading = loadingShaders.get(cacheName);
		if (loading != null) { loading.push(done); return; }

		loadingShaders.set(cacheName, [done]);

		ShaderData.parse(file, name, overrideContext, function(b:ShaderData) {
			cachedShaders.set(cacheName, b);
			for (f in loadingShaders.get(cacheName)) f(b);
			loadingShaders.remove(cacheName);
		});
	}

	static var loadingSceneRaws:Map<String, Array<TSceneFormat->Void>> = new Map();
	public static function getSceneRaw(file:String, done:TSceneFormat->Void) {
		var cached = cachedSceneRaws.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingSceneRaws.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingSceneRaws.set(file, [done]);

		// If no extension specified, set to .arm
		var compressed = StringTools.endsWith(file, '.zip');
		var isJson = StringTools.endsWith(file, '.json');
		var ext = (compressed || isJson || StringTools.endsWith(file, '.arm')) ? '' : '.arm';

		getBlob(file + ext, function(b:kha.Blob) {

			if (compressed) {
#if (!hl) // TODO: korehl - unresolved external symbol _fmt_inflate_buffer
				var input = new BytesInput(b.toBytes());
				var entry = Reader.readZip(input).first();
				if (entry == null) {
					trace('Failed to uncompress ' + file);
					return;
				}
				if (entry.compressed) b = kha.Blob.fromBytes(Reader.unzip(entry));
				else b = kha.Blob.fromBytes(entry.data);
#end
			}

#if (arm_stream && kha_webgl)
			workerDecode(b, function(parsed:TSceneFormat) {
				returnSceneRaw(file, parsed);
			});
#else

			var parsed:TSceneFormat = null;
			if (isJson) {
				var s = b.toString();
				parsed = s.charAt(0) == "{" ? haxe.Json.parse(s) : iron.system.ArmPack.decode(b.toBytes());
			}
			else {
				parsed = iron.system.ArmPack.decode(b.toBytes());
			}

			returnSceneRaw(file, parsed);
#end
		});
	}

	static function returnSceneRaw(file:String, parsed:TSceneFormat) {
		cachedSceneRaws.set(file, parsed);
		for (f in loadingSceneRaws.get(file)) f(parsed);
		loadingSceneRaws.remove(file);
	}

	#if (arm_stream && kha_webgl)
	static var worker:js.html.Worker = null;
	static var workerMap = new Map<Int, TSceneFormat->Void>();
	static var workerId = 0;
	static function workerDone(parsed:TSceneFormat, id:Int) {
		var done = workerMap.get(id);
		done(parsed);
		workerMap.remove(id);
	}
	static function workerDecode(b:kha.Blob, done:TSceneFormat->Void) {
		// ArmPack compiled to JS
		if (worker == null) {
			var blob = new js.html.Blob([
			"
			!function(a,b){'use strict';function d(a,b){function c(){}c.prototype=a;var d=new c;for(var e in b)d[e]=b[e];return b.toString!==Object.prototype.toString&&(d.toString=b.toString),d}var c=function(){return n.__string_rec(this,'')};Math.__name__=!0;var e=function(){};e.__name__=!0,e.string=function(a){return n.__string_rec(a,'')};var f=a.Test=function(){};f.__name__=!0,f.decode=function(a){var b=new g(a),c=new i(b);return c.set_bigEndian(!0),f.read(c)},f.read=function(a){try{var b=a.readByte();switch(b){case 192:return null;case 194:return!1;case 195:return!0;case 196:return a.read(a.readByte());case 197:return a.read(a.readUInt16());case 198:return a.read(a.readInt32());case 202:return a.readFloat();case 203:return a.readDouble();case 204:return a.readByte();case 205:return a.readUInt16();case 206:return a.readInt32();case 208:return a.readInt8();case 209:return a.readInt16();case 210:return a.readInt32();case 217:return a.readString(a.readByte());case 218:return a.readString(a.readUInt16());case 219:return a.readString(a.readInt32());case 220:return f.readArray(a,a.readUInt16());case 221:return f.readArray(a,a.readInt32());case 222:return f.readMap(a,a.readUInt16());case 223:return f.readMap(a,a.readInt32());default:if(b<128)return b;if(b<144)return f.readMap(a,15&b);if(b<160)return f.readArray(a,15&b);if(b<192)return a.readString(31&b);if(b>223)return-256|b}}catch(a){if(a instanceof m&&(a=a.val),!n.__instanceof(a,j))throw a}return null},f.readArray=function(a,b){var c=a.readByte();if(a.set_position(a.pos-1),202==c){a.set_position(a.pos+1);for(var d=new y(b),e=0;e<b;)d[e++]=a.readFloat();return d}if(210==c){a.set_position(a.pos+1);for(var g=new Uint32Array(b),h=0;h<b;)g[h++]=a.readInt32();return g}for(var i=[],j=0;j<b;)++j,i.push(f.read(a));return i},f.readMap=function(a,b){for(var c={},d=0;d<b;){++d;var g=f.read(a),h=f.read(a);c[e.string(g)]=h}return c},f.main=function(){};var g=function(a){this.length=a.byteLength,this.b=new z(a),this.b.bufferValue=a,a.hxBytes=this,a.bytes=this.b};g.__name__=!0,g.prototype={getString:function(a,b){if(a<0||b<0||a+b>this.length)throw new m(k.OutsideBounds);for(var c='',d=this.b,e=String.fromCharCode,f=a,g=a+b;f<g;){var h=d[f++];if(h<128){if(0==h)break;c+=e(h)}else if(h<224)c+=e((63&h)<<6|127&d[f++]);else if(h<240)c+=e((31&h)<<12|(127&d[f++])<<6|127&d[f++]);else{var i=(15&h)<<18|(127&d[f++])<<12|(127&d[f++])<<6|127&d[f++];c+=e(55232+(i>>10)),c+=e(1023&i|56320)}}return c},toString:function(){return this.getString(0,this.length)},__class__:g};var h=function(){};h.__name__=!0,h.prototype={readByte:function(){throw new m('Not implemented')},readBytes:function(a,b,c){var d=c,e=a.b;if(b<0||c<0||b+c>a.length)throw new m(k.OutsideBounds);try{for(;d>0;)e[b]=this.readByte(),++b,--d}catch(a){if(a instanceof m&&(a=a.val),!n.__instanceof(a,j))throw a}return c-d},set_bigEndian:function(a){return this.bigEndian=a,a},readFullBytes:function(a,b,c){for(;c>0;){var d=this.readBytes(a,b,c);if(0==d)throw new m(k.Blocked);b+=d,c-=d}},read:function(a){for(var b=new g(new x(a)),c=0;a>0;){var d=this.readBytes(b,c,a);if(0==d)throw new m(k.Blocked);c+=d,a-=d}return b},readFloat:function(){return l.i32ToFloat(this.readInt32())},readDouble:function(){var a=this.readInt32(),b=this.readInt32();return this.bigEndian?l.i64ToDouble(b,a):l.i64ToDouble(a,b)},readInt8:function(){var a=this.readByte();return a>=128?a-256:a},readInt16:function(){var a=this.readByte(),b=this.readByte(),c=this.bigEndian?b|a<<8:a|b<<8;return 0!=(32768&c)?c-65536:c},readUInt16:function(){var a=this.readByte(),b=this.readByte();return this.bigEndian?b|a<<8:a|b<<8},readInt32:function(){var a=this.readByte(),b=this.readByte(),c=this.readByte(),d=this.readByte();return this.bigEndian?d|c<<8|b<<16|a<<24:a|b<<8|c<<16|d<<24},readString:function(a){var b=new g(new x(a));return this.readFullBytes(b,0,a),b.toString()},__class__:h};var i=function(a,b,c){if(null==b&&(b=0),null==c&&(c=a.length-b),b<0||c<0||b+c>a.length)throw new m(k.OutsideBounds);this.b=a.b,this.pos=b,this.len=c,this.totlen=c};i.__name__=!0,i.__super__=h,i.prototype=d(h.prototype,{set_position:function(a){return a<0?a=0:a>this.totlen&&(a=this.totlen),this.len=this.totlen-a,this.pos=a},readByte:function(){if(0==this.len)throw new m(new j);return this.len--,this.b[this.pos++]},readBytes:function(a,b,c){if(b<0||c<0||b+c>a.length)throw new m(k.OutsideBounds);if(0==this.len&&c>0)throw new m(new j);this.len<c&&(c=this.len);for(var d=this.b,e=a.b,f=0,g=c;f<g;){var h=f++;e[b+h]=d[this.pos+h]}return this.pos+=c,this.len-=c,c},__class__:i});var j=function(){};j.__name__=!0,j.prototype={toString:function(){return'Eof'},__class__:j};var k={__ename__:!0,__constructs__:['Blocked','Overflow','OutsideBounds','Custom']};k.Blocked=['Blocked',0],k.Blocked.toString=c,k.Blocked.__enum__=k,k.Overflow=['Overflow',1],k.Overflow.toString=c,k.Overflow.__enum__=k,k.OutsideBounds=['OutsideBounds',2],k.OutsideBounds.toString=c,k.OutsideBounds.__enum__=k,k.Custom=function(a){var b=['Custom',3,a];return b.__enum__=k,b.toString=c,b};var l=function(){};l.__name__=!0,l.i32ToFloat=function(a){var b=a>>>23&255,c=8388607&a;return 0==c&&0==b?0:(1-(a>>>31<<1))*(1+Math.pow(2,-23)*c)*Math.pow(2,b-127)},l.floatToI32=function(a){if(0==a)return 0;var b=a<0?-a:a,c=Math.floor(Math.log(b)/.6931471805599453);c<-127?c=-127:c>128&&(c=128);var d=Math.round(8388608*(b/Math.pow(2,c)-1));return 8388608==d&&c<128&&(d=0,++c),(a<0?-2147483648:0)|c+127<<23|d},l.i64ToDouble=function(a,b){var c=(b>>20&2047)-1023,d=4294967296*(1048575&b)+2147483648*(a>>>31)+(2147483647&a);return 0==d&&-1023==c?0:(1-(b>>>31<<1))*(1+Math.pow(2,-52)*d)*Math.pow(2,c)};var m=function(a){Error.call(this),this.val=a,this.message=String(a),Error.captureStackTrace&&Error.captureStackTrace(this,m)};m.__name__=!0,m.wrap=function(a){return a instanceof Error?a:new m(a)},m.__super__=Error,m.prototype=d(Error.prototype,{__class__:m});var n=function(){};n.__name__=!0,n.getClass=function(a){if(a instanceof Array&&null==a.__enum__)return Array;var b=a.__class__;if(null!=b)return b;var c=n.__nativeClassName(a);return null!=c?n.__resolveNativeClass(c):null},n.__string_rec=function(a,b){if(null==a)return'null';if(b.length>=5)return'<...>';var c=typeof a;switch('function'==c&&(a.__name__||a.__ename__)&&(c='object'),c){case'function':return'<function>';case'object':if(a instanceof Array){if(a.__enum__){if(2==a.length)return a[0];var d=a[0]+'(';b+='\\t';for(var e=2,f=a.length;e<f;){var g=e++;d+=2!=g?','+n.__string_rec(a[g],b):n.__string_rec(a[g],b)}return d+')'}var h=a.length,j='[';b+='\\t';for(var k=0,l=h;k<l;){var m=k++;j+=(m>0?',':'')+n.__string_rec(a[m],b)}return j+=']'}var o;try{o=a.toString}catch(a){return'???'}if(null!=o&&o!=Object.toString&&'function'==typeof o){var p=a.toString();if('[object Object]'!=p)return p}var q=null,r='{\\n';b+='\\t';var s=null!=a.hasOwnProperty;for(var q in a)s&&!a.hasOwnProperty(q)||'prototype'!=q&&'__class__'!=q&&'__super__'!=q&&'__interfaces__'!=q&&'__properties__'!=q&&(2!=r.length&&(r+=', \\n'),r+=b+q+' : '+n.__string_rec(a[q],b));return b=b.substring(1),r+='\\n'+b+'}';case'string':return a;default:return String(a)}},n.__interfLoop=function(a,b){if(null==a)return!1;if(a==b)return!0;var c=a.__interfaces__;if(null!=c)for(var d=0,e=c.length;d<e;){var f=c[d++];if(f==b||n.__interfLoop(f,b))return!0}return n.__interfLoop(a.__super__,b)},n.__instanceof=function(a,b){if(null==b)return!1;switch(b){case Array:return a instanceof Array&&null==a.__enum__;case u:return'boolean'==typeof a;case s:return!0;case t:return'number'==typeof a;case r:return'number'==typeof a&&(0|a)===a;case String:return'string'==typeof a;default:if(null==a)return!1;if('function'==typeof b){if(a instanceof b)return!0;if(n.__interfLoop(n.getClass(a),b))return!0}else if('object'==typeof b&&n.__isNativeObj(b)&&a instanceof b)return!0;return b==v&&null!=a.__name__||(b==w&&null!=a.__ename__||a.__enum__==b)}},n.__nativeClassName=function(a){var b=n.__toStr.call(a).slice(8,-1);return'Object'==b||'Function'==b||'Math'==b||'JSON'==b?null:b},n.__isNativeObj=function(a){return null!=n.__nativeClassName(a)},n.__resolveNativeClass=function(a){return b[a]};var o=function(a){if(a instanceof Array&&null==a.__enum__)this.a=a,this.byteLength=a.length;else{var b=a;this.a=[];for(var c=0,d=b;c<d;)this.a[c++]=0;this.byteLength=b}};o.__name__=!0,o.sliceImpl=function(a,b){var c=new z(this,a,null==b?null:b-a),d=new x(c.byteLength);return new z(d).set(c),d},o.prototype={slice:function(a,b){return new o(this.a.slice(a,b))},__class__:o};var p=function(){};p.__name__=!0,p._new=function(a,b,c){var d;if('number'==typeof a){d=[];for(var f=0,g=a;f<g;){d[f++]=0}d.byteLength=d.length<<2,d.byteOffset=0;for(var i=[],j=0,k=d.length<<2;j<k;){j++;i.push(0)}d.buffer=new o(i)}else if(n.__instanceof(a,o)){var r=a;null==b&&(b=0),null==c&&(c=r.byteLength-b>>2),d=[];for(var s=0,t=c;s<t;){var v=(s++,r.a[b++]|r.a[b++]<<8|r.a[b++]<<16|r.a[b++]<<24);d.push(l.i32ToFloat(v))}d.byteLength=d.length<<2,d.byteOffset=b,d.buffer=r}else{if(!(a instanceof Array&&null==a.__enum__))throw new m('TODO '+e.string(a));d=a.slice();for(var w=[],x=0;x<d.length;){var y=d[x];++x;var z=l.floatToI32(y);w.push(255&z),w.push(z>>8&255),w.push(z>>16&255),w.push(z>>>24)}d.byteLength=d.length<<2,d.byteOffset=0,d.buffer=new o(w)}return d.subarray=p._subarray,d.set=p._set,d},p._set=function(a,b){if(n.__instanceof(a.buffer,o)){var c=a;if(a.byteLength+b>this.byteLength)throw new m('set() outside of range');for(var d=0,e=a.byteLength;d<e;){var f=d++;this[f+b]=c[f]}}else{if(!(a instanceof Array&&null==a.__enum__))throw new m('TODO');var g=a;if(g.length+b>this.byteLength)throw new m('set() outside of range');for(var h=0,i=g.length;h<i;){var j=h++;this[j+b]=g[j]}}},p._subarray=function(a,b){var c=p._new(this.slice(a,b));return c.byteOffset=4*a,c};var q=function(){};q.__name__=!0,q._new=function(a,b,c){var d;if('number'==typeof a){d=[];for(var f=0,g=a;f<g;){d[f++]=0}d.byteLength=d.length,d.byteOffset=0,d.buffer=new o(d)}else if(n.__instanceof(a,o)){var i=a;null==b&&(b=0),null==c&&(c=i.byteLength-b),d=0==b?i.a:i.a.slice(b,b+c),d.byteLength=d.length,d.byteOffset=b,d.buffer=i}else{if(!(a instanceof Array&&null==a.__enum__))throw new m('TODO '+e.string(a));d=a.slice(),d.byteLength=d.length,d.byteOffset=0,d.buffer=new o(d)}return d.subarray=q._subarray,d.set=q._set,d},q._set=function(a,b){if(n.__instanceof(a.buffer,o)){var c=a;if(a.byteLength+b>this.byteLength)throw new m('set() outside of range');for(var d=0,e=a.byteLength;d<e;){var f=d++;this[f+b]=c[f]}}else{if(!(a instanceof Array&&null==a.__enum__))throw new m('TODO');var g=a;if(g.length+b>this.byteLength)throw new m('set() outside of range');for(var h=0,i=g.length;h<i;){var j=h++;this[j+b]=g[j]}}},q._subarray=function(a,b){var c=q._new(this.slice(a,b));return c.byteOffset=a,c},String.prototype.__class__=String,String.__name__=!0,Array.__name__=!0;var r={__name__:['Int']},s={__name__:['Dynamic']},t=Number;t.__name__=['Float'];var u=Boolean;u.__ename__=['Bool'];var v={__name__:['Class']},w={},x=b.ArrayBuffer||o;null==x.prototype.slice&&(x.prototype.slice=o.sliceImpl);var y=b.Float32Array||p._new,z=b.Uint8Array||q._new;n.__toStr={}.toString,p.BYTES_PER_ELEMENT=4,q.BYTES_PER_ELEMENT=1}('undefined'!=typeof exports?exports:'undefined'!=typeof window?window:'undefined'!=typeof self?self:this,'undefined'!=typeof window?window:'undefined'!=typeof global?global:'undefined'!=typeof self?self:this);
			onmessage = function(e) {
				var arraybuffer = new Uint8Array(e.data.buffer);
				var data = Test.decode(arraybuffer);
				// Transfer ownership of arraybuffers
				var transferList = [];
				if (typeof data.mesh_datas !== 'undefined') {
					for (i = 0; i < data.mesh_datas.length; i++) {
						for (j = 0; j < data.mesh_datas[i].vertex_arrays.length; j++) {
							transferList.push(data.mesh_datas[i].vertex_arrays[j].values.buffer);
						}
						for (j = 0; j < data.mesh_datas[i].index_arrays.length; j++) {
							transferList.push(data.mesh_datas[i].index_arrays[j].values.buffer);	
						}
					}
				}
				postMessage({parsed: data, id: e.data.id}, transferList);
			}"]);
			var blobURL = untyped __js__("window.URL.createObjectURL({0});", blob);
			worker = new js.html.Worker(blobURL);
			worker.onmessage = function(e) {
				workerDone(e.data.parsed, e.data.id);
			}
		}
		var arraybuffer = untyped b.toBytes().getData().buffer;
		worker.postMessage({buffer: arraybuffer, id: workerId}, [arraybuffer]);
		workerMap.set(workerId, done);
		workerId++;
	}
	#end

	public static function getMeshRawByName(datas:Array<TMeshData>, name:String):TMeshData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getLampRawByName(datas:Array<TLampData>, name:String):TLampData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getCameraRawByName(datas:Array<TCameraData>, name:String):TCameraData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getMaterialRawByName(datas:Array<TMaterialData>, name:String):TMaterialData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getParticleRawByName(datas:Array<TParticleData>, name:String):TParticleData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getWorldRawByName(datas:Array<TWorldData>, name:String):TWorldData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	// public static function getGreasePencilRawByName(datas:Array<TGreasePencilData>, name:String):TGreasePencilData {
	// 	if (name == "") return datas[0];
	// 	for (dat in datas) if (dat.name == name) return dat;
	// 	return null;
	// }

	public static function getShaderRawByName(datas:Array<TShaderData>, name:String):TShaderData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getSpeakerRawByName(datas:Array<TSpeakerData>, name:String):TSpeakerData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	// Raw assets
	public static var assetsLoaded = 0;

	static var loadingBlobs:Map<String, Array<kha.Blob->Void>> = new Map();
	public static function getBlob(file:String, done:kha.Blob->Void) {
		var cached = cachedBlobs.get(file); // Is already cached
		if (cached != null) { done(cached); return; }

		var loading = loadingBlobs.get(file); // Is already being loaded
		if (loading != null) { loading.push(done); return; }

		loadingBlobs.set(file, [done]); // Start loading

		kha.Assets.loadBlobFromPath(dataPath + file, function(b:kha.Blob) {
			cachedBlobs.set(file, b);
			for (f in loadingBlobs.get(file)) f(b);
			loadingBlobs.remove(file);
			assetsLoaded++;
		});
	}

	static var loadingImages:Map<String, Array<kha.Image->Void>> = new Map();
	public static function getImage(file:String, done:kha.Image->Void, readable = false, format = 'RGBA32') {
#if (cpp || hl)
		file = file.substring(0, file.length - 4) + '.k';
#end

		var cached = cachedImages.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingImages.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingImages.set(file, [done]);

		// TODO: process format in Kha
		kha.Assets.loadImageFromPath(dataPath + file, readable, function(b:kha.Image) {
			cachedImages.set(file, b);
			for (f in loadingImages.get(file)) f(b);
			loadingImages.remove(file);
			assetsLoaded++;
		});
	}

	static var loadingSounds:Map<String, Array<kha.Sound->Void>> = new Map();
	public static function getSound(file:String, done:kha.Sound->Void) {
		#if arm_no_audio
		done(null);
		return;
		#end

		#if arm_soundcompress
		if (StringTools.endsWith(file, '.wav')) file = file.substring(0, file.length - 4) + '.ogg';
		#end

		var cached = cachedSounds.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingSounds.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingSounds.set(file, [done]);

		kha.Assets.loadSoundFromPath(dataPath + file, function(b:kha.Sound) {
			#if arm_soundcompress
			b.uncompress(function () {
			#end
				cachedSounds.set(file, b);
				for (f in loadingSounds.get(file)) f(b);
				loadingSounds.remove(file);
				assetsLoaded++;
			#if arm_soundcompress
			});
			#end
		});
	}

	static var loadingVideos:Map<String, Array<kha.Video->Void>> = new Map();
	public static function getVideo(file:String, done:kha.Video->Void) {
#if (cpp || hl)
		file = file.substring(0, file.length - 4) + '.avi';
#end
		var cached = cachedVideos.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingVideos.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingVideos.set(file, [done]);

		kha.Assets.loadVideoFromPath(dataPath + file, function(b:kha.Video) {
			cachedVideos.set(file, b);
			for (f in loadingVideos.get(file)) f(b);
			loadingVideos.remove(file);
			assetsLoaded++;
		});
	}

	static var loadingFonts:Map<String, Array<kha.Font->Void>> = new Map();
	public static function getFont(file:String, done:kha.Font->Void) {
		var cached = cachedFonts.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingFonts.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingFonts.set(file, [done]);

		kha.Assets.loadFontFromPath(dataPath + file, function(b:kha.Font) {
			cachedFonts.set(file, b);
			for (f in loadingFonts.get(file)) f(b);
			loadingFonts.remove(file);
			assetsLoaded++;
		});
	}
}
