#!/bin/tclsh
package require Tk

# окно

tk appname "Ninja"

wm protocol . WM_DELETE_WINDOW {
	::perl::on_window_destroy
	destroy .
}

# редактирование
bind Entry <Insert> {}
bind Text <Insert> {}
bind Entry <Control-a> { event generate %W <<SelectAll>> }
bind Text <Control-a> { event generate %W <<SelectAll>> }

bind Entry <<Paste>> {
	catch { %W delete sel.first sel.last }
	catch {
		%W insert insert [::tk::GetSelection %W CLIPBOARD]
		tk::EntrySeeInsert %W
	}
}

proc ::tk_textPaste w {
    if {![catch {::tk::GetSelection $w CLIPBOARD} sel]} {
	set oldSeparator [$w cget -autoseparators]
	if {$oldSeparator} {
	    $w configure -autoseparators 0
	    $w edit separator
	}
	catch { $w delete sel.first sel.last }
	$w insert insert $sel
	if {$oldSeparator} {
	    $w edit separator
	    $w configure -autoseparators 1
	}
    }
}



# puts  [ttk::style theme names]
# puts [ttk::style theme use]
# # clam alt default classic
# # default
# ttk::style theme use classic

# статусбар
pack [frame .f] -side bottom -fill x
pack [label .f.position -text "Line 1, Column 1" ] -side left
pack [label .f.who -text "packages" ] -side right

# делаем вертикальный скроллбар. f - фрейм с виджетом w для которого скроллбар и делается 
proc make_scrolled_y {f w} {
	scrollbar $f.scrollbar  -orient vertical -width 10 -command "$w yview"
	$w configure -yscrollcommand "$f.scrollbar set"
	pack $f.scrollbar -side right -fill y
	pack $w -expand 1 -fill both
	return $f
}

# при нажатии клавиши в списке перебрасываем её в фильтр
proc key_to_filter {w K} {
	regexp {^\.(\w+)} $w -> i
	puts ".$i key = $K"
	
	switch -regexp $K {
		^[a-zA-Z0-9]$ {
			focus .$i.filter
			.$i.filter insert end $K
		}
		^(Left|Right|Down|Up)$ {
			focus .$i.filter
		}
		default {return 0}
	}
	
	return 1
}

pack [panedwindow .main -orient vertical] -fill both -expand 1
pack [panedwindow .sections -orient horizontal] -fill both -expand 1

# секции
foreach i {packages classes categories methods} {
	
	frame .$i
	pack [entry .$i.filter] -side bottom -fill x
	pack [make_scrolled_y .$i [listbox .$i.list -selectmode single -activestyle none]] -side top -fill both -expand 1
	
	.sections add .$i
	
	# при нажатии клавиши в списке перебрасываем её в фильтр
	bind .$i.list <KeyPress> {if {[key_to_filter %W %K] == 1} {break}}
}

# текст
pack [make_scrolled_y [frame .t] [text .t.text -wrap word]] -fill both -expand 1


.main add .sections
.main add .t


bind .t.text <Control-f> { puts "hi!"; break}

# при установке курсора меняем и позицию в тулбаре
rename ::tk::TextSetCursor ::theRealSource::TextSetCursor
proc ::tk::TextSetCursor args {
    set res [uplevel 1 ::theRealSource::TextSetCursor $args]
	regexp {^(\d+)\.(\d+)} [.t.text index insert] -> line col
	set col [expr $col + 1]
	.f.position configure -text "Line $line, Column $col"
	return res
}



	# bind .packages.list <<ListboxSelect>> { puts [list %W %T [%W index active] [%W curselection] [%W index anchor] ] }
	# bind .classes.list <<ListboxSelect>> { puts [list %W %T [%W index active] [%W curselection] [%W index anchor] ] }
	
	
# делает toplevel модальным
proc open_as_modal {$w $top} {
	if {$top == ""} {set top .}

	tkwait visibility $top

	grab $w
	wm transient $w $top
	wm protocol $w WM_DELETE_WINDOW {grab release $w; destroy $w}
	raise $w
	tkwait window $w
}

# подсказка. висит, пока указатель мышки над элементом
proc balloon {w text} {
	bind $w <Enter> { set after_id [after 300 {  
		toplevel $w.balloon -background #666
		pack [label $w.balloon.label -text $text]
	}] }
	bind $w <Leave> { catch { clear $after_id }; catch { destroy $w.balloon } }
}

# диалог поиска
proc find_dialog {} {

	toplevel .s
	wm title .s {Поиск и замена. 0 совпадений в 0 файлов}
	#pack [label .s.status -text {0 совпадений в 0 файлов}] -side left
	
	pack [frame .s.top] -fill x
	pack [entry .s.top.find -text find] -side left -fill x -expand 1
	
	pack [checkbutton .s.top.match_case -text {Aa} -indicatoron 0] -side left
	pack [checkbutton .s.top.word_only -text {[W]} -indicatoron 0] -side left
	pack [checkbutton .s.top.regex -text {.*} -indicatoron 0] -side left
	pack [checkbutton .s.top.local -text {in} -indicatoron 0] -side left
	pack [checkbutton .s.top.show_replace -text {*->*} -indicatoron 0] -side left
	
	pack [frame .s.replace] -fill x
	pack [entry .s.replace.entry] -side left -fill x -expand 1
	
	pack [panedwindow .s.shower -orient vertical] -fill both -expand 1
	
	frame .s.r
	text .s.r.line
	text .s.r.file
	pack [panedwindow .s.r.shower -orient horizontal] -fill both -expand 1
	.s.r.shower add .s.r.line
	.s.r.shower add .s.r.file

	proc setScroll {s args} {
		eval [list $s set] $args
		eval [$s cget -command] [list moveto [lindex [$s get] 0]]
	}
	proc synchScroll {widgets args} {
		foreach w $widgets {eval [list $w] $args}
	}
	proc mouse_click {W x y} {
		set cur [tk::TextClosestGap $W $x $y]
		foreach w {.s.r.line .s.r.file} {
			$w tag delete active_line
			$w tag configure active_line -background [.packages.list cget -selectbackground]
			$w tag add active_line "$cur linestart" "$cur lineend+1c"
		}
		.s.r.line see $cur
	}
	
	scrollbar .s.r.scrollbar  -orient vertical -width 10 -command {synchScroll {.s.r.line .s.r.file} yview}
	pack .s.r.scrollbar -side right -fill y
	pack .s.r.line -expand 1 -side left -fill both
	pack .s.r.file -side left -fill y
		
	foreach w {.s.r.line .s.r.file} {
		$w insert end [exec cat /home/dart/.bashrc]
		$w configure -state disabled -cursor arrow -wrap none -yscrollcommand {setScroll .s.r.scrollbar}
		bind $w <1> { mouse_click %W %x %y }
	}
	
	pack [make_scrolled_y [frame .s.t] [text .s.t.text -wrap word]] -fill both -expand 1
	
	
	.s.shower add .s.r
	.s.shower add .s.t
	
	focus .s.top.find
}

