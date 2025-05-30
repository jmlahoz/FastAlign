# syllabify
# José María Lahoz-Bengoechea (jmlahoz@ucm.es)
# Version 2025-04-01

# LICENSE
# (C) 2025 José María Lahoz-Bengoechea
# This file is part of the plugin_SegmentSound.
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License
# as published by the Free Software Foundation
# either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# For more details, you can find the GNU General Public License here:
# http://www.gnu.org/licenses/gpl-3.0.en.html
# This file runs on Praat, a software developed by Paul Boersma
# and David Weenink at University of Amsterdam.

# This script takes a TextGrid with one tier named phones (+ possibly other tiers)
# and creates a syll tier following the syllabification rules for Spanish.

include auxiliary.praat
include stress.praat

##{ Dialog window
form Syllabify...
comment Creates 'syll' tier from a TG with existing 'phones' and 'words' tiers
boolean overwrite 1
endform
##}

##{ Create syll tier
call findtierbyname phones 1 1
phonesTID = findtierbyname.return
call findtierbyname syll 0 1
syllTID = findtierbyname.return

if syllTID = 0
syllTID = phonesTID+1
Duplicate tier... 'phonesTID' 'syllTID' syll
elsif syllTID != 0 and overwrite = 1
Remove tier... 'syllTID'
syllTID = phonesTID+1
Duplicate tier... 'phonesTID' 'syllTID' syll
elsif syllTID != 0 and overwrite = 0
Set tier name... 'syllTID' syllbak
syllTID = phonesTID+1
Duplicate tier... 'phonesTID' 'syllTID' syll
endif
##}

##{ Define types of segments by sonority
vowels$ = "ieaou"
vowels$[1] = "i"
vowels$[2] = "e"
vowels$[3] = "a"
vowels$[4] = "o"
vowels$[5] = "u"
glides$ = "jw"
liquids$[1] = "l"
liquids$[2] = "4"
obstruents$[1] = "p"
obstruents$[2] = "t"
obstruents$[3] = "k"
obstruents$[4] = "B"
obstruents$[5] = "D"
obstruents$[6] = "G"
obstruents$[7] = "f"
consonants$[1] = "p"
consonants$[2] = "t"
consonants$[3] = "tS"
consonants$[4] = "k"
consonants$[5] = "f"
consonants$[6] = "T"
consonants$[7] = "s"
consonants$[8] = "x"
consonants$[9] = "B"
consonants$[10] = "D"
consonants$[11] = "jj"
consonants$[12] = "G"
consonants$[13] = "m"
consonants$[14] = "n"
consonants$[15] = "J"
consonants$[16] = "l"
consonants$[17] = "4"
consonants$[18] = "r"
##}

nint = Get number of intervals... 'syllTID'

# Empty strings are substituted for by "_" to keep them from scoring at the index function.
# Previous and next labels are initially defined as "#" to avoid errors when there is no previous or next segment at all.
 
##{ Merge glides with neighboring vowels
# Swipe text from start to end
int = 1
while int <= nint
ini = Get start time of interval... 'syllTID' int
end = Get end time of interval... 'syllTID' int
lab$ = Get label of interval... 'syllTID' int
if lab$ = ""
lab$ = "_"
endif

if index(glides$,lab$) != 0
prevlab$ = "#"
nextlab$ = "#"
if int > 1
prevlab$ = Get label of interval... 'syllTID' int-1
if prevlab$ = ""
prevlab$ = "_"
endif
endif
if int < nint
nextlab$ = Get label of interval... 'syllTID' int+1
if nextlab$ = ""
nextlab$ = "_"
endif
endif

if lab$ = "j" and nextlab$ = "j"
@rmend
elsif index(vowels$,nextlab$) != 0
@rmend
elsif index(vowels$,right$(prevlab$,1)) != 0
@rmini
endif
endif
int = int+1
endwhile
##}

##{ Merge consonants with following vowels
# Swipe text from start to end
int = 1
while int <= nint
ini = Get start time of interval... 'syllTID' int
end = Get end time of interval... 'syllTID' int
lab$ = Get label of interval... 'syllTID' int
if lab$ = ""
lab$ = "_"
endif

for cons from 1 to 18
if lab$ = consonants$[cons]
nextlab$ = "#"
if int < nint
nextlab$ = Get label of interval... 'syllTID' int+1
if nextlab$ = ""
nextlab$ = "_"
endif
endif

for vow from 1 to 5
if index(nextlab$,vowels$[vow]) != 0
@rmend
endif
endfor ; vow to 5
endif
endfor ; cons to 18
int = int+1
endwhile
##}

##{ Merge selected obstruents with following liquids
# Swipe text from start to end
int = 1
while int <= nint
ini = Get start time of interval... 'syllTID' int
end = Get end time of interval... 'syllTID' int
lab$ = Get label of interval... 'syllTID' int
if lab$ = ""
lab$ = "_"
endif

for obs from 1 to 7
if lab$ = obstruents$[obs]
nextlab$ = "#"
if int < nint
nextlab$ = Get label of interval... 'syllTID' int+1
if nextlab$ = ""
nextlab$ = "_"
endif
endif

for liq from 1 to 2
if left$(nextlab$,1) = liquids$[liq]
@rmend
endif
endfor ; liq to 2
endif
endfor ; obs to 7
int = int+1
endwhile
##}

##{ Merge stranded consonants as codas with previous vowels
# Swipe text from start to end
int = 1
while int <= nint
ini = Get start time of interval... 'syllTID' int
end = Get end time of interval... 'syllTID' int
lab$ = Get label of interval... 'syllTID' int
if lab$ = ""
lab$ = "_"
endif

for cons from 1 to 18
if lab$ = consonants$[cons]
@rmini
endif
endfor ; cons to 18
int = int+1
endwhile
##}

##{ Mark stress
call findtierbyname words 1 1
wordsTID = findtierbyname.return
call mark_stress 'tg' 'syllTID' 'wordsTID'
##}

procedure rmini
Remove boundary at time... 'syllTID' 'ini'
nint = nint-1 ; due to boundary removal
int = int-1 ; since the removed boundary is the initial
endproc

procedure rmend
Remove boundary at time... 'syllTID' 'end'
nint = nint-1 ; due to boundary removal
endproc
