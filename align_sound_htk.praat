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

# This file also calls and executes HVite, a tool belonging to HTK, which is a software external to Praat,
# developed by the Speech Research Group at the University of Cambridge:
# https://htk.eng.cam.ac.uk/
# The alignment is based on Hidden Markov Models (HMMs) trained with HTK.
# In the current version, this only works for Windows and for Spanish.
# Although this is a limitation, it is more accurate than Praat's native method of alignment.

# This script takes a Sound and a TextGrid with an ortho and a phono tier.
# ortho must contain the transliteration of the sound in conventional Spanish spelling.
# phono must contain the corresponding SAMPA transcription (as the output of the script phonetize_orthotier).
# It yields phones, syll, and words tiers aligned to the contents of the sound.

include auxiliary.praat
nocheck createDirectory ("tmp")

##{ Dialog window
form 3. Align sound (HTK)...
comment Creates 'phones', 'syll', and 'words' tiers from a Sound and a TG with existing 'phono' and 'ortho' tiers
boolean overwrite 1
boolean open_sound_and_tg 1
comment Output tiers
boolean keep_phones 1
boolean keep_syll 1
boolean keep_words 1
boolean keep_ortho 1
endform
##}

##{ Stipulated variables
chars_to_ignore$ = "}-'';(),.Ώ?=+$~[]{}012356789" ; some of these characters might be needed as SAMPA in languages other than Spanish ("4" is retained as Spanish tap)
preptk_threshold = 90 ; miliseconds
precise_endpointing = 0 ; a value of 1 means no initial or final sp
empty$=""
failed_iphonos$ = ""
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

##{ Ensure sampling frequency is 44100
select so
fs = Get sampling frequency
if fs != 44100
if nso = 1
oldfsso = so
so = Resample... 44100 5
Rename... 'name$'
nowarn Save as FLAC file... tmp/'name$'_44100.flac

elsif nloso = 1
pause Attempting to do Resample... 44100   5     If this fails, do it manually.
oldfsso = so
sopart = Extract part... 0 0 yes
newfsso = Resample... 44100 5
nowarn Save as FLAC file... tmp/'name$'_44100.flac
select sopart
plus newfsso
Remove
so = Open long sound file... tmp/'name$'_44100.flac
Rename... 'name$'
endif
endif

if fs != 44100
beginPause ("Keep copies of the original / converted sounds...")
comment ("Sound succesfully resampled to 44100 Hz!")
comment ("The original version will be DELETED from the Objects list.")
comment ("Do you want to keep a copy in the tmp folder of the plugin?")
boolean ("Keep original", 0)
boolean ("Keep resampled", 0)
endPause ("Continue", 1)
if keep_resampled = 0
filedelete tmp/'name$'_44100.flac
endif
select oldfsso
if keep_original = 1
nowarn Save as FLAC file... tmp/'name$'_'fs'.flac
endif
Remove
select so
endif
##}

##{ Ensure TextGrid tiers are properly named and formatted
select tg
ini = Get start time
if ini != 0
Shift to zero
endif

call findtierbyname ortho 0 1
orthoTID = findtierbyname.return
call findtierbyname phono 0 1
phonoTID = findtierbyname.return

if orthoTID = 0
exit The TextGrid must contain one tier named ortho (and another named phono). Exiting...
endif
if phonoTID = 0
exit The TextGrid must contain one tier named ortho and another named phono. Execute step "2. Phonetization" to create phono from ortho, then execute step "3. Align sound (HTK)". Exiting...
endif

# Check if phonoTID and orthoTID have the same boundaries
call checkOrthoAndPhonoTiers
##}

filedelete tmp/reco.log

sampa2htk = Read from file... sampa2htk.Table

hmmfile$ = "lang/spa/spa.hmm"

select tg
nphono = Get number of intervals... 'phonoTID'
first = 1
for iphono from 1 to nphono
select tg
phono$ = Get label of interval... 'phonoTID' 'iphono'

##{ Check if phono and ortho tiers meet conditions for alignment to take place
align_it = 0

if (phono$!="") and (phono$!="_") and (mid$(phono$,1,1)!="%") ; ignore intervals which are empty or silence marks or junk and process the rest

# Remove punctuation
for ichar from 1 to length(chars_to_ignore$)
phono$ = replace$(phono$,mid$(chars_to_ignore$,ichar,1),"",0)
endfor

# Remove exceeding spaces
call removespaces 1 1 1 'phono$'
phono$ = removespaces.arg$

# Check all characters are SAMPA
select sampa2htk
call checksampa2 'phono$'

if checksampa2.isgood = 1
call countwords 'phono$'
npw = countwords.return

select tg
ortho$ = Get label of interval... 'orthoTID' 'iphono'
# Remove punctuation and exceeding spaces
call mystrip 0 0 1 'ortho$'
ortho$ = mystrip.arg$
call countwords 'ortho$'
now = countwords.return

if now = npw ; count of words matches between ortho and phono tiers
align_it = 1
else
# Remove dashes
call mystrip 0 1 1 'ortho$'
ortho$ = mystrip.arg$
call countwords 'ortho$'
now = countwords.return

if now = npw ; count of words matches between ortho and phono tiers
align_it = 1
else
# Add space after quote
call mystrip 1 1 1 'ortho$'
ortho$ = mystrip.arg$
call countwords 'ortho$'
now = countwords.return

if now = npw ; count of words matches between ortho and phono tiers
align_it = 1
endif ; now = npw

endif ; now = npw

endif ; now = npw

endif ; all characters are SAMPA
endif ; ignore intervals which are empty or silence marks _ or junk and process the rest
##}

# Reset temporary files
# .dct is a list of words for that phono interval, matched with their sequence of phones in htk transcription
# .dct is needed as input to HVite
# .lab is a list of words for that phono interval
# .lab (JML) I can't find the exact use in the code, but it is not expendable (probably invoked by the HVite blackbox)
# .rec contains the temporal information and labels for intervals in the phones and words tiers
# .rec is output of HVite and is used to insert boundaries and labels in the corresponding tiers
# .wav is the sound for that phono interval
# .wav is needed as input to HVite
filedelete tmp/'name$'_'iphono'.dct
filedelete tmp/'name$'_'iphono'.lab
filedelete tmp/'name$'_'iphono'.rec
filedelete tmp/'name$'_'iphono'.wav

if align_it = 1

##{ Split phono in words and get the sequence of phones for each word (in htk transcription instead of sampa)
fileappend "tmp/'name$'_'iphono'.dct" sp'tab$'sp'newline$'
if precise_endpointing = 0
fileappend "tmp/'name$'_'iphono'.lab" sp'newline$'
endif

# Iterate each word in phono
curphonoword$ = ""
while length(phono$) > 0
select tg

phonospace = index(phono$," ")
if phonospace = 0
curphonoword$ = phono$
phono$ = ""
else 
curphonoword$ = mid$(phono$,1,phonospace-1)
phono$ = mid$(phono$,phonospace+1,length(phono$)-phonospace)
endif

orthospace = index(ortho$," ")
if phonospace = 0 ; orthospace?
curorthoword$ = ortho$
ortho$ = ""
else 
curorthoword$ = mid$(ortho$,1,orthospace-1)
ortho$ = mid$(ortho$,orthospace+1,length(ortho$)-orthospace)
endif
curword$ = curorthoword$

# Remove diacritics
call dediacritize 'curword$'
curword$ = dediacritize.s$
fileappend "tmp/'name$'_'iphono'.lab" 'curword$''newline$'

if length(phono$) = 0 and precise_endpointing = 1
final_space = 0
else
final_space = 1
endif

# Write file with htk sequence of segments for all words in the phono interval
select sampa2htk
call addwordtodct 'final_space' 'curphonoword$'

endwhile ; length(phono$) > 0
##}

##{ Create temporary wav for that phono interval
select tg
phonoini = Get start time of interval... 'phonoTID' 'iphono'
phonoend = Get end time of interval... 'phonoTID' 'iphono'
select so
if nso=1
sopart = Extract part... 'phonoini' 'phonoend' Rectangular 1 no
elsif nloso=1
sopart = Extract part... 'phonoini' 'phonoend' no
endif
Scale peak... 0.99
Save as WAV file... tmp/'name$'_'iphono'.wav
Remove
##}

##{ Execute HMM with HTK
t1$=""
system HVite -A 't1$' 'empty$' -a -m -C analysis.cfg  -H "'hmmfile$'" -t 250 "tmp/'name$'_'iphono'.dct" lang/spa/spaphone.list "tmp/'name$'_'iphono'.wav" >> "tmp/reco.log"  2>&1
##}

endif ; align_it = 1

select tg
if first = 1
first = 0

##{ Create words tier
call findtierbyname words 0 1
wordsTID = findtierbyname.return

if wordsTID = 0
wordsTID = 1
Insert interval tier... 'wordsTID' words
elsif wordsTID != 0 and overwrite = 1
Remove tier... 'wordsTID'
wordsTID = 1
Insert interval tier... 'wordsTID' words
elsif wordsTID != 0 and overwrite = 0
Set tier name... 'wordsTID' wordsbak
wordsTID = 1
Insert interval tier... 'wordsTID' words
endif
##}

##{ Create phones tier
call findtierbyname phones 0 1
phonesTID = findtierbyname.return

if phonesTID = 0
phonesTID = 1
Insert interval tier... 'phonesTID' phones
elsif phonesTID != 0 and overwrite = 1
Remove tier... 'phonesTID'
phonesTID = 1
Insert interval tier... 'phonesTID' phones
elsif phonesTID != 0 and overwrite = 0
Set tier name... 'phonesTID' phonesback
phonesTID = 1
Insert interval tier... 'phonesTID' phones
endif
##}

##{ Get tier IDs (to be able to select them)
call findtierbyname words 0 1
wordsTID = findtierbyname.return
call findtierbyname ortho 1 1
orthoTID = findtierbyname.return
call findtierbyname phono 1 1
phonoTID = findtierbyname.return
##}

endif ; first = 1

# Insert boundaries and set texts in phones and words tiers
phonoini = Get start time of interval... 'phonoTID' 'iphono' ; this is necessary in the case of silent intervals, which have not undergone align_it
call getrec "tmp/'name$'_'iphono'.rec" 'phonesTID' 'wordsTID' 'phonoini'

# Reset temporary files
filedelete tmp/'name$'_'iphono'.dct
filedelete tmp/'name$'_'iphono'.lab
filedelete tmp/'name$'_'iphono'.rec
filedelete tmp/'name$'_'iphono'.wav
endfor ; to nphono

filedelete tmp/reco.log

select sampa2htk
Remove

##{ Attempt native alignment for failed iphono(s)
# In procedure getrec a string has been assembled with phono interval numbers
# that are not a silence mark and which failed to produce a .rec file in HTK
if failed_iphonos$ != ""
while failed_iphonos$ != ""
ibar = index(failed_iphonos$,"_")
iphono$ = mid$(failed_iphonos$,1,ibar-1)
failed_iphonos$ = mid$(failed_iphonos$,ibar+1,length(failed_iphonos$)-ibar)
ibar = index(failed_iphonos$,"_")

# Native alignment is invoked as a last resource only for those intervals, in order to fill in words and phones
select so
plus tg
runScript: "align_sound_native.praat", "yes", "no", "yes", "no", "yes", "yes", "'iphono$'"
endwhile
select tg
call findtierbyname "phones" 1 1
phonesTID = findtierbyname.return
call findtierbyname "words" 1 1
wordsTID = findtierbyname.return
call findtierbyname "phono" 1 1
phonoTID = findtierbyname.return
call findtierbyname "ortho" 1 1
orthoTID = findtierbyname.return
endif
##}

##{ Extract initial and final pauses from phono and ortho segments
select tg
iphono = 1

while iphono <= nphono

phonoini = Get start time of interval... 'phonoTID' 'iphono'
phonoend = Get end time of interval... 'phonoTID' 'iphono'
phono$ = Get label of interval... 'phonoTID' 'iphono'
ortho$ = Get label of interval... 'orthoTID' 'iphono'
    
# Get info of first phone within phono
iphone = Get interval at time... 'phonesTID' 'phonoini'
phoneend = Get end time of interval... 'phonesTID' 'iphone'
phone$ = Get label of interval... 'phonesTID' 'iphone'

# In case there is an initial silence phone within phono
if phone$ = "_" and phoneend < phonoend ; meaning it is not the case that the whole phono is a silence
# Insert aligned silences in phono and ortho
Insert boundary... 'orthoTID' 'phoneend'
Set interval text... 'orthoTID' 'iphono' _
Insert boundary... 'phonoTID' 'phoneend'
Set interval text... 'phonoTID' 'iphono' _
# Recalculate counters after new boundary insertion
iphono = iphono + 1
nphono = nphono + 1
# Readjust the interval with speech
Set interval text... 'orthoTID' 'iphono' 'ortho$'
Set interval text... 'phonoTID' 'iphono' 'phono$'
endif ; phone$ = "_"

# Get info of first phone after phono
iphone = Get interval at time... 'phonesTID' 'phonoend'

if iphone > 1 ; meaning there is more than one phone in the whole TextGrid
# Get info of last phone within phono
prevphone = iphone-1
prevphoneini = Get start time of interval... 'phonesTID' 'prevphone'
prevphone$ = Get label of interval... 'phonesTID' 'prevphone'

# In case there is a final silence phone within phono
if prevphone$ = "_" and prevphoneini > phonoini ; meaning it is not the case that the whole phono is a silence
# Readjust the interval with speech
Insert boundary... 'orthoTID' 'prevphoneini'
Insert boundary... 'phonoTID' 'prevphoneini'
# Recalculate counters after new boundary insertion
iphono=iphono+1
nphono=nphono+1
# Insert aligned silences in phono and ortho
Set interval text... 'orthoTID' 'iphono' _
Set interval text... 'phonoTID' 'iphono' _
endif ; prevphone$ = "_"
endif ; there is more than one phone in the whole TextGrid

# Move to next iphono iteration
iphono = iphono + 1
endwhile ; iphono <= nphono
##}

##{ Merge contiguous silences
select tg
nphone = Get number of intervals... 'phonesTID'
lastphone$ = Get label of interval... 'phonesTID' 'nphone'
nphono = Get number of intervals... 'phonoTID'
lastphono$ = Get label of interval... 'phonoTID' 'nphono'

for i from 1 to nphone-1
# This loop is used for a backward iteration over phones
iphone1 = nphone - i
phone1ini = Get start time of interval... 'phonesTID' 'iphone1'
phone1$ = Get label of interval... 'phonesTID' 'iphone1'
iphone2 = iphone1 + 1
phone2ini = Get start time of interval... 'phonesTID' 'iphone2'
iphono1 = Get interval at time... 'phonoTID' 'phone1ini'
phonoini = Get start time of interval... 'phonoTID' 'iphono1'
phono$ = Get label of interval... 'phonoTID' 'iphono1'

if (lastphone$ = "_") and (phone1$ = "_") and (lastphono$ = "_") and (phono$ = "_") and (phone1ini = phonoini)
# phones
Remove left boundary... 'phonesTID' 'iphone2'
Set interval text... 'phonesTID' 'iphone1' _

# words
iword2 = Get interval at time... 'wordsTID' 'phone2ini'
Set interval text... 'wordsTID' 'iword2'
Remove left boundary... 'wordsTID' 'iword2'

# phono
iphono2 = Get interval at time... 'phonoTID' 'phone2ini'
Set interval text... 'phonoTID' 'iphono2'
Remove left boundary... 'phonoTID' 'iphono2'

# ortho
iortho2 = Get interval at time... 'orthoTID' 'phone2ini'
Set interval text... 'orthoTID' 'iortho2'
Remove left boundary... 'orthoTID' 'iortho2'
endif

# Update which is considered last
lastphone$ = phone1$
lastphono$ = phono$
endfor
##}

##{ Consider previous silence not as a pause but as part of a stop consonant when duration is under stipulated threshold
# Express threshold in seconds
preptk_threshold = preptk_threshold / 1000
# Initialize variables
prevphone$ = ""
prevphonedur = 0

nphone = Get number of intervals... 'phonesTID'
iphone = 1
while iphone <= nphone
phone$ = Get label of interval... 'phonesTID' 'iphone'
phoneini = Get start time of interval... 'phonesTID' 'iphone'
phoneend = Get end time of interval... 'phonesTID' 'iphone'
phonedur = phoneend - phoneini

if (phone$ = "p" or phone$ = "t" or phone$ = "k") and prevphone$ = "_" and (prevphonedur < preptk_threshold)
#phones
Remove boundary at time... 'phonesTID' 'phoneini'
# Recalculate counters after boundary removal
iphone = iphone-1
nphone = nphone-1
Set interval text... 'phonesTID' 'iphone' 'phone$'

#words
iword = Get interval at time... 'wordsTID' 'phoneini'
word$ = Get label of interval... 'wordsTID' 'iword'
Remove boundary at time... 'wordsTID' 'phoneini'
iword = iword-1
Set interval text... 'wordsTID' 'iword' 'word$'
endif

# Update what is considered previous
prevphone$ = phone$
prevphonedur = phonedur
# Move to next iphone iteration
iphone = iphone+1
endwhile

# Express threshold back in miliseconds
preptk_threshold = preptk_threshold * 1000
##}

##{ Restore silence mark _ where necessary
Replace interval text: phonesTID, 0, 0, "", "_", "Literals"
Replace interval text: wordsTID, 0, 0, "", "_", "Literals"
Replace interval text: orthoTID, 0, 0, "", "_", "Literals"
##}

##{ Create syll tier
if keep_syll = 1
runScript: "syllabify.praat", 'overwrite', ""
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

# End of script

procedure addwordtodct .final_space .w$
call convertsampatohtk '.w$'
if .final_space = 1
.sp$ = " sp"
else
.sp$ = ""
endif
.wout$ = replace$(convertsampatohtk.wout$," ","",1)
fileappend "tmp/'name$'_'iphono'.dct" 'curword$''tab$''.wout$''.sp$''newline$'
endproc

procedure checkOrthoAndPhonoTiers
# Check if phonoTID and orthoTID have the same boundaries
.nint_phono = Get number of intervals... phonoTID
.nint_ortho = Get number of intervals... orthoTID
if .nint_phono != .nint_ortho
exit phono and ortho tiers should have the same number of intervals. Exiting...
endif
for .int from 1 to .nint_phono
.ini_phono = Get start time of interval... phonoTID .int
.ini_ortho = Get start time of interval... orthoTID .int
if .ini_phono != .ini_ortho
exit Starting points of interval '.int' differ in phono and ortho tiers ('.ini_phono:3', '.ini_ortho:3'). Exiting...
endif
endfor
endproc

procedure checksampa2 .s$
.n = length(.s$)
.i = 1
.isgood = 1
while (.i <= .n) and (.isgood = 1)
.convrow = 0
if (.convrow = 0) and (.i < .n)
.c2$ = mid$(.s$,.i,2)
.convrow = Search column... sampa '.c2$'
if .convrow != 0
.i=.i+1
endif
endif
if (.convrow = 0)
.c2$ = mid$(.s$,.i,1)
.convrow = Search column... sampa '.c2$'
if .convrow = 0
.isgood = 0
endif
endif
.i=.i+1
endwhile
endproc

procedure convertsampatohtk .w$
  .wout$=""
  for .ii to length(.w$)
    .convrow=0
    if .ii<length(.w$)-2
      .c2$=mid$(.w$,.ii,4)
      .convrow = Search column... sampa '.c2$'
      if .convrow!=0
        .c2$=Get value... '.convrow' htk
        .ii=.ii+3
      endif
    endif
    if (.convrow=0) and (.ii<length(.w$)-1)
      .c2$=mid$(.w$,.ii,3)
      .convrow = Search column... sampa '.c2$'
      if .convrow!=0
        .c2$=Get value... '.convrow' htk
        .ii=.ii+2
      endif
    endif
    if (.convrow=0) and (.ii<length(.w$))
      .c2$=mid$(.w$,.ii,2)
      .convrow = Search column... sampa '.c2$'
      if .convrow!=0
        .c2$=Get value... '.convrow' htk
        .ii=.ii+1
      endif
    endif
    if (.convrow=0)
      .c2$=mid$(.w$,.ii,1)
      .convrow = Search column... sampa '.c2$'
      if .convrow!=0
        .c2$=Get value... '.convrow' htk
      endif
    endif
    .wout$=.wout$+" "+.c2$
  endfor
endproc

procedure countwords .arg$
.return=0
while length(.arg$) > 0 ; this loop is safe under 300 iterations
.isp = index(.arg$," ") ; index of space char
.return = .return+1
if .isp = 0
.arg$ = ""
else 
.arg$ = mid$(.arg$,.isp+1,length(.arg$)-.isp)
endif
endwhile
endproc

procedure dediacritize .s$
# Characters are converted into their corresponding octal codes
.s$=replace_regex$(.s$,"č","\\304\\215",0)
.s$=replace_regex$(.s$,"Ľ","\\304\\275",0)
.s$=replace_regex$(.s$,"ľ","\\304\\276",0)
.s$=replace_regex$(.s$,"š","\\305\\241",0)
.s$=replace_regex$(.s$,"ť","\\305\\245",0)
.s$=replace_regex$(.s$,"Ž","\\305\\275",0)
.s$=replace_regex$(.s$,"ž","\\305\\276",0)
.s$=replace_regex$(.s$,"à","\\340",0)
.s$=replace_regex$(.s$,"á","\\341",0)
.s$=replace_regex$(.s$,"â","\\342",0)
.s$=replace_regex$(.s$,"ã","\\343",0)
.s$=replace_regex$(.s$,"ä","\\344",0)
.s$=replace_regex$(.s$,"å","\\345",0)
.s$=replace_regex$(.s$,"æ","\\346",0)
.s$=replace_regex$(.s$,"ç","\\347",0)
.s$=replace_regex$(.s$,"è","\\350",0)
.s$=replace_regex$(.s$,"é","\\351",0)
.s$=replace_regex$(.s$,"ê","\\352",0)
.s$=replace_regex$(.s$,"ë","\\353",0)
.s$=replace_regex$(.s$,"ì","\\354",0)
.s$=replace_regex$(.s$,"í","\\355",0)
.s$=replace_regex$(.s$,"î","\\356",0)
.s$=replace_regex$(.s$,"ï","\\357",0)
.s$=replace_regex$(.s$,"ñ","\\361",0)
.s$=replace_regex$(.s$,"ò","\\362",0)
.s$=replace_regex$(.s$,"ó","\\363",0)
.s$=replace_regex$(.s$,"ô","\\364",0)
.s$=replace_regex$(.s$,"õ","\\365",0)
.s$=replace_regex$(.s$,"ö","\\366",0)
.s$=replace_regex$(.s$,"ù","\\371",0)
.s$=replace_regex$(.s$,"ú","\\372",0)
.s$=replace_regex$(.s$,"û","\\373",0)
.s$=replace_regex$(.s$,"ü","\\374",0)
.s$=replace_regex$(.s$,"ý","\\375",0)      
endproc

procedure diacritize .s$
# Characters are restored from their corresponding octal codes
.s$=replace_regex$(.s$,"\\304\\215","č",0)
.s$=replace_regex$(.s$,"\\304\\275","Ľ",0)
.s$=replace_regex$(.s$,"\\304\\276","ľ",0)
.s$=replace_regex$(.s$,"\\305\\241","š",0)
.s$=replace_regex$(.s$,"\\305\\245","ť",0)
.s$=replace_regex$(.s$,"\\305\\275","Ž",0)
.s$=replace_regex$(.s$,"\\305\\276","ž",0)
.s$=replace_regex$(.s$,"\\301","Á",0)
.s$=replace_regex$(.s$,"\\311","É",0)
.s$=replace_regex$(.s$,"\\315","Í",0)
.s$=replace_regex$(.s$,"\\321","Ñ",0)
.s$=replace_regex$(.s$,"\\323","Ó",0)
.s$=replace_regex$(.s$,"\\332","Ú",0)
.s$=replace_regex$(.s$,"\\334","Ü",0)
.s$=replace_regex$(.s$,"\\340","à",0)
.s$=replace_regex$(.s$,"\\341","á",0)
.s$=replace_regex$(.s$,"\\342","â",0)
.s$=replace_regex$(.s$,"\\343","ã",0)
.s$=replace_regex$(.s$,"\\344","ä",0)
.s$=replace_regex$(.s$,"\\345","å",0)
.s$=replace_regex$(.s$,"\\346","æ",0)
.s$=replace_regex$(.s$,"\\347","ç",0)
.s$=replace_regex$(.s$,"\\350","è",0)
.s$=replace_regex$(.s$,"\\351","é",0)
.s$=replace_regex$(.s$,"\\352","ê",0)
.s$=replace_regex$(.s$,"\\353","ë",0)
.s$=replace_regex$(.s$,"\\354","ì",0)
.s$=replace_regex$(.s$,"\\355","í",0)
.s$=replace_regex$(.s$,"\\356","î",0)
.s$=replace_regex$(.s$,"\\357","ï",0)
.s$=replace_regex$(.s$,"\\361","ñ",0)
.s$=replace_regex$(.s$,"\\362","ò",0)
.s$=replace_regex$(.s$,"\\363","ó",0)
.s$=replace_regex$(.s$,"\\364","ô",0)
.s$=replace_regex$(.s$,"\\365","õ",0)
.s$=replace_regex$(.s$,"\\366","ö",0)
.s$=replace_regex$(.s$,"\\371","ù",0)
.s$=replace_regex$(.s$,"\\372","ú",0)
.s$=replace_regex$(.s$,"\\373","û",0)
.s$=replace_regex$(.s$,"\\374","ü",0)
.s$=replace_regex$(.s$,"\\375","ý",0)
endproc

procedure getrec recfile$ phonesTID wordsTID phonoini
if fileReadable(recfile$)
# Load rec info
rec$ < 'recfile$'

##{ Initialize variables
position_in_rec_line = 0
start_a_new_line = 0
intervalini = 0
intervalend = 0
iword = 0
wordsalready = 0
##}

while length(rec$) > 0 ; this loop is safe under 4000 iterations

##{ Reset variables at every new rec line
if start_a_new_line = 1
position_in_rec_line = 0
start_a_new_line = 0
endif
##}

##{ Get next piece of information from rec
isp = index(rec$," ") ; index of space char
inl = index(rec$,newline$) ; index of newline char
if isp > 0 and (isp < inl or inl = 0)
nextbreak = isp
position_in_rec_line = position_in_rec_line+1
elsif inl > 0 and (inl < isp or isp = 0)
nextbreak = inl
position_in_rec_line = position_in_rec_line+1
start_a_new_line = 1
endif

current_rec_info$ = mid$(rec$,1,nextbreak-1)
rec$ = mid$(rec$,nextbreak+1,length(rec$)-nextbreak)
##}

##{ Get temporal information
if position_in_rec_line = 1
intervalini = 'current_rec_info$'/10000000
elsif position_in_rec_line = 2
intervalend = 'current_rec_info$'/10000000
endif
##}

##{ Insert phones in tier
if position_in_rec_line = 3 and intervalini!=intervalend
# In rec some lines are devoted to word boundaries (marked as sp), but those have intervalini = intervalend.
# Those are not processed.

# JML: I don't know why we should apply this shift.
# This causes a shift in all starts except that of the first interval within each phono,
# such that the first interval has a duration increased by 0.015, and the rest remain intact but shifted to the right.
if intervalini!=0
intervalini = intervalini+0.015
endif

# Temporal information in rec is relative within phono, so it must be counted from phonoini
intervalini = phonoini + intervalini
intervalend = phonoini + intervalend

# This condition avoids the error that would result if attempting to insert a boundary at the very beginning of the TextGrid
# (if the first phono with some content started at phonini = 0)
if intervalini > 0
Insert boundary... 'phonesTID' 'intervalini'
endif

iphone = Get interval at time... 'phonesTID' 'intervalini'

if current_rec_info$ = "sp"
# Apart from sp marking word boundaries (which are not processed),
# some unexpected silences may have been found between segments during recognition, and those are assigned some duration,
# so they will be processed (segmented and transcribed).
Set interval text... 'phonesTID' 'iphone' _
if intervalini != phonoini
Insert boundary... 'wordsTID' 'intervalini'
spuriousword = iword+1
Set interval text... 'wordsTID' 'spuriousword' _
endif

else ; current_rec_info$ != "sp" (meaning it has some phone as a content)
select sampa2htk
phonerow = Search column... htk 'current_rec_info$'
if phonerow != 0
current_rec_info$ = Get value... 'phonerow' sampa
endif
select tg
Set interval text... 'phonesTID' 'iphone' 'current_rec_info$'
endif

endif
##}

##{ Insert words in tier
if position_in_rec_line = 5 and intervalini!=intervalend

# Insert boundary (except if this coincides with the beginning of phono)
if intervalini > 0
Insert boundary... 'wordsTID' 'intervalini'
endif
iword = Get interval at time... 'wordsTID' 'intervalini'

# Write silence if it has been recognized at the beginning of phono
if (wordsalready = 0) and (current_rec_info$ = "sp")
current_rec_info$ = "_"
endif
wordsalready = wordsalready+1

# Restore regular spelling from rec output
call diacritize 'current_rec_info$'
current_rec_info$ = diacritize.s$
# current_rec_info$ = replace$(current_rec_info$,"\277","¿",0)
# current_rec_info$ = replace$(current_rec_info$,"\241","¡",0)

if current_rec_info$ = "sil"
current_rec_info$ = "_"
endif

Set interval text... 'wordsTID' 'iword' 'current_rec_info$'
endif
##}

endwhile ; length(rec$) > 0

elsif ! fileReadable(recfile$)
if phonoini != 0
Insert boundary... 'phonesTID' 'phonoini'
iphone = Get interval at time... 'phonesTID' 'phonoini'
Set interval text... 'phonesTID' 'iphone' _
Insert boundary... 'wordsTID' 'phonoini'
iword = Get interval at time... 'wordsTID' 'phonoini'
Set interval text... 'wordsTID' 'iword' _
endif
if phono$ != "_"
# This string keeps record of phono intervals that failed to produce a .rec file in HTK
# (excluding those that are just a silence mark)
# This will be used later to invoke native alignment as a last resource just for those intervals
failed_iphonos$ = failed_iphonos$ + "'iphono'_"
endif
endif ; recfile is readable, or not

endproc
