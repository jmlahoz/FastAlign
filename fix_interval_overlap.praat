# FastAlign
# Author: José María Lahoz-Bengoechea
# License: GPL-3.0-or-later

# This script takes a TextGrid with one tier named ortho
# and checks whether the end time of each interval strictly coincides
# with the start time of the following.
# (Some mismatches may occur as a result of rounding in TextGrids produced by Whisper).
# If necessary, it corrects the timing of the boundaries to avoid incoherent overlap
# between successive intervals.

include auxiliary.praat

##{ Detect selected Sound/LongSound and TextGrid
nso=numberOfSelected("Sound")
nloso=numberOfSelected("LongSound")
ntg=numberOfSelected("TextGrid")
if ntg!=1 or nso+nloso>1
exit Select one TextGrid (and one Sound or none)
endif

tg=selected("TextGrid")
name$=selected$("TextGrid")
if nso = 1
so=selected("Sound")
elsif nloso = 1
so=selected("LongSound")
endif
##}

##{ Ensure there is a TextGrid tier named ortho
select tg

call findtierbyname ortho 0 1
orthoTID = findtierbyname.return

if orthoTID = 0
exit The TextGrid must contain one tier named ortho. Exiting...
endif
##}

select tg
northo = Get number of intervals... 'orthoTID'

##{ Fix possible interval overlaps
for iortho from 1 to northo-1
select tg
orthoend = Get end time of interval... 'orthoTID' 'iortho'
nextorthoini = Get start time of interval... 'orthoTID' 'iortho'+1

if orthoend != nextorthoini
ortho$ = Get label of interval... 'orthoTID' 'iortho'
nextortho$ = Get label of interval... 'orthoTID' 'iortho'+1

Remove right boundary... 'orthoTID' 'iortho'
Insert boundary... 'orthoTID' 'orthoend'

Set interval text... 'orthoTID' 'iortho' 'ortho$'
Set interval text... 'orthoTID' 'iortho'+1 'nextortho$'
endif ; orthoend != nextorthoini

endfor ; to northo
##}

select tg
nocheck plus so
