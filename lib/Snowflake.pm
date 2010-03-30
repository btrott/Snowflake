package Snowflake;

use strict;
use warnings;
use 5.008_001;

our $VERSION = '0.01';

use Any::Moose;
use Carp qw( croak );
use File::Slurp;
use File::Which;
use IPC::Run qw( run );

has 'content'   => ( is => 'rw', isa => 'Str', required => 1 );
has 'lexer'     => ( is => 'rw', isa => 'Str', default => 'text' );
has 'formatter' => ( is => 'rw', isa => 'Str', default => 'html' );

our $Bin = which( 'pygmentize' );

around BUILDARGS => sub {
    my $orig = shift;
    my( $class, $content, $lexer, $formatter ) = @_;
    $content = ref( $content ) ? $$content : read_file( $content );
    return $class->$orig(
        content => $content,
        ( defined $lexer ? ( lexer => $lexer ) : () ),
        ( defined $formatter ? ( formatter => $formatter ) : () ),
    );
};

use overload q("") => sub { $_[0]->colorize }, fallback => 1;

sub colorize {
    my $this = shift;
    my $self = ref( $this ) ? $this : $this->new( @_ );
    
    croak "can't find pygmentize!" unless $Bin && -x $Bin;

    my @cmd = ( $Bin,
        '-l', $self->lexer,
        '-f', $self->formatter,
        '-O', 'encoding=utf-8',
    );

    run \@cmd, \$self->content, \my( $out ), \my( $err )
        or die "running @cmd failed: $?";

    return $out;
}

1;
__END__

=head1 NAME

Snowflake - Wrapper for the Pygments command line tool, pygmentize.

=head1 SYNOPSIS

    use Snowflake;
    my $syntaxer = Snowflake->new( '/some/file.pl', 'perl' );
    print $syntaxer->colorize;

=head1 DESCRIPTION

I<Snowflake> is a port of (the Ruby package) I<Albino> to Perl; like that
package, it requires the F<pygmentize> command-line tool.

Assumes F<pygmentize> is in the path.  If not, set its location
with C<$Snowflake::Bin = '/path/to/pygmentize'>.

This'll print out an HTMLized, Perl-highlighted version
of F</some/file.pl>.

    my $syntaxer = Snowflake->new( '/some/file.pl', 'perl' );
    print $syntaxer->colorize;

To use another formatter, pass it as the third argument:

    my $syntaxer = Snowflake->new( '/some/file.pl', 'ruby', 'bbcode' );
    print $syntaxer->colorize;

You can also use the colorize class method:

    print Snowflake->colorize( '/some/file.pl', 'perl' );

Stringification is also overloaded on I<Snowflake> objects, for nicer use
in templates. For example:

    sub pretty_print {
        return Snowflake->new( \shift, 'perl' );
    }

The default lexer is C<text>. You need to specify a lexer yourself;
because we are using STDIN there is no auto-detect.

To see all lexers and formatters available, run C<pygmentize -L>.

=head1 AUTHOR

Benjamin Trott E<lt>ben@sixapart.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * Pygments: http://pygments.org/

=item * Albino: http://github.com/github/albino

=item * Snowflake, the albino gorilla: http://en.wikipedia.org/wiki/Snowflake_(gorilla)

=back

=cut