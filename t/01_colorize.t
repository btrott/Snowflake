use strict;
use Test::More tests => 11;

use File::Slurp;
use Snowflake;
use Test::Exception;

{
    my $syntaxer = Snowflake->new( __FILE__ );
    isa_ok $syntaxer, 'Snowflake';
    ok $syntaxer->content, 'file contents loaded';
    is $syntaxer->lexer, 'text', 'lexer defaults to text';
    is $syntaxer->formatter, 'html', 'formatter defaults to html';
    my $out;
    lives_ok { $out = $syntaxer->colorize } 'colorize lives';
    like $out, qr/highlight/, 'output contains highlighting';
    like "$syntaxer", qr/highlight/, 'overloads stringification';
}

{
    my $syntaxer = Snowflake->new( \'package Foo;', 'perl' );
    is $syntaxer->content, 'package Foo;', 'constructor works with strings';
    like $syntaxer->colorize, qr/highlight/, 'and so does highlighting';
}

{
    my $syntaxer = Snowflake->new( __FILE__, 'perl' );
    is $syntaxer->colorize, Snowflake->colorize( __FILE__, 'perl' ),
        'colorize class method works';
}

{
    local $Snowflake::Bin = '/no/such/script';
    throws_ok { Snowflake->colorize( __FILE__, 'perl' ) }
        qr/can't find pygmentize/, 'croak if we can\'t find pygmentize';
}