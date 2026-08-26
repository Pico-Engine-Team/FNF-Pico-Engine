package funkin.stages.data.weekspecial.engine.standard;

class Arenanew extends BaseStage
{
    var sky:BGSprite;
    var stands:BGSprite;
    var railingnew:BGSprite;
    var ground:BGSprite;
    override function create()
    {
        sky = new BGSprite('matt/Arena/skyBG', -450, -175);
        add(sky);

        stands = new BGSprite('matt/Arena/standsBG', -450, -225);
        add(stands);

        railingnew = new BGSprite('matt/Arena/railingBG', -450, -200);
        add(railingnew);

        ground = new BGSprite('matt/Arena/groundBG', -450, -100);
        add(ground);
    }
}