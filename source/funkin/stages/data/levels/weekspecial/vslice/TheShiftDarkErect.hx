package funkin.stages.data.levels.weekspecial.vslice;

// Pico Engine + (P-Slice and V-Slice)
import funkin.utils.engines.vslice.shaders.AdjustColorShader;
import funkin.utils.engines.vslice.VsliceOptions;

import funkin.states.GameOverState;
import funkin.data.cutscenes.CutsceneHandler;

class TheShiftDarkErect extends BaseStage
{
    var bg:BGSprite;
    var pico:FlxAnimate;
    var sky:FlxAnimate;
    var bfCutout:BGSprite;
    var bSideCutout:BGSprite;
    var neoCutout:BGSprite;
    var blurryCutout:BGSprite;
    var dih:Float = 0;
    override function create()
        {
            bg = new BGSprite('stages/weeks/bonus/erect/pinkWorldCooler', -2473, -656);
            bg.scrollFactor.set(0.5, 0.5);
            bg.scale.set(3, 1);
	        add(bg);

            bfCutout = new BGSprite('stages/weeks/bonus/erect/bfCardboard', -115, 383);
            bfCutout.scrollFactor.set(0.9, 0.9);
            bfCutout.scale.set(0.88, 0.88);
            add(bfCutout);

            bSideCutout = new BGSprite('stages/weeks/bonus/erect/bSideCardboard', 1300, 383);
            bSideCutout.scrollFactor.set(0.9, 0.9);
            bSideCutout.scale.set(0.88, 0.88);
            add(bSideCutout);

            neoCutout = new BGSprite('stages/weeks/bonus/neoCardboard', -550, 750);
            neoCutout.scrollFactor.set(1.1, 1.1);
            neoCutout.scale.set(1.12, 1.12);
            add(neoCutout);

            blurryCutout = new BGSprite('stages/weeks/bonus/sky/erect/bfCardboard_Blurry', 1613, 800);
            blurryCutout.scrollFactor.set(1, 1);
            blurryCutout.scale.set(1.3, 1.3);
            add(blurryCutout);

            var _song = PlayState.SONG;
            if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverState.characterName = 'pico-dead';
		    if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverState.deathSoundName = 'fnf_loss_sfx';
		    if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverState.loopSoundName = 'gameOver';
		    if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverState.endSoundName = 'gameOverEnd';

            pico = new FlxAnimate(boyfriend.x, boyfriend.y - 10);
            pico.frames = Paths.getAtlas('stages/stageCutscenes/erect/pico_sky_anims');
            pico.anim.addBySymbol('inspectAnim', 'PICOEXPORTS/Pico Inspcet', 24, false);
            pico.anim.addBySymbol('upPoleAnim', 'PICOEXPORTS/Pico Upping Pole', 24, false);
            pico.anim.addBySymbol('shootAnim', 'PICOEXPORTS/Pico Fake Gun Blamming', 24, false);
            pico.anim.addBySymbol('blamAnim', 'PICOEXPORTS/Pico Blamming', 24, false);
            pico.scrollFactor.set(1, 1);
            add(pico);
            boyfriend.visible = false;

            sky = new FlxAnimate(dad.x - 15, dad.y - 10);
            sky.frames = Paths.getAtlas('stages/stageCutscenes/sky/erect/sky_pico_anims');
            sky.anim.addBySymbol('pointAnim', 'SKYEXPORTS/Sky Pointing', 24, false);
            sky.anim.addBySymbol('scrambleAnim', 'SKYEXPORTS/Sky Scrambling', 24, true);
            sky.anim.addBySymbol('deathAnim', 'SKYEXPORTS/Sky Death', 24, false);
            sky.anim.addBySymbol('dodgeAnim', 'SKYEXPORTS/Sky Dodging', 24, false);
            sky.anim.addBySymbol('deadAnim', 'SKYEXPORTS/Sky on the floor dead as fuck', 24, false);
            sky.scrollFactor.set(1, 1);
            add(sky);
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
