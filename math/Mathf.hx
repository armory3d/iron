/*
HAXOR HTML5 ENGINE (c) 2013 - 2014 by Eduardo Pons - eduardo@thelaborat.org

HAXOR HTML5 ENGINE is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
 */
package fox.math;

/**
 * ...
 * @author Eduardo Pons - eduardo@thelaborat.org
 */

class Mathf 
{
        static public var Epsilon 			= 1.0 / 100000.0;
        
		static public var NaN 				= Math.NaN;
        
		static public var Infinity 			= Math.POSITIVE_INFINITY;
        
		static public var NegativeInfinity 	= Math.NEGATIVE_INFINITY;
        
		static public var E 				= 2.7182818284590452353602874713527;
        
		static public var PI 				= 3.1415926535897932384626433832795028841971693993751058;
        
		static public var HalfPI 			= PI * 0.5;
        
		static public var PI2 				= PI * 2.0;
        
		static public var PI4 				= PI * 4.0;
		
		static public var InvPI				= 0.31830988618379067153776752674503;
        
		static public var Rad2Deg 			= 180.0 / PI;
        
		static public var Deg2Rad 			= PI / 180.0;
        
		static public var Px2Em 			= 0.063;
        
		static public var Em2Px 			= 1.0 / 0.063;
		
		static public var Byte2Float	: Float	= 0.00392156863;
		
		static public var Short2Float	: Float	= 0.0000152587890625;
		
		static public var Long2Float	: Float	= 0.00000000023283064365386962890625;
		
		static public var Float2Byte	: Float	= 255.0;
		
		static public var Float2Short	: Float	= 65536.0;
		
		static public var Float2Long	: Float	= 4294967296.0;
		
		
		static inline public function IsPOT(p_v:Int):Bool { return ((p_v > 0) && ((p_v & (p_v - 1)) == 0)); }

        static inline public function NextPOT(p_v:Int):Int
        {
            --p_v; 
			p_v |= p_v >> 1;  p_v |= p_v >> 2;
			p_v |= p_v >> 4;  p_v |= p_v >> 8;
            p_v |= p_v >> 16;
            return ++p_v;
        }
		
		static public inline function Sign(p_a:Float):Float  { return p_a < 0 ? -1.0 : 1.0; }
		
		static public inline function SignInt(p_a:Int):Int  { return p_a < 0 ? -1 : 1; }
		
		static public inline function Abs(p_a:Float):Float  { return p_a < 0 ? -p_a : p_a; }
        static public inline function AbsInt(p_a:Int):Int   { return p_a < 0 ? -p_a : p_a;  }
        
		static public inline function Clamp(p_v : Float,p_min : Float, p_max : Float) : Float { return p_v <= p_min ? p_min : (p_v>=p_max ? p_max : p_v); }
        static public inline function Clamp01(p_v:Float):Float { return Clamp(p_v,0.0,1.0); }
        static public inline function ClampInt(p_v:Int, p_min : Int, p_max : Int)  : Int { return Std.int(p_v <= p_min ? p_min : (p_v>=p_max ? p_max : p_v)); }
		
        static public function Min(p_v:Array<Float>) : Float
        {
            if (p_v.length <= 0) return 0;
			if (p_v.length <= 1) return p_v[0];
            var m:Float = p_v[0];
			var i:Int = 0;
			for(i in 1...p_v.length) { m = m > p_v[i] ? p_v[i] : m; }            
            return m;
        }
		
		static public function MinInt(p_v:Array<Int>) : Int
        {
            if (p_v.length <= 0) return 0;
			if (p_v.length <= 1) return p_v[0];
            var m:Int = p_v[0];
			var i:Int = 0;
			for(i in 1...p_v.length) { m = m > p_v[i] ? p_v[i] : m; }            
            return Std.int(m);
        }

	   static public function MinMax(p_v:Array<Float>) : Array<Float>
	   {
		    if (p_v.length <= 0) return [];
			if (p_v.length <= 1) return [p_v[0],p_v[0]];
            var m0:Float = p_v[0];
			var m1:Float = p_v[0];
			var i:Int = 0;
			for (i in 1...p_v.length) 
			{ 
				m0 = m0 < p_v[i] ? p_v[i] : m0;
				m1 = m1 > p_v[i] ? p_v[i] : m1;
			}
            return [m0,m1];
	   }
		
       static public function Max(p_v:Array<Float>) : Float
        {
            if (p_v.length <= 0) return 0;
			if (p_v.length <= 1) return p_v[0];
            var m:Float = p_v[0];
			var i:Int = 0;
			for(i in 1...p_v.length) { m = m < p_v[i] ? p_v[i] : m; }
            return m;
        }

		static public function MaxInt(p_v:Array<Int>) : Int
        {
            if (p_v.length <= 0) return 0;
			if (p_v.length <= 1) return p_v[0];
            var m:Int = p_v[0];
			var i:Int = 0;
			for(i in 1...p_v.length) { m = m < p_v[i] ? p_v[i] : m; }
            return Std.int(m);
        }
		
		static public var Sin = Math.sin;		
		
		static inline public function SinDeg(p_v:Float) { return Mathf.Sin(p_v * Mathf.Deg2Rad); }
		
		static public var Cos = Math.cos;
		
		static inline public function CosDeg(p_v:Float) { return Mathf.Cos(p_v * Mathf.Deg2Rad); }
		
		static public var Asin  = Math.asin;		        
		
		static public var Acos  = Math.acos;
        
		static public var Tan   = Math.tan;
        
		static public var Atan  = Math.atan;
        
		static public var Atan2 = Math.atan2;
        
		static public var Sqrt  = Math.sqrt;
        
		static public var Pow   = Math.pow;
        
		static inline public function Floor(p_v : Float):Float { return cast Std.int(p_v); }
        
		static inline public function Ceil(p_v : Float):Float  { return cast Std.int(p_v + (p_v < 0 ? -0.9999999 : 0.9999999)); }
        
		static inline public function Round(p_v:Float):Float { return cast Std.int(p_v + (p_v < 0 ? -0.5 : 0.5)); }
		
		static inline public function RoundPlaces(p_v:Float, p_decimal_places:Int = 2):Float 
		{ 
			var d:Float = Pow(10,p_decimal_places);
			return Mathf.Round(p_v * d)/d;
		}
        
		static inline public function Lerp(p_a:Float, p_b:Float, p_ratio : Float):Float { return p_a + (p_b - p_a) * p_ratio; }
		
		static inline public function LerpInt(p_a:Int, p_b:Int,p_ratio : Float):Int { return cast(Lerp(cast(p_a,Float),cast(p_b,Float),p_ratio),Int); }
        
		static inline public function Frac(p_v:Float):Float { return p_v - Mathf.Floor(p_v); }
        
		static public function Loop(p_v:Float, p_v0:Float, p_v1:Float):Float 
		{ 
			var vv0 : Float = Math.min(p_v0, p_v1);
			var vv1 : Float = Math.max(p_v0, p_v1);
			var dv : Float = (vv1 - vv0);
			if (dv <= 0) return vv0;
			var n : Float  = (p_v - p_v0) / dv;			
			var r : Float  = p_v < 0 ? 1.0 - Mathf.Frac(Mathf.Abs(n)) : Mathf.Frac(n);			
			return Mathf.Lerp(p_v0, p_v1, r); 
		}
        
		static inline public function Linear2Gamma(p_v:Float):Float { return Mathf.Pow(p_v, 2.2); }
        
		static inline public function Oscilate(p_v:Float, p_v0:Float, p_v1:Float)
        {			
            var w:Float = -Mathf.Abs(Loop(p_v - 1.0, -1.0, 1.0)) + 1.0;
            return Mathf.Lerp(w, p_v0, p_v1);
		}

        static inline public function WrapAngle(p_angle:Float):Float
        {
            if (p_angle < 360.0) if (p_angle > -360.0) return p_angle;
            return Mathf.Frac(Mathf.Abs(p_angle) / 360.0) * 360.0;
        }
		
		
			
		
}