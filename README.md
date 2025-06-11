LICENSE
(C) 2025 José María Lahoz-Bengoechea 
This file is part of FastAlign. 
FastAlign is free software; you can redistribute it and/or modify it 
under the terms of the GNU General Public License 
as published by the Free Software Foundation 
either version 3 of the License, or (at your option) any later version. 
This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY, without even the implied warranty 
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
For more details, you can find the GNU General Public License here: 
http://www.gnu.org/licenses/gpl-3.0.en.html 
FastAlign is partially based on EasyAlign, by Jean-Philippe Goldman (2011), 
and further developed by José María Lahoz-Bengoechea. 
FastAlign runs on Praat, a software developed by Paul Boersma 
and David Weenink at University of Amsterdam.

Suggested citation:

Lahoz-Bengoechea, José María (2025). FastAlign: A Praat plugin for phonemic, syllabic and wordly segmentation of Spanish audios (1.0) [Computer software]. https://github.com/jmlahoz/fastalign

------------------------------------------------------------------------------------------
FastAlign is a tool designed to segment audios in phonetically relevant units (phonemes, syllables, and words). 

How to install FastAlign as a Praat plugin in a permanent fashion: 
1. Go to your Praat preferences folder. 
   This is always under your user folder, but the location varies depending on your operating system. 
   (In each case, change user_name for your actual user name). 
   --On Windows, go to C:\Users\user_name\Praat 
   --On Mac, go to /Users/user_name/Library/Preferences/Praat Prefs/ (You may need to make invisible folders visible by pressing Command+Shift+Period) 
   --On Linux, go to /home/user_name/.praat-dir 
2. Create a subfolder named plugin_fastalign 
   (this is case-sensitive). 
3. Copy all the FastAlign files into that subfolder. 
   You are ready to go. 
   Next time you open Praat, go to the Praat menu on the objects window and 
   you will find the FastAlign sub-menu.

------------------------------------------------------------------------------------------
FastAlign creates 'phones', 'syll', and 'words' tiers from a Sound and a TextGrid 
with an existing 'ortho' tier. 

The ortho tier can be automatically created with Whisper as a previous step, 
as shown here: 

------------------------------------------------------------------------------------------
On Windows, segmentation is based on HTK by default. 
This draws from Hidden Markov Models (HMM). 
FastAlign includes such a model especially trained with data in Spanish. 
HTK alignment is more accurate than Praat native alignment functions. 
However, sometimes it fails to produce a viable segmentation. 
Only in those cases, native alignment will be invoked as a last resource. 
Both algorithms are available to allow comparison and research. 

On other operating systems, segmentation is based solely on Praat native alignment functions.

------------------------------------------------------------------------------------------
Run one-click segmentation with the function FastAlign. 

On Windows, a step-by-step segmentation is also possible: 
First, phonetize the ortho tier to create a temporary phono tier 
(which consists of a phonetic transcription in SAMPA). 
Then apply HTK alignment.
As an alternative, just apply native alignment (no prior phonetization is needed in that case).

If you have an already segmented TextGrid and want to re-try segmentation of just one ortho interval, 
you may choose to do so by running "Align sound (native)". 
For just that one interval, information will be overwritten regardless of the overwrite checkbox.

Syllabification and IPA transcription are included in the alignment 
but are also available as separate functions for your convenience.

------------------------------------------------------------------------------------------
In any case, alignment should be further hand-corrected. 
Tip: hold SHIFT down while you click and drag any boundary of a given tier, 
and the associated boundaries in the tiers below will move accordingly. 
That way, you do not have to correct all tiers one by one, 
and you can make sure that boundaries for different tiers will coincide as appropriate.