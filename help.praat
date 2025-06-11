# LICENSE
# (C) 2025 José María Lahoz-Bengoechea
# This file is part of FastAlign.
# FastAlign is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License
# as published by the Free Software Foundation
# either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# For more details, you can find the GNU General Public License here:
# http://www.gnu.org/licenses/gpl-3.0.en.html
# FastAlign is partially based on EasyAlign, by Jean-Philippe Goldman (2011),
# and further developed by José María Lahoz-Bengoechea.
# FastAlign runs on Praat, a software developed by Paul Boersma
# and David Weenink at University of Amsterdam.



clearinfo
printline Contact, questions, suggestions: José María Lahoz-Bengoechea'newline$''tab$'jmlahoz@ucm.es
printline
printline FastAlign creates 'phones', 'syll', and 'words' tiers from a Sound and a TextGrid
printline with an existing 'ortho' tier.
printline The 'ortho' tier can be automatically created with Whisper as a previous step,
printline as shown here: 
printline
printline -------------------------------------------------------------------------
printline
if windows = 1
printline Segmentation is based on HTK by default.
printline This draws from Hidden Markov Models (HMM).
printline FastAlign includes such a model especially trained with data in Spanish.
printline HTK alignment is more accurate than Praat native alignment functions.
printline However, sometimes it fails to produce a viable segmentation.
printline Only in those cases, native alignment will be invoked as a last resource.
printline Both algorithms are available to allow comparison and research.
elsif macintosh = 1 or unix = 1
printline Segmentation is based on Praat native alignment functions.
endif
printline
printline -------------------------------------------------------------------------
printline
if windows = 1
printline Run one-click segmentation with the function FastAlign.
printline
printline A step-by-step segmentation is also possible:
printline First, phonetize the ortho tier to create a temporary phono tier
printline (which consists of a phonetic transcription in SAMPA).
printline Then apply HTK alignment.
printline
printline As an alternative, just apply native alignment (no prior phonetization is needed in that case).
printline If you have an already segmented TextGrid and want to re-try segmentation of just one ortho interval,
printline you may choose to do so by running "Align sound (native)".
printline For just that one interval, information will be overwritten regardless of the overwrite checkbox.
elsif macintosh = 1 or unix = 1
printline If you have an already segmented TextGrid and want to re-try segmentation of just one ortho interval,
printline you may choose to do so by running "Align sound (native)".
printline For just that one interval, information will be overwritten regardless of the overwrite checkbox.
endif
printline
printline -------------------------------------------------------------------------
printline
printline Syllabification and IPA transcription are included in the alignment
printline but are also available as separate functions for your convenience.
printline
printline -------------------------------------------------------------------------
printline
printline In any case, alignment should be further hand-corrected.
printline Tip: hold SHIFT down while you click and drag any boundary of a given tier,
printline and the associated boundaries in the tiers below will move accordingly.
printline That way, you do not have to correct all tiers one by one,
printline and you can make sure that boundaries for different tiers will coincide as appropriate.