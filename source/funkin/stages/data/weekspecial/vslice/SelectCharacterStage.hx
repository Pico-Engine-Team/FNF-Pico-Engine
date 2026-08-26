package funkin.stages.data.levels.weekspecial.vslice;

class SelectCharacterStage extends BaseStage
{
    var upperBoppers:FlxSprite;
    override function create()
    {
        var floor = new BGSprite('stages/weeks/bonus/funkin/suelo', -469, 570);
        floor.scale.set(1.75, 1.75);
        floor.scrollFactor.set(1,1);
        add(floor);

		upperBoppers = new FlxSprite(-469, 237);
		upperBoppers.frames = Paths.getSparrowAtlas('stages/weeks/bonus/funkin/publico');
		upperBoppers.animation.addByPrefix("idle", "bg", 10);
		upperBoppers.scale.set(1.75,1.75);
        upperBoppers.scrollFactor.set(1.1, 1);
		add(upperBoppers);

        var cortina = new BGSprite('stages/weeks/bonus/funkin/cortina', -459, 1075);
        cortina.scale.set(1.75, 1.75);
        cortina.scrollFactor.set(1, 1);
        add(cortina);

        var filtro = new BGSprite('stages/weeks/bonus/funkin/filtro', -666, -14);
        filtro.scale.set(1.75, 1.75);
        filtro.scrollFactor.set(1, 1);
        add(filtro);

        var fondo = new BGSprite('stages/weeks/bonus/funkin/fondo', -718,-415);
        fondo.scale.set(1.8, 1.8);
        fondo.scrollFactor.set(1, 1);
        add(fondo);
    }
}
