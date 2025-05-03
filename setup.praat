# LICENSE
# (C) 2011 Jean-Philippe Goldman
# This distribution includes modifications by José María Lahoz-Bengoechea (2021),
# as indicated in the appropriate scripts.
# This file is part of EasyAlign.
# EasyAlign is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License
# as published by the Free Software Foundation
# either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# For more details, you can find the GNU General Public License here:
# http://www.gnu.org/licenses/gpl-3.0.en.html
# EasyAlign runs on Praat, a software developed by Paul Boersma
# and David Weenink at University of Amsterdam.

Add menu command... "Objects" "Praat" "EasyAlign" "" 0 
Add menu command... "Objects" "Control" "FAST ALIGN (phones)" "EasyAlign" 1 fast_align_phones.praat
Add menu command... "Objects" "Control" "FAST ALIGN (syll)" "EasyAlign" 1 fast_align_syll.praat
Add menu command... "Objects" "Control" "1. Macro-segmentation..." "EasyAlign" 1 utt_seg2.praat
Add menu command... "Objects" "Control" "2. Phonetization..." "EasyAlign" 1 phonetize_orthotier.praat
Add menu command... "Objects" "Control" "3. Phone segmentation..." "EasyAlign" 1 align_sound.praat
Add menu command... "Objects" "Control" "-" "EasyAlign" 1
Add menu command... "Objects" "Control" "About" "EasyAlign" 1 about.praat
