package funkin.stages.data.weekspecial.engine.mods;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.utils.engines.vslice.shaders.AdjustColorShader;
import funkin.utils.engines.vslice.VsliceOptions;

class PhillyAlleyCass extends BaseStage
{
	var sky:BGSprite;
	var car:BGSprite;
	var signPost:BGSprite;
	var ground:BGSprite;
	var foreground:BGSprite;

	var timeElap:Float = 0;
	var startIntensity:Float = 0.1;
	var endIntensity:Float = 0.2;
	override function create()
	{
		sky = new BGSprite('phillyAlleyCass/sky', 500, -130, 0.7, 0.7);
		sky.scale.set(1.8, 1.8);
		sky.updateHitbox();
		add(sky);

		car = new BGSprite('phillyAlleyCass/cars', 3590, 400, 0.85, 0.85);
		car.animation.addByPrefix('car1', 'Van', 24, false);
		car.animation.addByPrefix('car2', 'car_normal', 24, false);
		car.animation.addByPrefix('car3', 'caravan', 24, false);
		car.animation.play('car1', true);
		car.scale.set(1.5, 1.5);
		car.updateHitbox();
		car.flipX = true;
		add(car);

		signPost = new BGSprite('phillyAlleyCass/billboard', 2090, -32, 0.9, 0.9);
		signPost.scale.set(1.6, 1.6);
		signPost.updateHitbox();
		add(signPost);

		ground = new BGSprite('phillyAlleyCass/stage', 880, -215);
		ground.scale.set(1.7, 1.7);
		ground.updateHitbox();
		add(ground);
	}

		function remapToRange(value:Float, fromMin:Float, toMin:Float, fromMax:Float, toMax:Float):Float
	{
		return fromMax + (value - fromMin) * ((toMax - fromMax) / (toMin - fromMin));
	}

	override function createPost()
	{
		foreground = new BGSprite('phillyAlleyCass/foreground', -600, -302, 1.1, 1.1);
		foreground.scale.set(1.7, 1.7);
		foreground.updateHitbox();
		add(foreground);

		if(VsliceOptions.SHADERS)
		{
			var h:Float = -7;
			var s:Float = -7;
			var c:Float = -6;
			var b:Float = -12;

			for(char in [dad, gf, boyfriend])
			{
				if(char == null) continue;
				var shader = new AdjustColorShader();
				shader.hue.value        = [h];
				shader.saturation.value = [s];
				shader.contrast.value   = [c];
				shader.brightness.value = [b];
				char.shader = shader;
			}
		}
	}

	override function update(elapsed:Float)
	{
		timeElap += elapsed;
	}

	override function beatHit()
	{
		var randomBeat:Int = FlxG.random.int(35, 45);
		if(curBeat % randomBeat == 0)
		{
			var randomCar:Int = FlxG.random.int(1, 3);
			car.animation.play('car' + randomCar, true);
			FlxTween.cancelTweensOf(car);
			FlxTween.tween(car, {x: car.x - 2500}, FlxG.random.float(3, 4),
			{
				ease: FlxEase.sineOut,
				onComplete: function(_) { car.x = 3590; }
			});
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case 'Play Animation':
				if(value2 == 'Dad')
				{
					if(dad != null && dad.animation.curAnim != null && dad.animation.curAnim.name == 'shoot')
					{
						var props:Array<FlxSprite> = [sky, car, signPost, ground, foreground];
						for(spr in props)
						{
							if(spr == null) continue;
							spr.color = 0x606060;
							FlxTween.color(spr, 0.6, 0x606060, 0xFFFFFF);
						}
					}
				}

				if(value1 == 'killCass')
				{
					if(dad != null) dad.visible = false;
				}
		}
	}
}
