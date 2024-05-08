package funkin.objects.userInterface;

import funkin.data.scripts.HScript;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
#if polymod
import polymod.format.ParseRules.TargetSignatureElement;
#end
import funkin.states.PlayState;
import funkin.data.JudgeManager;

using StringTools;

typedef HitResult = {
	var judgement:Judgement;
	var difference:Float;
}

enum abstract NoteType(String) from String to String // just to make it a bit easier when writing note type code
{ 
	var NONE = '';
	var ALT_ANIM = 'alt animation';
	var MINE = 'mine'; 
	var FAKE = 'fake';
}

enum NoteQuant
{
	N_4TH;
	N_8TH;
	N_12TH;
	N_16TH;
	N_24TH;
	N_32ND;
	N_48TH;
	N_64TH;
	N_192ND;
}

class NoteUtils // mainly quant stuff but might have more use eventually
{
	// Quants
	public static inline final ROWS_PER_BEAT = 48; // from Stepmania
	public static inline final BEATS_PER_MEASURE = 4; // TODO: time sigs
	public static inline final ROWS_PER_MEASURE = ROWS_PER_BEAT * BEATS_PER_MEASURE; // from Stepmania
	public static inline final MAX_NOTE_ROW = 1 << 30; // from Stepmania

	static var conversionMap:Map<Int, NoteQuant> = [
		64 => N_64TH,
		48 => N_48TH,
		32 => N_32ND,
		24 => N_24TH,
		16 => N_16TH,
		12 => N_12TH,
		8 => N_8TH,
		4 => N_4TH
	];

	public static function quantToBeat(quant:NoteQuant):Float
	{
		switch (quant)
		{
			case N_4TH:
				return 1;
			case N_8TH:
				return 1 / 2;
			case N_12TH:
				return 1 / 3;
			case N_16TH:
				return 1 / 4;
			case N_24TH:
				return 1 / 6;
			case N_32ND:
				return 1 / 8;
			case N_48TH:
				return 1 / 12;
			case N_64TH:
				return 1 / 16;
			default:
				return 1 / 48;
		}
	}

	public static function quantToString(quant:NoteQuant)
	{
		switch (quant)
		{
			case N_4TH:
				return '4th';
			case N_8TH:
				return '8th';
			case N_12TH:
				return '12th';
			case N_16TH:
				return '16th';
			case N_24TH:
				return '24th';
			case N_32ND:
				return '32nd';
			case N_48TH:
				return '48th';
			case N_64TH:
				return '64th';
			default:
				return '192nd';
		}
	}

	public inline static function beatToQuant(beat:Float):NoteQuant
		return rowToQuant(beatToRow(beat));

	public inline static function beatToRow(beat:Float):Int
		return Math.round(beat * ROWS_PER_BEAT);

	public inline static function rowToBeat(row:Int):Float
		return row / ROWS_PER_BEAT;

	public static function rowToQuant(row:Int):NoteQuant
	{
		for (key in conversionMap.keys())
		{
			if (row % (ROWS_PER_MEASURE / key) == 0)
				return conversionMap.get(key);
		}
		return N_192ND;
	}
}
class Note extends FlxSprite // maybe like ScriptableSprite idfk man
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var hitResult:HitResult = {difference: 0, judgement: UNJUDGED};

	// TODO: sustainType, for roll or hold

	public var noteType:String = NONE;
	public var quant:NoteQuant = N_16TH;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public static var swagWidth:Float = 160 * 0.7;

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		x += 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;

		this.noteData = noteData;

		var daStage:String = PlayState.curStage;

		switch (daStage)
		{
			case 'school' | 'schoolEvil':
				loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);

				animation.add('greenScroll', [6]);
				animation.add('redScroll', [7]);
				animation.add('blueScroll', [5]);
				animation.add('purpleScroll', [4]);

				if (isSustainNote)
				{
					loadGraphic(Paths.image('weeb/pixelUI/arrowEnds'), true, 7, 6);

					animation.add('purpleholdend', [4]);
					animation.add('greenholdend', [6]);
					animation.add('redholdend', [7]);
					animation.add('blueholdend', [5]);

					animation.add('purplehold', [0]);
					animation.add('greenhold', [2]);
					animation.add('redhold', [3]);
					animation.add('bluehold', [1]);
				}

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();

			default:
				frames = Paths.getSparrowAtlas('NOTE_assets');

				animation.addByPrefix('greenScroll', 'green0');
				animation.addByPrefix('redScroll', 'red0');
				animation.addByPrefix('blueScroll', 'blue0');
				animation.addByPrefix('purpleScroll', 'purple0');

				animation.addByPrefix('purpleholdend', 'pruple end hold');
				animation.addByPrefix('greenholdend', 'green hold end');
				animation.addByPrefix('redholdend', 'red hold end');
				animation.addByPrefix('blueholdend', 'blue hold end');

				animation.addByPrefix('purplehold', 'purple hold piece');
				animation.addByPrefix('greenhold', 'green hold piece');
				animation.addByPrefix('redhold', 'red hold piece');
				animation.addByPrefix('bluehold', 'blue hold piece');

				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				antialiasing = true;
		}

		switch (noteData)
		{
			case 0:
				x += swagWidth * 0;
				animation.play('purpleScroll');
			case 1:
				x += swagWidth * 1;
				animation.play('blueScroll');
			case 2:
				x += swagWidth * 2;
				animation.play('greenScroll');
			case 3:
				x += swagWidth * 3;
				animation.play('redScroll');
		}

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;

			x += width / 2;

			switch (noteData)
			{
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
				case 1:
					animation.play('blueholdend');
				case 0:
					animation.play('purpleholdend');
			}

			updateHitbox();

			x -= width / 2;

			if (PlayState.curStage.startsWith('school'))
				x += 30;

			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			/*if (Math.abs(Conductor.songPosition - strumTime) <= PlayState.instance.judgeMan.hitWindow )
				canBeHit = true;
			else
				canBeHit = false;*/

			// prob gonna end up removing this all entirely, and having the canBeHit n shit be handled in PlayState
			// TODO: replace with like.. isHittable(judgeNote())	

            
            // remove this once i rewrite holds
			if(!tooLate && !wasGoodHit && isSustainNote)
				canBeHit = PlayState.instance.judgeMan.judgeNote(this, Conductor.songPosition)!=UNJUDGED; // hopefully this isnt too terribly unoptimized or anything

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}
