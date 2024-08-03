package OSLV::Monitor::Backends::FreeBSD;

use 5.006;
use strict;
use warnings;
use JSON;
use Clone 'clone';
use File::Slurp;

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
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{base_dir} ) ) {
		$opts{base_dir} = '/var/cache/oslv_monitor';
	}

	my $self = { version => 1, proc_cache => $opts{base_dir} . '/freebsd_proc_cache.json' };
	bless $self;

	return $self;
} ## end sub new

=head2 run

    $return_hash_ref=$backend->run;

=cut

sub run {
	my $self = $_[0];

	my $data = {
		errors        => [],
		cache_failure => 0,
		oslvms        => {},
		totals        => {
			'copy-on-write-faults'         => 0,
			'cpu-time'                     => 0,
			'data-size'                    => 0,
			'elapsed-times'                => 0,
			'involuntary-context-switches' => 0,
			'major-faults'                 => 0,
			'minor-faults'                 => 0,
			'percent-cpu'                  => 0,
			'percent-memory'               => 0,
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
			'procs'                        => 0,
		},
	};

	my $proc_cache;
	my $new_proc_cache = {};
	if ( -f $self->{proc_cache} ) {
		eval {
			my $raw_cache = read_file( $self->{proc_cache} );
			$proc_cache = decode_json($raw_cache);
		};
		if ($@) {
			push(
				@{ $data->{errors} },
				'reading proc cache "' . $self->{proc_cache} . '" failed... using a empty one...' . $@
			);
			$data->{cache_failure} = 1;
			$proc_cache = {};
		}
	} ## end if ( -f $self->{proc_cache} )

	my $base_stats = {
		'copy-on-write-faults'         => 0,
		'cpu-time'                     => 0,
		'data-size'                    => 0,
		'elapsed-times'                => 0,
		'involuntary-context-switches' => 0,
		'major-faults'                 => 0,
		'minor-faults'                 => 0,
		'percent-cpu'                  => 0,
		'percent-memory'               => 0,
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
		'procs'                        => 0,
		'ipv4'                         => undef,
		'path'                         => undef,
		'ipv6'                         => undef,
	};

	# get a list of jails
	my $output = `/usr/sbin/jls --libxo json 2> /dev/null`;
	my $jls;
	eval { $jls = decode_json($output) };
	if ($@) {
		push( @{ $data->{errors} }, 'decoding output from "jls --libxo json 2> /dev/null" failed... ' . $@ );
		return $data;
	}
	if (   defined($jls)
		&& ref($jls) eq 'HASH'
		&& defined( $jls->{'jail-information'} )
		&& ref( $jls->{'jail-information'} ) eq 'HASH'
		&& defined( $jls->{'jail-information'}{jail} )
		&& ref( $jls->{'jail-information'}{jail} ) eq 'ARRAY' )
	{
		foreach my $jls_jail ( @{ $jls->{'jail-information'}{jail} } ) {
			$data->{oslvms}{ $jls_jail->{'hostname'} } = clone($base_stats);
			$data->{oslvms}{ $jls_jail->{'hostname'} }{path} = $jls_jail->{path};
			if ( defined( $jls_jail->{ipv4} ) && $jls_jail->{ipv4} ne '' ) {
				$data->{oslvms}{ $jls_jail->{'hostname'} }{ipv4} = $jls_jail->{ipv4};
			}
			if ( defined( $jls_jail->{ipv6} ) && $jls_jail->{ipv6} ne '' ) {
				$data->{oslvms}{ $jls_jail->{'hostname'} }{ipv6} = $jls_jail->{ipv6};
			}
		} ## end foreach my $jls_jail ( @{ $jls->{'jail-information'...}})
	} ## end if ( defined($jls) && ref($jls) eq 'HASH' ...)

	my @stats = (
		'copy-on-write-faults',         'cpu-time',
		'data-size',                    'elapsed-times',
		'involuntary-context-switches', 'major-faults',
		'minor-faults',                 'percent-cpu',
		'percent-memory',               'read-blocks',
		'received-messages',            'rss',
		'sent-messages',                'stack-size',
		'swaps',                        'system-time',
		'text-size',                    'user-time',
		'virtual-size',                 'voluntary-context-switches',
		'written-blocks',
	);

	$output
		= `/bin/ps a --libxo json -o %cpu,%mem,pid,acflag,cow,dsiz,etimes,inblk,jail,majflt,minflt,msgrcv,msgsnd,nivcsw,nswap,nvcsw,oublk,rss,ssiz,systime,time,tsiz,usertime,vsz,pid,gid,uid,command,jid 2> /dev/null`;
	my $ps;
	eval { $ps = decode_json($output); };
	if ($@) {
		push( @{ $data->{errors} }, 'decoding output from ps failed... ' . $@ );
		return $data;
	}

	# values that are time stats that require additional processing
	my $times = { 'cpu-time' => 1, 'system-time' => 1, 'user-time' => 1, };
	# these are counters and differences needed computed for them
	my $counters = {
		'cpu-time'                     => 1,
		'system-time'                  => 1,
		'user-time'                    => 1,
		'read-blocks'                  => 1,
		'major-faults'                 => 1,
		'elapsed-times'                => 1,
		'involuntary-context-switches' => 1,
		'minor-faults'                 => 1,
		'received-messages'            => 1,
		'sent-messages'                => 1,
		'swaps'                        => 1,
		'voluntary-context-switches'   => 1,
		'written-blocks'               => 1,
		'copy-on-write-faults'         => 1,
	};

	if (   defined($ps)
		&& ref($ps) eq 'HASH'
		&& defined( $ps->{'process-information'} )
		&& ref( $ps->{'process-information'} ) eq 'HASH'
		&& defined( $ps->{'process-information'}{process} )
		&& ref( $ps->{'process-information'}{process} ) eq 'ARRAY' )
	{
		foreach my $proc ( @{ $ps->{'process-information'}{process} } ) {
			if ( $proc->{'jail-name'} ne '-' ) {
				# should not happen in general... only happens if a jail was just created in between jls and ps
				if ( !defined( $data->{oslvms}{ $proc->{'jail-name'} } ) ) {
					$data->{oslvms}{ $proc->{'jail-name'} } = clone($base_stats);
				}

				my $cache_name
					= $proc->{pid} . '-'
					. $proc->{uid} . '-'
					. $proc->{gid} . '-'
					. $proc->{'jail-id'} . '-'
					. $proc->{command};

				foreach my $stat (@stats) {
					# pre-process the stat if it is a time value that requires it
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
						$proc->{$stat} = $seconds;
					} ## end if ( defined( $times->{$stat} ) )

					if ( $counters->{$stat} ) {
						if ( defined( $proc_cache->{$cache_name} ) && defined( $proc_cache->{$cache_name}{$stat} ) ) {
							my $new_value = $proc->{$stat} - $proc_cache->{$cache_name}{$stat};
						} else {
							$data->{oslvms}{ $proc->{'jail-name'} }{$stat}
								= $data->{oslvms}{ $proc->{'jail-name'} }{$stat} + $proc->{$stat};
							$data->{totals}{$stat} = $data->{totals}{$stat} + $proc->{$stat};
						}
					} else {
						$data->{oslvms}{ $proc->{'jail-name'} }{$stat}
							= $data->{oslvms}{ $proc->{'jail-name'} }{$stat} + $proc->{$stat};
						$data->{totals}{$stat} = $data->{totals}{$stat} + $proc->{$stat};
					}
				} ## end foreach my $stat (@stats)

				$data->{oslvms}{ $proc->{'jail-name'} }{procs}++;
				$data->{totals}{procs}++;

				$new_proc_cache->{$cache_name} = $proc;
			} ## end if ( $proc->{'jail-name'} ne '-' )
		} ## end foreach my $proc ( @{ $ps->{'process-information'...}})
	} ## end if ( defined($ps) && ref($ps) eq 'HASH' &&...)

	# save the proc cache for next run
	eval { write_file( $self->{proc_cache}, encode_json($new_proc_cache) ); };
	if ($@) {
		push( @{ $data->{errors} }, 'saving proc cache failed, "' . $self->{proc_cache} . '"... ' . $@ );
		return $data;
	}

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
