#if !macro
#if DISCORD_ALLOWED
// New Discord API
import funkin.utils.api.DiscordAPI;
#end

#if LUA_ALLOWED
// Psych
import llua.*;
import llua.Lua;
#end

#if ACHIEVEMENTS_ALLOWED
import funkin.states.achievements.Achievements;
#end

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

// New Souce Code folders (Pico Engine v2.7.26)
import funkin.Paths;
import funkin.data.ClientPrefs;
import funkin.states.PlayState;
import funkin.play.Difficulty;
import funkin.stages.BaseStage;
import funkin.stages.BGSprite;
import funkin.states.LoadingState;
import funkin.states.MusicBeatState;
import funkin.utils.Controls;
import funkin.utils.CoolUtil;
import funkin.utils.substates.MusicBeatSubstate;
import funkin.utils.CustomFadeTransition;
import funkin.play.Conductor;
import funkin.translations.Language;
import funkin.utils.Alphabet;
import funkin.menus.MainMenuState;

#if MODS_ALLOWED
import funkin.modding.Mods;
#end

#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLua;
import funkin.modding.scripting.psychlua.*;
#end

import funkin.states.TitleState;
import funkin.states.CreditsState;
import funkin.menus.StoryMenuState;
import funkin.modding.ModsMenuState;
import funkin.states.options.OptionsState;

#if PSYCH_ALLOWED
// Psych UI'S elements
import funkin.utils.engine.psych.ui.*;
#end

#if flxanimate
import funkin.utils.engine.psych.PsychFlxAnimate as FlxAnimate;
import flxanimate.*;
#end

// News Flixel and openfl
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.system.FlxAssets.FlxShader;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import openfl.media.Sound;
import lime.utils.Assets;
using StringTools;
#end
