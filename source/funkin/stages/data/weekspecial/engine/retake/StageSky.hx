package funkin.stages.data.weekspecial.engine.retake;

import lucas.vslice.VsliceOptions;
import lucas.vslice.shaders.AdjustColorShader;

class StageSky extends BaseStage
{
    var bg:BGSprite;
    var filtro:BGSprite;
    var coolShader:AdjustColorShader;
    override function create()
    {
        var bg = new BGSprite('Reteke/Sky/stage1', -630, -350);
        bg.scale.set(1.4, 1.4);
        add(bg);

        var filtro = new BGSprite('Reteke/Sky', -400, -820);
        filtro.scale.set(2, 2);
        add(filtro);
    }

    override function createPost() {
        super.createPost();
        if(VsliceOptions.SHADERS)
        {
            gf.shader = makeCoolShader(-26,-16,0,-5);
            dad.shader = makeCoolShader(-26,-16,0,-5);
            boyfriend.shader = makeCoolShader(-26,-16,0,-5);
        }
    }

    function makeCoolShader(hue:Float, sat:Float, bright:Float, contrast:Float) {
        var coolShader = new AdjustColorShader();
        coolShader.hue = hue;
        coolShader.saturation = sat;
        coolShader.brightness = bright;
        coolShader.contrast = contrast;
        return coolShader;
    }
}