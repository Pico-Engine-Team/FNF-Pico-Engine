package funkin.stages.data.weekspecial.engine.mods;

class NonsenseRoom extends BaseStage
{
    var sky:BGSprite;
    var background:BGSprite;
    override function create()
    {
        sky = new BGSprite('stages/weeks/bonus/nonsense/sky and city', -800, -350);
        sky.scale.set(0.8, 0.8);
        sky.scrollFactor.set(0.5, 0.85);
        add(sky);

        var grass = new BGSprite('stages/weeks/bonus/nonsense/grass', 0, 450);
        grass.scale.set(0.9, 0.9);
        grass.scrollFactor.set(0.9, 0.9);
        add(grass);

        background = new BGSprite('stages/weeks/bonus/nonsense/bg', -1150, -700);
        background.scale.set(1,1);
        background.scrollFactor.set(1,1);
        add(background);

        var chair = new BGSprite('stages/weeks/bonus/nonsense/chair', 1900, 700);
        chair.scale.set(1,1);
        chair.scrollFactor.set(1.3, 1.3);
        add(chair);
    }
}