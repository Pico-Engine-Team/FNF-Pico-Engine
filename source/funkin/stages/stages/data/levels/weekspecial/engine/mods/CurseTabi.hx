package funkin.stages.data.levels.weekspecial.engine.mods;

class CurseTabi extends BaseStage
{
    override function create()
    {
		var Bg = new BGSprite('tabi/normal_stage', -510, -230);
		add(Normal);

        var Sumtable = new BGSprite('tabi/sumtable', -510, -230);
		add(Sumtable);
    }
}