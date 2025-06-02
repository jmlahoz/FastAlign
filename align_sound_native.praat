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

# The alignment is based on Praat's native method.
# It works on Windows, Macintosh or Linux. However, it is less accurate than HTK.
# It potentially aligns multiple languages, but in the current version this is adapted for Spanish only.

# This script takes a Sound and a TextGrid with an ortho and a phono tier.
# ortho must contain the transliteration of the sound in conventional Spanish spelling.
# phono must contain the corresponding SAMPA transcription (as the output of the script phonetize_orthotier).
# It yields phones, syll, and words tiers aligned to the contents of the sound.

include auxiliary.praat

##{ Dialog window
form 3. Align sound (native)...
comment Creates 'phones', 'syll', and 'words' tiers from a Sound and a TG with an existing 'ortho' tier
boolean overwrite 1
boolean open_sound_and_tg 1
comment Output tiers
boolean keep_phones 1
boolean keep_syll 1
boolean keep_words 1
boolean keep_ortho 1
comment Which ortho interval do you want to align?
comment (leave this empty to align all intervals)
word interval_number 
endform
##}

##{ Detect selected Sound/LongSound and TextGrid and exit if selection is not correct
nso=numberOfSelected("Sound")
nloso=numberOfSelected("LongSound")
ntg=numberOfSelected("TextGrid")
if ntg!=1 or (nso!=1 and nloso!=1) or nso+nloso!=1
exit Select one Sound and one TextGrid
endif

tg=selected("TextGrid")
name$=selected$("TextGrid")
if nso = 1
so=selected("Sound")
elsif nloso = 1
so=selected("LongSound")
endif
##}

##{ Check selection of interval number
interval_number = number(interval_number$)
if interval_number <= 0 or round(interval_number) != interval_number
exit Interval number must be a positive whole number. Exiting...
endif
##}

##{ Apply native alignment
View & Edit
select tg

ini = Get start time
if ini != 0
Shift to zero
endif

call findtierbyname ortho 1 1
orthoTID = findtierbyname.return

# Tier ortho must be tier 1, since Align interval operates on selected tier.
# The tier selected by default in the editor is tier 1 and this cannot be changed by script.
# If necessary, ortho must be temporarily duplicated to position 1.
if orthoTID != 1
orthobakTID = orthoTID
Set tier name... 'orthobakTID' orthobak
orthoTID = 1
Duplicate tier... 'orthobakTID' 'orthoTID' ortho
endif

# If an interval number was specified, only this will be aligned.
# Otherwise, all intervals are processed.
if interval_number != undefined
fromortho = interval_number
toortho = interval_number
else
fromortho = 1
toortho = Get number of intervals... 'orthoTID'
endif

for int from fromortho to toortho
lab$ = Get label of interval... 'orthoTID' int
if lab$ = "-" or lab$ = "_" or lab$ = " "
Set interval text... 'orthoTID' int 
endif
ini = Get start time of interval... 'orthoTID' int
editor TextGrid 'name$'
Move cursor to... ini
if int = fromortho
if praatVersion >= 6036
Alignment settings: "Spanish (Spain)", "yes", "yes", "yes"
else
Alignment settings: "Spanish", "yes", "yes", "yes"
endif
endif
nowarn Align interval
if int = toortho
Close
endif
endeditor
endfor ; int

call findtierbyname orthobak 0 1
orthobakTID = findtierbyname.return
if orthobakTID != 0
Remove tier... 'orthoTID' ; this is the duplicate (bak is the backup, the original)
call findtierbyname orthobak 1 1
orthoTID = findtierbyname.return
Set tier name... 'orthoTID' ortho
endif
##}

##{ Adapt tier names and order
call findtierbyname phones 0 1
oldphonesTID = findtierbyname.return
call findtierbyname orthophon 1 1
orthophonTID = findtierbyname.return
if oldphonesTID = 0
Duplicate tier... 'orthophonTID' 1 phones
elsif interval_number != undefined
@align_selected_interval: orthophonTID, oldphonesTID
elsif oldphonesTID != 0 and overwrite = 1
Remove tier... 'oldphonesTID'
Duplicate tier... 'orthophonTID' 1 phones
elsif oldphonesTID != 0 and overwrite = 0
Set tier name... 'oldphonesTID' phonesbak
Duplicate tier... 'orthophonTID' 1 phones
endif
call findtierbyname orthophon 1 1
orthophonTID = findtierbyname.return
Remove tier... 'orthophonTID'

call findtierbyname words 0 1
oldwordsTID = findtierbyname.return
call findtierbyname orthoword 1 1
orthowordTID = findtierbyname.return
if oldwordsTID = 0
Duplicate tier... 'orthowordTID' 2 words
elsif interval_number != undefined
# Ortho position must be recalculated since orthophonTID has been deleted.
# This was not necessary for the phones round, nor is it necessary for the other branches of this condition.
# It will be recalculated after deletion of orthowordTID, anyway.
call findtierbyname ortho 1 1
orthoTID = findtierbyname.return
@align_selected_interval: orthowordTID, oldwordsTID
elsif oldwordsTID != 0 and overwrite = 1
Remove tier... 'oldwordsTID'
Duplicate tier... 'orthowordTID' 2 words
elsif oldwordsTID != 0 and overwrite = 0
Set tier name... 'oldwordsTID' wordsbak
Duplicate tier... 'orthowordTID' 2 words
endif
call findtierbyname orthoword 1 1
orthowordTID = findtierbyname.return
Remove tier... 'orthowordTID'

call findtierbyname "phones" 1 1
phonesTID = findtierbyname.return
call findtierbyname "words" 1 1
wordsTID = findtierbyname.return
call findtierbyname "ortho" 1 1
orthoTID = findtierbyname.return
##}

##{ Get interval range for phones and words tiers
if interval_number != undefined
ini = Get start time of interval... 'orthoTID' 'interval_number'
end = Get end time of interval... 'orthoTID' 'interval_number'
fromphone = Get high interval at time... 'phonesTID' 'ini'
tophone = Get low interval at time... 'phonesTID' 'end'
fromword = Get high interval at time... 'wordsTID' 'ini'
toword = Get low interval at time... 'wordsTID' 'end'
else
fromphone = 1
tophone = Get number of intervals... 'phonesTID'
fromword = 1
toword = Get number of intervals... 'wordsTID'
endif
##}

##{ Adapt native aligner output to SAMPA
Replace interval text... phonesTID fromphone tophone tʃ tS Literals
Replace interval text... phonesTID fromphone tophone θ T Literals
Replace interval text... phonesTID fromphone tophone β B Literals
Replace interval text... phonesTID fromphone tophone ð D Literals
Replace interval text... phonesTID fromphone tophone ɣ G Literals
Replace interval text... phonesTID fromphone tophone b B Literals
Replace interval text... phonesTID fromphone tophone d D Literals
Replace interval text... phonesTID fromphone tophone ɡ G Literals
Replace interval text... phonesTID fromphone tophone ʎ jj Literals
Replace interval text... phonesTID fromphone tophone ɲ J Literals
Replace interval text... phonesTID fromphone tophone ŋ n Literals
Replace interval text... phonesTID fromphone tophone ɾ 4 Literals
Replace interval text... phonesTID fromphone tophone ɛ e Literals
Replace interval text... phonesTID fromphone tophone ɔ o Literals
Replace interval text... phonesTID fromphone tophone ɪ j Literals
Replace interval text... phonesTID fromphone tophone ʊ w Literals
##}

##{ Adapt native aligner output to Spanish phonotactics

##{ Properly interpret güe, güi as /Gwe, Gwi/
for iword from fromword to toword
word$ = Get label of interval... 'wordsTID' iword
if index(word$,"ü") != 0
ini = Get start time of interval... 'wordsTID' iword
end = Get end time of interval... 'wordsTID' iword
pho1 = Get high interval at time... 'phonesTID' ini
pho2 = Get low interval at time... 'phonesTID' end
for ipho from pho1 to pho2
pho$ = Get label of interval... 'phonesTID' ipho
if pho$ = "u"
prevpho$ = Get label of interval... 'phonesTID' ipho-1
nextpho$ = Get label of interval... 'phonesTID' ipho+1
if prevpho$ = "G" and (nextpho$ = "e" or nextpho$ = "i")
Set interval text... 'phonesTID' ipho w
endif
endif
endfor ; from pho1 to pho2
endif
endfor ; to toword
##}

##{ Diphthongs and triphthongs
for int from fromphone to tophone
lab$ = Get label of interval... 'phonesTID' int
if lab$ = "aw" or lab$ = "ew" or lab$ = "ow" or lab$ = "aj" or lab$ = "ej" or lab$ = "oj"
# Bisegmental, not monosegmental diphthongs
nucleus$ = left$(lab$,1)
paravowel$ = right$(lab$,1)
ini = Get start time of interval... 'phonesTID' int
end = Get end time of interval... 'phonesTID' int
mid = (ini+end)/2
Insert boundary... 'phonesTID' mid
Set interval text... 'phonesTID' int 'nucleus$'
if paravowel$ = "j"
Set interval text... 'phonesTID' int+1 j
elsif paravowel$ = "w"
Set interval text... 'phonesTID' int+1 w
endif
int = int+1
tophone = tophone+1
elsif lab$ = "i" or lab$ = "u"
ini = Get start time of interval... 'phonesTID' int
iword = Get interval at time... 'wordsTID' ini
word$ = Get label of interval... 'wordsTID' iword
prev1lab$ = "#"
prev2lab$ = "#"
if int > 2
prev1lab$ = Get label of interval... 'phonesTID' int-1
prev2lab$ = Get label of interval... 'phonesTID' int-2
if prev1lab$ = ""
prev1lab$ = "_"
endif
if prev2lab$ = ""
prev2lab$ = "_"
endif
endif
if (index("eao",prev1lab$) != 0 and index("jw",prev2lab$) != 0)
... or (index("eao",prev1lab$) != 0 and index(word$,"í") = 0 and index(word$,"ú") = 0)
# rising + falling sonority forms a triphthong
# ortho éáó + iu forms a diphthong
if lab$ = "i"
Set interval text... 'phonesTID' int j
elsif lab$ = "u"
Set interval text... 'phonesTID' int w
endif
endif
endif
endfor ; to tophone
##}

##}

##{ Remove punctuation from words tier
for iword from fromword to toword
word$ = Get label of interval... 'wordsTID' iword
if word$ != ""
call removepunct 'word$'
word$ = removepunct.arg$
call removespaces 1 1 1 'word$'
word$ = removespaces.arg$
Set interval text... 'wordsTID' iword 'word$'
endif
endfor ; to nword
##}

##{ Restore silence mark _ where necessary
Replace interval text: phonesTID, 0, 0, "", "_", "Literals"
Replace interval text: wordsTID, 0, 0, "", "_", "Literals"
Replace interval text: orthoTID, 0, 0, "", "_", "Literals"
##}

##{ Create syll tier
if keep_syll = 1
runScript: "syllabify.praat", 'overwrite', "'interval_number$'"
call findtierbyname "phones" 1 1
phonesTID = findtierbyname.return
call findtierbyname "syll" 1 1
syllTID = findtierbyname.return
call findtierbyname "words" 1 1
wordsTID = findtierbyname.return
endif ; keep_syll
##}

##{ Convert SAMPA to IPA transcription
select tg
call toipa phones
if keep_syll = 1
call toipa syll
endif
##}

##{ Leave tiers selected by the user and delete the rest
if keep_phones = 0
call findtierbyname phones 1 1
phonesTID = findtierbyname.return
Remove tier... phonesTID
endif
if keep_words = 0
call findtierbyname words 1 1
wordsTID = findtierbyname.return
Remove tier... wordsTID
endif
# Tier phono is removed by default since it is just an intermediate step for the HTK method of alignment
call findtierbyname phono 0 1
phonoTID = findtierbyname.return
nocheck Remove tier... phonoTID
if keep_ortho = 0
call findtierbyname ortho 1 1
orthoTID = findtierbyname.return
Remove tier... orthoTID
endif
##}

plus so
if open_sound_and_tg
Edit
endif

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
