# Fast-Align
# José María Lahoz-Bengoechea (jmlahoz@ucm.es)
# Version 2025-06-02

# LICENSE
# (C) 2025 José María Lahoz-Bengoechea
# This file is part of Fast-Align.
# Fast-Align is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License
# as published by the Free Software Foundation
# either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# For more details, you can find the GNU General Public License here:
# http://www.gnu.org/licenses/gpl-3.0.en.html
# Fast-Align runs on Praat, a software developed by Paul Boersma
# and David Weenink at University of Amsterdam.

##{ Dialog window
form FastAlign...
comment Creates 'phones', 'syll', and 'words' tiers from a Sound and a TG with an existing 'ortho' tier
boolean overwrite 1
boolean open_sound_and_tg 1
comment Output tiers
boolean keep_phones 1
boolean keep_syll 1
boolean keep_words 1
boolean keep_ortho 1
endform
##}

simulatemac = 1

if windows = 1 and simulatemac = 0
runScript: "phonetize_orthotier.praat", 'overwrite', "no"
runScript: "align_sound_htk.praat", 'overwrite', 'open_sound_and_tg', 'keep_phones', 'keep_syll', 'keep_words', 'keep_ortho'
elsif macintosh = 1 or unix = 1 or simulatemac = 1
runScript: "align_sound_native.praat", 'overwrite', 'open_sound_and_tg', 'keep_phones', 'keep_syll', 'keep_words', 'keep_ortho', ""
endif

