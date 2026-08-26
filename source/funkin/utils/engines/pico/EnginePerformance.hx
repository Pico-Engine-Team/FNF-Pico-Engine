package funkin.utils.engines.pico;

import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.data.NoteSplash;

import openfl.system.System;
import flixel.FlxG;

/**
 * Performance + memory helpers for Pico Engine.
 *
 * IMPORTANT: Never call Paths.clearUnusedMemory() while sprites are still
 * on screen / being drawn — that causes Null Object Reference in
 * FlxDrawQuadsItem (bitmap/graphic already destroyed).
 */
class EnginePerformance
{
	public static var lastLoadMs:Float = 0;
	public static var lastCleanupMs:Float = 0;
	static var lastAutoGcTime:Float = 0;
	public static var pendingMenuCleanup:Bool = false; // Run Paths cleanup on next menu/state, not mid-draw in PlayState

	public static function isDevMode():Bool
	{
		try
		{
			return ClientPrefs.data.devMode == true;
		}
		catch(e:Dynamic)
		{
			return false;
		}
	}

	public static function wantClearOnSongLoad():Bool
	{
		try
		{
			return ClientPrefs.data.clearMemoryOnSongLoad == true; // opt-in (safer default off)
		}
		catch(e:Dynamic)
		{
			return false;
		}
	}

	public static function wantClearOnExitSong():Bool
	{
		try
		{
			return ClientPrefs.data.clearMemoryOnExitSong != false;
		}
		catch(e:Dynamic)
		{
			return true;
		}
	}

	public static function isAggressive():Bool
	{
		try
		{
			return ClientPrefs.data.aggressiveMemory == true;
		}
		catch(e:Dynamic)
		{
			return false;
		}
	}

	public static function getAutoGcInterval():Float
	{
		try
		{
			var v:Dynamic = Reflect.field(ClientPrefs.data, 'autoGcInterval');
			if(v == null) return 0;
			var n:Float = Std.parseFloat(Std.string(v));
			return Math.isNaN(n) ? 0 : n;
		}
		catch(e:Dynamic)
		{
			return 0;
		}
	}

	/**
	 * Start of song load. Does NOT dump graphics still in use.
	 * PlayState already calls Paths.clearStoredMemory() before this.
	 */
	public static function beginSongLoad():Void
	{
		lastLoadMs = haxe.Timer.stamp() * 1000;
		if(isDevMode())
			trace('[Perf] beginSongLoad | mem=${getMemoryMB()} MB');
	}

	/**
	 * End of song load. Never clearUnusedMemory here — notes/UI just loaded
	 * and are about to be drawn (fixes FlxDrawQuadsItem null crash).
	 */
	public static function endSongLoad():Void
	{
		lastLoadMs = (haxe.Timer.stamp() * 1000) - lastLoadMs;
		if(isDevMode())
			trace('[Perf] Song load took ${Math.round(lastLoadMs)} ms | mem=${getMemoryMB()} MB');
	}

	/**
	 * Leaving PlayState. Only clear lightweight config maps here.
	 * Heavy Paths dump is deferred to the next menu (pendingMenuCleanup).
	 */
	public static function onExitSong():Void
	{
		try
		{
			if(Note.noteSkinConfigs != null)
				Note.noteSkinConfigs.clear();
		}
		catch(e:Dynamic) {}

		try
		{
			Note.globalRgbShaders = [];
		}
		catch(e:Dynamic) {}

		// Do NOT clear NoteSplash.configs / Paths here while destroy() is mid-frame
		if(wantClearOnExitSong())
			pendingMenuCleanup = true;

		if(isDevMode())
			trace('[Perf] onExitSong | pendingCleanup=$pendingMenuCleanup | mem=${getMemoryMB()} MB');
	}

	/**
	 * Call from menu states (MainMenu / Freeplay create) after the previous
	 * PlayState is fully gone.
	 */
	public static function flushPendingCleanup():Void
	{
		if(!pendingMenuCleanup) return;
		pendingMenuCleanup = false;
		cleanup(isAggressive(), 'menu-after-song');
	}

	/**
	 * Safe memory cleanup — only call when no gameplay sprites need their graphics.
	 */
	public static function cleanup(aggressive:Bool = false, ?reason:String = null):Void
	{
		var t0:Float = haxe.Timer.stamp() * 1000;
		try
		{
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();
		}
		catch(e:Dynamic)
		{
			if(isDevMode())
				trace('[Perf] Paths cleanup error: $e');
		}

		try
		{
			if(NoteSplash.configs != null)
				NoteSplash.configs.clear();
		}
		catch(e:Dynamic) {}

		#if (cpp || hl)
		try
		{
			System.gc();
		}
		catch(e:Dynamic) {}
		#end

		lastCleanupMs = (haxe.Timer.stamp() * 1000) - t0;
		if(isDevMode())
			trace('[Perf] cleanup($reason) ${Math.round(lastCleanupMs)} ms | mem=${getMemoryMB()} MB | aggressive=$aggressive');
	}

	/** Soft GC in menus only — never dumps tracked graphics mid-song */
	public static function updateAutoGc(elapsed:Float):Void
	{
		var interval:Float = getAutoGcInterval();
		if(interval <= 0) return;

		// Never auto-GC during PlayState
		try
		{
			if(PlayState.instance != null)
				return;
		}
		catch(e:Dynamic) {}

		lastAutoGcTime += elapsed;
		if(lastAutoGcTime < interval) return;
		lastAutoGcTime = 0;

		#if (cpp || hl)
		try
		{
			System.gc();
		}
		catch(e:Dynamic) {}
		#end

		if(isDevMode())
			trace('[Perf] auto-GC | mem=${getMemoryMB()} MB');
	}

	public static function getMemoryMB():Float
	{
		#if (cpp || hl)
		return Math.abs(Math.round(System.totalMemory / 1024 / 1024 * 100) / 100);
		#else
		return 0;
		#end
	}

	public static function formatDevHudLine():String
	{
		if(!isDevMode()) return '';
		return 'MEM: ${getMemoryMB()} MB | load ${Math.round(lastLoadMs)}ms';
	}
}
