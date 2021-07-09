package Ninja::Config;
# Конфиг

use common::sense;
use JSON::XS;

my $json = JSON::XS->new->canonical->allow_nonref->pretty(1);

sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls;
}

sub load {
	my ($self) = @_;
	
	if(-f $self->path) {
		open my $f, $self->path or do { warn "$self->{path}: $!"; return };
		read $f, $_, -s $f;
		close $f;
		eval {
			%$self = (%$self, %{ $json->decode($_) });
		};
		warn $@ if $@;
    }
	
	$self
}

sub save {
	my ($self) = @_;
	
	my $config_path = $self->path;
	
	if(!-e $config_path) {
        mkdir $`, 0644 while $config_path =~ /\//g;
        undef $!;
    }
	
	::p $self;
	
	open my $f, ">", $config_path or do { warn "$config_path: $!"; return };
    print $f $json->encode({%$self});
    close $f;
	
	$self
}

sub path {
	my ($self) = @_;
	$self->{path}
}


1;