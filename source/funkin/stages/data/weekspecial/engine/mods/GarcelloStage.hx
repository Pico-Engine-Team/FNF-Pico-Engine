package funkin.stages.data.weekspecial.engine.mods;

class GarcelloStage extends BaseStage
{
    var bgstars:BGSprite;
    var dayburnBuildings:BGSprite;
    var hillAsf:BGSprite;
    override function create()
    {
        bgstars = new BGSprite('AshtonAlleyway/bgstars', -789, -339);
        bgstars.scale.set(0.75);
        bgstars.scrollFactor.set(0.1, 0.1);
        add(bgstars);

        dayburnBuildings = new BGSprite('AshtonAlleyway/dayburn buildings',-784,-345);
        dayburnBuildings.scale.set(0.75);
        dayburnBuildings.scrollFactor.set(0.35, 0.35);
        add(dayburnBuildings);

        hillAsf = new BGSprite('AshtonAlleyway/hill asf',-791,-341);
        hillAsf.scale.set(0.75);
        hillAsf.scrollFactor.set(0.35, 0.35);
        add(hillAsf);

        dayburnBuildings = new BGSprite('"AshtonAlleyway/dayburn buildings',-784,-345);
        dayburnBuildings.scale.set(0.75);
        dayburnBuildings.scrollFactor.set(0.35, 0.35);
        add(dayburnBuildings);

        dayburnBuildings = new BGSprite('AshtonAlleyway/dayburn buildings',-784,-345);
        dayburnBuildings.scale.set(0.75);
        dayburnBuildings.scrollFactor.set(0.35, 0.35);
        add(dayburnBuildings);

        dayburnBuildings = new BGSprite('AshtonAlleyway/dayburn buildings',-784,-345);
        dayburnBuildings.scale.set(0.75);
        dayburnBuildings.scrollFactor.set(0.35, 0.35);
        add(dayburnBuildings);

        dayburnBuildings = new BGSprite('AshtonAlleyway/dayburn buildings',-784,-345);
        dayburnBuildings.scale.set(0.75);
        dayburnBuildings.scrollFactor.set(0.35, 0.35);
        add(dayburnBuildings);

        dayburnBuildings = new BGSprite('AshtonAlleyway/dayburn buildings',-784,-345);
        dayburnBuildings.scale.set(0.75);
        dayburnBuildings.scrollFactor.set(0.35, 0.35);
        add(dayburnBuildings);

        dayburnBuildings = new BGSprite('AshtonAlleyway/dayburn buildings',-784,-345);
        dayburnBuildings.scale.set(0.75);
        dayburnBuildings.scrollFactor.set(0.35, 0.35);
        add(dayburnBuildings);
    }
}