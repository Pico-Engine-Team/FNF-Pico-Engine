package funkin.stages.data.levels.weekspecial.engine.mods;

class WhittyAlley extends BaseStage
{
    override function create()
    {
        var bg:BGSprite = new BGSprite('Whitty/whittyBack', -400, -130);
        bg.scrollFactor.set(1.0, 1.0);
        add(bg);

        var bg2:BGSprite = new BGSprite('Whitty/whittyFront', -300, 670);
        bg2.scrollFactor.set(1.0, 1.0);
        add(bg2);
    }
}