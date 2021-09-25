#!/bin/tclsh

package require Tk 8

tk appname "Ninja"


# puts  [ttk::style theme names]
# puts [ttk::style theme use]
# # clam alt default classic
# # default
# ttk::style theme use classic
puts $xxx
puts $config(x)

proc make_scrolled_y {f w} {
	puts $f.scrollbar

	scrollbar $f.scrollbar -width 10 -orient vertical -command "$w yview"
	$w configure -yscrollcommand "$f.scrollbar set"
	pack $f.scrollbar -side right -fill y
	pack $w -expand 1 -fill both
	# grid $w $f.scrollbar -sticky nsew
	# grid columnconfigure $f 0 -weight 1
	# grid rowconfigure $f 0 -weight 1
	return $f
}


pack [panedwindow .main -orient vertical] -fill both -expand 1
pack [panedwindow .sections -orient horizontal] -fill both -expand 1


# секции
foreach i {0 1 2 3} \
	name {packages classes categories methods} {
	
	pack [make_scrolled_y [frame .f$i] [listbox .f$i.list]] -side top -fill both -expand 1
	
	pack [entry .f$i.filter] -side bottom -fill both
	
	.sections add .f$i 
	#-width $config(sections)(widths)[$i]
}

# тулбар
pack [frame .f] -side bottom
pack [label .f.position -text "Line 1, Column 1" -justify left] -side left -expand 1


# текст
pack [make_scrolled_y [frame .t] [text .t.text -wrap word]] -fill both -expand 1

.t.text insert end [exec cat README.md]


.main add .sections
.main add .t




