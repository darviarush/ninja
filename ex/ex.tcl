#!/usr/bin/tclsh
package require Tk 8

# regexp {(?<x>\d+)} "-123-" -> sub1
# puts $sub1
# exit


pack [text .t -wrap word] -fill both -expand 1

.t insert end "Здравствуй Мир!"

tk appname "Мировой!"
