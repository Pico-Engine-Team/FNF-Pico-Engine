package lucas.funkin.engine.mods;

import objects.*;

class GreenHill extends BaseStage
{
    override function create()
    {
        Bg = new BGSprite('pixel/sonic/bg1', -1000, -700);
        Bg.scale.set(8, 8);
        Bg.scrollFactor.set(0.9, 0.9);
		add(Bg);