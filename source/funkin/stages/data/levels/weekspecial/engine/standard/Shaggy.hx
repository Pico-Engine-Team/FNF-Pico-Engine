package funkin.stages.data.levels.weekspecial.engine.standard;

class Shaggy extends BaseStage {
    var sky:BGSprite;
    var clds:BGSprite;
    var backmount:BGSprite;
    var middlemount:BGSprite;
    var ground:BGSprite;
    
    override function create()
    {
        var sky = new BGSprite('shaggy/Hill/sky', -1204, -456, 0.15, 1.1);
        add(sky);

        var clds = new BGSprite('shaggy/Hill/clouds', -988, -260, 0.25, 1.1);
        add(clds);

        var backmount = new BGSprite('shaggy/Hill/backmount', -700, -40, 0.4, 1.1);
        add(backmount);

        var middlemount = new BGSprite('shaggy/Hill/middlemount', -240, 200, 0.6, 1.1);
        add(middlemount);

        var ground = new BGSprite('shaggy/Hill/ground', -660, 624, 1.1);
        add(ground);
    }
}