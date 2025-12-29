# FastAlign
# José María Lahoz-Bengoechea (jmlahoz@ucm.es)
# Version 2025-12-29

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

# This script takes a TextGrid with one tier named words and another named syll.
# It includes knowledge about instrinsically unstressed words in Spanish and leaves them unmarked.
# Otherwise, it recognizes the graphic accent position (or in its absence it applies the general rule)
# to determine which syllable is stressed, and it adds the stress mark to the corresponding syllable.

procedure mark_stress tg syllTID wordsTID
##{ Define vowel inventory
nacvowel$[1] = "i"
nacvowel$[2] = "e"
nacvowel$[3] = "a"
nacvowel$[4] = "o"
nacvowel$[5] = "u"
nacvowel$[6] = "I"
nacvowel$[7] = "E"
nacvowel$[8] = "A"
nacvowel$[9] = "O"
nacvowel$[10] = "U"
acvowel$[1] = "í"
acvowel$[2] = "é"
acvowel$[3] = "á"
acvowel$[4] = "ó"
acvowel$[5] = "ú"
acvowel$[6] = "Í"
acvowel$[7] = "É"
acvowel$[8] = "Á"
acvowel$[9] = "Ó"
acvowel$[10] = "Ú"
##}

# Define instrinsically unstressed words
clitics = Read Table from comma-separated file... clitics.csv
nclit = Get number of rows

# Define words ending in -mente other than adverbs
mente_noadv = Read Table from comma-separated file... mente_noadv.csv
nmente = Get number of rows

##{ Split -mente adverbs in two words (and flag suffix for later re-merge)
select tg
nword = Get number of intervals... 'wordsTID'
for iword from 1 to nword
select tg
word$ = Get label of interval... 'wordsTID' iword
if right$(word$,5) = "mente"
for imente from 1 to nmente
select mente_noadv
imente$ = Get value... imente noadv
if word$ = imente$
goto mente_is_solved
endif
endfor

select tg
wordbase$ = word$ - "mente"
wordend = Get end time of interval... 'wordsTID' iword
suffix_lastphone = Get low interval at time... 'phonesTID' wordend
suffix_firstphone = suffix_lastphone - 4
suffixini = Get start time of interval... 'phonesTID' suffix_firstphone
Insert boundary... 'wordsTID' suffixini
Set interval text... 'wordsTID' iword 'wordbase$'
Set interval text... 'wordsTID' iword+1 ADVmente
iword = iword + 1
nword = nword + 1

label mente_is_solved
endif ; ends in -mente
endfor ; to nword
##}

##{ Calculate stress
select tg
nword = Get number of intervals... 'wordsTID'
for iword from 1 to nword
word$ = Get label of interval... 'wordsTID' iword

# Check if this is an unstressed word
isclitic = 0
for iclit from 1 to nclit
select clitics
iclitmay$ = Get value... iclit nacmay
iclitmin$ = Get value... iclit nacmin
if word$ = iclitmay$ or word$ = iclitmin$
isclitic = 1
iclit = nclit
endif
endfor ; to nclit
select tg

if isclitic = 0
# Get number of syllables in the word
ini = Get start time of interval... 'wordsTID' iword
end = Get end time of interval... 'wordsTID' iword
firstsyll = Get high interval at time... 'syllTID' ini
lastsyll = Get low interval at time... 'syllTID' end
lastsyll2 = Get high interval at time... 'syllTID' end
if lastsyll = lastsyll2
lastsyll = lastsyll - 1 ; this prevents miscalculations in case of resyllabification
endif
nsyll = lastsyll - firstsyll + 1

# Monosyllabic words
if nsyll = 1
stressposition = 1

# Plurisyllabic words
elsif nsyll > 1
ac = 0
vow$ = ""
# Check if word has stress mark
for ivow from 1 to 10
ac = ac + index(word$,acvowel$[ivow])
if ac > 0
vow$ = acvowel$[ivow]
ivow = 10
endif
endfor ; ivow to 10

# Spanish general rule of stress
if ac = 0
if index("aeiouns",right$(word$,1)) != 0
stressposition = 2
else
stressposition = 1
endif

# Get number of syllables from stress mark to word end
elsif ac > 0
stressposition = 1
tmp$ = mid$(word$,ac+1,length(word$)-ac)
if left$(tmp$,1) = "i" or left$(tmp$,1) = "u"
tmp$ = mid$(tmp$,2,length(tmp$)-1)
endif
@getnextvow
while nextvow > 0
if nextvow != 1 or (vow$ = "í" or vow$ = "ú" or vow$ = "Í" or vow$ = "Ú") or ((vow$ = "a" or vow$ = "e" or vow$ = "o") and (nextvow$ = "a" or nextvow$ = "e" or nextvow$ = "o"))
stressposition = stressposition + 1
endif
tmp$ = mid$(tmp$,nextvow+1,length(tmp$)-nextvow)
vow$ = nextvow$
@getnextvow
endwhile

endif ; there is not stress mark, otherwise there is

endif ; monosyllabic words, otherwise plurisyllabic

# Transcribe stress in corresponding syllable
stressedsyll = lastsyll - stressposition + 1
stressedsyll$ = Get label of interval... 'syllTID' stressedsyll
if stressedsyll$ != "" and stressedsyll$ != "_"
stressedsyll$ = "'" + stressedsyll$
endif
Set interval text... 'syllTID' stressedsyll 'stressedsyll$'

endif ; isclitic = 0
endfor ; to nword
##}

##{ Re-merge -mente adverbs
select tg
nword = Get number of intervals... 'wordsTID'
for iword from 1 to nword
select tg
word$ = Get label of interval... 'wordsTID' iword
if word$ = "ADVmente"

wordbase$ = Get label of interval... 'wordsTID' iword-1
adverb$ = wordbase$ + "mente"
wordini = Get start time of interval... 'wordsTID' iword
Remove boundary at time... 'wordsTID' wordini
Set interval text... 'wordsTID' iword-1 'adverb$'
iword = iword - 1
nword = nword - 1

endif ; is suffix -mente
endfor ; to nword
##}

select clitics
plus mente_noadv
Remove
select tg
endproc

procedure getnextvow
nextvow = 0
nextvow$ = ""
for ivow from 1 to 10
nextvow = nextvow + index(tmp$,nacvowel$[ivow])
if nextvow > 0
nextvow$ = nacvowel$[ivow]
ivow = 10
endif
endfor ; ivow to 10
endproc
