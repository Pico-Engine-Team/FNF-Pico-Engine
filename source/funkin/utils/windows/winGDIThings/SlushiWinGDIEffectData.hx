package funkin.utils.windows.winGDIThings;

import funkin.utils.windows.winGDIThings.SlushiWinGDI.SlushiWinGDIEffect;

class SlushiWinGDIEffectData {
	public var gdiEffect:SlushiWinGDIEffect;
	public var wait:Float = 0;
	public var enabled:Bool = false;

	public function new(_gdiEffect:SlushiWinGDIEffect, _wait:Float = 0, _enabled:Bool = false) {
		this.gdiEffect = _gdiEffect;
		this.wait = _wait;
		this.enabled = _enabled;
	}
}