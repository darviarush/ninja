package Ninja::SelectorBoxes;
# списки пакетов, классов, категорий и методов

use common::sense;

sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls
}

sub main { shift->{main} }
sub i { shift->{main}{i} }

sub packages { shift->{packages} }
sub classes { shift->{classes} }
sub categories { shift->{categories} }
sub methods { shift->{methods} }

sub sections { return qw/packages classes categories methods/ }
sub singular { return qw/package class category method/ }
my %singular = map { ((sections())[$_] => (singular())[$_]) } 0..3; 

# создать selector_boxes
sub construct {
	my ($self) = @_;
	
	my $jinnee = $self->main->jinnee;
	my $i = $self->i;
	
	for my $section ($self->sections) {
		$self->{$section} = Ninja::Tk::Listbox->new(frame=>".$section", i=>$i);
		#$i->call("bind", ".$name.list", "<FocusIn>", sub { $self->select_section($name) });
		
		$i->call("bind", ".$section.list", "<<ListboxSelect>>", sub {
			my $x = "$singular{$section}_select";
			::msg "$section - $self->{section} $x";
			
			$self->$x if $self->$section->index ne "";
			
			if($self->$section->size == 0) {
				$self->new_action_class(-1) if $section eq "classes" && $self->{section} eq "packages";
				$self->new_action_method(-1) if $section eq "methods" && $self->{section} eq "categories";
			}
		});
	}

	$i->call(qw/bind .packages.list <Double-1>/, sub { $self->edit_action });
	$i->call(qw/bind .categories.list <Double-1>/, sub { $self->edit_action });
	
	$i->call(qw/bind .packages.filter <KeyRelease>/, sub { $self->packages_init });
	$i->call(qw/bind .classes.filter <KeyRelease>/, sub { $self->package_select });
	$i->call(qw/bind .categories.filter <KeyRelease>/, sub { $self->class_select });
	$i->call(qw/bind .methods.filter <KeyRelease>/, sub { $self->category_select });
	
	$self->packages_init;

	my $selectors = $self->main->project->{selectors};
	if(0 + %$selectors) {
		for my $section ($self->sections) {
			last if !exists $selectors->{$section} || $selectors->{$section} >= $self->$section->size;
			
			$self->$section->select_element($selectors->{$section});
			my $meth = "$singular{$section}_select";
			$self->$meth;
		}
		
		$self->main->area->goto($selectors->{areaCursor}) if $selectors->{areaCursor};
	}
	else {
		$self->packages->select_element(0); 
		$self->package_select;
	}
	
	$self
}


package Ninja::Tk::Listbox {
	# расширяем листбокс
	sub new {
		my $cls = shift;
		my $self = bless {
			HRAN => [],		# доп-информация к элементам
			name => "?",	# имя виджета
			frame => "?",	# имя фрейма виджета
			i => undef, 	# интерпретатор Tcl
			@_,
		}, ref $cls || $cls;
		
		$self->{name} = "$self->{frame}.list";
		$self
	}
	
	sub i { shift->{i} }
	sub name { shift->{name} }
	sub frame { shift->{frame} }
	sub delete { my $self = shift; $self->i->invoke($self->name, qw/delete/, @_); $self }
	sub insert { my $self = shift; $self->i->invoke($self->name, qw/insert/, @_); $self }
	sub index { my ($self) = @_; $self->i->Eval("lindex [$self->{name} curselection] 0") }
	sub anchor { my ($self) = @_; $self->i->Eval("$self->{name} index anchor") }
	sub list { my ($self) = @_; $self->{HRAN} }
	sub size { my ($self) = @_; 0+@{$self->{HRAN}} }
	sub sel {
		my ($self) = @_;
		#::trace("sel");
		my $i = $self->index;
		$i = $self->anchor if $i eq "";
		my $res = $self->{HRAN}[ $i ];
		die "Вначале выберите элемент списка $self->{name}" if !$res;
		$res
	}

	# sub sel {
		# my ($self) = @_;
		# die "Метод sel нельзя использовать если в списке $self->{name} есть выделение" if $self->index ne "";
		# my $res = $self->{HRAN}[ $self->anchor ];
		# die "anchor не установлен в списке $self->{name}" if !$res;
		# $res
	# }

	sub replace {
		my $self = shift;
		$self->delete(0, "end");
		$self->{HRAN} = [@_];
		$self->insert(0, map { $_->{name} } @_);
		$self
	}
	
	sub insert_element {
		my ($self, $idx, $elem) = @_;
		$self->insert($idx, $elem->{name});
		$self->select_element($idx);
		splice @{$self->{HRAN}}, $idx, 0, $elem;
		$self
	}
	
	sub rename_element {
		my ($self, $idx, $elem) = @_;
		$self->delete($idx);
		$self->insert($idx, $elem->{name});
		$self->select_element($idx);
		$self->{HRAN}[$idx] = $elem;
		$self
	}
	
	sub delete_element {
		my ($self, $idx) = @_;
		$self->delete($idx);
		splice @{$self->{HRAN}}, $idx, 1;
		$self->select_element($idx==@{$self->{HRAN}}? $idx-1: $idx) if @{$self->{HRAN}};
	}
	
	sub focus { my ($self) = @_; $self->i->Eval("focus $self->{name}"); $self }
	
	sub select_element {
		my ($self, $index) = @_;
		
		my $n = $self->{name};
		my $prev = $self->{prev};
		
		$self->i->Eval("
			$n selection clear 0 end
			$n selection anchor $index
			$n activate $index
			$n selection set $index
			$n see $index
		");
		
		$self
	}
	
	sub _entry {
		my ($self, $cb) = @_;
		
		my $n = $self->{name};
		$self->i->Eval("
			entry $n.s  -borderwidth 0 -highlightthickness 1
			bind $n.s  <Escape> {destroy $n.s}
			$n.s  insert 0 [$n get [$n index active]]
			$n.s  selection range 0 end
			$n.s  icursor end
			set box [$n bbox [$n index active]]
			place $n.s -relx 0 -y [lindex \$box 1] -relwidth 1 -width -1
			focus $n.s
		");
		$self->i->call("bind", "$n.s", "<Return>", sub { 
			$cb->($self->i->invoke("$n.s", "get"), $self);
			$self->i->invoke("destroy", "$n.s");
			return;
		});
	}
	
	sub filter {
		my ($self) = @_;
		$self->i->invoke("$self->{frame}.filter", "get");
	}

}

# выбрана секция
sub select_section {
	my ($self, $section) = @_;
	$self->{section} = $section;
	$self->i->invoke(qw/.f.who configure -text/, $section);
	#::msg "select_section", $section, $self->$section->sel;
	my $listbox = $self->$section;
	my $i = $listbox->{prev};
	$self->i->Eval(".$section.list itemconfigure $i -background [.$section.list cget -background]") if $i ne "" && $i<@{$listbox->list};
	$listbox->{prev} = $i = $listbox->index;
	$self->i->Eval(".$section.list itemconfigure $i -background [.$section.list cget -selectbackground]") if $i ne "";
	$self
}

# событие инициализации пакетов
sub packages_init {
	my ($self) = @_;
	::msg "- " . (caller(0))[3];
	my $re = $self->packages->filter;
	$self->packages->replace(grep { $_->{name} =~ /$re/i } +{name => "*", all => 1}, $self->main->jinnee->package_list);
	$self
}

# событие на выбор пакета
sub package_select {
	my ($self) = @_;
	
	my $package = $self->packages->sel;
	::msg "- " . (caller(0))[3], $package;
	
	#$self->packages_init, $self->packages->select_element(0) if $package->{name} eq "*";
	
	my $re = $self->classes->filter;
	$self->classes->replace(grep { $_->{name} =~ /$re/i } $self->main->jinnee->class_list($package));
	$self->categories->replace;
	$self->methods->replace;
	$self->main->area->disable;
	
	$self->select_section("packages");
	
	$self
}

sub class_select {
	my ($self) = @_;
	
	my $class = $self->classes->sel;
	::msg "- " . (caller(0))[3], $class;
	
	my $re = $self->categories->filter;
	$self->categories->replace(grep { $_->{name} =~ /$re/i } +{name => "*", path => $class->{path}, all => 1}, $self->main->jinnee->category_list($class));
	$self->methods->replace;
	$self->main->area->to_class($class);
	
	$self->select_section("classes");
	
	$self
}

sub category_select {
	my ($self) = @_;
	
	::msg "- " . (caller(0))[3];
	my $re = $self->methods->filter;
	$self->methods->replace(grep { $_->{name} =~ /$re/i } $self->main->jinnee->method_list($self->categories->sel));
	$self->main->area->disable;
	
	$self->select_section("categories");
	$self
}

sub method_select {
	my ($self) = @_;
	
	::msg "- " . (caller(0))[3];
	
	$self->main->area->to_method($self->methods->sel);

	$self->select_section("methods");

	$self
}

#@category actions

# что выбрано в текущий момент
sub who {
	my ($self) = @_;
	my $section = $self->{section};	
	return $section, $self->$section->index;
}

sub new_action_class {
	my ($self, $idx) = @_;
	
	my $package = $self->packages->sel;
		
	return if $package->{all};
	
	my $class = $self->main->jinnee->class_new("-", $package);
	$self->classes->insert_element($idx+1, $class);
	$self->class_select;
	$self->i->Eval("focus .t.text");
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
		$self->packages->_entry(sub {
			my $package = $jinnee->package_new(shift);
			$self->packages->insert_element($idx+1, $package);
			$self->package_select;
		});
	}
	
	$self->new_action_class($idx) if $type eq "classes";
	
	if($type eq "categories") {
		$self->categories->_entry(sub {
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
	
	$self->packages->_entry(sub {
		$self->packages->rename_element($idx, $jinnee->package_rename(shift, $self->packages->sel));
	}) if $type eq "packages" and !$self->packages->sel->{all};

	$self->categories->_entry(sub {
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
		$self->packages->select_element($idx==$self->packages->size? $idx-1: $idx);
		$self->package_select;
	}
	
	if($type eq "classes") {
		$jinnee->class_erase($self->classes->sel);
		$self->classes->delete_element($idx);
		if($self->classes->size == 0) {
			$self->packages->select_element($self->packages->anchor);
			$self->package_select;
		} else { $self->class_select }
	}
		
	if($type eq "categories" and !$self->categories->sel->{all}) {
		$jinnee->category_erase($self->categories->sel);
		$self->categories->delete_element($idx);
		$self->category_select;
	}

	if($type eq "methods") {
		$jinnee->method_erase($self->methods->sel);
		$self->methods->delete_element($idx);
		if($self->methods->size == 0) { 
			$self->categories->select_element($self->categories->anchor);
			$self->category_select;
		} else { $self->method_select }
	}
}

1;