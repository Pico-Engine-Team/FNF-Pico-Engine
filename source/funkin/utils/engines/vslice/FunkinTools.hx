package funkin.utils.engines.vslice;

import flixel.graphics.FlxGraphic;

class FunkinTools
{
	public static function makeSolidColor(sprite:FlxSprite, width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FlxSprite
	{
		var graphic:FlxGraphic = FlxG.bitmap.create(2, 2, color, false, 'solid#${color.toHexString(true, false)}');
		sprite.frames = graphic.imageFrame;
		sprite.scale.set(width / 2.0, height / 2.0);
		sprite.updateHitbox();
		return sprite;
	}

	public static function extractWeeks(text:String)
	{
		if (text == null)
			return [];
		var baseStr = text.trim();
		if (baseStr == "")
			return [];
		var base_weeks = baseStr.split(",").map(s -> s.trim().toLowerCase());
		return base_weeks;
	}

	public static function mergeWithJson<T>(target:T,source:Dynamic,?ignoreFields:Array<String>):T
	{
		if(ignoreFields == null) ignoreFields = [];
		var fillInFields = Type.getInstanceFields(Type.getClass(target)).filter(s -> !ignoreFields.contains(s));

		if(source == null) return target;
		for (field in Reflect.fields(source))
		{
			if(fillInFields.contains(field)) Reflect.setField(target,field,Reflect.field(source,field));
			#if debug
			else if (!ignoreFields.contains(field)) throw 'Class ${Type.getClassName(Type.getClass(target))} doesn\'t contain field field $field';
			#else
			else if (!ignoreFields.contains(field)) trace('Class ${Type.getClassName(Type.getClass(target))} doesn\'t contain field field $field');
			#end
		}
		return target;
	}
}