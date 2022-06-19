# This script has been written by Jose M Lahoz (2021-01-12)

form Adjust boundaries...
comment Run this function.
comment During the pause, manually adjust boundary positions of one tier.
comment Continue. Boundaries in other specified tiers will shift accordingly.
comment Ideally, you want to adjust the most crowded tier
comment and those with fewer boundaries will match automatically.
comment This function is only intended to shift boundaries.
comment If you want to add or remove boundaries, make those changes before running.
comment  
comment Name of the master tier (the one you will correct yourself):
sentence master_tier syll
comment Name of the tiers to be automatically corrected (space-separated):
sentence automatically_corrected_tiers words ortho
boolean open_sound_and_tg 1
endform

# Identify selected objects
so = selected("Sound")
tg = selected("TextGrid")
thistg$ = selected$("TextGrid")

# Get number and names of tiers to be corrected
ntiers = 0
repeat
ntiers = ntiers+1
if index(automatically_corrected_tiers$," ") = 0
tier'ntiers'$ = automatically_corrected_tiers$
automatically_corrected_tiers$ = ""
else
tier'ntiers'$ = mid$(automatically_corrected_tiers$,1,index(automatically_corrected_tiers$," ")-1)
automatically_corrected_tiers$ = mid$(automatically_corrected_tiers$,index(automatically_corrected_tiers$," ")+1,length(automatically_corrected_tiers$))
endif
until automatically_corrected_tiers$ = ""

# Store correspondence between indices of different tiers
select tg
call findtierbyname 'master_tier$' 1 0
mastertier = findtierbyname.return
masterisint = Is interval tier... mastertier
for itier from 1 to ntiers
copytier$ = tier'itier'$
call findtierbyname 'copytier$' 1 0
copytier = findtierbyname.return
copyisint = Is interval tier... copytier
copytiertable$ = "tmp\tier" + string$('itier') + ".csv"
filedelete 'copytiertable$'
fileappend "'copytiertable$'" idx,masteridx,pct'newline$'

call get_number_of_indices mastertier masterisint
initialmasternidx = get_number_of_indices.return
call get_number_of_indices copytier copyisint
nidx = get_number_of_indices.return
if copyisint = 1
firstidx = 2
elsif copyisint = 0
firstidx = 1
endif
for idx from firstidx to nidx
call get_time_of_index copytier copyisint idx
t = get_time_of_index.return
call get_low_index mastertier masterisint t
loidx = get_low_index.return
call get_high_index mastertier masterisint t
hiidx = get_high_index.return

if masterisint = 0
masteridx = loidx
if loidx = hiidx
pct = 0
else
if loidx = 0
tloidx = Get start time
else
call get_time_of_index mastertier masterisint loidx
tloidx = get_time_of_index.return
endif
if hiidx = 0
thiidx = Get end time
else
call get_time_of_index mastertier masterisint hiidx
thiidx = get_time_of_index.return
endif
pct = (t - tloidx) / (thiidx - tloidx)
endif
endif

if masterisint = 1
if loidx != hiidx
masteridx = hiidx
pct = 0
else
masteridx = loidx
if loidx = 1
tloidx = Get start time
else
call get_time_of_index mastertier masterisint loidx
tloidx = get_time_of_index.return
endif
if loidx = initialmasternidx
thiidx = Get end time
else
call get_time_of_index mastertier masterisint loidx+1
thiidx = get_time_of_index.return
endif
pct = (t - tloidx) / (thiidx - tloidx)
endif
endif

fileappend "'copytiertable$'" 'idx','masteridx','pct''newline$'

endfor ; to nidx

endfor ; to ntiers

select so
plus tg
View & Edit

# Give control to user
beginPause: "Make changes"
comment: "Shift boundaries in master tier."
comment: "DO NOT ADD OR REMOVE BOUNDARIES."
endPause: "Continue",1

nocheck editor TextGrid 'thistg$'
nocheck Close
nocheck endeditor

# Check that number of boundaries remains the same
select tg
call get_number_of_indices mastertier masterisint
masternidx = get_number_of_indices.return

if masternidx != initialmasternidx
select so
plus tg
exit You have changed the number of boundaries in master tier. Exiting...
endif

# Shift boundaries in selected tiers according to changes in master tier
for itier from 1 to ntiers
select tg
copytier$ = tier'itier'$
call findtierbyname 'copytier$' 1 0
copytier = findtierbyname.return
copyisint = Is interval tier... copytier
copytiertable$ = "tmp\tier" + string$('itier') + ".csv"
copytiertable = Read Table from comma-separated file... 'copytiertable$'
nrow = Get number of rows

for irow from 1 to nrow
select copytiertable
idx = Get value... irow idx
masteridx = Get value... irow masteridx
pct = Get value... irow pct

select tg
call get_time_of_index copytier copyisint idx
tidx = get_time_of_index.return
if masteridx = 0
tmasteridx = Get start time
else
call get_time_of_index mastertier masterisint masteridx
tmasteridx = get_time_of_index.return
endif

if pct != 0
if masteridx = masternidx
tnext = Get end time
else
call get_time_of_index mastertier masterisint masteridx+1
tnext = get_time_of_index.return
endif
tmasteridx = tmasteridx + pct*(tnext - tmasteridx)
endif ; pct != 0

if copyisint = 0
lab$ = Get label of point... copytier idx
Remove point... copytier idx
Insert point... copytier tmasteridx 'lab$'
endif ; copyisint = 0

if copyisint = 1
lab1$ = Get label of interval... copytier idx-1
lab2$ = Get label of interval... copytier idx
Remove boundary at time... copytier tidx
Insert boundary... copytier tmasteridx
loint = Get low interval at time... copytier tmasteridx
hiint = Get high interval at time... copytier tmasteridx
Set interval text... copytier loint 'lab1$'
Set interval text... copytier hiint 'lab2$'
endif ; copyisint = 1

endfor ; to nrow

select copytiertable
Remove

endfor ; to ntiers

select so
plus tg
if open_sound_and_tg
View & Edit
endif
# End of script

include utils.praat
