package OSLV::Monitor;

use 5.006;
use strict;
use warnings;
use Module::List qw(list_modules);

=head1 NAME

OSLV::Monitor - OS level virtualization monitoring extend.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use OSLV::Monitor;

    my $monitor = OSLV::Monitor->new();
    ...

=head2 METHODS

Inits the object.

One option is taken and that is a hash ref.

    # init with the cbsd backend
    my $monitor->new(backend=>'FreeBSD');

The keys are list as below.

    - backend :: The name of the backend to use.
        Default :: CBSD

=cut

sub new {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{backend} ) ) {
		$opts{backend} = 'FreeBSD';
		if ( $^O eq 'freebsd' ) {
			$opts{backend} = 'FreeBSD';
		} elsif ( $^O eq 'linux' ) {
			$opts{backend} = 'cgroup';
		}
	}

	if (!defined($opts{base_dir})) {
		$opts{base_dir}='/var/cache/oslv_monitor';
	}

	my $self = {
				version => 1,
				backend => $opts{backend},
				base_dir => $opts{base_dir},
				};
	bless $self;

	return $self;
}

=head2 load

This loads the specified backend.

    eval{ $monitor->load; };
    if ( $@ ){
        print "Failed to load the backend... ".$@;
    }

=cut

sub load {
	my $self = $_[0];

	my $loaded = 0;

	my $backend_test;
	my $usable;
	my $test_string = '
use OSLV::Monitor::Backends::' . $self->{backend} . ';
$backend_test=OSLV::Monitor::Backends::' . $self->{backend} . '->new(base_dir=>$self->{base_dir}));
$usable=$backend_test->usable;
';
	eval($test_string);
	if ($usable) {
		$self->{backend_mod} = $backend_test;
		$loaded = 1;
	}
	else {
		die( 'Failed to load backend... ' . $@ );
	}

	return $loaded;
}

=head2 run

Runs the poller backend and report the results.

If nothing is nothing is loaded, load will be called.

    my $status=$monitor->run;

=cut

sub run {
	my $self = $_[0];

	if ( !defined( $self->{backend_mod} ) ) {
		return {
			version     => $self->{version},
			data        => {},
			error       => 1,
			errorString => 'No module loaded',
		};
	}

	my $to_return_data;
	#	eval { $to_return_data = $self->{backend_mod}->run };
	$to_return_data = $self->{backend_mod}->run;
	if ($@) {
	return {
			version     => $self->{version},
			data        => {},
			error       => 1,
			errorString => 'Failed to run backend... ' . $@,
		};
	}

	return {
			version     => $self->{version},
			data        => $to_return_data,
			error       => undef,
			errorString => ''
			};
}

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
