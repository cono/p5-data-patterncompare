package Data::PatternCompare;

use strict;
use warnings;

use Scalar::Util qw(looks_like_number refaddr blessed);

our $VERSION = v0.01;

our $any  = Data::PatternCompare::Any->new;

sub new {
    my $class  = shift;
    my %params = @_;

    @params{qw(_dup_addr _dup_addra _dup_addrb)} = ({}, {}, {});

    return bless(\%params, $class);
}

sub _is_any {
    my $val   = shift;
    my $class = blessed($val);

    if ($class && $class eq 'Data::PatternCompare::Any') {
        return $class;
    }

    return 0;
}

sub _match_ARRAY {
    my ($self, $got, $expected) = @_;

    for (my $i = 0; $i < scalar(@$expected); ++$i) {
        if (_is_any($expected->[$i]) && !exists($got->[$i])) {
            return 0;
        }
        return 0 unless $self->_pattern_match($got->[$i], $expected->[$i]);
    }

    return 1;
}

sub _match_HASH {
    my ($self, $got, $expected) = @_;

    for my $key ( keys %$expected ) {
        if (_is_any($expected->{$key}) && !exists($got->{$key})) {
            return 0;
        }
        return 0 unless $self->_pattern_match($got->{$key}, $expected->{$key});
    }

    return 1;
}

sub _pattern_match {
    my ($self, $got, $expected) = @_;

    my $ref = ref($expected);
    unless ($ref) {
        # simple type
        unless (defined $expected && defined $got) {
            unless (defined $expected || defined $got) {
                return 1;
            }
            return 0;
        }

        if (looks_like_number($expected)) {
            return $expected == $got;
        }

        return $expected eq $got;
    }

    my $addr   = refaddr($expected);
    my $is_dup = $self->{'_dup_addr'};
    if (exists $is_dup->{$addr}) {
        die "Cycle in pattern: $expected";
    }
    $is_dup->{$addr} = 1;

    my $class  = blessed($expected);
    if ($class) {
        return 1 if $class eq 'Data::PatternCompare::Any';

        return (
            $class eq blessed($got) &&
            $addr == refaddr($got)
        );
    }

    my $code = $self->can("_match_$ref");
    die "Don't know how to compare $ref type" unless $code;

    return 0 unless ref($got) eq $ref;

    return $self->$code($got, $expected);
}

sub pattern_match {
    my $self = shift;

    my $res;
    eval {
        $res = $self->_pattern_match(@_);
    };
    $self->{'_dup_addr'} = {};
    die $@ if $@;

    return $res;
}

sub _compare_ARRAY {
    my ($self, $pa, $pb) = @_;

    my $sizea = scalar(@$pa);
    my $sizeb = scalar(@$pb);

    unless ($sizea eq $sizeb) {
        return $sizea > $sizeb ? -1 : 1;
    }

    for (my $i = 0; $i < $sizea; ++$i) {
        my $res = $self->_compare_pattern($pa->[$i], $pb->[$i]);

        return $res if $res;
    }

    return 0;
}

sub _compare_HASH {
    my ($self, $pa, $pb) = @_;

    my ($sizea, $sizeb, $matched) = (0) x 3;
    for my $key ( keys %$pa ) {
        if (exists $pb->{$key}) {
            ++$matched;
        } else {
            ++$sizea;
        }
    }
    $sizeb = scalar(keys %$pb) - $matched;

    unless ($sizea eq $sizeb) {
        return $sizea > $sizeb ? -1 : 1;
    }

    for my $key ( keys %$pa ) {
        next unless exists $pb->{$key};

        my $res = $self->_compare_pattern($pa->{$key}, $pb->{$key});

        return $res if $res;
    }

    return 0;
}

sub _compare_pattern {
    my ($self, $pa, $pb) = @_;

    my $refa = ref($pa);
    my $refb = ref($pb);
    my @tmp  = grep { $_ } ($refa, $refb);
    my $cnt  = scalar(@tmp);

    # simple type - equal
    return 0 unless $cnt;

    # 1 ref
    if ($cnt == 1) {
        # any ref (including any) is wider than simple type
        return $refb ? -1 : 1;
    }

    my $addra  = refaddr($pa);
    my $addrb  = refaddr($pb);
    my $classa = blessed($pa);
    my $classb = blessed($pb);

    my $is_dupa = $self->{'_dup_addra'};
    my $is_dupb = $self->{'_dup_addrb'};
    if (exists $is_dupa->{$addra} || exists $is_dupb->{$addrb}) {
        die "Cycle in pattern";
    }
    $is_dupa->{$addra} = 1;
    $is_dupb->{$addrb} = 1;

    @tmp = grep { $_ && $_ eq 'Data::PatternCompare::Any' } ($classa, $classb);
    $cnt = scalar @tmp;

    # 1 "any"
    if ($cnt == 1) {
        return $classb eq 'Data::PatternCompare::Any' ? -1 : 1;
    }

    # both are "any"
    return 0 if $cnt == 2;

    # different types, no reason to go deeper
    return 0 unless $refa eq $refb;

    my $code = __PACKAGE__->can("_compare_$refa");
    die "Don't know how to compare $refa type" unless $code;

    return $self->$code($pa, $pb);
}

sub compare_pattern {
    my $self = shift;

    my $res;
    eval {
        $res = $self->_compare_pattern(@_);
    };
    $self->{'_dup_addra'} = {};
    $self->{'_dup_addrb'} = {};

    die $@ if $@;

    return $res;
}
 
package Data::PatternCompare::Any;

sub new { bless({}); }

42;
