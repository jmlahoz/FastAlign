# include auxiliary.praat
# include stress.praat

##{ Dialog window
form FastAlign...
comment Creates 'phones', 'syll', and 'words' tiers from a Sound and a TG with an existing 'ortho' tier
boolean overwrite 1
boolean open_sound_and_tg 1
comment Output tiers
boolean keep_phones 1
boolean keep_syll 1
boolean keep_words 1
boolean keep_ortho 1
endform
##}

simulatemac = 1

if windows = 1 and simulatemac = 0
runScript: "phonetize_orthotier.praat", 'overwrite', "no"
runScript: "align_sound_htk.praat", 'overwrite', 'open_sound_and_tg', 'keep_phones', 'keep_syll', 'keep_words', 'keep_ortho'
elsif macintosh = 1 or unix = 1 or simulatemac = 1
runScript: "align_sound_native.praat", 'overwrite', 'open_sound_and_tg', 'keep_phones', 'keep_syll', 'keep_words', 'keep_ortho'
endif

