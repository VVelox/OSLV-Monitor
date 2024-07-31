package OSLV::Monitor::Backends::FreeBSD;

use 5.006;
use strict;
use warnings;
use JSON;

=head1 NAME

OSLV::Monitor::Backends::FreeBSD - backend for FreeBSD jails

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use OSLV::Monitor::Backends::FreeBSD;

    my $backend = OSLV::Monitor::Backends::FreeBSD->new;

    my $usable=$backend->usable;
    if ( $usable ){
        $return_hash_ref=$backend->run;
    }

=head2 METHODS

=head2 new

Initiates the backend object.

    my $backend=OSLV::MOnitor::Backend::FreeBSD->new;

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

	my $data = {
		oslvms => {},
		totals => {
			'accounting-flag'              => 0,
			'copy-on-write-faults'         => 0,
			'cpu-time'                     => 0,
			'data-size'                    => 0,
			'elapsed-time'                 => 0,
			'involuntary-context-switches' => 0,
			'major-faults'                 => 0,
			'minor-faults'                 => 0,
			'percent-cpu'                  => 0,
			'percent-memory'               => 0,
			'pid'                          => 0,
			'read-blocks'                  => 0,
			'received-messages'            => 0,
			'rss'                          => 0,
			'sent-messages'                => 0,
			'stack-size'                   => 0,
			'swaps'                        => 0,
			'system-time'                  => 0,
			'text-size'                    => 0,
			'user-time'                    => 0,
			'virtual-size'                 => 0,
			'voluntary-context-switches'   => 0,
			'written-blocks'               => 0,
		},
	};

	my @stats = (
		'accounting-flag',   'copy-on-write-faults',         'cpu-time',      'data-size',
		'elapsed-time',      'involuntary-context-switches', 'major-faults',  'minor-faults',
		'percent-cpu',       'percent-memory',               'pid',           'read-blocks',
		'received-messages', 'rss',                          'sent-messages', 'stack-size',
		'swaps',             'system-time',                  'text-size',     'user-time',
		'virtual-size',      'voluntary-context-switches',   'written-blocks',
	);

	my $output
		= `ps a --libxo json -o %cpu,%mem,pid,acflag,cow,dsiz,etimes,inblk,jail,majflt,minflt,msgrcv,msgsnd,nivcsw,nswap,nvcsw,oublk,rss,ssiz,systime,time,tsiz,usertime,vsz 2> /dev/null`;
	my $ps;
	eval { $ps = decode_json($output); };
	if ($@) {
		return $data;
	}

	my $times = { 'cpu-time' => 1, 'system-time' => 1, 'user-time' => 1, };

	if (   defined( $ps->{'process-information'} )
		&& ref( $ps->{'process-information'} ) eq 'HASH'
		&& defined( $ps->{'process-information'}{process} )
		&& ref( $ps->{'process-information'}{process} ) eq 'ARRAY' )
	{
		foreach my $proc ( @{ $ps->{'process-information'}{process} } ) {
			if ( $proc->{'jail-name'} ne '-' ) {
				if ( !defined( $data->{oslvms}{ $proc->{'jail-name'} } ) ) {
					$data->{oslvms}{ $proc->{'jail-name'} } = {
						'accounting-flag'              => 0,
						'copy-on-write-faults'         => 0,
						'cpu-time'                     => 0,
						'data-size'                    => 0,
						'elapsed-time'                 => 0,
						'involuntary-context-switches' => 0,
						'major-faults'                 => 0,
						'minor-faults'                 => 0,
						'percent-cpu'                  => 0,
						'percent-memory'               => 0,
						'pid'                          => 0,
						'read-blocks'                  => 0,
						'received-messages'            => 0,
						'rss'                          => 0,
						'sent-messages'                => 0,
						'stack-size'                   => 0,
						'swaps'                        => 0,
						'system-time'                  => 0,
						'text-size'                    => 0,
						'user-time'                    => 0,
						'virtual-size'                 => 0,
						'voluntary-context-switches'   => 0,
						'written-blocks'               => 0,
					};
				} ## end if ( !defined( $data->{oslvms}{ $proc->{'jail-name'...}}))

				foreach my $stat (@stats) {
					if ( defined( $times->{$stat} ) ) {
						# [days-][hours:]minutes:seconds
						my $seconds = 0;
						my $time    = $proc->{$stat};
						if ( $time =~ /-/ ) {
							my $days = $time;
							$days =~ s/\-.*$//;
							$seconds = $seconds + ( $days * 86400 );
						} else {
							my @time_split = split( /\:/, $time );
							if ( defined( $time_split[2] ) ) {
								$seconds
									= $seconds + ( 3600 * $time_split[0] ) + ( 60 * $time_split[1] ) + $time_split[2];
							} else {
								$seconds = $seconds + ( 60 * $time_split[1] ) + $time_split[1];
							}
						}
						$data->{oslvms}{ $proc->{'jail-name'} }{$stat}
							= $data->{oslvms}{ $proc->{'jail-name'} }{$stat} + $seconds;
						$data->{totals}{$stat} = $data->{totals}{$stat} + $seconds;
					} else {
						$data->{oslvms}{ $proc->{'jail-name'} }{$stat}
							= $data->{oslvms}{ $proc->{'jail-name'} }{$stat} + $proc->{$stat};
						$data->{totals}{$stat} = $data->{totals}{$stat} + $proc->{$stat};
					}
				} ## end foreach my $stat (@stats)
			} ## end if ( $proc->{'jail-name'} ne '-' )
		} ## end foreach my $proc ( @{ $ps->{'process-information'...}})
	} ## end if ( defined( $ps->{'process-information'}...))

	return $data;
} ## end sub run

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
