package funkin.data.objects.game.notes.data;

import funkin.states.PlayState;
import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.config.StrumNote;
import funkin.utils.engines.psych.PsychAnimationController;
import funkin.data.objects.game.notes.data.Note.NoteSkinConfig;

class HoldNoteCover extends FlxSprite
{
	public var babyArrow:StrumNote;
	public var noteData:Int = 0;

	var texture:String;
	var textureIsAtlas:Bool = false;
	var ending:Bool = false;
	var releaseTimer:Float = 0;
	var playEndOnRelease:Bool = false;
	var coverOffsets:Array<Float> = [0, 0];
	var centerOnStrum:Bool = true;

	public function new(x:Float = 0, y:Float = 0) {
		super(x, y);

		animation = new PsychAnimationController(this);
		scrollFactor.set();
		visible = false;
		active = false;
	}

	public function spawnCover(strum:StrumNote, note:Note, phase:String, holdTime:Float = 0)
	{
		if(strum == null || note == null)
		{
			kill();
			return;
		}

		var skin:String = NoteData.notestyles.songStyle(note.mustPress);
		var config:NoteSkinConfig = NoteData.notestyles.config(skin);
		if(!Note.holdNoteCoverEnabled(config))
		{
			kill();
			return;
		}

		var assetPath:String = NoteData.notestyles.holdNoteCover(skin, note.noteData);
		if(assetPath == null || assetPath.length < 1)
		{
			kill();
			return;
		}

		var useAtlas:Bool = Note.noteSkinAtlasExists(assetPath);
		if(texture != assetPath || textureIsAtlas != useAtlas)
		{
			texture = assetPath;
			textureIsAtlas = useAtlas;

			if(useAtlas)
			{
				frames = Note.getNoteSkinAtlas(texture);
			}
			else if(Note.holdNoteCoverIsPixel(config))
			{
				var graphic = Note.getNoteSkinGraphic(texture);
				if(graphic == null)
				{
					kill();
					return;
				}

				loadGraphic(
					graphic,
					true,
					Math.floor(graphic.width / Note.holdNoteCoverColumns(config)),
					Math.floor(graphic.height / Note.holdNoteCoverRows(config))
				);
				antialiasing = false;
			}
			else
			{
				kill();
				return;
			}
		}
		if(frames == null)
		{
			kill();
			return;
		}

		babyArrow = strum;
		noteData = note.noteData;
		ending = false;
		playEndOnRelease = PlayState.isPlayerNote(note);
		releaseTimer = holdTime > 0 ? holdTime : 0.001;
		coverOffsets = Note.holdNoteCoverOffset(config).copy();
		centerOnStrum = Note.holdNoteCoverCenterOnStrum(config);
		visible = true;
		active = true;
		revive();
		if(strum.cameras != null && strum.cameras.length > 0)
			cameras = strum.cameras;

		Note.addHoldNoteCoverAnimation(animation, 'start', config, noteData, 'start');
		Note.addHoldNoteCoverAnimation(animation, 'hold', config, noteData, 'hold');
		Note.addHoldNoteCoverAnimation(animation, 'end', config, noteData, 'end');

		var coverScale:Float = Note.holdNoteCoverScale(config);
		scale.set(coverScale, coverScale);
		updateHitbox();

		followStrum(config);
		if(animation.curAnim == null || animation.curAnim.name == 'end' || phase == 'start')
			playCoverAnim(hasCoverAnim('start') ? 'start' : 'hold', true);
		else if(animation.curAnim.name != 'start' && animation.curAnim.name != 'hold')
			playCoverAnim('hold', true);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(babyArrow != null)
			followStrum(null);

		if(releaseTimer > 0)
		{
			releaseTimer -= elapsed;
			if(releaseTimer <= 0)
				releaseCover();
		}

		if(animation.curAnim != null)
		{
			if(animation.curAnim.name == 'start' && animation.curAnim.finished)
				playCoverAnim('hold', true);
			else if(ending && animation.curAnim.name == 'end' && animation.curAnim.finished)
				kill();
		}
	}

	function releaseCover()
	{
		releaseTimer = 0;
		if(ending) return;

		if(playEndOnRelease && hasCoverAnim('end'))
		{
			ending = true;
			playCoverAnim('end', true);
		}
		else
			kill();
	}

	function hasCoverAnim(anim:String):Bool
		return animation.getByName(anim) != null;

	function playCoverAnim(anim:String, force:Bool = false)
	{
		if(hasCoverAnim(anim))
			animation.play(anim, force);
	}

	function followStrum(config:NoteSkinConfig)
	{
		if(babyArrow == null) return;

		var offsets:Array<Float> = coverOffsets;
		if(centerOnStrum)
		{
			setPosition(
				babyArrow.x + (babyArrow.width - width) * 0.5 + offsets[0],
				babyArrow.y + (babyArrow.height - height) * 0.5 + offsets[1]
			);
		}
		else
			setPosition(babyArrow.x + offsets[0], babyArrow.y + offsets[1]);

		alpha = babyArrow.alpha;
		visible = babyArrow.visible && exists;
	}
}