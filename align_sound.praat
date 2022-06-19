form 3.Segmentation: create phones, syll and words tiers
comment Creates 'phones', 'syll', and 'words' tiers from a Sound and a TG with existing 'phono' and 'ortho' tiers
sentence ortho_tier ortho
sentence phono_tier phono
comment Choose a language
optionmenu language: 3
		option fra
		option nan
		option spa
		option slk
word chars_to_ignore }-'';(),.¿?
comment After processing,
real preptk_threshold_(ms) 90
comment Output tiers
boolean keep_phones 0
boolean keep_syll 1
boolean keep_words 1
boolean keep_phono 0
boolean keep_ortho 1
comment Stress
boolean mark_syllable_stress 1
comment As a result,
boolean open_sound_and_tg 1
endform

##### Options deleted from form and added here by Jose M. Lahoz-Bengoechea (2021-03-11)
overwrite = 1
precise_endpointing = 0 ; a value of 1 means no initial or final sp
consider_star = 1
allow_elision = 0
# open_sound_and_tg = 1
show_info_window = 0
#####

##### Added by Jose M. Lahoz-Bengoechea (2020-12-22)
keep_info = 0
#####

bsil$=""		;"-b sil"
keeptmpfile=1

##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
if show_info_window
printline 
printline ###EASYALIGN: Segment in phones, sylls, words
printline 
endif

#Post-process pre-ptk pauses. Suppress pause less than (in ms)
n_utt_rec=0
n_utt_notrec=0
n_utt_ignored=0
n_utt_misformatted=0
n_utt_silence=0

if language$="fra"
  spfreqref=16000
elsif language$="nan"
  spfreqref=16000
elsif language$="spa"
  spfreqref=44100
elsif language$="slk"
  spfreqref=22050
endif

basename$=""
ns=numberOfSelected("Sound")
##### Line added by Jose M. Lahoz-Bengoechea (2013-01-31)
nls=numberOfSelected("LongSound")
nt=numberOfSelected("TextGrid")

if nt=1 and ns=1
  basename$=selected$("TextGrid")
  tgID=selected("TextGrid")
  soundID=selected("Sound")
  by_select=1
elsif nt=1 and nls=1
##### Elsif added by Jose M. Lahoz-Bengoechea (2013-01-31)
  basename$=selected$("TextGrid")
  tgID=selected("TextGrid")
  soundID=selected("LongSound")
  by_select=1
else
  exit Select one Sound and one TextGrid
endif

Read from file... lang/'language$'/'language$'.Table
Append row
nr=Get number of rows
Set string value... 'nr' htk sil
Set string value... 'nr' sampa _

filedelete reco.log

srcrateref=10000000/spfreqref
if fileReadable("lang/'language$'/'language$'.cfg")
  Read Strings from raw text file... lang/'language$'/'language$'.cfg
else
  Read Strings from raw text file... analysis.cfg
endif
Set string... 1 SOURCERATE = 'srcrateref'
Write to raw text file... tmp/analysis.cfg
Remove

select 'soundID'

##### Condition added by Jose M. Lahoz-Bengoechea (2013-01-31): not the content
if ns = 1
ncan=Get number of channels
if ncan=2
  Convert to mono
  soundID=selected("Sound")
endif
elsif nls = 1
# Elsif added by Jose M. Lahoz-Bengoechea (2013-01-31)
ls_info$ = Info
ncan = extractNumber(ls_info$,"Number of channels: ")
if ncan=2
label mono_conversion
beginPause ("Convert to mono...")
comment ("Attempting to convert to mono. If this fails, do it manually.")
comment ("Which channel do you want to extract?")
comment ("1 = Left; 2 = Right; 0 = Merge both")
natural ("channel",1)
clicked = endPause ("Continue",1)
if channel != 0 and channel != 1 and channel != 2
pause channel value must be either 0, 1 or 2
goto mono_conversion
endif
regularSoundID = Extract part... 0 0 yes
if channel = 0
monoSoundID = Convert to mono
elsif channel = 1 or channel = 2
monoSoundID = Extract one channel... 'channel'
endif
nowarn Save as WAV file... tmp/'basename$'_mono.wav
select 'regularSoundID'
plus 'monoSoundID'
plus 'soundID'
Remove
soundID = Open long sound file... tmp/'basename$'_mono.wav
Rename... 'basename$'
endif
##### End of added elsif
endif
##### End of added condition

spfreq = Get sampling frequency
if spfreq != spfreqref
##### Condition added by Jose M. Lahoz-Bengoechea (2013-01-31): not the content
if ns = 1
  Resample... spfreqref 5
  soundID=selected("Sound")
  spfreq=spfreqref
##### Elsif content added by Jose M. Lahoz-Bengoechea (2013-01-31)
elsif nls = 1
  pause Attempting to do Resample... 'spfreqref'   5     If this fails, do it manually.
  regularSoundID = Extract part... 0 0 yes
  resampleSoundID = Resample... 'spfreqref' 5
  nowarn Save as WAV file... tmp/'basename$'_'spfreqref'.wav
  select 'regularSoundID'
  plus 'resampleSoundID'
  plus 'soundID'
  Remove
  soundID = Open long sound file... tmp/'basename$'_'spfreqref'.wav
  Rename... 'basename$'
endif
endif

select 'tgID'
st = Get start time
if st!= 0
##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
if show_info_window
  printline TextGrid does not start at time 0. Times are shifted to zero.
endif
  Shift to zero
endif

call findtierbyname 'ortho_tier$' 1 1
orthoTID = findtierbyname.return
call findtierbyname 'phono_tier$' 1 1
phonoTID = findtierbyname.return

#jpg 22.04.2008: checks if phonoTID and orthoTID have the same boundaries
call checkOrthoAndPhonoTiers

hmmfile$="lang/'language$'/'language$'.hmm"
if fileReadable(hmmfile$)

else
   hmmfile$="lang/fra/fra.hmm"
endif
##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
if show_info_window
printline Using HMM file: 'hmmfile$'
endif

n = Get number of intervals... 'phonoTID'
first=1
for i from 1 to n

 select 'tgID'
 #printline int 'i'
 l$ = Get label of interval... 'phonoTID' 'i'
 align_it=0
 
 #IGNORE phono segment empty or starting with %
 if (l$=="") or (mid$(l$,1,1)=="%")
   align_it=5
   n_utt_ignored = n_utt_ignored + 1
   #printline Utt.# 'i' ignored (phono tier is empty or start with a %) 'l$'
 
 #SKIP phono segment with _ only
 elsif (l$=="_") 
   align_it=6
   n_utt_silence = n_utt_silence + 1
   #printline Utt.# 'i' ignored (phono tier is silence)

 #PROCESS the others
 else
   for j to length(chars_to_ignore$)
     l$=replace$(l$,mid$(chars_to_ignore$,j,1),"",0)
   endfor
   call removespaces 1 1 1 'l$'
   l$ = removespaces.arg$

   lobak$=l$
   call countwords 'l$'
   npw = countwords.return
   if language$="nl"
     call checknl 'l$'
   elsif language$="fra" or language$="sw" or language$="en" or language$="nan" or language$="spa" or language$="slk"
     call checksampa2 "'l$'" 'language$' *
     isgood=1-checksampa2.cont
     #pause 'language$' 'l$' 'isgood'
   else
     call checksampa 'l$'
     isgood=checksampa.i
   endif
  
   if isgood!=0
     align_it = 3
     ##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
	 if show_info_window
     if language$="nl"
       printline Utt.# 'i' misformatted: 'checknl.wrongi'th char is not SAMPA (a): |'checknl.wrongc$'| in 'l$'
     elsif language$="fra" or language$="sw" or language$="en" or language$="nan" or language$="spa" or language$="slk" 
       printline Utt.# 'i' misformatted: 'checksampa2.i'th char is not SAMPA (b): |'checksampa2.c2$'| in |'checksampa2.s$'|
     else
       printline Utt.# 'i' misformatted: 'checksampa.i'th char is not SAMPA (c): |'checksampa.c$'| in |'checksampa.s$'|
     endif
	 endif
     n_utt_misformatted = n_utt_misformatted + 1
   else
     select 'tgID'
     if orthoTID>0 and orthoTID!=phonoTID
       lo$ = Get label of interval... 'orthoTID' 'i'
       call mystrip 0 0 1 'lo$'
       lo$ = mystrip.arg$
       call countwords 'lo$'
       now = countwords.return
       if now!=npw
         #try with ortho clean up
         call mystrip 0 1 1 'lo$'
         lo$ = mystrip.arg$
         call countwords 'lo$'
         now = countwords.return
         if now!=npw
           #try with ortho clean up
           call mystrip 1 1 1 'lo$'
           lo$ = mystrip.arg$
           call countwords 'lo$'
           now = countwords.return
           if now!=npw
             align_it=2
			 ##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
			 if show_info_window
             printline Utt.# 'i' misformatted: 'ortho' has 'now' words as 'phono' tier has 'npw' words : 'lo$'
             printline vs. 'l$'
			 endif
             n_utt_misformatted = n_utt_misformatted + 1
           else
             align_it=1
           endif
         else
           align_it=1
         endif
       else
         align_it=1
       endif
       lobak$=lo$
     else
       align_it=1
     endif
   endif
 endif ; empty or sil or junk int
# START RECO

  select 'tgID'
  sp=Get starting point... 'phonoTID' 'i'
  end=Get end point... 'phonoTID' 'i'
  filedelete tmp/'basename$'_'i'.dct
  filedelete tmp/'basename$'_'i'.lab
  filedelete tmp/'basename$'_'i'.rec
  filedelete tmp/'basename$'_'i'.wav
  if align_it==1
     #printline label$ is now #'l$'#
      iw=1
      nsafe=0

      if fileReadable("tmp/'basename$'_'i'.dct")
        filedelete tmp/'basename$'_'i'.dct
      endif
      #fileappend "tmp/'basename$'_'i'.dct" sil'tab$'sil'newline$'
      #fileappend "tmp/'basename$'_'i'.dct" BRTH'tab$'BRTH'newline$'
      #if language$="slk"
      #  fileappend "tmp/'basename$'_'i'.dct" sil'tab$'[] sil
      #  fileappend "tmp/'basename$'_'i'.dct" <fil>'tab$'[] <fil>
      #  fileappend "tmp/'basename$'_'i'.dct" <spk>'tab$'[] <spk>
      #else
       fileappend "tmp/'basename$'_'i'.dct" sp'tab$'sp'newline$'
      #endif
      
      if fileReadable("tmp/'basename$'_'i'.lab")
        filedelete tmp/'basename$'_'i'.lab
      endif
      if precise_endpointing=0
        fileappend "tmp/'basename$'_'i'.lab" sp'newline$'
      endif

      w$=""
      while length(l$)>0
        select 'tgID'
        nsafe=nsafe+1
        isp=index(l$," ")
        if isp==0
          w$=l$
          l$=""
        else 
          w$=mid$(l$,1,isp-1)
          l$=mid$(l$,isp+1,length(l$)-isp)
        endif
        w1$=w$
        
        if (left$(w1$,1)=="9") or (left$(w1$,1)=="2")
          w1$="a"+w1$
	  #pause do I really come here sometimes ?
        endif
       
        if orthoTID>0 and orthoTID!=phonoTID
          ispo=index(lo$," ")
          if isp==0    ;ispo?
            wo$=lo$
            lo$=""
          else 
            wo$=mid$(lo$,1,ispo-1)
            lo$=mid$(lo$,ispo+1,length(lo$)-ispo)
          endif
          w1$=wo$
        endif

	#jpg 22aout07
        call dediacritize 'w1$'
        w1$=dediacritize.s$

        #printline here 'iw' 'w$' 'wo$'

        fileappend "tmp/'basename$'_'i'.lab" 'w1$''newline$'
        wout$=""
        if length(l$)=0 and precise_endpointing=1
          final_space=0
        else
          final_space=1
        endif
        
	select Table 'language$'
        if (consider_star=0)
          w$=replace$(w$,"*","",0)
	  call addwordtodct 'final_space' 'w$'
        else
          call countchar * 'w$'
          if countchar.n=0
  	    call addwordtodct 'final_space' 'w$'
          elsif countchar.n=1
            call addonestarword 'final_space' 'w$'
          elsif countchar.n=2
            istar=index(w$,"*")
            w5$=replace$(w$,"*","",1)
            call addonestarword 'final_space' 'w5$'
            w6$=left$(w5$,istar-2)+right$(w5$,length(w5$)-istar+1)
            call addonestarword 'final_space' 'w6$'
            #printline W56 |'w$'|'w5$'|'w6$'|
          endif
        endif
        
        if (allow_elision=1) and (index(wout$,"@")>0)
          wout$=replace$(wout$," @","",0)
          fileappend "tmp/'basename$'_'i'.dct" 'w1$''tab$''wout$' sp'newline$'
        endif
        
        iw=iw+1
        #    printline label$ is now !'l$'!
      endwhile
      #jpg 17.06.2008 add aux dct
      if fileReadable("lang/'language$'.dctnonono")
        auxdctID = Read Strings from raw text file... lang/'language$'.dct
        naux=Get number of strings
        for iaux to naux
          s$=Get string... 'iaux'
          fileappend "tmp/'basename$'_'i'.dct" 's$''newline$'
        endfor
        Remove
      endif
     
      select 'tgID'
      start = Get starting point... 'phonoTID' 'i'
      end = Get end point...  'phonoTID' 'i'
      select 'soundID'
	  ##### Condition added by Jose M. Lahoz-Bengoechea (2013-01-31): not the content
	  if ns=1
      Extract part... 'start' 'end' Rectangular 1 no
	  ##### Elsif content added by Jose M. Lahoz-Bengoechea (2013-01-31)
	  elsif nls=1
	  Extract part... 'start' 'end' no
	  endif
      soundpartID = selected("Sound")
      #jpg 22 aout 2007
      Scale peak... 0.99
      Write to WAV file... tmp/'basename$'_'i'.wav
      Remove
      
      if language$="slk" 
        t1$ = "-T 1"
      else
        t1$=""
      endif
      
      system HVite -A 't1$' 'bsil$' -a -m -C tmp/analysis.cfg  -H "'hmmfile$'" -t 250 "tmp/'basename$'_'i'.dct" lang/'language$'/'language$'phone1.list "tmp/'basename$'_'i'.wav" >> "tmp/reco.log"  2>&1
      if fileReadable("tmp/'basename$'_'i'.rec")==0
	  	##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
		if show_info_window
        printline Utt.# 'i', alignment could not be aligned. : 'lobak$'
		endif
        n_utt_notrec = n_utt_notrec +1    ; nombre de reco non reussies
      else
        n_utt_rec = n_utt_rec +1    ; nombre de reco reussies
      endif
  endif

#merge
        #merge
        select 'tgID'
#        printline merge 'i'
        if first==1
          first=0
          call findtierbyname words 0 1
          wordsTID = findtierbyname.return

          if wordsTID!=0
            if overwrite=1
              Remove tier... 'wordsTID'
			  ##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
			  if show_info_window
              printline Overwriting previous words tier
			  endif
              wordsTID=1
              Insert interval tier... 'wordsTID' words
            else
			##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
			  if show_info_window
              printline Renaming previous words tier as wordsbak
			  endif
              Set tier name... 'wordsTID' wordsbak
              Insert interval tier... 'wordsTID' words
            endif
          else
            wordsTID=1
            Insert interval tier... 'wordsTID' words
          endif

          call findtierbyname phones 0 1
          phonesTID = findtierbyname.return
          if phonesTID!=0
            if overwrite=1
              Remove tier... 'phonesTID'
			  ##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
			  if show_info_window
              printline Overwriting previous phones tier
			  endif
              phonesTID=1
              Insert interval tier... 'phonesTID' phones
            else
			  ##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
			if show_info_window
				printline Renaming previous phones tier as phonesback
			endif
              Set tier name... 'phonesTID' phonesback
              Insert interval tier... 'phonesTID' phones
            endif
          else
            phonesTID=1
            Insert interval tier... 'phonesTID' phones
          endif
          call findtierbyname words 0 1
          wordsTID = findtierbyname.return
          call findtierbyname 'ortho_tier$' 1 1
	  orthoTID = findtierbyname.return
	  call findtierbyname 'phono_tier$' 1 1
	  phonoTID = findtierbyname.return

##### Condition added by Jose M. Lahoz-Bengoechea (2011-01-26): not the content
if show_info_window
printline wordsTID 'wordsTID' phonesTID 'phonesTID'
printline orthoTID 'orthoTID' phonoTID 'phonoTID'
endif

#######################
if 0
          #printline wordsTID 'wordsTID' phonesTID 'phonesTID'
          if (wordsTID !=0 or phonesTID != 0) and overwrite==1
            #pause Tier 'words' and/or 'phones already exists. Erase tiers and continue ?
            if wordsTID!=0
              Remove tier... 'wordsTID'
              Insert interval tier... 'wordsTID' words
			  ##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
			  if show_info_window
              printline Overwriting previous words tier
			  endif
            else
              #jpg 30.04.07
              if phonesTID!=0
                wordsTID=phonesTID+1
              else
                wordsTID=1
	      endif
	      Insert interval tier... 'wordsTID' words
            endif
            #jpg 30.04.07
            if phonesTID!=0
              Remove tier... 'phonesTID'
              Insert interval tier... 'phonesTID' phones
			  ##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
			  if show_info_window
              printline Overwriting previous phones tier
			  endif
            else
              phonesTID=wordsTID
              wordsTID=wordsTID+1
              Insert interval tier... 'wordsTID' phones
            endif
          else
            if orthoTID!=0
              mintid=min(phonoTID,orthoTID)
            else
              mintid=phonoTID
            endif
            Insert interval tier... 'mintid' words
            Insert interval tier... 'mintid' phones
            phonesTID=mintid
            wordsTID=mintid+1
            phonoTID=phonoTID+2
            if orthoTID!=0
              orthoTID=orthoTID+2
            endif
          endif
          #printline wordsTID 'wordsTID' phonesTID 'phonesTID'
endif
#######################


        endif
        call getrec "tmp/'basename$'_'i'.rec" 'phonesTID' 'wordsTID' 'sp'
if keeptmpfile=0
  filedelete tmp/'basename$'_'i'.dct
  filedelete tmp/'basename$'_'i'.lab
  filedelete tmp/'basename$'_'i'.rec
  filedelete tmp/'basename$'_'i'.wav
endif
endfor

##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
if show_info_window
printline
endif
if n_utt_rec!=0
  ##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
  if show_info_window
  printline 'n_utt_rec' utt. aligned
  endif
  l$="'n_utt_rec' utt. aligned'newline$'"
  l$ >> tmp/log.txt
endif
##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
if show_info_window
if n_utt_notrec!=0
  printline 'n_utt_notrec' utt. could NOT be aligned by the speech engine. Make shorter utt.
endif
if n_utt_misformatted!=0
  printline 'n_utt_misformatted' utt. were misformated. Check spaces or SAMPA symbols...
endif
if n_utt_ignored!=0
  printline 'n_utt_ignored' utt. ignored (empty or %-junk utt)
endif
if n_utt_silence!=0
  printline 'n_utt_silence' utt. were annotated as silence (_)
endif
endif

#pause extract initial and final pauses from phono and ortho segments
#
# extract initial and final pauses from phono and ortho segments
#
  select 'tgID'
  uints = Get number of intervals... 'phonoTID'
  uint=1
  while uint<=uints
    #get phono info
    usp = Get starting point... 'phonoTID' 'uint'
    uep = Get end point... 'phonoTID' 'uint'
    ulab$=Get label of interval... 'phonoTID' 'uint'
    if orthoTID>0
      uolab$=Get label of interval... 'orthoTID' 'uint'
    endif
    
    #get 1st PHONE info
    pint = Get interval at time... 'phonesTID' 'usp'
    psp = Get starting point... 'phonesTID' 'pint'
    pep = Get end point... 'phonesTID' 'pint'
    plab$ = Get label of interval... 'phonesTID' 'pint'
    #printline uint='uint' ('usp','uep') pint='pint' ('psp','pep') 'plab$' 'ulab$'

    if plab$=="_"
     if pep<uep
       #pause MSG 101 'pep' 'uep' 'uint' 'pint'
       if orthoTID>0
         Insert boundary... 'orthoTID' 'pep'
         Set interval text... 'orthoTID' 'uint' _
       endif
       if orthoTID!=phonoTID
         Insert boundary... 'phonoTID' 'pep'
         Set interval text... 'phonoTID' 'uint' _
       endif
       uint=uint+1
       uints=uints+1
       if orthoTID>0
         Set interval text... 'orthoTID' 'uint' 'uolab$'
       endif
       if orthoTID!=phonoTID       
         Set interval text... 'phonoTID' 'uint' 'ulab$'
       endif
      endif
    endif
    pint = Get interval at time... 'phonesTID' 'uep'

    if pint>1
      ppint = pint-1
      ppsp = Get starting point... 'phonesTID' 'ppint'
      ppep = Get end point... 'phonesTID' 'ppint'
      pplab$ = Get label of interval... 'phonesTID' 'ppint'
      #printline uint='uint' ('usp','uep') ppint='ppint' ('ppsp','ppep') 'pplab$' 'ulab$' (pint='pint')

      if (pplab$=="_") and (ppsp>usp)
         if orthoTID>0
           Insert boundary... 'orthoTID' 'ppsp'
         endif
         if orthoTID!=phonoTID
           Insert boundary... 'phonoTID' 'ppsp'
         endif
         uint=uint+1
         uints=uints+1
         if orthoTID>0
           Set interval text... 'orthoTID' 'uint' _
         endif
         if orthoTID!=phonoTID
           Set interval text... 'phonoTID' 'uint' _
         endif
      endif
    endif 
    uint=uint+1
  endwhile

#pause remove_doublesil
#
#remove_doublesil
#

  select 'tgID'
  noints = Get number of intervals... 'phonesTID'
  last$ = Get label of interval... 'phonesTID' 'noints'
  nouints = Get number of intervals... 'phonoTID'
  ulast$ = Get label of interval... 'phonoTID' 'nouints'
  for noint from 1 to noints-1
    noint1=noints-noint
    curr$ = Get label of interval... 'phonesTID' 'noint1'
    noint2=noint1+1
    sp = Get starting point... 'phonesTID' 'noint2'
    sp1 = Get starting point... 'phonesTID' 'noint1'
    uint = Get interval at time... 'phonoTID' 'sp1'
    #printline 'phonoTID' 'uint' 'sp1' 'sp' 'noint1' 'noint2'
    sp_utt = Get starting point... 'phonoTID' 'uint'
    ucurr$ = Get label of interval... 'phonoTID' 'uint'
    #ep_utt = Get end point... 'phonesTID' 'noint2'
    #printline sp='sp' sp1='sp1' sp'_utt='sp_utt'

    if (last$=="_") and (curr$=="_") and (ulast$=="_") and (ucurr$=="_") and (sp1==sp_utt)
     #pause sp='sp' sp1='sp1' sp_utt='sp_utt'
     #phones
      Remove left boundary... 'phonesTID' 'noint2'
      Set interval text... 'phonesTID' 'noint1' _

      #words
      nint2 = Get interval at time... 'wordsTID' 'sp'
      Set interval text... 'wordsTID' 'nint2'
      Remove left boundary... 'wordsTID' 'nint2'

      #phono
      nint2 = Get interval at time... 'phonoTID' 'sp'
      Set interval text... 'phonoTID' 'nint2'
      Remove left boundary... 'phonoTID' 'nint2'

      #ortho
      if orthoTID>0 and orthoTID!=phonoTID
        nint2 = Get interval at time... 'orthoTID' 'sp'
        Set interval text... 'orthoTID' 'nint2'
        Remove left boundary... 'orthoTID' 'nint2'
      endif

    endif
    last$=curr$
    ulast$=ucurr$
  endfor

#pause b4 ptkfilter
#pre ptk filter 18.9.2006
n = Get number of intervals... 'phonesTID'
ll$=""
ld=0
i=1
preptk_threshold=preptk_threshold/1000
nptk=0
while i<=n

  l$= Get label of interval... 'phonesTID' 'i'
  sp= Get starting point... 'phonesTID' 'i'
  ep= Get end point... 'phonesTID' 'i'
  d=ep-sp
  if (l$=="p" or l$=="t" or l$=="k" or l$=="D") and ll$=="_" and (ld < preptk_threshold)
    #phones
    Remove boundary at time... 'phonesTID' 'sp'
    i1=i-1
    Set interval text... 'phonesTID' 'i1' 'l$'
    i=i-1
    n=n-1
    
    #words
    wi=Get interval at time... 'wordsTID' 'sp'
    wl$=Get label of interval... 'wordsTID' 'wi'
    Remove boundary at time... 'wordsTID' 'sp'
    wi1=wi-1
    Set interval text... 'wordsTID' 'wi1' 'wl$'
    
    #stats printline 'l$' 'ld' 'sp' 'wl$'
    nptk=nptk+1
    
  endif
  ll$=l$
  ld=d
  i=i+1
endwhile
preptk_threshold=preptk_threshold*1000
##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
if show_info_window
printline Pre-PTK filter : 'nptk' silences removed (threshold was 'preptk_threshold' ms)
endif

#include syllabify2.praat
if keep_syll = 1
##### Argument added by Jose M. Lahoz-Bengoechea (2012-07-08)
execute syllabify2.praat 'show_info_window'
##### Code added by Jose M. Lahoz-Bengoechea (2020-12-23)
select 'tgID'

call findtierbyname phones 1 1
phonesTID = findtierbyname.return
call findtierbyname syll 1 1
syllTID = findtierbyname.return
call findtierbyname words 1 1
wordsTID = findtierbyname.return

nword = Get number of intervals... wordsTID

for iword from 1 to nword
iword$ = Get label of interval... wordsTID iword

if iword$ = "y"
wordini = Get start time of interval... wordsTID iword
wordend = Get end time of interval... wordsTID iword
cursyll = Get interval at time... syllTID wordini
cursyll$ = Get label of interval... syllTID cursyll
syllini = Get start time of interval... syllTID cursyll
syllend = Get end time of interval... syllTID cursyll

if mid$(cursyll$,1,2) = "jj" ; context __V y V__
newsyll$ = replace$(cursyll$,"jj","",0)
Insert boundary... syllTID wordend
Set interval text... syllTID cursyll i
Set interval text... syllTID cursyll+1 'newsyll$'
curphone = Get interval at time... phonesTID syllini
Set interval text... phonesTID curphone i
elsif syllend > wordend ; context __C y V__
resyllcons$ = mid$(cursyll$,1,1)
newsyll$ = mid$(cursyll$,3,length(cursyll$)-2)
Insert boundary... syllTID wordend
Set interval text... syllTID cursyll 'resyllcons$'i
Set interval text... syllTID cursyll+1 'newsyll$'
elsif syllini < wordini ; context __X y C__
prevword$ = Get label of interval... wordsTID iword-1
if index("aeiouáéíóú",right$(prevword$,1)) != 0 ; context __V y C__
newsyll$ = cursyll$ - "j"
Insert boundary... syllTID wordini
Set interval text... syllTID cursyll 'newsyll$'
Set interval text... syllTID cursyll+1 i
else ; context __C y C__
# Resyllabification is always respected
endif
endif

elsif right$(iword$,1) = "y"
wordend = Get end time of interval... wordsTID iword
cursyll = Get interval at time... syllTID wordend
syllini = Get start time of interval... syllTID cursyll
if syllini < wordend
prevsyll$ = Get label of interval... syllTID cursyll-1
newprevsyll$ = prevsyll$ + "i\nv"
cursyll$ = Get label of interval... syllTID cursyll
newsyll$ = mid$(cursyll$,2,length(cursyll$)-1)
Insert boundary... syllTID wordend
Remove boundary at time... syllTID syllini
Set interval text... syllTID cursyll-1 'newprevsyll$'
Set interval text... syllTID cursyll 'newsyll$'
endif

endif ; iword$ = "y" or right$(iword$,1) = "y"
endfor ; to nword


Replace interval text... phonesTID 0 0 j i\nv Literals
Replace interval text... phonesTID 0 0 i\nvi\nv \jc\Tv Literals
Replace interval text... phonesTID 0 0 w u\nv Literals
Replace interval text... syllTID 0 0 j i\nv Literals
Replace interval text... syllTID 0 0 i\nvi\nv \jc\Tv Literals
Replace interval text... syllTID 0 0 w u\nv Literals

# Syllabification of "x" /ks/ and of "dr" (tautosyllabic)
nsyll = Get number of intervals... syllTID

for cursyll from 1 to nsyll-1
cursyll$ = Get label of interval... syllTID cursyll
if right$(cursyll$,1) = "k"
nextsyll$ = Get label of interval... syllTID cursyll+1
if mid$(nextsyll$,1,1) = "'"
nextsyll$ = replace$(nextsyll$,"'","",0)
replace_stress = 1
else
replace_stress = 0
endif
if mid$(nextsyll$,1,1) = "s" and index("aeiou",mid$(nextsyll$,2,1)) = 0
cursyll$ = cursyll$ + "s"
nextsyll$ = mid$(nextsyll$,2,length(nextsyll$)-1)
if replace_stress = 1
nextsyll$ = "'" + nextsyll$
endif
syllend = Get end time of interval... syllTID cursyll
nextphone = Get interval at time... phonesTID syllend
phoneend = Get end time of interval... phonesTID nextphone
Insert boundary... syllTID phoneend
Remove boundary at time... syllTID syllend
Set interval text... syllTID cursyll 'cursyll$'
Set interval text... syllTID cursyll+1 'nextsyll$'
endif
elsif right$(cursyll$,1) = "D"
nextsyll$ = Get label of interval... syllTID cursyll+1
if mid$(nextsyll$,1,1) = "'"
nextsyll$ = replace$(nextsyll$,"'","",0)
replace_stress = 1
else
replace_stress = 0
endif
if mid$(nextsyll$,1,1) = "4"
cursyll$ = cursyll$ - "D"
nextsyll$ = "D" + nextsyll$
if replace_stress = 1
nextsyll$ = "'" + nextsyll$
endif
syllend = Get end time of interval... syllTID cursyll
swingphone = Get low interval at time... phonesTID syllend
prevphoneend = Get end time of interval... phonesTID swingphone-1
Insert boundary... syllTID prevphoneend
Remove boundary at time... syllTID syllend
Set interval text... syllTID cursyll 'cursyll$'
Set interval text... syllTID cursyll+1 'nextsyll$'
endif
endif
endfor ; to nsyll

if mark_syllable_stress = 1
call mark_stress
endif

# Possibly apply_syllable_merger here
# V_V (unstressed V2), including clitics (closed list of BI=0)
# Add script to apply syllable merger to BI=1 after Intonalyzer

##### End of added code
endif ; keep_syll

if keeptmpfile=0
  filedelete tmp/reco.log
  filedelete tmp/log.txt
endif

select Table 'language$'
Remove

select 'tgID'
if by_select==0
  Write to text file... tmp/'basename$'.TextGrid
##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
if show_info_window
  printline TextGrid written : tmp/'basename$'.TextGrid
endif
endif

##### Code added by Jose M. Lahoz-Bengoechea (2020-12-23)
if language = 3
call toipa phones
if keep_syll = 1
call toipa syll
endif
endif

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
if keep_phono = 0
call findtierbyname phono 1 1
phonoTID = findtierbyname.return
Remove tier... phonoTID
endif
if keep_ortho = 0
call findtierbyname ortho 1 1
orthoTID = findtierbyname.return
Remove tier... orthoTID
endif
##### End of addition

plus 'soundID'

if open_sound_and_tg
Edit
##### Inactivated by Jose M. Lahoz-Bengoechea (2012-07-08)
# else
# Remove
##### End of inactivation
endif

fappendinfo tmp/'basename$'.info.txt
##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
if show_info_window
printline Info saved in: tmp/'basename$'.info.txt
endif

##### Code added by Jose M. Lahoz-Bengoechea (2012-12-23)
procedure mark_stress
select 'tgID'

call findtierbyname syll 1 1
syllTID = findtierbyname.return
call findtierbyname phono 1 1
phonoTID = findtierbyname.return

nphono = Get number of intervals... phonoTID

for iphono from 1 to nphono

lp$ = Get label of interval... phonoTID iphono
if lp$ !="" and lp$ !="_" ; lp$ is not silence
lp$ = replace$(lp$," ","-",0)

pini = Get starting point... phonoTID iphono

cursyll = Get interval at time... syllTID pini

while length(lp$) > 0
dashpos = index(lp$,"-")

if dashpos != 0
syll$ = mid$(lp$,1,dashpos-1)
lp$ = mid$(lp$,dashpos+1,length(lp$)-dashpos)
else
syll$ = lp$
lp$ = ""
endif

accentpos = index(syll$,"'")
if accentpos != 0
syll$ = Get label of interval... syllTID cursyll
syll$ = replace$(syll$,"'","",0)
syll$ = "'" + syll$
if syll$ = "'am" or syll$ = "'em" or syll$ = "'um"
call findtierbyname words 1 1
wordsTID = findtierbyname.return
.syllend = Get end time of interval... syllTID cursyll
.word = Get low interval at time... wordsTID .syllend
.word$ = Get label of interval... wordsTID .word
if .word$ = "am" or .word$ = "ham" or .word$ = "ahm" or .word$ = "em" or .word$ = "hem" or .word$ = "ehm" or .word$ = "um" or .word$ = "hum" or .word$ = "uhm"
syll$ = mid$(syll$,2,length(syll$)-1)
endif
endif
Set interval text... 'syllTID' 'cursyll' 'syll$'
endif

syll$ = Get label of interval... syllTID cursyll
if syll$ != "_"
cursyll = cursyll + 1
else
cursyll = cursyll + 2
endif
endwhile ; length(lp$) > 0

endif ; lp$ is not silence
endfor ; to nphono
endproc ; mark_stress
##### End of addition

procedure getrec recfile$ phonesTID wordsTID shift
.verbose=0
tgID =selected("TextGrid")
if fileReadable(recfile$)
  rec$ < 'recfile$'
  nsafe=0
  #word in line
  wil=0
  nointphones=0
  nointwords=0
  nl=0
  intwords=0
  nwords=0
  
  while length(rec$)>0 ;and nsafe<4000
    if nl==1
      wil=0
      nl=0
    endif
    nsafe=nsafe+1
    isp=index(rec$," ")
    inl=index(rec$,newline$)
    if isp>0 and (isp<inl or inl==0)
      i1=isp
      wil=wil+1
    elsif inl>0 and (inl<isp or isp==0)
      i1=inl
      wil=wil+1
      nl=1
    endif

    w$=mid$(rec$,1,i1-1)
    rec$=mid$(rec$,i1+1,length(rec$)-i1)
if .verbose=1
##### Condition added by Jose M. Lahoz-Bengoechea (2012-07-08): not the content
if show_info_window
    printline 'wil' 'w$' 'rec_start' 'rec_end'
endif
endif
    if wil==1
      rec_start='w$'/10000000
    elsif wil==2
      rec_end='w$'/10000000
    elsif wil == 3 and rec_start!=rec_end
      if rec_start!=0
        rec_start=rec_start+0.015 	;tatatang.... was 0.013
      endif
      rec_start = rec_start + shift
      rec_end = rec_end + shift
      if rec_start>0
#printline phonesbound 'i' 'rec_start'
      Insert boundary... 'phonesTID' 'rec_start'
      endif
      intphones = Get interval at time... 'phonesTID' 'rec_start'
      if w$=="sp"
        Set interval text... 'phonesTID' 'intphones' _
        if rec_start != shift
          Insert boundary... 'wordsTID' 'rec_start'
          intwords1=intwords+1
          Set interval text... 'wordsTID' 'intwords1' _
        endif

      else
        select Table 'language$'
        phonerow = Search column... htk 'w$'
        if phonerow!=0
          w$=Get value... 'phonerow' sampa
        endif
#       if if w$=="oe"
#         w$="9"
#       elsif w$=="eu"
#         w$="2"
#       else
        if w$=="sil"
          w$="_"
        endif
        select 'tgID'
        Set interval text... 'phonesTID' 'intphones' 'w$'
      endif
    elsif (rec_start!=rec_end) and (wil == 5)
#    elsif (wil == 5)
      if rec_start>0
        Insert boundary... 'wordsTID' 'rec_start'
      endif
      if (nwords==0) and (w$=="sp")
        w$="_"
      endif
      nwords=nwords+1
      intwords = Get interval at time... 'wordsTID' 'rec_start'
#jpg 22aout07
      call diacritize 'w$'
      w$=diacritize.s$
      if w$=="sil"
        w$="_"
      endif
      ##### Added by Jose M. Lahoz-Bengoechea (2020-12-21): lower-case words
	  # w$ = replace_regex$(w$,".*","\L&",1)
	  ##### End of addition
	  ##### Added by Jose M. Lahoz-Bengoechea (2020-12-22)
	  w$ = replace$(w$,"\374","ü",0)
	  w$ = replace$(w$,"\301","Á",0)
	  w$ = replace$(w$,"\311","É",0)
	  w$ = replace$(w$,"\315","Í",0)
	  w$ = replace$(w$,"\323","Ó",0)
	  w$ = replace$(w$,"\332","Ú",0)
	  w$ = replace$(w$,"\277","",0)
	  w$ = replace$(w$,"\241","",0)
	  ##### End of addition
	  Set interval text... 'wordsTID' 'intwords' 'w$'
    endif
  endwhile
else
  if shift!=0
    Insert boundary... 'phonesTID' 'shift'
    pint = Get interval at time... 'phonesTID' 'shift'
    Set interval text... 'phonesTID' 'pint' _
    Insert boundary... 'wordsTID' 'shift'
    wint = Get interval at time... 'wordsTID' 'shift'
    Set interval text... 'wordsTID' 'wint' _
#    printline insert p&w bound at 'shift' (pint='pint', wint='wint')
  endif
endif   ; recfile is readable
endproc

procedure wanabergo
if nt>1
  exit Please select only one TextGrid
elsif nt=1
  basename$=selected$("TextGrid")
  tgID=selected("TextGrid")
  if ns>1
    exit Please select only one Sound
  elsif ns=1
    soundID=selected("Sound")
  elsif ns=0
    if fileReadable("'basename$'.wav")
      Read from file... 'basename$'.wav
      soundID=selected("Sound")
    else
      exit File "'basename$'.wav" not readable
    endif
  endif
else ; nt=0
  if ns>1
    exit Please select only one Sound
  elsif ns=1
    soundID=selected("Sound")
    basename$=selected$("Sound")
    if fileReadable("'basename$'.TextGrid")
      Read from file... 'basename$'.Text
      tgID=selected("TextGrid")
    else
      exit File "'basename$'.TextGrid" not readable
    endif
  elsif ns=0
    #from filename field
    basename$=filename$-".wav"
    basename$=basename$-".TextGrid"
    if fileReadable("'basename$'.wav")
      Read from file... 'basename$'.wav
      soundID=selected("Sound")
    else
      exit File "'basename$'.wav" not readable
    endif
    if fileReadable("'basename$'.TextGrid")
      Read from file... 'basename$'.TextGrid
      tgID=selected("TextGrid")
    else
      exit File "'basename$'.TextGrid" not readable
    endif
  endif
endif
endproc


#jpg 22.04.2008: checks if phonoTID and orthoTID have the same boundaries
procedure checkOrthoAndPhonoTiers
if orthoTID>0
  np = Get number of intervals... 'phonoTID'
  no = Get number of intervals... 'orthoTID'
  if no!=np
    exit phono and ortho tier should have the same number of intervals. Exiting....
  endif
  for i to np
    spp=Get starting point... 'phonoTID' 'i'
    spo=Get starting point... 'orthoTID' 'i'
    if spp!=spo
      exit Starting points of interval 'i' differ in phono and ortho tiers ('spp:3', 'spo:3'). Exiting....
    endif
  endfor
endif
endproc


procedure addwordtodct .final_space .w$
    call convertsampatohtk '.w$'
    if .final_space=1
      .sp$=" sp"
    else
      .sp$=""
    endif
    .wout$=replace$(convertsampatohtk.wout$," ","",1)
    fileappend "tmp/'basename$'_'i'.dct" 'w1$''tab$''.wout$''.sp$''newline$'
endproc

procedure addonestarword .final_space .w$
  .istar=index(.w$,"*")
  .w$=replace$(.w$,"*","",0)
  #printline istar0 |'.w$'|
  call addwordtodct '.final_space' '.w$'
  .w$=left$(.w$,.istar-2)+right$(.w$,length(.w$)-.istar+1)
  #printline istar0 |'.w$'|
  call addwordtodct '.final_space' '.w$'
endproc

include utils.praat