package lucas.funkin.stages.engine.mods.funkadelix.week3;

// Pico Engine 
import flixel.FlxSprite;
import backend.BaseStage;
import backend.Paths;
import backend.ClientPrefs;
import states.stages.objects.*;
import openfl.filters.ShaderFilter;
import shaders.*;

class PhillyFunkadelix extends BaseStage
{
	var sexualintercourse:FlxSprite;
	var sexualintercourse2:FlxSprite;
	var sexualintercourse3:FlxSprite;
	var sexualintercourse4:FlxSprite;
	var overlay:BGSprite;
	override function create()
	{
        PlayState.SONG.arrowSkin = "noteSkins/NOTE_assets-funkadelix";

		sexualintercourse = new FlxSprite(0, 0);
		sexualintercourse.frames = Paths.getSparrowAtlas('funkadelix/week3/philly');
		sexualintercourse.animation.addByPrefix('philly', 'sky', 24, true);
		sexualintercourse.animation.play('sky');
		sexualintercourse.scrollFactor.set(1, 1);
		sexualintercourse.scale.set(1, 1);

		sexualintercourse2 = new FlxSprite(0, 0);
		sexualintercourse2.frames = Paths.getSparrowAtlas('funkadelix/week3/philly');
		sexualintercourse2.animation.addByPrefix('philly', 'beams', 24, true);
		sexualintercourse2.animation.play('beams');
		sexualintercourse2.scrollFactor.set(1, 1);
		sexualintercourse2.scale.set(1, 1);

		sexualintercourse3 = new FlxSprite(0, 0);
		sexualintercourse3.frames = Paths.getSparrowAtlas('funkadelix/week3/philly');
		sexualintercourse3.animation.addByPrefix('philly', 'roof', 24, true);
		sexualintercourse3.animation.play('roof');
		sexualintercourse3.scrollFactor.set(1, 1);
		sexualintercourse3.scale.set(1, 1);

		sexualintercourse4 = new FlxSprite(0, 0);
		sexualintercourse4.frames = Paths.getSparrowAtlas('funkadelix/week3/philly');
		sexualintercourse4.animation.addByPrefix('philly', 'buildings', 24, true);
		sexualintercourse4.animation.play('buildings');
		sexualintercourse4.scrollFactor.set(1, 1);
		sexualintercourse4.scale.set(1, 1);

        overlay = new BGSprite('funkadelix/week3/overlay', -200, 300);
        add(overlay);

        add(sexualintercourse);
		add(sexualintercourse4);
		add(sexualintercourse2);
		add(sexualintercourse3);


		/*
		if (ClientPrefs.data.shaders)
		{
			var bloom = PlayState.instance.createRuntimeShader('bloomSmol');
			var warp = PlayState.instance.createRuntimeShader('warp');
			var chrom = PlayState.instance.createRuntimeShader('chromFNF');
			var shadows = PlayState.instance.createRuntimeShader('flixel-shadows');
			// PlayState.instance.camGame.setFilters([new ShaderFilter(bloom), new ShaderFilter(warp), new ShaderFilter(chrom), new ShaderFilter(shadows)]);
		}
		*/
	}
	/*
	override function createPost()
	{
		if (boyfriend.custom)
		{
			boyfriendGroup.x -= 50;
			boyfriendGroup.y -= 320;
		}

		if (dad.custom)
		{
			dadGroup.x -= 70;
			dadGroup.y -= 286;
		}
	}
	*/
}