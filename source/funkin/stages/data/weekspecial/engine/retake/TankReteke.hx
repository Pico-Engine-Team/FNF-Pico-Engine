package funkin.stages.data.weekspecial.engine.retake;

import funkin.states.GameOverState;
import lucas.vslice.shaders.AdjustColorShader;
import lucas.vslice.VsliceOptions;

class TankReteke extends BaseStage
{
    var bg:BGSprite;
    var niebla:BGSprite;
    var filtro:BGSprite;
    override function create()
    {
        bg = new BGSprite('Retake/stage', -400, -350);
        bg.scale.set(1.2, 1.2);
        add(bg);

        niebla = new BGSprite('Retake/stage', -400, -820);
        niebla.scale.set(2, 2);
        add(niebla);

        filtro = new BGSprite('Retake/stage', -400, -300);
        filtro.scale.set(1.2, 1.2);
        add(filtro);

        var _song = PlayState.SONG;
        if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverState.characterName = 'pico-dead';
        if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverState.deathSoundName = 'fnf_loss_sfx';
        if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverState.loopSoundName = 'gameOver';
        if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverState.endSoundName = 'gameOverEnd';
    }

    override function createPost()
    {
        super.createPost();
        if(VsliceOptions.SHADERS)
        {
            boyfriend.shader = makeCoolShader(-26,-16,0,-5);
            dad.shader = makeCoolShader(-26,-16,0,-5);
            gf.shader = makeCoolShader(-26,-16,0,-5);
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