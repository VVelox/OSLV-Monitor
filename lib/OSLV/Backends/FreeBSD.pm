package OSLV::Monitor::Backends::FreeBSD;

use 5.006;
use strict;
use warnings;
use Module::List qw(list_modules);

=head1 NAME

OSLV::Monitor::Backends::FreeBSD - backend for FreeBSD jails

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use OSLV::Monitor::Backends::FreeBSD;

    my $backend = OSLV::Monitor::Backends::FreeBSD->new;

    my $usable=$backend->usable;
    if ( $usable ){
        $return_hash_ref=$backend->run;
    }

=head2 METHODS

=head2 new

Initiates the backend object.

    my $backend=OSLV::MOnitor::Backend::Libvirt->new;

=cut

sub new {
	my $self = { version => 1, };
	bless $self;

	return $self;
}

=head2 run

    $return_hash_ref=$backend->run;

=cut

sub run {
	my $self = $_[0];

}

=head2 usable

Dies if not usable.

    eval{ $backend->usable; };
    if ( $@ ){
        print 'Not usable because... '.$@."\n";
    }

=cut

sub usable {
	my $self = $_[0];

	# make sure it is freebsd
	if ( $^O !~ 'freebsd' ) {
		die '$^O is "' . $^O . '" and not "freebsd"';
	}

	# make sure we can locate jls
	my $cmd_bin = `/bin/sh -c 'which jls 2> /dev/null'`;
	if ( $? != 0 ) {
		die 'The command "jls" is not in the path... ' . $ENV{PATH};
	}

	return 1;
} ## end sub usable

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-oslv-monitor at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=OSLV-Monitor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OSLV::Monitor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=OSLV-Monitor>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/OSLV-Monitor>

=item * Search CPAN

L<https://metacpan.org/release/OSLV-Monitor>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of OSLV::Monitor
