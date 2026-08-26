package funkin.play;

/**
 * Accuracy + Rank system (substitui o ratingStuff antigo na UI).
 *
 * Display style (freeplay):
 *   HIGHSCORE: 0 [N/A]
 *   ACCURACY: 0% [N/A]
 *   MISSES: 0
 */
class Rank
{
	/**
	 * Equivalent to old ratingStuff, but with letter ranks.
	 * Format: [rankName, minAccuracy]  (0.0 - 1.0, highest first)
	 */
	public static var ratingStuff:Array<Dynamic> = [
		['P',  1.0],
		['S+', 0.99],
		['S',  0.95],
		['A',  0.90],
		['B',  0.80],
		['C',  0.70],
		['D',  0.60],
		['F',  0.0]
	];

	/** Returns letter rank from accuracy (0.0 - 1.0). Empty/invalid → N/A */
	public static function getRank(accuracy:Float, ?misses:Int = -1, ?fullCombo:Bool = false):String
	{
		if (accuracy < 0 || Math.isNaN(accuracy))
			return 'N/A';

		if (accuracy <= 0)
			return 'N/A';

		var clamped:Float = Math.max(0, Math.min(1, accuracy));
		var rank:String = 'F';

		for (i in 0...ratingStuff.length)
		{
			var entry:Dynamic = ratingStuff[i];
			var name:String = Std.string(entry[0]);
			var minAcc:Float = Std.parseFloat(Std.string(entry[1]));
			if (Math.isNaN(minAcc)) minAcc = 0;
			if (clamped >= minAcc)
			{
				rank = name;
				break;
			}
		}

		if ((fullCombo || misses == 0) && (rank == 'P' || rank == 'S+' || rank == 'S'))
			return rank + ' (FC)';

		return rank;
	}

	public static function getRatingName(accuracy:Float):String
	{
		return getRank(accuracy);
	}

	public static function formatAccuracy(accuracy:Float, decimals:Int = 2):String
	{
		if (accuracy < 0 || Math.isNaN(accuracy))
			return '0';

		var percent:Float = Math.max(0, Math.min(1, accuracy)) * 100;
		var factor:Float = Math.pow(10, decimals);
		var value:Float = Math.floor(percent * factor) / factor;
		return Std.string(value);
	}

	/**
	 * Freeplay score box (multi-line), same style as the reference image:
	 * HIGHSCORE: 12345 [S]
	 * ACCURACY: 98.5% [S]
	 * MISSES: 2
	 */
	public static function formatFreeplayBox(score:Int, accuracy:Float, misses:Int, ?difficulty:String = null):String
	{
		// Freeplay box (tudo na mesma caixa):
		// HIGHSCORE: 68816 [S (FC)]
		// MISSES: 0
		// < PICO >
		var rank:String = (score <= 0 && (accuracy <= 0 || Math.isNaN(accuracy))) ? 'N/A' : getRank(accuracy, misses);
		var missStr:String = Std.string(Std.int(Math.max(0, misses)));

		var text:String = 'HIGHSCORE: ' + score + ' [' + rank + ']\n'
			+ 'MISSES: ' + missStr;

		if(difficulty != null && difficulty.trim().length > 0)
			text += '\n' + difficulty.trim();

		return text;
	}

	public static function formatShort(accuracy:Float, ?misses:Int = -1):String
	{
		return formatAccuracy(accuracy) + '% [' + getRank(accuracy, misses) + ']';
	}

	public static function getRankColor(rank:String):Int
	{
		var clean:String = rank;
		if (clean.indexOf(' ') > -1)
			clean = clean.split(' ')[0];

		return switch (clean)
		{
			case 'P':  0xFFFF66FF;
			case 'S+': 0xFFFFD700;
			case 'S':  0xFFFFFF00;
			case 'A':  0xFF00FF88;
			case 'B':  0xFF66B2FF;
			case 'C':  0xFFFFAA00;
			case 'D':  0xFFFF6600;
			case 'F':  0xFFFF3333;
			case 'N/A': 0xFFAAAAAA;
			default:   0xFFFFFFFF;
		};
	}

	/**
	 * Hook for PlayState.RecalculateRating.
	 * ratingName = Rank.applyToPlayState(ratingPercent, songMisses);
	 */
	public static function applyToPlayState(accuracy:Float, songMisses:Int = 0):String
	{
		return getRank(accuracy, songMisses, songMisses == 0 && accuracy > 0);
	}
}
