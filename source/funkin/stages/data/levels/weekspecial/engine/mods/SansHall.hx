package funkin.stages.data.levels.weekspecial.engine.mods;

class SansHall extends BaseStage
{
	override function create()
    {
        var bg:BGSprite = new BGSprite('Cross/Sans/hall', 0, 100);
        bg.scale.set(1.55, 1.5);
		add(bg);
    }
}