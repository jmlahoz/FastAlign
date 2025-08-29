# FastAlign
# José María Lahoz-Bengoechea (jmlahoz@ucm.es)
# Version 2025-06-10

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

##{ Check selection of interval number
interval_number = number(interval_number$)
if interval_number <= 0 or round(interval_number) != interval_number
exit Interval number must be a positive whole number. Exiting...
endif
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

##{ Ensure Sound is mono
select so
if nso = 1
nch=Get number of channels
if nch=2
stereoso = so
so = Convert to mono
Rename... 'name$'
nowarn Save as FLAC file... tmp/'name$'_mono.flac
endif

elsif nloso = 1
loso_info$ = Info
nch = extractNumber(loso_info$,"Number of channels: ")
if nch=2
beginPause ("Convert to mono...")
comment ("Attempting to convert Sound to mono. If this fails, do it manually.")
comment ("Which channel do you want to extract?")
optionMenu ("Channel", 1)
option ("Left")
option ("Right")
option ("Merge both")
endPause ("Continue",1)
stereoso = so
sopart = Extract part... 0 0 yes
if channel = 3
monoso = Convert to mono
elsif channel = 1 or channel = 2
monoso = Extract one channel... channel
endif
nowarn Save as FLAC file... tmp/'name$'_mono.flac
select sopart
plus monoso
Remove
so = Open long sound file... tmp/'name$'_mono.flac
Rename... 'name$'
endif
endif

if nch = 2
beginPause ("Keep copies of the stereo / mono versions...")
comment ("Sound succesfully converted to mono!")
comment ("The stereo version will be DELETED from the Objects list.")
comment ("Do you want to keep a copy in the tmp folder of the plugin?")
boolean ("Keep mono", 0)
boolean ("Keep stereo", 0)
endPause ("Continue", 1)
if keep_mono = 0
filedelete tmp/'name$'_mono.flac
endif
select stereoso
if keep_stereo = 1
nowarn Save as FLAC file... tmp/'name$'_stereo.flac
endif
Remove
select so
endif
##}

##{ Apply native alignment
select so
plus tg
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
# Make silent intervals really empty
Set interval text... 'orthoTID' int 
endif
ini = Get start time of interval... 'orthoTID' int
editor TextGrid 'name$'
Move cursor to... ini
# Specify language settings
if int = fromortho
if praatVersion >= 6036
Alignment settings: "Spanish (Spain)", "yes", "yes", "yes"
else
Alignment settings: "Spanish", "yes", "yes", "yes"
endif
endif
# Apply native alignment
nowarn Align interval
if int = toortho
Close
endif
endeditor
endfor ; int

# Remove the temporary copy of ortho tier if that had been necessary
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
Replace interval text... phonesTID fromphone tophone ʝ jj Literals
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
for iphone from fromphone to tophone
phone$ = Get label of interval... 'phonesTID' iphone
if phone$ = "aw" or phone$ = "ew" or phone$ = "ow" or phone$ = "aj" or phone$ = "ej" or phone$ = "oj"
# Bisegmental, not monosegmental diphthongs
nucleus$ = left$(phone$,1)
paravowel$ = right$(phone$,1)
phoneini = Get start time of interval... 'phonesTID' iphone
phoneend = Get end time of interval... 'phonesTID' iphone
phonemid = (phoneini+phoneend)/2
Insert boundary... 'phonesTID' phonemid
Set interval text... 'phonesTID' iphone 'nucleus$'
if paravowel$ = "j"
Set interval text... 'phonesTID' iphone+1 j
elsif paravowel$ = "w"
Set interval text... 'phonesTID' iphone+1 w
endif
iphone = iphone+1 ; due to boundary insertion
tophone = tophone+1 ; due to boundary insertion
elsif phone$ = "i" or phone$ = "u"
phoneini = Get start time of interval... 'phonesTID' iphone
iword = Get low interval at time... 'wordsTID' phoneini
jword = Get high interval at time... 'wordsTID' phoneini
word$ = Get label of interval... 'wordsTID' iword
prev1phone$ = "#"
prev2phone$ = "#"
if iphone-2 >= fromphone
prev1phone$ = Get label of interval... 'phonesTID' iphone-1
prev2phone$ = Get label of interval... 'phonesTID' iphone-2
if prev1phone$ = ""
prev1phone$ = "_"
endif
if prev2phone$ = ""
prev2phone$ = "_"
endif
endif
if (index("jw",prev2phone$) != 0 and index("eao",prev1phone$) != 0)
... or (index("eao",prev1phone$) != 0 and index(word$,"í") = 0 and index(word$,"ú") = 0)
# rising + falling sonority forms a triphthong
# ortho éáó + iu forms a diphthong
if iword = jword ; only when those sequences occur word-internally
if phone$ = "i"
Set interval text... 'phonesTID' iphone j
elsif phone$ = "u"
Set interval text... 'phonesTID' iphone w
endif
endif
endif
endif
endfor ; to tophone
##}

##{ Rising diphthongs after consonant clusters
for iphone from fromphone to tophone
phone$ = Get label of interval... 'phonesTID' iphone
if (phone$ = "i" or phone$ = "u") and iphone-2 >= fromphone and iphone+1 <= tophone
prev2phone$ = Get label of interval... 'phonesTID' iphone-2
prev1phone$ = Get label of interval... 'phonesTID' iphone-1
nextphone$ = Get label of interval... 'phonesTID' iphone+1
phoneend = Get end time of interval... 'phonesTID' iphone
iword = Get low interval at time... 'wordsTID' 'phoneend'
jword = Get high interval at time... 'wordsTID' 'phoneend'
word$ = Get label of interval... 'wordsTID' iword
iseq$ = prev2phone$ + prev1phone$ + "í" + nextphone$
useq$ = prev2phone$ + prev1phone$ + "ú" + nextphone$
iseq$ = replace$(iseq$,"k","c",0)
iseq$ = replace$(iseq$,"B","b",0)
iseq$ = replace$(iseq$,"D","d",0)
iseq$ = replace$(iseq$,"G","g",0)
iseq$ = replace$(iseq$,"4","r",0)
useq$ = replace$(useq$,"k","c",0)
useq$ = replace$(useq$,"B","b",0)
useq$ = replace$(useq$,"D","d",0)
useq$ = replace$(useq$,"G","g",0)
useq$ = replace$(useq$,"4","r",0)

if index("aeiou",nextphone$) != 0
... and iword = jword
... and ((phone$ = "i" and index(word$,iseq$) = 0) or (phone$ = "u" and index(word$,useq$) = 0))
... and index("ptkBDGf",prev2phone$) != 0
... and index("l4",prev1phone$) != 0
Replace interval text... phonesTID iphone iphone i j Literals
Replace interval text... phonesTID iphone iphone u w Literals
endif ; nextphone$ is a vowel, within the same word, and /i, u/ are not stressed (all after a consonant cluster)
endif ; phone$ = "i" or phone$ = "u"
endfor ; to tophone
##}

##{ Sonority valleys
# Keep word-final palatal paravowel from consonantizing before vowel-initial word (eg. "muy a menudo" -/-> "mu ya menudo")
for iphone from fromphone to tophone
phone$ = Get label of interval... 'phonesTID' iphone
if phone$ = "j" and iphone+1 <= tophone
nextphone$ = Get label of interval... 'phonesTID' iphone+1
if nextphone$ = "j"
phoneend = Get end time of interval... 'phonesTID' iphone
Remove boundary at time... 'phonesTID' phoneend
Set interval text... 'phonesTID' iphone j
tophone = tophone - 1 ; due to boundary removal
endif ; nextphone$ = "j"
endif ; phone$ = "j"
endfor ; to tophone
##}

##{ Phonemic transcription of /n/ before labial
for iphone from fromphone to tophone
phone$ = Get label of interval... 'phonesTID' iphone
if phone$ = "m" and iphone+1 <= tophone

nextphone$ = Get label of interval... 'phonesTID' iphone+1
if (nextphone$ = "_" or nextphone$ = "") and iphone+2 <= tophone
# This prevents miscalculations in case of automatic estimation of silence between phones
nextphone$ = Get label of interval... 'phonesTID' iphone+2
endif
phoneend = Get end time of interval... 'phonesTID' iphone
iword = Get low interval at time... 'wordsTID' phoneend
jword = Get high interval at time... 'wordsTID' phoneend
word$ = Get label of interval... 'wordsTID' iword

if nextphone$ = "f"
... and (iword = jword or right$(word$,1) != "m")
# [mf] is /nf/ except if there is a word boundary and the first word ends in /m/ (eg. curriculum)
Set interval text... 'phonesTID' iphone n
elsif nextphone$ = "B"
... and ((iword = jword and index(word$,"mb") = 0) or (iword != jword and right$(word$,1) != "m"))
# [mb] is /nB/ except when spelled "mb" word-internally (otherwise, "nv"), or across words if the first word ends in /m/
Set interval text... 'phonesTID' iphone n
elsif nextphone$ = "p"
... and (iword != jword and right$(word$,1) != "m")
# [mp] is /np/ across words except if the first word ends in /m/; it is always /mp/ word-internally
Set interval text... 'phonesTID' iphone n
endif ; nextphone$ is labial

endif ; phone$ = "m"
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
# call findtierbyname phono 0 1
# phonoTID = findtierbyname.return
# nocheck Remove tier... phonoTID
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

##{ align_selected_interval
# This transfers boundaries and labels from a temporary tier (origin) to a definitive tier (destiny)
# The transfer is done only for a certain temporal range,
# while preserving any other information previously existing on the destiny tier
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
##}
