# FastAlign
# Author: José María Lahoz-Bengoechea
# License: GPL-3.0-or-later

Add menu command... "Objects" "Praat" "FastAlign" "" 0 
Add menu command... "Objects" "Control" "FastAlign..." "FastAlign" 1 fast_align.praat
Add menu command... "Objects" "Control" "Batch align..." "FastAlign" 1 batch_align.praat
Add menu command... "Objects" "Control" "-" "FastAlign" 1
if windows = 1
Add menu command... "Objects" "Control" "Phonetize ortho tier..." "FastAlign" 1 phonetize_orthotier.praat
Add menu command... "Objects" "Control" "Align sound (HTK)..." "FastAlign" 1 align_sound_htk.praat
Add menu command... "Objects" "Control" "Align sound (native)..." "FastAlign" 1 align_sound_native.praat
elsif macintosh = 1 or unix = 1
Add menu command... "Objects" "Control" "Align sound (native)..." "FastAlign" 1 align_sound_native.praat
endif
Add menu command... "Objects" "Control" "-" "FastAlign" 1
Add menu command... "Objects" "Control" "About" "FastAlign" 1 about.praat
Add menu command... "Objects" "Control" "Help" "FastAlign" 1 help.praat
