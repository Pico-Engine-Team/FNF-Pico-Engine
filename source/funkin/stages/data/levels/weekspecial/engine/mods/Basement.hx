package funkin.stages.data.levels.weekspecial.engine.mods;

class Basement extends BaseStage {
     var basement:BGSprite;
     var CUpheqdshidA:FlxSprite;

     override function create()
    {
        basement = new BGSprite('base/basement', -800, -450);
		add(basement);

        CUpheqdshidA = new FlxSprite(-510, -230);
        CUpheqdshidA.loadGraphic(Paths.image('base/CUpheqdshidA'));
        add(CUpheqdshidA);
    }       
}