package funkin.stages.data.levels.weekspecial.engine.standard;

class MaledictionStage extends BaseStage {
    var bg:BGSprite;
    var trees:BGSprite;
    var trees2:BGSprite;
    var fountain:FlxSprite;
    var floor:BGSprite;
    override function create()
    {
        bg = new BGSprite('malediction/background', -300, -200, 1.1);
        add(bg);

        trees = new BGSprite('malediction/treesfarback', -850, -300, 1.5, 1.1);
        add(trees);

        trees2 = new BGSprite('malediction/treesback', -850, -300, 1.5, 1.1);
        add(trees2);

		fountain = new FlxSprite(-850, -300);
		fountain.frames = Paths.getSparrowAtlas('malediction/fountain');
		fountain.animation.addByPrefix("fountain", "fountainlol", 24);
        fountain.animation.addByPrefix("fountain", "fountainlol", 24);
		fountain.scale.set(1.15, 1.15);
		add(fountain);

        floor = new BGSprite('malediction/floor', -750, 675, 1.5, 1.1);
        add(floor);
    }
}