#!/bin/tclsh
package require Tk

# окно

tk appname "Ninja"

wm protocol . WM_DELETE_WINDOW {
	::perl::on_window_destroy
	destroy .
}

# редактирование
bind Entry <Control-a> { event generate %W <<SelectAll>> }

bind Entry <<Paste>> {
	catch { %W delete sel.first sel.last }
	catch {
		%W insert insert [::tk::GetSelection %W CLIPBOARD]
		tk::EntrySeeInsert %W
	}
}

bind Text <Control-a> { event generate %W <<SelectAll>> }


# puts  [ttk::style theme names]
# puts [ttk::style theme use]
# # clam alt default classic
# # default
# ttk::style theme use classic

proc make_scrolled_y {f w} {
	scrollbar $f.scrollbar  -orient vertical -width 10 -command "$w yview"
	$w configure -yscrollcommand "$f.scrollbar set"
	pack $f.scrollbar -side right -fill y
	pack $w -expand 1 -fill both
	return $f
}


pack [panedwindow .main -orient vertical] -fill both -expand 1
pack [panedwindow .sections -orient horizontal] -fill both -expand 1


# секции
foreach i {packages classes categories methods} {
	
	pack [make_scrolled_y [frame .$i] [listbox .$i.list]] -side top -fill both -expand 1
	
	pack [entry .$i.filter] -side bottom -fill both
	
	.sections add .$i
}

# текст
pack [make_scrolled_y [frame .t] [text .t.text -wrap word]] -fill both -expand 1

# тулбар
pack [frame .f] -side bottom
pack [label .f.position -text "Line 1, Column 1" -justify left] -side left

# закрываем
.main add .sections
.main add .t


# при установке курсора меняем и позицию в тулбаре
rename ::tk::TextSetCursor ::theRealSource::TextSetCursor
proc ::tk::TextSetCursor args {
    set res [uplevel 1 ::theRealSource::TextSetCursor $args]
	regexp {^(\d+)\.(\d+)} [.t.text index insert] -> line col
	set col [expr $col + 1]
	.f.position configure -text "Line $line, Column $col"
	return res
}

