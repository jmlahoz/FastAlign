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

# This script takes a TextGrid and converts SAMPA transcription into IPA transcription
# for a tier of the user's choice (either phones or syll).

include auxiliary.praat

##{ Dialog window
form Convert SAMPA to IPA...
choice tier 1
button phones
button syll
endform
##}

##{ Detect selected TextGrid plus one optional Sound/LongSound and exit if selection is not correct
nso=numberOfSelected("Sound")
nloso=numberOfSelected("LongSound")
ntg=numberOfSelected("TextGrid")
if ntg!=1 or nso>1 or nloso>1 or nso+nloso>1
exit Select one TextGrid plus optionally up to one Sound.
endif

tg=selected("TextGrid")
if nso = 1
so=selected("Sound")
elsif nloso = 1
so=selected("LongSound")
endif
##}

##{ Convert SAMPA to IPA
select tg
call toipa 'tier$'
nocheck plus so
##}
