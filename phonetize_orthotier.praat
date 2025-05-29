# Fast-Align
# José María Lahoz-Bengoechea (jmlahoz@ucm.es)
# Version 2025-05-03

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

# This file also calls and executes SAGA, a software external to Praat,
# developed by José B. Mariño and Albino Nogueiras Rodríguez,
# licensed under the GNU General Public License (version 3)
# and publicly available here: https://github.com/TALP-UPC/saga

# This script takes a Sound and a TextGrid with an ortho tier
# consisting of a transliteration of the sound in conventional Spanish spelling
# and it creates an additional phono tier with its corresponding SAMPA transcription.

# Ortho intervals starting with % are treated as comments and left blank in phono.
# The symbol % placed anywhere else causes errors or ommissions on local segments within the interval.
# The symbol - placed right after a word without intervening space makes the transcription fail for the entire TextGrid.
# The symbol & as a word on its own or right before a word without intervening space makes the transcription fail for the entire TextGrid.

include auxiliary.praat

##{ Dialog window
form 2. Phonetization...
comment Creates 'phono' tier from a Sound and a TG with an existing 'ortho' tier
boolean overwrite 1
boolean open_sound_and_tg 1
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

select tg
call textEncodingPreferences

##{ Write "_" in silent intervals
select tg
call findtierbyname ortho 1 1
orthoTID = findtierbyname.return
nint = Get number of intervals... 'orthoTID'

for int from 1 to nint
lab$ = Get label of interval... 'orthoTID' 'int'
if lab$ = ""
lab$ = "_"
Set interval text... 'orthoTID' 'int' 'lab$'
endif
endfor
##}

##{ Turn uppercase into lowercase to prepare phonetization
# Duplicate ortho tier to keep a copy of the original. This will be restored after processing.
Duplicate tier... orthoTID orthoTID+1 ortho2
call findtierbyname ortho2 1 1
ortho2TID = findtierbyname.return

# Conversion of diacritized letters to lowercase.
Replace interval text... orthoTID 0 0 Á á Literals
Replace interval text... orthoTID 0 0 É é Literals
Replace interval text... orthoTID 0 0 Í í Literals
Replace interval text... orthoTID 0 0 Ó ó Literals
Replace interval text... orthoTID 0 0 Ú ú Literals
Replace interval text... orthoTID 0 0 Ü ü Literals
Replace interval text... orthoTID 0 0 Ñ ñ Literals

# Conversion of other letters to lowercase (in this case, we can use regular expressions).
for int from 1 to nint
lab$ = Get label of interval... 'orthoTID' 'int'
call mystrip 0 0 1 'lab$'
lab$ = mystrip.arg$
if index(lab$,newline$) != 0
lab$ = replace_regex$(lab$,newline$," ",0)
endif
lab$ = replace_regex$(lab$,".*","\L&",1)
Set interval text... 'orthoTID' 'int' 'lab$'
endfor
##}

##{ Create phono tier as a duplicate of ortho
call findtierbyname phono 0 1
phonoTID=findtierbyname.return

if phonoTID = 0
phonoTID = 1
Duplicate tier... 'orthoTID' 'orthoTID' phono
elsif phonoTID != 0 and overwrite = 1
Remove tier... 'phonoTID'
if phonoTID < orthoTID
orthoTID = orthoTID-1
endif
Duplicate tier... 'orthoTID' 'orthoTID' phono
elsif phonoTID != 0 and overwrite = 0
Set tier name... 'phonoTID' phonobak
Duplicate tier... 'orthoTID' 'orthoTID' phono
endif

call findtierbyname phono 1 1
phonoTID = findtierbyname.return
call findtierbyname ortho 1 1
orthoTID = findtierbyname.return
call findtierbyname ortho2 1 1
ortho2TID = findtierbyname.return
##}

##{ Convert conventional Spanish spelling to SAMPA and write results to the corresponding phono intervals

# Extract phono intervals as strings
phonotier = Extract tier... 'phonoTID'
phonotable = Down to TableOfReal (any)
phonostr1 = Extract row labels as Strings

# Reset temporary files
createDirectory ("tmp")
filedelete tmp/tout.txt

Text writing preferences... try ISO Latin-1, then UTF-16
Text reading preferences... try UTF-8, then ISO Latin-1

# Suppress uppercase for SAGA
phonostr2 = Change... .* \L& 0 Regular Expressions

Write to raw text file... tmp/t.txt

# Execute phonetization with SAGA
# This only works with backslash to indicate directories
system lang\spa\saga.exe -MX tmp\t.txt tmp\tout.txt

# Adapt SAGA output to Spanish SAMPA
phonostr3 = Read Strings from raw text file... tmp/tout.txt.fon
phonostr4 = Change... r 4 0 Literals
phonostr = Change... 44 r 0 Literals

select phonotier
plus phonotable
plus phonostr1
plus phonostr2
plus phonostr3
plus phonostr4
Remove

select phonostr
call resumeTextEncodingPreferences

# Write the result of phonetization to the corresponding phono intervals
for int from 1 to nint
select phonostr
phonostr$ = Get string... 'int'
select tg
Set interval text... 'phonoTID' 'int' 'phonostr$'
ortholab$ = Get label of interval... 'orthoTID' 'int'
if left$(ortholab$,1) = "%" or ortholab$ = ""
Set interval text... 'phonoTID' 'int'
elsif ortholab$ = "_"
Set interval text... 'phonoTID' 'int' _
endif
endfor

# Reset temporary files
filedelete tmp/tout.txt.fon
filedelete tmp/t.txt

select phonostr
Remove

# Restore the original ortho tier (with uppercase and punctuation)
select tg
Remove tier... 'orthoTID'
ortho2TID = ortho2TID-1
Set tier name... 'ortho2TID' ortho
call findtierbyname phono 1 1
phonoTID = findtierbyname.return

# Correct the stress position to last syllable in the case of Spanish words that end in falling diphthong spelled with "y"
Replace interval text... phonoTID 0 0 'es-toj es-t'oj Literals
Replace interval text... phonoTID 0 0 k'a-4aj ka-4'aj Literals
Replace interval text... phonoTID 0 0 k'om-boj kom-b'oj Literals
Replace interval text... phonoTID 0 0 'es-p4aj es-p4'aj Literals
Replace interval text... phonoTID 0 0 x'e4-sej xe4-s'ej Literals
Replace interval text... phonoTID 0 0 B'i-rej Bi-r'ej Literals
Replace interval text... phonoTID 0 0 b'i-rej bi-r'ej Literals

##}

plus so
if open_sound_and_tg
Edit
endif

procedure textEncodingPreferences
Read Strings from raw text file... 'preferencesDirectory$'\Preferences5.ini
.nstr = Get number of strings
for .istr to .nstr
.str$ = Get string... '.istr'
if index(.str$,"TextEncoding.inputEncoding:") != 0
.teie$ = extractLine$(.str$,"TextEncoding.inputEncoding: ")
elsif index(.str$,"TextEncoding.outputEncoding:") != 0
.teoe$ = extractLine$(.str$,"TextEncoding.outputEncoding: ")
endif
endfor
Remove
endproc

procedure resumeTextEncodingPreferences
Text reading preferences... 'textEncodingPreferences.teie$'
Text writing preferences... 'textEncodingPreferences.teoe$'
endproc
