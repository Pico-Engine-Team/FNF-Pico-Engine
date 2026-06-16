package funkin.stages.data.levels.week1.variation.erect;

import funkin.data.objects.game.characters.Character;
import funkin.data.notes.Note;
import funkin.utils.engines.vslice.VsliceOptions;
import funkin.utils.engines.vslice.shaders.AdjustColorShader;

import openfl.display.BlendMode;

class MainStageErect extends BaseStage
{   
	var peeps:BGSprite;
	override function create()
	{
		var bg:FlxSprite = new FlxSprite(-500,-1000);
		bg.makeGraphic(2400, 2000, 0xFF222026);
		add(bg);

        if(!VsliceOptions.IS_LOW_QUALITY)
        {
            peeps = new BGSprite('erect/crowd', 682, 290,0.8,0.8,["idle"],true);
            if(peeps.animation.curAnim != null)
                peeps.animation.curAnim.frameRate = 12;
            add(peeps);

            var lightSmol = new BGSprite('erect/brightLightSmall',967, -103,1.2,1.2);
            lightSmol.blend = BlendMode.ADD;
            add(lightSmol);
        }
		var stageFront:BGSprite = new BGSprite('erect/bg', -765, -247);
		add(stageFront);

        var server:BGSprite = new BGSprite('erect/server', -991, 205);
		add(server);

		if(!VsliceOptions.IS_LOW_QUALITY)
        {
			var greenLight:BGSprite = new BGSprite('erect/lightgreen', -171, 242);
            greenLight.blend = BlendMode.ADD;
			add(greenLight);

            var redLight:BGSprite = new BGSprite('erect/lightred', -101, 560);
            redLight.blend = BlendMode.ADD;
			add(redLight);

            var orangeLight:BGSprite = new BGSprite('erect/orangeLight', 189, -500);
            orangeLight.blend = BlendMode.ADD;
			add(orangeLight);
		}
        var beamLol:BGSprite = new BGSprite('erect/lights', -847, -245,1.2,1.2);
		add(beamLol);

        if(!VsliceOptions.IS_LOW_QUALITY)
        {
			var TheOneAbove:BGSprite = new BGSprite('erect/lightAbove', 804, -117);
            TheOneAbove.blend = BlendMode.ADD;
			add(TheOneAbove);
        }
	}
    override function createPost()
    {
        super.createPost();
        if(VsliceOptions.SHADERS)
        {
            gf.shader = makeCoolShader(-9,0,-30,-4);
            dad.shader = makeCoolShader(-32,0,-33,-23);
            boyfriend.shader = makeCoolShader(12,0,-23,7);
        }
    }
    function makeCoolShader(hue:Float,sat:Float,bright:Float,contrast:Float) {
        var coolShader = new AdjustColorShader();
        coolShader.hue = hue;
        coolShader.saturation = sat;
        coolShader.brightness = bright;
        coolShader.contrast = contrast;
        return coolShader;
    }
}