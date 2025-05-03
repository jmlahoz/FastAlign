LICENSE
(C) 2011 Jean-Philippe Goldman
This distribution includes modifications by José María Lahoz-Bengoechea (2021),
as indicated in the appropriate scripts.
This file is part of EasyAlign.
EasyAlign is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License
as published by the Free Software Foundation
either version 3 of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY, without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
For more details, you can find the GNU General Public License here:
http://www.gnu.org/licenses/gpl-3.0.en.html
EasyAlign runs on Praat, a software developed by Paul Boersma
and David Weenink at University of Amsterdam.

Suggested citations:

Goldman, J.-P. (2011). EasyAlign: An automatic phonetic alignment tool under Praat. Proceedings of Interspeech.
Goldman, J.-P., & Schwab, S. (2014). EasyAlign Spanish: An (semi-)automatic segmentation tool under Praat. In Y. Congosto Martín, M. L. Montero Curiel, & A. Salvador Plans (Eds.), Fonética experimental, educación superior e investigación (Vol. 1, pp. 629-640). Arco/Libros.

------------------------------------------------------------------------------------------
EasyAlign is a tool designed to segment a sound in a TextGrid. Given an orthographic transcription, it creates tiers for words, syllables, and phones, and properly aligns the boundaries to the sound.

How to install EasyAlign as a Praat plugin in a permanent fashion:
1. Go to your Praat preferences folder.
   This is always under your user folder, but the location varies depending on your operating system.
   (In each case, change user_name for your actual user name).
   --On Windows, go to C:\Users\user_name\Praat
   --On Mac, go to /Users/user_name/Library/Preferences/Praat Prefs/ (You may need to make invisible folders visible by pressing Command+Shift+Period)
   --On Linux, go to /home/user_name/.praat-dir
2. Create a subfolder named plugin_EasyAlign
   (this is case-sensitive).
3. Copy all the EasyAlign files into that subfolder.
   You are ready to go.
   Next time you open Praat, go to the Praat menu on the objects window and
   you will find the EasyAlign sub-menu.


EasyAlign runs in three steps.

------------------------------------------------------------------------------------------

1. Macro-segmentation

You must select a Sound and a Strings to run this script.
You may Read Strings from raw text file.
The Strings must contain the orthographic transcription of the sound,
one sentence per line.
The script will generate a TextGrid with intervals for each sentence.
Segmentation is based on automatic detection of silence (pauses between sentences).

You may want to hand-correct the outcome to improve alignment,
and most importantly to add intervals of silence for long pauses
(these can be left empty or labeled as underscore _)

Alternatively, you may skip this step and do it entirely manually
(I personally find it is worth doing this first step by hand).
Create a TextGrid with one interval tier named ortho and segment and label sentences.
Proceed to the second step.

-------------------------------------------------------------------------

2. Phonetization

The orthographic transcription is turned into a phonetic transcription in SAMPA.

-------------------------------------------------------------------------

3. Phone segmentation

The program uses a Hidden Markov Model trained with HTK
to force-align the TextGrid to the Sound.
Up to three different tiers may be created: words, syll, phones.
The Spanish version is optimized for some syllable phenomena, like resyllabification.
Also, phones are transcribed in IPA rather than SAMPA (to the phonemic, not allophonic, level).

-------------------------------------------------------------------------

Steps 2 & 3 may be run at once with the FAST ALIGN options.
Two alternatives are offered:
FAST ALIGN (phones) includes words, syll, phones, while FAST ALIGN (syll) includes words, syll.
The latter may be convenient for subsequent intonation analysis with Intonalyzer.

-------------------------------------------------------------------------

In any case, alignment should be further hand-corrected.
Tip: hold SHIFT down while you click and drag any boundary of the phones (or syll) tiers,
and the associated boundaries in the tiers below (syll and words) will move accordingly.
That way, you do not have to correct all tiers one by one, and you can make sure that boundaries for different tiers will coincide as appropriate.
