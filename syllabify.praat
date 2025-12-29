# FastAlign
# José María Lahoz-Bengoechea (jmlahoz@ucm.es)
# Version 2025-12-29

# LICENSE
# (C) 2025 José María Lahoz-Bengoechea
# This file is part of FastAlign.
# FastAlign free software; you can redistribute it and/or modify it
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

# This script takes a TextGrid with one tier named phones (+ possibly other tiers)
# and creates a syll tier following the syllabification rules for Spanish.
# The algorithm assumes that phones are transcribed in SAMPA.

include auxiliary.praat
include stress.praat

##{ Dialog window
form Create syll tier from phones...
comment Creates 'syll' tier from a TG with existing 'phones' and 'words' tiers
boolean overwrite 1
comment Which ortho interval do you want to align?
comment (leave this empty to align all intervals)
word interval_number 
endform
##}

##{ Check selection of interval number
interval_number = number(interval_number$)
if interval_number <= 0 or round(interval_number) != interval_number
exit Interval number must be a positive whole number. Exiting...
endif
##}

##{ Create syll tier
call findtierbyname phones 1 1
phonesTID = findtierbyname.return
call findtierbyname syll 0 1
syllTID = findtierbyname.return

if syllTID = 0
syllTID = phonesTID+1
Duplicate tier... 'phonesTID' 'syllTID' syll
elsif syllTID != 0 and overwrite = 1 and interval_number = undefined
Remove tier... 'syllTID'
syllTID = phonesTID+1
Duplicate tier... 'phonesTID' 'syllTID' syll
elsif syllTID != 0 and (overwrite = 0 or interval_number != undefined)
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
obstruents$[7] = "b"
obstruents$[8] = "d"
obstruents$[9] = "g"
obstruents$[10] = "f"
consonants$[1] = "p"
consonants$[2] = "t"
consonants$[3] = "tS"
consonants$[4] = "k"
consonants$[5] = "f"
consonants$[6] = "T"
consonants$[7] = "s"
consonants$[8] = "z"
consonants$[9] = "x"
consonants$[10] = "B"
consonants$[11] = "D"
consonants$[12] = "jj"
consonants$[13] = "G"
consonants$[14] = "b"
consonants$[15] = "d"
consonants$[16] = "g"
consonants$[17] = "m"
consonants$[18] = "n"
consonants$[19] = "N"
consonants$[20] = "J"
consonants$[21] = "l"
consonants$[22] = "L"
consonants$[23] = "4"
consonants$[24] = "r"
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

for cons from 1 to 24
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
endfor ; cons to 24
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

for obs from 1 to 10
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
endfor ; obs to 10
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

for cons from 1 to 24
if lab$ = consonants$[cons]
@rmini
endif
endfor ; cons to 24
int = int+1
endwhile
##}

##{ Mark stress
call findtierbyname words 1 1
wordsTID = findtierbyname.return
tg = selected("TextGrid")
call mark_stress 'tg' 'syllTID' 'wordsTID'
##}

##{ Syllable merger

# Define instrinsically unstressed words
clitics = Read Table from comma-separated file... clitics.csv
nclit = Get number of rows

select tg
nword = Get number of intervals... 'wordsTID'

# Swipe text from start to end
iword = 1
while iword <= nword
wordini = Get start time of interval... 'wordsTID' iword
isyll = Get high interval at time... 'syllTID' wordini
syllini = Get start time of interval... 'syllTID' isyll

if syllini = wordini ; word boundary is not resyllabified
lab$ = Get label of interval... 'syllTID' isyll
if lab$ = ""
lab$ = "_"
endif

if index(vowels$,left$(lab$,1)) != 0 ; word starts with any (unstressed) vowel
prevlab$ = "#"
if isyll > 1
prevlab$ = Get label of interval... 'syllTID' isyll-1
if prevlab$ = ""
prevlab$ = "_"
endif
endif
if index(vowels$,right$(prevlab$,1)) != 0 ; previous word also ends with a vowel
if right$(prevlab$,2) != "ju" and right$(prevlab$,2) != "wi" ; merger will not cause a sonority valley
Remove boundary at time... 'syllTID' 'syllini'
endif
endif ; previous word also ends with a vowel

elsif left$(lab$,1) = "'" and index(vowels$,mid$(lab$,2,1)) != 0 ; word starts with any (stressed) vowel
prevlab$ = "#"
if isyll > 1
prevlab$ = Get label of interval... 'syllTID' isyll-1
if prevlab$ = ""
prevlab$ = "_"
endif
endif
if index(vowels$,right$(prevlab$,1)) != 0 ; previous word also ends with a vowel
if right$(prevlab$,2) != "ju" and right$(prevlab$,2) != "wi" ; merger will not cause a sonority valley

prevword$ = "#"
if iword > 1
prevword$ = Get label of interval... 'wordsTID' iword-1
if prevword$ = ""
prevword$ = "_"
endif
endif

# Check if the previous word is an unstressed word
isclitic = 0
for iclit from 1 to nclit
select clitics
iclitmay$ = Get value... iclit nacmay
iclitmin$ = Get value... iclit nacmin
if prevword$ = iclitmay$ or prevword$ = iclitmin$
isclitic = 1
iclit = nclit
endif
endfor ; to nclit
select tg

if isclitic = 1
Remove boundary at time... 'syllTID' 'syllini'
# Stress mark must be placed at the beginning of the new resulting syllable
newsyll$ = Get label of interval... 'syllTID' isyll-1
newsyll$ = replace$(newsyll$,"'","",0)
newsyll$ = "'" + newsyll$
Set interval text... 'syllTID' isyll-1 'newsyll$'
endif ; (word-initial vowel is stressed but) previous word is an unstressed word
endif
endif ; previous word also ends with a vowel

endif ; word starts with any vowel
endif ; word boundary is not resyllabified

iword = iword+1
endwhile

select clitics
Remove
select tg
##}

##{ Conjunction "y" must not become a consonant between vowels
select tg
nint = Get number of intervals... 'phonesTID'
for int from 1 to nint
lab$ = Get label of interval... 'phonesTID' int
if lab$ = "jj"
ini = Get start time of interval... 'phonesTID' int
iword = Get high interval at time... 'wordsTID' ini
word$ = Get label of interval... 'wordsTID' iword
if word$ = "y"
Set interval text... 'phonesTID' int j
isyll = Get high interval at time... 'syllTID' ini
syll$ = Get label of interval... 'syllTID' isyll
syll$ = replace$(syll$,"jj","j",1)
Set interval text... 'syllTID' isyll 'syll$'
endif
endif
endfor
##}

##{ Transfer syllables to proper tier if only one interval was selected
if interval_number != undefined
call findtierbyname syllbak 0 1
syllbakTID = findtierbyname.return
if syllbakTID > 0
@align_selected_interval: syllTID, syllbakTID
Remove tier... 'syllTID'
call findtierbyname syllbak 1 1
syllbakTID = findtierbyname.return
Set tier name... 'syllbakTID' syll
endif
endif
##}

procedure align_selected_interval .originTID .destinyTID
call findtierbyname ortho 1 1
orthoTID = findtierbyname.return
.ini = Get start time of interval... 'orthoTID' 'interval_number'
.end = Get end time of interval... 'orthoTID' 'interval_number'

# Remove pre-existing boundaries and text in destiny tier within selected times
.fromdestinyint = Get high interval at time... '.destinyTID' '.ini'
.todestinyint = Get low interval at time... '.destinyTID' '.end'
while .fromdestinyint < .todestinyint
Remove left boundary... '.destinyTID' '.todestinyint'
.todestinyint = .todestinyint - 1
endwhile
Set interval text... '.destinyTID' '.fromdestinyint' 

.fromint = Get high interval at time... '.originTID' '.ini'
.toint = Get low interval at time... '.originTID' '.end'

for .int from .fromint to .toint
.intend = Get end time of interval... '.originTID' '.int'
.lab$ = Get label of interval... '.originTID' '.int'

if .int < .toint
Insert boundary... '.destinyTID' '.intend'
endif

.targetint = Get low interval at time... '.destinyTID' '.intend'
Set interval text... '.destinyTID' '.targetint' '.lab$'
endfor

endproc

procedure rmini
Remove boundary at time... 'syllTID' 'ini'
nint = nint-1 ; due to boundary removal
int = int-1 ; since the removed boundary is the initial
endproc

procedure rmend
Remove boundary at time... 'syllTID' 'end'
nint = nint-1 ; due to boundary removal
endproc
