package lucas.funkin.stages.engine.mods;

class HappyRon extends BaseStage
{ 
    var Sky:BGSprite;
    var Ground:BGSprite;
	override function create()
    {
        Sky = new BGSprite('rom/happyRon_sky', -200, -150);
        Sky.scrollFactor.set(0.2, 0.2);
        add(Sky);

        Ground = new BGSprite('rom/happyRon_ground', -600, -300);
        Ground.scrollFactor.set(0.8, 0.8);
        add(Ground);
    }
}