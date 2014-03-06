package wings.w2d.ui.layouts;
import wings.w2d.shapes.ShapeItem;
import wings.services.Pos;

class SlideDot extends ShapeItem
{

	public function new(x:Float, y:Float, radius:Float) 
	{
		super(x, y, 1);
		
		shape.graphics.beginFill(0x000000);
		shape.graphics.drawCircle(0, 0, radius - 1);
		shape.graphics.endFill();

		shape.graphics.beginFill(0xffffff);
		shape.graphics.drawCircle(0, 0, radius);
		shape.graphics.endFill();

		cacheAsBitmap = true;
	}
}
