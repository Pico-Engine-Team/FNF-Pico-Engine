package funkin.stages.objects.levels.week3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class PhillyRemixLights {
	public var lights:FlxSprite;
	public var curLight:Int = -1;
	public var phillyLightsColors:Array<FlxColor>;

	public function new(lights:FlxSprite, ?colors:Array<FlxColor>)
	{
		this.lights = lights;
		phillyLightsColors = colors != null ? colors.copy() : defaultColors();
	}

	public function beatHit(curBeat:Int)
	{
		if(curBeat % 4 == 0)
			setColor();
	}

	public function setColor()
	{
		if(lights == null || phillyLightsColors == null || phillyLightsColors.length < 1) return;

		curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
		lights.color = phillyLightsColors[curLight];
		lights.alpha = 1;

		FlxTween.cancelTweensOf(lights);
		FlxTween.tween(lights, {alpha: 0}, 0.9, {ease: FlxEase.sineOut});
	}

	public function destroy()
	{
		if(lights != null)
			FlxTween.cancelTweensOf(lights);
		lights = null;
	}

	public static function defaultColors():Array<FlxColor>
	{
		return [0xFFFD4531, 0xFF31A2FD, 0xFF31FD8C, 0xFFFBA633, 0xFFFB33F5];
	}
}