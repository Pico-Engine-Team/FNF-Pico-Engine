package funkin.stages.data.levels.weekspecial.engine.mods.exe.encore;

class EndlessEncore extends BaseStage
{ 
    var bg:BGSprite;
    var bg2:BGSprite;
	var fg1:FlxSprite;
	var fg2:FlxSprite;
	override function create()
	{
		PlayState.SONG.arrowSkin = "noteSkins/data/charts/endless-(pico-mix)/NOTE-Majin-Note";
		PlayState.SONG.splashSkin = "noteSplashes/data/charts/endless-(pico-mix)/noteSplashes-endless";

		bg = new BGSprite('exe/majin/stagefront', -1100, -500);
		add(bg);

		bg2 = new BGSprite('exe/majin/stageback', -1100, -500);
		add(bg2);

		fg1 = new FlxSprite(1200, 750);
		fg1.frames = Paths.getSparrowAtlas('exe/majin/majin FG1');
		fg1.animation.addByPrefix('bop1', 'majin front bopper', 26, true);
		fg1.animation.play('bop1');
		fg1.scrollFactor.set(0.9, 1);
		fg1.antialiasing = ClientPrefs.data.antialiasing;
		insert(10, fg1);

		fg2 = new FlxSprite(-400, 750);
		fg2.frames = Paths.getSparrowAtlas('exe/majin/majin FG2');
		fg2.animation.addByPrefix('bop2', 'majin front bopper2', 28, true);
		fg2.animation.play('bop2');
		fg2.scrollFactor.set(0.9, 1);
		fg2.antialiasing = ClientPrefs.data.antialiasing;
		insert(11, fg2);
	}
}