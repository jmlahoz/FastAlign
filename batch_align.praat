# FastAlign
# Author: José María Lahoz-Bengoechea
# License: GPL-3.0-or-later

# This script takes any number of TextGrids and name-matching Sounds within a folder.
# TextGrids must consist of a tier named ortho,
# which must contain the transliteration of the sound in conventional Spanish spelling.
# It yields phones, syll, and words tiers aligned to the contents of the sound.

form Batch align...
comment Write here the path to the folder containing the sounds and TextGrids
comment (any TextGrid should be named the same as its corresponding sound)
sentence folder 
comment Indicate the extension of the sound files
word sound_extension .flac
endform

str = Create Strings as file list... str 'folder$'/*.TextGrid

nstr = Get number of strings

for istr from 1 to nstr
select str

tg$ = Get string... istr
name$ = tg$ - ".TextGrid"
so$ = name$ + sound_extension$

so = Read from file... 'folder$'/'so$'
tg = Read from file... 'folder$'/'tg$'

select so
plus tg
runScript: "fast_align.praat", "yes", "no", "yes", "yes", "yes", "yes"
select tg
Save as text file... 'folder$'/'tg$'

select so
plus tg
Remove

endfor ; to nstr

select str
Remove
