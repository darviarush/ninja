package Ninja::SelectorBoxes;
# списки пакетов, классов, категорий и методов

use common::sense;

sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls
}

sub i { shift()->{main}{i} }

sub package_filter { shift()->{package_filter} }
sub class_filter { shift()->{class_filter} }
sub category_filter { shift()->{category_filter} }
sub method_filter { shift()->{method_filter} }
sub packages { shift()->{packages} }
sub classes { shift()->{classes} }
sub categories { shift()->{categories} }
sub methods { shift()->{methods} }
sub main { shift()->{main} }
sub sections { return qw/packages classes categories methods/ }
sub singular { return qw/package class category method/ }

# создать selector_boxes
sub construct {
	my ($self) = @_;
	
	my $jinnee = $self->main->jinnee;
	my $i = $self->i;
	
	
	$i->call(qw/.packages.list replace {1 2 3}/);
	
	return $self;


	$i->call(qw/bind packages.list <Double-1>/, sub { $self->edit_action });
	$i->call(qw/bind categories.list <Double-1>/, sub { $self->edit_action });
	
	$i->call(qw/bind packages.filter <KeyRelease>/, sub { $self->packages_init });
	$self->packages_init;

	$i->call(qw/bind classes.filter <KeyRelease>/, sub { $self->package_select });
	$i->call(qw/bind packages.list <<ListboxSelect>>/, sub { $self->package_select });

	$i->call(qw/bind categories.filter <KeyRelease>/, sub { $self->class_select });
	$i->call(qw/bind packages.list <<ListboxSelect>>/, sub { $self->class_select });


	$i->call(qw/bind methods.filter <KeyRelease>/, sub { $self->category_select });
	$i->call(qw/bind categories.list <<ListboxSelect>>/, sub { $self->category_select });


	$i->call(qw/bind methods.list <<ListboxSelect>>/, sub { $self->method_select });

	my $project = $self->main->project;
	if($project) {
		my $i;
		for my $section ($self->sections) {
			my $sec;
			my $singular = ($self->singular)[$i];
			if(@{$sec = $project->{selectors}->{$singular}}) {
				last if @{$self->{$section}->list} <= $sec->[0];
				$self->{$section}->select_element($sec->[0]);
				my $meth = "${singular}_select";
				$self->$meth;
			}
			$i++;
		}
		
		
	}
	else {
		$i->call(); #$packages->select_element(0); 
		$self->package_select;
	}
	
	
	$self
}


package Tk::Listbox {
	# расширяем листбокс
	sub sel {
		my ($self) = @_;
		#::trace("sel");
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
	
	sub insert_element {
		my ($self, $idx, $elem) = @_;
		$self->insert($idx, $elem->{name});
		$self->select_element($idx);
		splice @{$self->{HRAN}}, $idx, 0, $elem;
	}
	
	sub rename_element {
		my ($self, $idx, $elem) = @_;
		$self->delete($idx);
		$self->insert($idx, $elem->{name});
		$self->select_element($idx);
		$self->{HRAN}[$idx] = $elem;
	}
	
	sub delete_element {
		my ($self, $idx) = @_;
		$self->delete($idx);
		splice @{$self->{HRAN}}, $idx, 1;
		$self->select_element($idx==0? 0: $idx-1) if @{$self->{HRAN}};	
	}
	
	sub select_element {
		my ($self, $index) = @_;
		my $idx = $self->curselection;
		$self->selectionClear($idx->[0]) if @$idx;
		$self->activate($index);
		$self->selectionSet($index);
	}
	
	sub _entry {
		my ($self, $main, $cb) = @_;
		my $idx = $self->curselection->[0];
		my $box = $self->bbox($idx);
		my $entry = $self->Entry(-borderwidth=>0, -highlightthickness=>1);
		$entry->bind("<Return>" => sub { 
			eval { $cb->($entry->get, $idx, $self); };
			$main->errorbox($@) if $@;
			$entry->destroy;
		});
		$entry->bind("<Escape>" => sub { $entry->destroy });
		$entry->insert(0, $self->get($idx));
		$entry->selectionRange(0, "end");
		$entry->icursor("end");
		$entry->place(-relx=>0, -y=>$box->[1], -relwidth=>1, -width=>-1);
		$entry->focus;
		#$entry->grab;
	}
}

# событие инициализации пакетов
sub packages_init {
	my ($self) = @_;
	my $re = $self->package_filter->get;
	$self->packages->replace(grep { $_->{name} =~ /$re/i } +{name => "*", all => 1}, $self->main->jinnee->package_list);
	$self
}

# событие на выбор пакета
sub package_select {
	my ($self) = @_;
	my $package = $self->packages->sel;
	
	$self->packages_init, $self->packages->select_element(0) if $package->{name} eq "*";
	
	my $re = $self->class_filter->get;
	$self->classes->replace(grep { $_->{name} =~ /$re/i } $self->main->jinnee->class_list($package));
	$self->categories->replace;
	$self->methods->replace;
	$self->main->area->disable;
	
	$self->{section} = "packages";
	$self
}

sub class_select {
	my ($self) = @_;
	
	$self->new_action_class(-1), return if !@{$self->classes->list};
	
	my $class = $self->classes->sel;
	my $re = $self->category_filter->get;
	$self->categories->replace(grep { $_->{name} =~ /$re/i } +{name => "*", path => $class->{path}, all => 1}, $self->main->jinnee->category_list($class));
	$self->methods->replace;
	$self->main->area->to_class($self->classes->sel);
	
	$self->{section} = "classes";
	$self
}

sub category_select {
	my ($self) = @_;
	my $re = $self->method_filter->get;
	$self->methods->replace(grep { $_->{name} =~ /$re/i } $self->main->jinnee->method_list($self->categories->sel));
	$self->main->area->disable;
	$self->{section} = "categories";
	$self
}

sub method_select {
	my ($self) = @_;
	
	$self->new_action_method(-1), return if !@{$self->methods->list};
	
	$self->main->area->to_method($self->methods->sel);
	
	$self->{section} = "methods";
	$self
}

#@category actions

# что выбрано в текущий момент
sub who {
	my ($self) = @_;
	my $section = $self->{section};	
	return $section, $self->$section->curselection->[0];
}

sub new_action_class {
	my ($self, $idx) = @_;
	
	my $package = $self->packages->sel;
		
	return if $package->{all};
	
	my $class = $self->main->jinnee->class_new("-", $package);
	$self->classes->insert_element($idx+1, $class);
	$self->class_select;
}

sub new_action_method {
	my ($self, $idx) = @_;
	
	my $category = $self->categories->sel;
		
	return if $category->{all};
	
	my $method = $self->main->jinnee->method_new("a -", $category);
	$self->methods->insert_element($idx+1, $method);
	$self->method_select;
}

# создать объект в текущей секции
sub new_action {
	my ($self) = @_;
	my ($type, $idx) = $self->who;
	my $jinnee = $self->main->jinnee;
	
	
	if($type eq "packages") {
		$self->packages->_entry($self->main, sub {
			my $package = $jinnee->package_new(shift);
			$self->packages->insert_element($idx+1, $package);
			$self->package_select;
		});
	}
	
	$self->new_action_class($idx) if $type eq "classes";
	
	if($type eq "categories") {
		$self->categories->_entry($self->main, sub {
			my $class = $self->classes->sel;
			my $category = $jinnee->category_new(shift, $class);
			$self->categories->insert_element($idx+1, $category);
			$self->category_select;
		});
	}
	
	$self->new_action_method($idx) if $type eq "methods";
}

# редактировать категорию или пакет
sub edit_action {
	my ($self) = @_;
	my $jinnee = $self->main->jinnee;
	my ($type, $idx) = $self->who;
	
	$self->packages->_entry($self->main, sub {
		$self->packages->rename_element($idx, $jinnee->package_rename(shift, $self->packages->sel));
	}) if $type eq "packages" and !$self->packages->sel->{all};

	$self->categories->_entry($self->main, sub {
		$self->categories->rename_element($idx, $jinnee->category_rename(shift, $self->categories->sel));
	}) if $type eq "categories" and !$self->categories->sel->{all};
	
	$self->main->area->goto("1.end") if $type =~ /classes|methods/;
}

# удалить текущий объект
sub delete_action {
	my ($self) = @_;
	my $jinnee = $self->main->jinnee;
	my ($type, $idx) = $self->who;

	if($type eq "packages" and !$self->packages->sel->{all}) {
		$jinnee->package_erase($self->packages->sel);
		$self->packages->delete_element($idx);
		$self->package_select;
	}
	
	if($type eq "classes") {
		$jinnee->class_erase($self->classes->sel);
		$self->classes->delete_element($idx);
		if(!@{$self->classes->list}) { $self->package_select } else { $self->class_select }
	}
		
	if($type eq "categories" and !$self->categories->sel->{all}) {
		$jinnee->category_erase($self->categories->sel);
		$self->categories->delete_element($idx);
		$self->category_select;
	}

	if($type eq "methods") {
		$jinnee->method_erase($self->methods->sel);
		$self->methods->delete_element($idx);
		if(!@{$self->methods->list}) { $self->category_select } else { $self->method_select }
	}
}

1;