package lucas.funkin.stages.engine.mods.sonic.exe.tails;

class SBz extends BaseStage
{
    var sky:BGSprite;
    var city:BGSprite;
    var caps:BGSprite;
    var floor:BGSprite;
    override function create()
    {
        sky = new BGSprite('sbz/sky',  -900, -400);
        sky.scale.set(1.7, 1.7);
        sky.scrollFactor.set(0.4, 0.4);
        add(sky);

        city = new BGSprite('sbz/destroyed-city',  -600, -100);
        city.scale.set(1.4, 1.4);
        city.scrollFactor.set(0.6, 0.6);
        add(city);

        caps = new BGSprite('sbz/Capsules',  -900, -200);
        caps.scale.set(1.4, 1.4);
        caps.scrollFactor.set(0.78, 0.78);
        add(caps);

        floor = new BGSprite('sbz/floor',  -400, -50);
        floor.scale.set(1.3, 1.3);
        floor.scrollFactor.set(1, 1);
        add(floor);
    }
}