#if VSLICE_ALLOWED
package funkin.utils.engines.vslice.stages;

import funkin.stages.data.levels.week1.*;
import funkin.stages.data.levels.week2.*;
import funkin.stages.data.levels.week3.*;
import funkin.stages.data.levels.week4.*;
import funkin.stages.data.levels.week5.*;
import funkin.stages.data.levels.week6.*;
import funkin.stages.data.levels.week7.*;
import funkin.stages.data.levels.weekend1.*;
import funkin.stages.data.levels.week1.variation.erect.*;
import funkin.stages.data.levels.week1.variation.remix.*;
import funkin.stages.data.levels.week2.variation.erect.*;
import funkin.stages.data.levels.week3.variation.erect.*;
import funkin.stages.data.levels.week3.variation.remix.*;
import funkin.stages.data.levels.week4.variation.erect.*;
import funkin.stages.data.levels.week5.variation.erect.*;
import funkin.stages.data.levels.week6.variation.erect.*;
import funkin.stages.data.levels.week7.variation.erect.*;
import funkin.stages.data.levels.week7.variation.remix.*;
import funkin.stages.data.levels.weekend1.variation.erect.*;
import funkin.stages.data.levels.weekspecial.vslice.*;

import funkin.stages.BaseStage;
import funkin.modding.scripting.FunkinLua;
import haxe.ds.List;

class StagesVslice extends BaseStage {

    public static var currentStage:BaseStage = null;
    #if LUA_ALLOWED
    public static function implement(funk:FunkinLua) {
        var lua:State = funk.lua;
        funk.set('versionPS', MainMenuState.PicoVersion.trim());
    }
    #end

        public static function addstage(name:String) {
            currentStage = null;
            currentStage = switch (name) {
                case 'stage': new StageWeek1();                        //Week 1
                case 'mainStageErect': new MainStageErect();           //Week 1 - Erect
                case 'spookyMansion': new SpookyMansion();             //Week 2
                case 'philly': new Philly();                           //Week 3
                case 'phillyTrainRemix': new PhillyRemix();            //Week 3 - Remix
                case 'limoRide': new LimoRide();					   //Week 4
                case 'mallXmas': new MallXmas();					   //Week 5 - Cocoa, Eggnog
                case 'mallEvil': new MallEvil();					   //Week 5 - Winter Horrorland
                case 'school': new School();						   //Week 6 - Senpai, Roses
                case 'schoolEvil': new SchoolEvil();				   //Week 6 - Thorns
                case 'tankmanBattlefield': new TankmanBattlefield();   //Week 7 - Ugh, Guns, Stress
                case 'phillyStreets': new PhillyStreets();             //Weekend 1 - Darnell, Lit Up, 2Hot
                case 'phillyStreetsErect': new PhillyStreetsErect();   //Weekend 1 - Erect
                case 'phillyBlazin': new PhillyBlazin();               //weekend1 - Blazin
                case 'shiftDarkErect': new TheShiftDarkErect();        //Sky (Pico Mix)
                case 'charSelector': new SelectCharacterStage();   //StayFunky
            default: null;
        }
        #end
    }
}