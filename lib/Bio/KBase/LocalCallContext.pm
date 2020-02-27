package Bio::KBase::LocalCallContext;
use strict;
use warnings;

sub new {
    my ( $class, $token, $user, $provenance, $method ) = @_;
    my $self = {
        token      => $token,
        user_id    => $user,
        provenance => $provenance,
        method     => $method,
    };
    return bless $self, $class;
}

sub user_id {
    my ( $self ) = @_;
    return $self->{ user_id };
}

sub token {
    my ( $self ) = @_;
    return $self->{ token };
}

sub provenance {
    my ( $self ) = @_;
    return $self->{ provenance };
}

sub method {
    my ( $self ) = @_;
    return $self->{ method };
}

sub authenticated {
    return 1;
}

sub log_debug {
    my ( $self, $msg ) = @_;
    print STDERR $msg . "\n";
}

sub log_info {
    my ( $self, $msg ) = @_;
    print STDERR $msg . "\n";
}

sub TO_JSON {
    my ( $self ) = @_;

    return {
        map { $_ => $self->$_ } qw( authenticated method provenance token user_id )
    };
}

1;

