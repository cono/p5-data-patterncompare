
use strict;
use warnings;

use Test::More;

use Data::PatternCompare;

my $m = Data::PatternCompare->new;

subtest 'simple match' => sub {
    match(42, 42, 'int value match');
    not_match(42, 41, 'int value does not match');

    match("hello", "hello", 'string value match');
    not_match("hello", "world", 'string value does not match');

    match(undef, undef, 'undef value match');
    not_match(42, undef, 'value does not match undef');
    not_match(undef, 42, 'undef does not match value');

    match(42, $Data::PatternCompare::any, 'compare int to any');
    match("hello", $Data::PatternCompare::any, 'compare string to any');
    match({}, $Data::PatternCompare::any, 'compare hash to any');
    match([], $Data::PatternCompare::any, 'compare array to any');

    not_match([], {}, 'different types does not match');

    done_testing;
};

subtest 'array match' => sub {
    match([42], [42], 'equal arrays');
    not_match([42], [41], 'not equal arrays');

    not_match([1, 2, 3], [1, 42, 3], 'arrays should be exact');

    # pattern [ VALUE ], will match any kind of arrays [ VALUE, ... ]
    match([42, 1], [42], 'pattern less than test array');
    not_match([], [ $Data::PatternCompare::any ], 'any is not an empty array');
};

subtest 'hash match' => sub {
    match({data => 42}, {data => 42}, 'equal hashes');
    not_match({data => 42}, {data => 41}, 'not equal hashes');

    # pattern [ VALUE ], will match any kind of arrays [ VALUE, ... ]
    match({data => 42, a => 'b'}, {data => 42}, 'pattern less than test hash');
    not_match({a => 'b'}, [ data => $Data::PatternCompare::any ], 'any is not match if key is not exists');
};

subtest 'bugs' => sub {
    not_match([ "hello" ], [ 0 ], "string not equal to 0");
};

done_testing;

sub not_match {
    my ($data, $pattern, $message) = @_;

    ok(!$m->pattern_match($data, $pattern), $message);
}

sub match {
    my ($data, $pattern, $message) = @_;

    ok($m->pattern_match($data, $pattern), $message);
}
