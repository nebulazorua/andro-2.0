package funkin.data;

import flixel.FlxSprite;
import funkin.objects.userInterface.Note;

/**
 * Used to handle note judging, etc
 * Modify this if you need to add or remove judgements or have other custom judgement logic
 */


typedef JudgementData =
{
	var internalName:String;
	var displayName:String;
	var window:Float;
	var score:Int;
	var accuracy:Float;
	var frame:Int;
    var health:Float;
}

enum Judgement {
	UNJUDGED; // unjudged

    TIER1; // shit
    TIER2; // bad
    TIER3; // good
    TIER4; // great / sick
    TIER5; // sick / epic
    MISS; // miss
    
}

class JudgeManager {
    public var judgementDatas:Array<JudgementData> = [
        {
            internalName: "sick",
            displayName: "Sick",
            window: 45,
            score: 350,
            accuracy: 100,
            health: 1.15,
            frame: 0
        },
		{
			internalName: "good",
			displayName: "Good",
			window: 90,
			score: 100,
			accuracy: 80,
            health: 1.15,
			frame: 1
		},
		{
			internalName: "bad",
			displayName: "Bad",
			window: 135,
			score: 0,
			accuracy: 50,
            health: 0,
			frame: 2
		},
		{
			internalName: "shit",
			displayName: "Shit",
			window: 180,
			score: -100,
			accuracy: -20,
            health: -1.5, // to discourage mashing
			frame: 3
		},
        {
			internalName: "miss",
			displayName: "Miss",
			window: -1,
			score: -200,
			accuracy: -100,
            health: -2.375,
			frame: 4
        }
    ]; // 

    public final hittableJudgements:Array<Judgement> = [TIER5, TIER4, TIER3, TIER2, TIER1]; // decides the hierarchy of judgements
    // make sure this is in order of highest window at the front, to lowest window at the back

    public final judgementMap:Map<Judgement, Int> = [ // NONE isnt here because its a lack of judgement
        TIER5 => 0,
        TIER4 => 0,
        TIER3 => 1,
        TIER2 => 2,
        TIER1 => 3,
        MISS => 4,
    ];
    // the int is the index in judgementdatas

	@:isVar
	public var hitWindow(get, null):Float = 0;

	function get_hitWindow()
		return get(hittableJudgements[hittableJudgements.length - 1]).window;

    public function new() {}

	public function get(idx:Judgement)
		return judgementDatas[judgementMap.get(idx)];

	public function getIndexByName(name:String):Judgement
	{
		for (k in judgementMap.keys())
		{
			if (get(k).internalName == name || get(k).displayName == name)
				return k;
		}
		return TIER5;
	}

	public function getByName(name:String)
		return get(getIndexByName(name));

    public function judgeNote(note:Note, time:Float): Judgement
    {
		var diff = Math.abs(note.strumTime - time);
        switch(note.noteType){
            case MINE:
                // mine logic
            case FAKE:
                return UNJUDGED; // fake notes dont ever get judged as they're fake
            default:
				for (i in 0...hittableJudgements.length)
				{
					var k = hittableJudgements[i];
					var ms = get(k).window;
					if (Math.abs(diff) <= ms)
						return k;
				}
        }

        return UNJUDGED;
    }

	public function getSprite(name:String)
	{
		var idx = getByName(name).frame;
		var judgement = new FlxSprite();
		judgement.loadGraphic(Paths.image("judgements"), true, 403, 152);
		judgement.antialiasing = true;
		judgement.animation.add("early", [2 * idx], 0, true);
		judgement.animation.add("late", [(2 * idx) + 1], 0, true);
		judgement.animation.play("early", true);
		judgement.setGraphicSize(Std.int(judgement.width * 0.8));
		judgement.updateHitbox();
		return judgement;
	}

	public function getNumber(num:String)
	{
		var indexes = ["-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "."];
		var idx = indexes.indexOf(num);
		var number = new FlxSprite();
		number.loadGraphic(Paths.image("numbers"), true, 91, 135);
		number.antialiasing = true;
		number.animation.add(num, [idx], 0, true);
		number.animation.play(num, true);
		number.setGraphicSize(Std.int(number.width * 0.5));
		number.updateHitbox();
		return number;
	}
}