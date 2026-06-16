#if PICO_ALLOWED
package funkin.utils.engines.pico.stages;

import funkin.stages.data.levels.weekspecial.engine.standard.*;
import funkin.stages.data.levels.weekspecial.engine.mods.*;
import funkin.stages.data.levels.weekspecial.engine.retake.*;
import funkin.stages.data.levels.weekspecial.engine.mods.exe.*;
import funkin.stages.data.levels.weekspecial.engine.mods.exe.encore.*;
import funkin.stages.data.levels.weekspecial.engine.mods.funkadelix.*;

import funkin.stages.BaseStage;
import funkin.modding.scripting.FunkinLua;
import haxe.ds.List;

class StagesPicoEnigne extends BaseStage {
    public static var currentStage:BaseStage = null;
    #if LUA_ALLOWED
    public static function implement(funk:FunkinLua) {
        var lua:State = funk.lua;
        funk.set('versionPS', MainMenuState.PicoVersion.trim());
    }
    #end

        public static function addstage(name:String)
        {
            currentStage = null;
            currentStage = switch (name)
            {
                case "endlessEncore": new EndlessEncore();         //Sonic.exe Vs Sonic Majin
                case 'castleBowser': new CastleBowser();           //Vs Bowser (Pico Mix)
                case 'matt-arena': new Arenanew();                 //Vs Matt (Pico Mix)
                case 'stageSky': new StageSky();                   //Reteke Sky (Pico Mix)
                case 'tankReteke': new TankReteke();			   //Week 7 Retake
                case 'HappyRon': new Ron();						   //Vs Happy Ron (Pico Mix)
                case 'whittyAlley': new WhittyAlley();             //Vs Whitty (Pico Mix)
            default: null;
        }
        #end
    }
}