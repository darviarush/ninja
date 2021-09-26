package require Ttk

# Create a panedwindow
ttk::frame .f
ttk::panedwindow .f.pane -orient vertical

# Create three panes
ttk::frame .f.pane.one -height 50 -width 50
ttk::label .f.pane.one.l -text "Number one"
pack .f.pane.one.l

ttk::frame .f.pane.two -height 50 -width 50
ttk::label .f.pane.two.l -text "Number two"
pack .f.pane.two.l

ttk::frame .f.pane.three -height 50 -width 50
ttk::label .f.pane.three.l -text "Number three"
pack .f.pane.three.l

# Add frames one and two to the panedwindow
.f.pane add .f.pane.one
.f.pane add .f.pane.two

pack .f.pane -expand 1 -fill both
pack .f -expand 1 -fill both

# Replace pane one with pane three
.f.pane insert 1 .f.pane.three
.f.pane forget 2 