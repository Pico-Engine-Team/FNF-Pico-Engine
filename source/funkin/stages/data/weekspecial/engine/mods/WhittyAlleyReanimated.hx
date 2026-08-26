package funkin.stages.data.weekspecial.engine.mods;

import flixel.FlxSprite;
import flixel.util.FlxColor;

class WhittyAlleyReanimated extends BaseStage
{
    var sky:BGSprite;
    var buildings:BGSprite;
    var poles2:BGSprite;
    var house:BGSprite;
    var poles1:BGSprite;
    var ground:BGSprite;
    var graffitis:BGSprite;
    var light:BGSprite;
    var shadow:BGSprite;
    var backlight:BGSprite;
    var fg:BGSprite;
    var alert:BGSprite;

    var camFlash:FlxSprite;
    var alerting:Bool = false;
    var time:Float = 0;
    var crazy:Bool = false;

    override function create()
    {
        super.create();
        sky = new BGSprite('alley/sky', -597, -480, 0.1, 0.1);
        sky.scale.set(0.8, 0.8);
        add(sky);

        buildings = new BGSprite('alley/buildings', 347, 100, 0.3, 0.3);
        add(buildings);

        poles2 = new BGSprite('alley/poles2', -292, -20, 0.5, 0.5);
        add(poles2);

        house = new BGSprite('alley/house', -1161, -535, 0.7, 0.7);
        add(house);

        poles1 = new BGSprite('alley/poles1', 592, -515, 0.9, 0.9);
        add(poles1);

        ground = new BGSprite('alley/ground', -1604, -50, 1, 1);
        add(ground);

        graffitis = new BGSprite('alley/graffitis', -541, 414, 1, 1, ['graffitis'], false);
        graffitis.animation.addByPrefix('graffitis', 'graffitis', 24, false);
        graffitis.animation.play('graffitis');
        graffitis.alpha = 0;
        add(graffitis);

        light = new BGSprite('alley/light', 250, -442, 1, 1);
        add(light);

        shadow = new BGSprite('alley/shadow', -1564, 375, 1, 1);
        add(shadow);

        backlight = new BGSprite('alley/backlight', -1401, 900, 1, 1);
        backlight.alpha = 0;
        add(backlight);

        fg = new BGSprite('alley/fg', -754, -400, 1.1, 1.1);
        add(fg);

        // Alert sprite (FX layer)
        alert = new BGSprite('alley/alert', 0, 0, 1, 1);
        alert.visible = false;
        alert.scrollFactor.set();
        add(alert);

        // Camera flash fallback when shaders are not used
        camFlash = new FlxSprite(0, 0);
        camFlash.makeGraphic(1, 1, 0xFFFFFFFF);
        camFlash.scale.set(4500, 1600);
        camFlash.alpha = 0;
        add(camFlash);
    }

    function getProperty(name:String, defaultVal:Dynamic)
    {
        // small helper to avoid direct property lookups from Lua port
        return defaultVal;
    }

    public function goCrazy(transitionTime:Float = 0.6):Void
    {
        crazy = !crazy;
        // Simple visual transition: use a timer to apply changes after transitionTime
        new FlxTimer().start(transitionTime, function(_)
        {
            applyCrazyState();
        });
    }

    function applyCrazyState():Void
    {
        if (crazy)
        {
            backlight.alpha = 1;
            graffitis.alpha = 1;
            buildings.alpha = 0;
            shadow.alpha = 0;
            sky.color = FlxColor.BLACK;

            // Adjust simple colors for characters if they exist
            if (dad != null) dad.color = FlxColor.WHITE;
            if (boyfriend != null) boyfriend.color = FlxColor.WHITE;
            if (gf != null) gf.color = FlxColor.WHITE;
        }
        else
        {
            backlight.alpha = 0;
            graffitis.alpha = 0;
            buildings.alpha = 1;
            shadow.alpha = 1;
            sky.color = FlxColor.WHITE;

            if (dad != null) dad.color = 0xFFa1a3c2;
            if (boyfriend != null) boyfriend.color = 0xFFa1a3c2;
            if (gf != null) gf.color = 0xFFa1a3c2;
        }
    }

    function lerp(a:Float, b:Float, t:Float):Float { return a + (b - a) * t; }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (alerting)
        {
            time += elapsed;
            alert.visible = true;
            alert.alpha = lerp(alert.alpha, Math.abs(Math.sin(time * 2)) * 0.5, elapsed * 10);
        }
        else
        {
            alert.alpha = lerp(alert.alpha, 0, elapsed * 10);
            if (alert.alpha <= 0.01) alert.visible = false;
        }
    }

    override function onEvent(n:String, v1:String, v2:String):Void
    {
        switch(n)
        {
            case 'alley_go-crazy':
                var t:Float = try Std.parseFloat(v1) catch(0.6);
                goCrazy(t);
            case 'alley_alert':
                alerting = (v1 == 'true');
        }
    }
}
