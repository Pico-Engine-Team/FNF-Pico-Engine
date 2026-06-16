package funkin.utils.engines.psych;

import flixel.animation.FlxAnimationController;

class PsychAnimationController extends FlxAnimationController {
    public var followGlobalSpeed:Bool = true;

    public override function update(elapsed:Float):Void {
		if (_curAnim != null) {
			if(_curAnim.numFrames < 1 || _curAnim.frames == null || _curAnim.frames.length < 1)
				return;

            var speed:Float = timeScale;
            if (followGlobalSpeed) speed *= FlxG.animationTimeScale;
			_curAnim.update(elapsed * speed);
		}
		else if (_prerotated != null) {
			_prerotated.angle = _sprite.angle;
		}
	}
}
