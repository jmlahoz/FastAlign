# FastAlign
# José María Lahoz-Bengoechea (jmlahoz@ucm.es)
# Version 2025-06-11

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
# FastAlign runs on Praat, a software developed by Paul Boersma
# and David Weenink at University of Amsterdam.

Add menu command... "Objects" "Praat" "FastAlign" "" 0 
Add menu command... "Objects" "Control" "FastAlign..." "FastAlign" 1 fast_align.praat
if windows = 1
Add menu command... "Objects" "Control" "-" "FastAlign" 1
Add menu command... "Objects" "Control" "Phonetize ortho tier..." "FastAlign" 1 phonetize_orthotier.praat
Add menu command... "Objects" "Control" "Align sound (HTK)..." "FastAlign" 1 align_sound_htk.praat
Add menu command... "Objects" "Control" "Align sound (native)..." "FastAlign" 1 align_sound_native.praat
endif
Add menu command... "Objects" "Control" "-" "FastAlign" 1
Add menu command... "Objects" "Control" "Create syll tier from phones..." "FastAlign" 1 syllabify.praat
Add menu command... "Objects" "Control" "-" "FastAlign" 1
Add menu command... "Objects" "Control" "About" "FastAlign" 1 about.praat
