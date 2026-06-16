package funkin.stages.data.levels.weekspecial.engine.standard;

class CastleBowser extends BaseStage
{
	var bg:BGSprite;
	var walls:BGSprite;
	var floor:BGSprite;
	override function create()
	{
		var bg:BGSprite = new BGSprite('Bowser/bg', -155, -250);
		bg.scale.set(1.2, 1.2);
		bg.scrollFactor.set(0.8, 0.8);
		add(bg);

		var walls:BGSprite = new BGSprite('Bowser/walls', -185, 650);
		walls.scrollFactor.set(0.9, 0.9);
		add(walls);

		var floor:BGSprite = new BGSprite('Bowser/main_flopor', 0, 375);
		add(floor);
	}
}