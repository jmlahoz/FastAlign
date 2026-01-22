# FastAlign
# Author: José María Lahoz-Bengoechea
# License: GPL-3.0-or-later

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
