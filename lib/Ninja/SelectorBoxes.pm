package Ninja::SelectorBoxes;
# списки пакетов, классов, категорий и методов

use common::sense;

sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls
}

sub main { shift->{main} }
sub i { shift->{main}{i} }
sub section { shift->{section} }

sub packages { shift->{packages} }
sub classes { shift->{classes} }
sub categories { shift->{categories} }
sub methods { shift->{methods} }

# создать selector_boxes
sub construct {
	my ($self) = @_;
	
	my $jinnee = $self->main->jinnee;
	my $i = $self->i;
	
	for my $section ($jinnee->sections) {
		$self->{$section} = Ninja::Tk::Listbox->new(frame=>".$section", i=>$i);
		#$self->i->call("bind", ".$name.list", "<FocusIn>", sub { $self->select_section($name) });
		
		$self->i->call("bind", ".$section.list", "<<ListboxSelect>>", sub {
			my $x = $jinnee->sin($section) . "_select";
			::msg "<<ListboxSelect>>: $section - $self->{section} $x";
			
			$self->$x if $self->$section->index ne "";
			
			if($self->$section->size == 0) {
				$self->new_action_class(-1) if $section eq "classes" && $self->{section} eq "packages";
				$self->new_action_method(-1) if $section eq "methods" && $self->{section} eq "categories";
			}
		});
		
		$self->i->call("bind", ".$section.filter", "<KeyRelease>", sub { $self->$section->filter_set });
	}

	$self->i->call(qw/bind .packages.list <Double-1>/, sub { $self->edit_action });
	$self->i->call(qw/bind .categories.list <Double-1>/, sub { $self->edit_action });
	
	$self->packages_init;

	my $set;
	my $selectors = $self->main->project->{selectors};
	::msg "selectors", $selectors;
	if(0 + %$selectors) {
		for my $section ($jinnee->sections) {
			last if !exists $selectors->{$section} || $selectors->{$section} >= $self->$section->size;
			
			$self->$section->select_element($selectors->{$section});
			my $meth = $jinnee->sin($section) . "_select";
			$self->$meth;
			
			$set++;
		}
		
		$self->main->area->goto($selectors->{areaCursor}) if $selectors->{areaCursor};
	}
	
	if(!$set) {
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
			A => [],		# все сущности в списке
			HRAN => [],		# отображённые сущности
			sel => undef, 	# выбранная сущность
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
	sub all { my ($self) = @_; $self->{A} }
	sub power { my ($self) = @_; 0+@{$self->{A}} }
	sub sel {
		my ($self) = @_;
		#::trace("sel");
		my $i = $self->index;
		$i = $self->anchor if $i eq "";
		return undef if $i eq "";
		$self->{HRAN}[ $i ];
	}

	sub filter {
		my ($self) = @_;
		$self->i->invoke("$self->{frame}.filter", "get");
	}
	
	sub filter_set {
		my ($self) = @_;
		my $sel = $self->sel;
		$self->replace(my @copy = @{$self->{A}});
		my $idx = $self->scan($sel);
		$self->select_element($idx)->activate if defined $idx;
		$self
	}

	sub replace {
		my $self = shift;
		$self->clear;
		$self->append(@_);
	}
	
	sub clear {
		my $self = shift;
		$self->delete(0, "end");
		@{$self->{A}} = ();
		@{$self->{HRAN}} = ();
		$self
	}
	
	sub append {
		my $self = shift;
		push @{$self->{A}}, @_;
		my $re = $self->filter;
		return $self if not my @HRAN = grep { $_->{name} =~ /()$re/i } @_;
		push @{$self->{HRAN}}, @HRAN;
		$self->insert("end", map { $_->{name} } @HRAN);
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
		%{$self->{HRAN}[$idx]} = %$elem;
		$self
	}
	
	sub delete_element {
		my ($self, $idx) = @_;
		$self->delete($idx);
		my ($elem) = splice @{$self->{HRAN}}, $idx, 1;
		my $index = $self->scan_all($elem);
		splice @{$self->{A}}, $index, 1;
		$self->select_element($idx==@{$self->{HRAN}}? $idx-1: $idx) if @{$self->{HRAN}};
	}
	
	#sub focus { my ($self) = @_; $self->i->Eval("focus $self->{name}"); $self }
	
	sub select_element {
		my ($self, $index) = @_;
		
		my $n = $self->{name};
		
		$self->i->Eval("
			$n selection clear 0 end
			$n selection anchor $index
			$n activate $index
			$n selection set $index
			$n see $index
		");
		
		$self
	}
	
	sub activate {
		my ($self) = @_;
		# active_idx - текущий активный индекс. Его нужно перезакрасить
		my $i = $self->{active_idx};
		my $n = $self->{name};
		$self->i->Eval("$n itemconfigure $i -background [$n cget -background]") if $i ne "" && $i<$self->size;
		$self->{active_idx} = my $index = $self->index;
		$self->i->Eval("
			$n itemconfigure $index -background [$n cget -selectbackground]
			$n see $index
		");
	}
	
	sub scan {
		my ($self, $who) = @_;
		my $i = 0;
		for(@{$self->{HRAN}}) {
			return $i if $_->{path} eq $who->{path};
			$i++;
		}
		return undef;
	}
	
	sub scan_all {
		my ($self, $who) = @_;
		my $i = 0;
		for(@{$self->{A}}) {
			return $i if $_ == $who;
			$i++;
		}
		return undef;
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
			$cb->(scalar $self->i->invoke("$n.s", "get"), $self);
			$self->i->invoke("destroy", "$n.s");
			return;
		});
	}	
}

# выбрана секция
sub select_section {
	my ($self, $section) = @_;
	$self->{section} = $section;
	$self->i->invoke(qw/.f.who configure -text/, $section);
	#::msg "select_section", $section, $self->$section->sel;
	$self->$section->activate;
	$self
}

# вспомогательный метод для выбора указанной сущности
sub select_by {
	my ($self, $who) = @_;
	my $section = $who->{section};
	my $select = $self->main->jinnee->sin($section) . "_select";
	my $idx = $self->$section->scan($who);
	$self->$section->select_element($idx) if defined $idx;
	$self->$select($who);
}

# выбирает сущность
sub select {
	my ($self, $who) = @_;
	
	# очистка фильтров
	$self->i->Eval(".$_.filter delete 0 end") for $self->main->jinnee->sections;
	
	if($who->{category}) {
		$self->select_by($who->{category}{class}{package});
		$self->select_by($who->{category}{class});
		$self->select_by($who->{category});
		$self->select_by($who);
	}
	elsif($who->{class}) {
		$self->select_by($who->{class}{package});
		$self->select_by($who->{class});
		$self->select_by($who);
	}
	elsif($who->{package}) {
		$self->select_by($who->{package});
		$self->select_by($who);
	}
	else {
		$self->select_by($who);
	}
}

# событие инициализации пакетов
sub packages_init {
	my ($self) = @_;
	::msg "- " . (caller(0))[3];
	
	$self->packages->replace(
		+{section => "packages", name => "*", all => 1}, 
		$self->main->jinnee->package_list,
	);
	$self
}

# событие на выбор пакета
sub package_select {
	my ($self, $package) = @_;
	
	$package //= $self->packages->sel;
	::msg "- " . (caller(0))[3], $package;

	#$self->packages_init, $self->packages->select_element(0) if $package->{name} eq "*";

	if($package->{all}) {
		my @packages = @{$self->packages->list}[1..$self->packages->size-1];

		$self->classes->clear;
		
		$self->idle("package_select" => sub {
			$self->classes->append($self->main->jinnee->class_list(shift @packages));
			0+@packages
		});
				
	} else {
		my @classes = $self->main->jinnee->class_list($package);
		$self->classes->replace(@classes);
	}
	
	$self->categories->clear;
	$self->methods->clear;
	$self->main->area->disable;

	$self->select_section("packages");	

	$self
}

sub class_select {
	my ($self, $class) = @_;
	
	$class //= $self->classes->sel;
	::msg "- " . (caller(0))[3], $class;
	
	$self->categories->replace(
		+{section => "categories", name => "*", class => $class, all => 1}, 
		$self->main->jinnee->category_list($class),
	);
	$self->methods->clear;
	$self->main->area->to_class($class);
	
	$self->select_section("classes");
	
	$self
}

sub category_select {
	my ($self, $category) = @_;
	
	::msg "- " . (caller(0))[3];
	
	$category //= $self->categories->sel;
	
	if($category->{all}) {
		my @categories = @{$self->categories->list}[1..$self->categories->size-1];

		$self->methods->clear;
		
		$self->idle("category_select" => sub {
			$self->methods->append($self->main->jinnee->method_list(shift @categories));
			0+@categories;
		});
		
	} else {
		$self->methods->replace($self->main->jinnee->method_list($category));
	}
	
	$self->main->area->disable;
	
	$self->select_section("categories");
	$self
}

sub method_select {
	my ($self, $method) = @_;
	
	::msg "- " . (caller(0))[3];
	
	$method //= $self->methods->sel;
	
	$self->main->area->to_method($method);

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
	my ($section, $idx) = $self->who;
	my $jinnee = $self->main->jinnee;
	
	
	if($section eq "packages") {
		$self->packages->_entry(sub {
			my $package = $jinnee->package_new(shift);
			$self->packages->insert_element($idx+1, $package);
			$self->package_select;
		});
	}
	
	$self->new_action_class($idx) if $section eq "classes";
	
	if($section eq "categories") {
		$self->categories->_entry(sub {
			my $class = $self->classes->sel;
			my $category = $jinnee->category_new(shift, $class);
			$self->categories->insert_element($idx+1, $category);
			$self->category_select;
		});
	}
	
	$self->new_action_method($idx) if $section eq "methods";
}

# редактировать категорию или пакет
sub edit_action {
	my ($self, $new_name) = @_;
	my $jinnee = $self->main->jinnee;
	my ($section, $idx) = $self->who;
	
	$self->packages->_entry(sub {
		$self->packages->rename_element($idx, $jinnee->package_rename(shift, $self->packages->sel));
		$self->package_select;
	}) if $section eq "packages" and !$self->packages->sel->{all};

	$self->categories->_entry(sub {
		$self->categories->rename_element($idx, $jinnee->category_rename(shift, $self->categories->sel));
		$self->category_select;
	}) if $section eq "categories" and !$self->categories->sel->{all};
	
	$self->main->area->goto("1.end"), $self->i->Eval('
		set bg [.t.text cget -background]
		.t.text configure -background #ccf
		after 300 {.t.text configure -background $bg}
	') if $section =~ /classes|methods/;
}

# удалить текущий объект
sub delete_action {
	my ($self) = @_;
	my $jinnee = $self->main->jinnee;
	my ($section, $idx) = $self->who;

	if($section eq "packages" and !$self->packages->sel->{all}) {
		$jinnee->package_erase($self->packages->sel);
		$self->packages->delete_element($idx);
		$self->packages->select_element($idx==$self->packages->size? $idx-1: $idx);
		$self->package_select;
	}
	
	if($section eq "classes") {
		$jinnee->class_erase($self->classes->sel);
		$self->classes->delete_element($idx);
		if($self->classes->size == 0) {
			$self->packages->select_element($self->packages->anchor);
			$self->package_select;
		} else { $self->class_select }
	}
		
	if($section eq "categories" and !$self->categories->sel->{all}) {
		$jinnee->category_erase($self->categories->sel);
		$self->categories->delete_element($idx);
		$self->category_select;
	}

	if($section eq "methods") {
		$jinnee->method_erase($self->methods->sel);
		$self->methods->delete_element($idx);
		if($self->methods->size == 0) { 
			$self->categories->select_element($self->categories->anchor);
			$self->category_select;
		} else { $self->method_select }
	}
}

# восстановить объект
sub restore_action {
	my ($self) = @_;
	my $jinnee = $self->main->jinnee;
	my ($section, $idx) = $self->who;

	$self->i->Eval("
		toplevel .restore
		
	");

	if($section eq "packages" and !$self->packages->sel->{all}) {
		$jinnee->package_erase($self->packages->sel);
		$self->packages->delete_element($idx);
		$self->packages->select_element($idx==$self->packages->size? $idx-1: $idx);
		$self->package_select;
	}
	
	if($section eq "classes") {
		$jinnee->class_erase($self->classes->sel);
		$self->classes->delete_element($idx);
		if($self->classes->size == 0) {
			$self->packages->select_element($self->packages->anchor);
			$self->package_select;
		} else { $self->class_select }
	}
		
	if($section eq "categories" and !$self->categories->sel->{all}) {
		$jinnee->category_erase($self->categories->sel);
		$self->categories->delete_element($idx);
		$self->category_select;
	}

	if($section eq "methods") {
		$jinnee->method_erase($self->methods->sel);
		$self->methods->delete_element($idx);
		if($self->methods->size == 0) { 
			$self->categories->select_element($self->categories->anchor);
			$self->category_select;
		} else { $self->method_select }
	}
}

# закрыть диалог поиска
sub find_close {
	my ($self) = @_;

	my $i = $self->i;
	my $project = $self->main->project;
	
	$project->{find} = {
		geometry => $i->icall(qw/wm geometry .s/),
		height => $i->Eval("winfo height .s.r"),
	};
	
	$i->Eval("destroy .s");
	
	$self
}

# найти или заменить
sub find_action {
	my ($self, $local, $replace) = @_;
	
	my $jinnee = $self->main->jinnee;
	my ($section, $idx) = $self->who;	
	my $i = $self->i;
	
	# удаление
	$i->Eval("catch { destroy .s }");
	$self->cancel("find_action");
	
	# создание
	$i->Eval("find_dialog");
	
	$i->SetVar("local", $local);
	$i->SetVar("show_replace", $replace);
	
	my $x = eval { $i->Eval(".t.text get sel.first sel.last") } //
		$self->$section->sel->{name};
	$i->invoke(qw/.s.top.find insert end/, $x);
	$i->invoke(qw/.s.top.find selection range 0 end/);
	
	# конфигурация
	my $project = $self->main->project;
	$i->icall(qw/wm geometry .s/, $project->{find}{geometry}) if $project->{find}{geometry};
	$i->icall(qw/.s.shower paneconfigure .s.r -height/, $project->{find}{height}) if $project->{find}{height};
	
	$i->call(qw/wm protocol .s WM_DELETE_WINDOW/, sub { $self->find_close });	

	# устанавливаем теги с цветами
	my $tags = $jinnee->tags;
	for my $w (qw/.s.r.line .s.r.file .s.t.text/) {
		$i->invoke($w, qw/tag configure/, $_ => @{$tags->{$_}}) for sort keys %$tags;
	}
	
	# показываем в нижнем окошке, если не указан goto, иначе - переходим 
	$i->CreateCommand("::perl::find_line_show" => sub {
		my ($line) = $i->GetVar("cur") =~ /^(\d+)/;
		my $goto = $i->GetVar("goto");

		my $res = $jinnee->{find_param}{result}[$line-1];
		
		my ($from, $to) = @{$res->{select_in_text}};
		
		# перейти на результат
		if($goto) {
			# закрываем окно поиска
			$self->find_close;

			# выбираем в основном окне объект поиска
			$self->select($res->{who}) if $res->{who} != self->$section->sel;
			
			# - TODO: выделить найденные элементы?
			# TODO: установить курсор на искомый элемент
			
			$self->main->area->select($from, $to);
			$self->main->area->goto($to);

			return;
		}

		my ($linestart, $text) = $jinnee->get($res->{who});

		$i->Eval("
			.s.t.text configure -state normal
			.s.t.text delete 1.0 end
		");

		# TODO: выделение в тексте и see
		# TODO: переставлять курсор
		# TODO: замена
		# TODO: движение построчно курсором

		$i->invoke(qw/.s.t.text insert end/, @$_) for @{$jinnee->color($text)};
		
		$i->Eval("
			.s.t.text tag add find_illumination $from $to
			#tk::TextSetCursor .s.t.text $to
			.t.text see $to
		");

		$i->Eval(".s.t.text configure -state disable");
	});

	
	# события	
	$i->Eval("bind .s.top.find <Up> {puts \"%A %K\"}");
	$i->Eval("bind .s.top.find <Down> {puts \"%A %K\"}");
	
	$i->call(qw/bind .s.top.find <KeyRelease>/, sub { $self->find_start });
	
	$self->find_start if length $i->Eval(".s.top.find get");
	
	$self
}

sub find_start {
	my ($self) = @_;
	
	my ($section, $idx) = $self->who;
	my $i = $self->i;
	
	# останавливаем предыдущий поиск и очищаем окна поиска
	$self->cancel("find_action");
	$self->find_list_manip(sub {
		$i->Eval(".s.r.line delete 1.0 end");
		$i->Eval(".s.r.file delete 1.0 end");
		::msg "delete!";
	});
	
	
	my $re = $i->Eval(".s.top.find get");
	
	return $self if !length $re;
	
	my $match_case = $i->GetVar("match_case");
	my $word_only = $i->GetVar("word_only");
	my $regex = $i->GetVar("regex");
	my $local = $i->GetVar("local");
	my $show_replace = $i->GetVar("show_replace");
	
	return $self if $local && $self->main->area->disabled;
	
	$re = quotemeta $re if !$regex;
	if($word_only) {
		$re = "\\b$re" if $re =~ /^\w/;
		$re = "$re\\b" if $re =~ /\w\z/;
	}
	$re = "(?i:$re)" if !$match_case;

	$self->main->jinnee->find_set($re, $local? $self->$section->sel: ());

	$self->idle("find_action" => sub {
		my $res = $self->main->jinnee->find;
		
		return 0 if !ref $res;
		
		my $index = $i->Eval(".s.r.line index end-1c");
		my ($line) = split /\./, $index;
		for my $r ( @$res ) {
			$self->find_list_manip(sub {
				$i->icall(qw/.s.r.line insert end/, @$_) for @{$r->{line}};
				$i->icall(qw/.s.r.file insert end/, @$_) for @{$r->{file}};
			});
			
			my ($c1, $c2) = @{$r->{select}};
			$i->icall(qw/.s.r.line tag add find_illumination/, "$line.$c1", "$line.$c2");
			
			
			
			$line++;
		}
		
		return 1;
	});
	
	$self
}

# включает списки найденного для редактирования
sub find_list_manip {
	my ($self, $sub) = @_;
	$self->i->Eval(".s.r.line configure -state normal; .s.r.file configure -state normal");
	$sub->();
	$self->i->Eval(".s.r.line configure -state disable; .s.r.file configure -state disable");
	$self
}

# Запускает на выполнение в фоне функцию, которая будет вызываться пока возвращает 1 
# или её не перекроет функция с тем же идентификатором
sub idle {
	my ($self, $id, $idle) = @_;
	
	$self->cancel($id);
	
	$self->i->CreateCommand("::perl::idle_$id" => $idle);
	$self->i->Eval("
	proc idle_$id {} {
		if {[::perl::idle_$id]} { 
			set _idle_$id [after idle idle_$id]
		} else {
			proc ::perl::idle_$id {} {}
			proc idle_$id {} {}
		}
	}
	
	set _idle_$id [after idle idle_$id]
	");
	
	$self
}

# прекращает выполнение idle-функции по id
sub cancel {
	my ($self, $id) = @_;

	$self->i->Eval("
		catch { after cancel \$_idle_$id }
		proc ::perl::idle_$id {} {}
		proc idle_$id {} {}
	");
}

1;