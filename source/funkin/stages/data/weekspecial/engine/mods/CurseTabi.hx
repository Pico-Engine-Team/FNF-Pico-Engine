package funkin.stages.data.weekspecial.engine.mods;

class CurseTabi extends BaseStage
{
    var Bg:BGSprite;
    var Sumtable:BGSprite;
    override function create()
    {
		bg = new BGSprite('tabi/normal_stage', -510, -230);
		add(bg);

        sumtable = new BGSprite('tabi/sumtable', -510, -230);
		add(sumtable);
    }
}