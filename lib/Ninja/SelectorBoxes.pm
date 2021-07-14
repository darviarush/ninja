package Ninja::SelectorBoxes;
# 

use common::sense;

my $SEL;

sub new {
	return $SEL if $SEL;
	
	my $cls = shift;
	$SEL = my $self = bless {@_}, ref $cls || $cls;
	$self
}

sub package_filter { shift()->{package_filter} }
sub class_filter { shift()->{class_filter} }
sub category_filter { shift()->{category_filter} }
sub method_filter { shift()->{method_filter} }
sub packages { shift()->{packages} }
sub classes { shift()->{classes} }
sub categories { shift()->{categories} }
sub methods { shift()->{methods} }
sub main { shift()->{main} }

package Tk::Listbox {
	# расширяем листбокс
	sub sel {
		my ($self) = @_;
		
		$self->{HRAN}[ $self->curselection->[0] ]
	}

	sub list {
		my ($self) = @_;
		$self->{HRAN}
	}

	sub replace {
		my $self = shift;		
		$self->delete(0, "end");
		$self->{HRAN} = [@_];
		$self->insert(0, map { $_->{name} } @_);
	}
	
	sub select_element {
		my ($self, $index) = @_;
		$self->activate($index);
		$self->selectionSet($index);
	}
	
	sub _entry {
		my ($list, $cb) = @_;
		my $idx = $list->curselection;
		my $box = $list->bbox($idx);
		my $entry = $list->Entry(-borderwidth=>0, -highlightthickness=>1);
		$entry->bind("<Return>" => sub { $cb->($entry->get); $entry->destroy });
		$entry->bind("<Escape>" => sub { $entry->destroy });
		$entry->insert(0, $list->get($idx));
		$entry->selectionRange(0, "end");
		$entry->icursor("end");
		$entry->place(-relx=>0, -y=>$box->[1], -relwidth=>1, -width=>-1);
		$entry->focus;
		#$entry->grab;
	}
}

sub construct {
	my ($self) = @_;
	
	my $jinnee = $self->main->jinnee;

	my $package_filter = $self->{package_filter};
	my $class_filter = $self->{class_filter};
	my $category_filter = $self->{category_filter};
	my $method_filter = $self->{method_filter};
	my $packages = $self->{packages};
	my $classes = $self->{classes};
	my $categories = $self->{categories};
	my $methods = $self->{methods};

	$self->main->root->bind("<F2>" => sub {
		my $sel_cat = $categories->curselection;
		my $sel_met = $methods->curselection;
		
		if(@$sel_cat && !@$sel_met) {
			$categories->_entry(sub {  });
		}
		
		my $sel_pkg = $packages->curselection;
		my $sel_cls = $classes->curselection;
		
		if(@$sel_pkg && !@$sel_cls) {
			$packages->_entry(sub {  });
		}
	});

	$packages->bind("<Double-1>" => sub { $packages->_entry(sub {}) });
	
	$package_filter->bind("<KeyRelease>" => (my $evt_package_list = sub {
		# print "KeyRelease\n";
		# ::p my $k=$Tk::event? $Tk::event->K: undef;
		$packages->replace($jinnee->package_list($package_filter->get));
	}));
	$evt_package_list->();

	$class_filter->bind("<KeyRelease>" => (my $evt_class_list = sub {
		$classes->replace($jinnee->class_list($class_filter->get, $packages->sel));
		$categories->replace;
		$methods->replace;
		$self->main->area->disable;
	}));
	$packages->bind("<<ListboxSelect>>" => $evt_class_list);
	
	$packages->select_element(0);
	$evt_class_list->();


	$category_filter->bind("<KeyRelease>" => (my $evt_category_list = sub {
		$categories->replace($jinnee->category_list($category_filter->get, $classes->sel));
		$methods->replace;
		$self->main->area->to_class($classes->sel);
	}));
	$self->classes->bind("<<ListboxSelect>>" => $evt_category_list);


	$method_filter->bind("<KeyRelease>" => (my $evt_method_list = sub {
		$methods->replace( $jinnee->method_list($method_filter->get, $categories->sel) );
		$self->main->area->disable;
	}));
	$self->categories->bind("<<ListboxSelect>>" => $evt_method_list);


	$methods->bind("<<ListboxSelect>>" => (my $evt_method_show = sub {
		$self->main->area->to_method($methods->sel);
	}));

	
	$self
}



1;