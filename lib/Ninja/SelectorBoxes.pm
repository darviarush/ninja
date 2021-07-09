package Ninja::SelectorBoxes;
# 

use common::sense;

sub new {
	my ($cls) = @_;
	bless {		
		@_,
	}, ref $cls || $cls;
}

sub package_filter {
	my ($self) = @_;
	$self->{package_filter}
}

sub class_filter {
	my ($self) = @_;
	$self->{class_filter}
}

sub category_filter {
	my ($self) = @_;
	$self->{category_filter}
}

sub method_filter {
	my ($self) = @_;
	$self->{method_filter}
}

sub packages {
	my ($self) = @_;
	$self->{packages}
}

sub classes {
	my ($self) = @_;
	$self->{classes}
}

sub categories {
	my ($self) = @_;
	$self->{categories}
}

sub methods {
	my ($self) = @_;
	$self->{methods}
}


sub listbox_sel {
	my ($box) = @_;
	$box->get($box->curselection)
}

sub listbox_list {
	my ($box) = @_;
	[ map { $box->get($_) } 0..$box->size-1 ]
}

sub listbox_replace {
	my $box = shift;	
	$box->delete(0, "end");
	$box->insert(0, @_);
}

sub bind {
	my ($self) = @_;
	
	# $self->package_filter->bind("<KeyRelease>" => \&evt_package_list);
	# evt_package_list();
	# sub evt_package_list {
		# listbox_replace($packages, $jinnee->package_list($package_filter->get));
	# }

	# $self->class_filter->bind("<KeyRelease>" => \&evt_class_list);
	# $self->packages->bind("<<ListboxSelect>>" => \&evt_class_list);
	# evt_class_list();
	# sub evt_class_list {
		# listbox_replace($classes, $jinnee->class_list($class_filter->get, listbox_sel($packages)));
	# }

	# $self->category_filter->bind("<KeyRelease>" => \&evt_category_list);
	# $self->classes->bind("<<ListboxSelect>>" => \&evt_category_list);
	# evt_category_list();
	# sub evt_category_list {
		# listbox_replace($categories, $jinnee->category_list($category_filter->get, listbox_sel($packages), listbox_sel($classes)));
	# }

	# $self->method_filter->bind("<KeyRelease>" => \&evt_method_list);
	# $self->categories->bind("<<ListboxSelect>>" => \&evt_method_list);
	# evt_method_list();
	# sub evt_method_list {
		# listbox_replace($methods, $jinnee->method_list($method_filter->get, listbox_sel($packages), listbox_sel($classes), listbox_sel($categories)));
	# }

	# $self->methods->bind("<<ListboxSelect>>" => \&evt_method_show);
	# sub evt_method_show {
		
	# }

	
	$self
}



1;