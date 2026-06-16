package funkin.data.objects;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';
	public var animatedIcon:Bool = false;
	private var neutralAnim:String = '';
	private var loseAnim:String = '';
	private var winAnim:String = '';

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true, ?animatedIcon:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		this.animatedIcon = animatedIcon;
		changeIcon(char, allowGPU, animatedIcon);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true, ?animatedIcon:Null<Bool> = null)
	{
		var icon:String = char != null ? char.trim() : '';
		if(icon.length < 1) icon = 'face';

		var newAnimatedIcon:Bool = animatedIcon != null ? animatedIcon : this.animatedIcon;
		if(!newAnimatedIcon && hasAnimatedIconAtlas(icon))
			newAnimatedIcon = true;
		if(this.char != icon || this.animatedIcon != newAnimatedIcon)
		{
			this.animatedIcon = newAnimatedIcon;
			var name:String = getIconPath(icon, this.animatedIcon);

			if(hasIconAtlas(name))
			{
				frames = Paths.getAtlas(name, null, allowGPU);
				if(frames == null || frames.frames == null || frames.frames.length < 1)
					loadPlaceholderIcon(icon);
				else
				{
					addIconAnimations(icon, name);
					animation.play(neutralAnim);
					iconOffsets[0] = width - 150;
					iconOffsets[1] = height - 150;
					updateHitbox();
				}
			}
			else
			{
				var graphic = Paths.image(name, allowGPU);
				if (graphic == null) 
				{
					loadPlaceholderIcon(icon);
				}
				else
				{
					var iSize:Float = Math.max(1, Math.round(graphic.width / graphic.height));
					loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
					iconOffsets[0] = (width - 150) / iSize;
					iconOffsets[1] = (height - 150) / iSize;
					updateHitbox();

					animation.add(icon, [for(i in 0...frames.frames.length) i], this.animatedIcon ? 24 : 0, this.animatedIcon, isPlayer);
					animation.play(icon);
					neutralAnim = icon;
					loseAnim = icon;
					winAnim = icon;
				}
			}
			this.char = icon;

			if(icon.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	private function getIconPath(char:String, animated:Bool):String
	{
		var icon:String = char != null ? char.trim() : '';
		if(icon.length < 1) icon = 'face';

		var paths:Array<String> = [];
		if(animated) paths.push('icons/animated/' + icon + '/' + icon);
		paths.push('icons/' + icon);
		paths.push('icons/baseGame/' + icon);
		paths.push('icons/baseGame/icon-' + icon);
		paths.push('icons/icon-' + icon);
		paths.push('icons/icon-face');

		for(path in paths)
			if(Paths.fileExists('images/' + path + '.png', IMAGE))
				return path;

		return 'icons/icon-face';
	}

	private function hasAnimatedIconAtlas(char:String):Bool
	{
		var icon:String = char != null ? char.trim() : '';
		if(icon.length < 1) return false;
		return Paths.fileExists('images/icons/animated/$icon/$icon.png', IMAGE) && Paths.fileExists('images/icons/animated/$icon/$icon.xml', TEXT);
	}

	private function hasIconAtlas(name:String):Bool
	{
		if(Paths.fileExists('images/' + name + '.xml', TEXT))
			return true;

		return false;
	}

	private function loadPlaceholderIcon(char:String):Void
	{
		var placeholder:BitmapData = new BitmapData(150, 150, true, 0xFF000000);
		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(placeholder, false, 'icon-face');
		loadGraphic(graphic, true, 150, 150);
		iconOffsets[0] = 0;
		iconOffsets[1] = 0;
		updateHitbox();
		animation.add(char, [0], 0, false, isPlayer);
		animation.play(char);
		neutralAnim = char;
		loseAnim = char;
		winAnim = char;
	}

	private function addIconAnimations(char:String, name:String):Void
	{
		neutralAnim = char;
		loseAnim = char;
		winAnim = char;

		if(this.animatedIcon)
		{
			var hasNeutral:Bool = addAtlasAnim('neutral', ['icon animated idle', 'icon animated neutral', 'icon animated0', 'icon animated', 'Neutral', 'neutral', 'Idle', 'idle'], true);
			var hasLose:Bool = addAtlasAnim('lose', ['icon animated lose', 'icon animated losing', 'icon lose', 'Lose', 'lose', 'Losing', 'losing'], true);
			var hasWin:Bool = addAtlasAnim('win', ['icon animated win', 'icon animated winning', 'icon win', 'Win', 'win', 'Winning', 'winning'], true);

			if(hasNeutral) neutralAnim = 'neutral';
			if(hasLose) loseAnim = 'lose';
			if(hasWin) winAnim = 'win';

			if(hasNeutral || hasLose || hasWin)
			{
				if(!hasNeutral) neutralAnim = hasLose ? 'lose' : 'win';
				if(!hasLose) loseAnim = neutralAnim;
				if(!hasWin) winAnim = neutralAnim;
				return;
			}
		}

		animation.add(char, [for(i in 0...frames.frames.length) i], this.animatedIcon ? 24 : 0, this.animatedIcon, isPlayer);
		neutralAnim = char;
		loseAnim = char;
		winAnim = char;
	}

	private function addAtlasAnim(animName:String, prefixes:Array<String>, loop:Bool):Bool
	{
		var prefix:String = findAtlasPrefix(prefixes);
		if(prefix == null) return false;

		animation.addByPrefix(animName, prefix, 24, loop, isPlayer);
		return animation.getByName(animName) != null;
	}

	private function findAtlasPrefix(prefixes:Array<String>):String
	{
		if(frames == null || frames.frames == null) return null;
		for(prefix in prefixes)
		{
			if(prefix == null || prefix.length < 1) continue;
			for(frame in frames.frames)
			{
				if(frame != null && frame.name != null && frame.name.indexOf(prefix) == 0)
					return prefix;
			}
		}
		return null;
	}

	public function updateHealthState(healthPercent:Float, opponent:Bool = false):Void
	{
		if(animation == null || animation.curAnim == null) return;

		if(!animatedIcon)
		{
			var frame:Int = (opponent ? healthPercent > 80 : healthPercent < 20) ? 1 : 0;
			if(animation.curAnim.frames != null && animation.curAnim.frames.length > frame)
				animation.curAnim.curFrame = frame;
			return;
		}

		var target:String = neutralAnim;
		if(opponent)
		{
			if(healthPercent > 80) target = loseAnim;
			else if(healthPercent < 20) target = winAnim;
		}
		else
		{
			if(healthPercent < 20) target = loseAnim;
			else if(healthPercent > 80) target = winAnim;
		}

		playIconAnim(target);
	}

	public function playIconAnim(anim:String):Void
	{
		if(anim == null || anim.length < 1 || animation.getByName(anim) == null)
			anim = neutralAnim;

		if(anim != null && anim.length > 0 && animation.getByName(anim) != null && (animation.curAnim == null || animation.curAnim.name != anim))
			animation.play(anim, true);
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}
