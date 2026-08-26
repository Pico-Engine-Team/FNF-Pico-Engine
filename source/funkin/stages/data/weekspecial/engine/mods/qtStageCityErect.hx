package funkin.stages.data.weekspecial;

import funkin.stages.BaseStage;
import funkin.states.PlayState;
import funkin.states.GameOverState;

import lucas.vslice.shaders.AdjustColorShader;
import lucas.vslice.VsliceOptions;

import openfl.display.BlendMode;

class TankReteke extends BaseStage
{
    var overlayAdd:BGSprite;
    var overlayOverlay:BGSprite;
    var car:BGSprite;
    var poster:BGSprite;
    var grass:BGSprite;
    var flower:BGSprite;
    var storeLightAdd:BGSprite;
    var mainGround:BGSprite;
    var lampAndBuilding:BGSprite;
    var storeInterior:BGSprite;
    var storeBg:BGSprite;
    var sign:BGSprite;
    var building:BGSprite;
    var bgBuildings2:BGSprite;
    var stars:BGSprite;
    var sky:BGSprite;
    override function create()
    {
        sky = new BGSprite('erectCity/sky', -973, -1076, 1, 1);
        sky.scale.set(1, 1);
        sky.updateHitbox();
        add(sky);

        stars = new BGSprite('erectCity/stars', -685, -600, 0.7, 0.7, ['stars']);
        stars.scale.set(1, 1);
        stars.updateHitbox();
        add(stars);

        bgBuildings2 = new BGSprite('erectCity/bgBuildings2', -606, -671, 0.8, 0.8);
        bgBuildings2.scale.set(1, 1);
        bgBuildings2.updateHitbox();
        add(bgBuildings2);

        building = new BGSprite('erectCity/bgBuilding', -1075, -835, 0.75, 0.75);
        building.scale.set(1, 1);
        building.updateHitbox();
        add(building);

        sign = new BGSprite('erectCity/signBetterCallSahur', 30, -425, 0.85, 0.85);
        sign.scale.set(1, 1);
        sign.updateHitbox();
        add(sign);

        storeBg = new BGSprite('erectCity/storeBg', -989, 446, 1, 1);
        storeBg.scale.set(1.0057, 1.0057);
        storeBg.updateHitbox();
        add(storeBg);

        storeInterior = new BGSprite('erectCity/storeInterior', -985, 437, 0.95, 0.95);
        storeInterior.scale.set(0.6663, 0.6663);
        storeInterior.updateHitbox();
        add(storeInterior);

        lampAndBuilding = new BGSprite('erectCity/lampAndBuilding', 875, 125, 0.8, 0.8);
        lampAndBuilding.scale.set(1, 1);
        lampAndBuilding.updateHitbox();
        add(lampAndBuilding);

        mainGround = new BGSprite('erectCity/mainGround', -992, -305, 1, 1);
        mainGround.scale.set(1, 1);
        mainGround.updateHitbox();
        add(mainGround);

        storeLightAdd = new BGSprite('erectCity/storeLightAdd', -1249, 161, 1, 1);
        storeLightAdd.scale.set(1, 1);
        storeLightAdd.alpha = 0.7;
        storeLightAdd.blend = BlendMode.ADD;
        storeLightAdd.updateHitbox();
        add(storeLightAdd);

        flower = new BGSprite('erectCity/flower', -56, 1080, 1, 1, ['flower']);
        flower.scale.set(1, 1);
        flower.updateHitbox();
        add(flower);

        grass = new BGSprite('erectCity/grass', 1598, 1115, 1, 1, ['grass']);
        grass.scale.set(1, 1);
        grass.updateHitbox();
        add(grass);

        poster = new BGSprite('erectCity/poster', 1665, 846, 1, 1, ['poster']);
        poster.scale.set(1, 1);
        poster.updateHitbox();
        add(poster);

        car = new BGSprite('erectCity/car', -1048, 810, 1.03, 1.03);
        car.scale.set(1, 1);
        car.updateHitbox();
        add(car);

        overlayOverlay = new BGSprite('erectCity/overlayOverlay', -1025, -665, 1, 0.5);
        overlayOverlay.scale.set(1, 1);
        overlayOverlay.alpha = 0.6;
        overlayOverlay.blend = BlendMode.OVERLAY;
        overlayOverlay.updateHitbox();
        add(overlayOverlay);

        overlayAdd = new BGSprite('erectCity/overlayAdd', -1242, -1060, 1, 0.5);
        overlayAdd.scale.set(1, 1);
        overlayAdd.alpha = 0.15;
        overlayAdd.blend = BlendMode.ADD;
        overlayAdd.updateHitbox();
        add(overlayAdd);
    }
}

    override function createPost()
    {
        super.createPost();
        if(VsliceOptions.SHADERS)
        {
            if (game.boyfriend != null) game.boyfriend.shader = makeCoolShader(-26, -16, 0, -5);
            if (game.dad != null) game.dad.shader = makeCoolShader(-26, -16, 0, -5);
            if (game.gf != null) game.gf.shader = makeCoolShader(-26, -16, 0, -5);
        }
    }

    function makeCoolShader(hue:Float, sat:Float, bright:Float, contrast:Float) 
    {
        var coolShader = new AdjustColorShader();
        coolShader.hue = hue;
        coolShader.saturation = sat;
        coolShader.brightness = bright;
        coolShader.contrast = contrast;
        return coolShader;
    }
}