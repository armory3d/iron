package fox.sys.util;

class Accelerometer {

	static var accelX:Float;
	static var accelY:Float;
	static var accelZ:Float;

	public static var filteringFactor = 0.1;

	public static function filterX(raw:Float):Float {
        accelX = raw * filteringFactor + accelX * (1.0 - filteringFactor);
        return raw - accelX;
	}

	public static function filterY(raw:Float):Float {
        accelY = raw * filteringFactor + accelY * (1.0 - filteringFactor);
        return raw - accelY;
	}

	public static function filterZ(raw:Float):Float {
        accelZ = raw * filteringFactor + accelZ * (1.0 - filteringFactor);
        return raw - accelZ;
	}
}
