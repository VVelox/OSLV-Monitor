package OSLV::Monitor::Backends::cgroups;

use 5.006;
use strict;
use warnings;
use JSON;
use Clone 'clone';

=head1 NAME

OSLV::Monitor::Backends::cgroups - backend for Linux cgroups.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use OSLV::Monitor::Backends::cgroups;

    my $backend = OSLV::Monitor::Backends::cgroups->new;

    my $usable=$backend->usable;
    if ( $usable ){
        $return_hash_ref=$backend->run;
    }

=head2 METHODS

=head2 new

Initiates the backend object.

    my $backend=OSLV::MOnitor::Backend::cgroups->new

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $self = {
		version         => 1,
		cgroupns_usable => 1,
		mapping         => {},
		podman_mapping  => {},
	};
	bless $self;

	return $self;
} ## end sub new

=head2 run

    $return_hash_ref=$backend->run;

=cut

sub run {
	my $self = $_[0];

	my $data = {
		errors => [],
		oslvms => {},
		totals => {
			procs                        => 0,
			rbytes                       => 0,
			wbytes                       => 0,
			rios                         => 0,
			wios                         => 0,
			dbytes                       => 0,
			dios                         => 0,
			usage_usec                   => 0,
			user_usec                    => 0,
			system_usec                  => 0,
			'core_sched.force_idle_usec' => 0,
			nr_periods                   => 0,
			nr_throttled                 => 0,
			throttled_usec               => 0,
			nr_bursts                    => 0,
			burst_usec                   => 0,
			anon                         => 0,
			file                         => 0,
			kernel                       => 0,
			kernel_stack                 => 0,
			pagetables                   => 0,
			sec_pagetables               => 0,
			percpu                       => 0,
			sock                         => 0,
			vmalloc                      => 0,
			shmem                        => 0,
			zswap                        => 0,
			zswapped                     => 0,
			file_mapped                  => 0,
			file_dirty                   => 0,
			file_writeback               => 0,
			swapcached                   => 0,
			anon_thp                     => 0,
			file_thp                     => 0,
			shmem_thp                    => 0,
			inactive_anon                => 0,
			active_anon                  => 0,
			inactive_file                => 0,
			active_file                  => 0,
			unevictable                  => 0,
			slab_reclaimable             => 0,
			slab_unreclaimable           => 0,
			slab                         => 0,
			workingset_refault_anon      => 0,
			workingset_refault_file      => 0,
			workingset_activate_anon     => 0,
			workingset_activate_file     => 0,
			workingset_restore_anon      => 0,
			workingset_restore_file      => 0,
			workingset_nodereclaim       => 0,
			pgscan                       => 0,
			pgsteal                      => 0,
			pgscan_kswapd                => 0,
			pgscan_direct                => 0,
			pgscan_khugepaged            => 0,
			pgsteal_kswapd               => 0,
			pgsteal_direct               => 0,
			pgsteal_khugepaged           => 0,
			pgfault                      => 0,
			pgmajfault                   => 0,
			pgrefill                     => 0,
			pgactivate                   => 0,
			pgdeactivate                 => 0,
			pglazyfree                   => 0,
			pglazyfreed                  => 0,
			zswpin                       => 0,
			zswpout                      => 0,
			thp_fault_alloc              => 0,
			thp_collapse_alloc           => 0,
		},
	};

	my $base_stats = {
		procs                        => 0,
		rbytes                       => 0,
		wbytes                       => 0,
		rios                         => 0,
		wios                         => 0,
		dbytes                       => 0,
		dios                         => 0,
		usage_usec                   => 0,
		user_usec                    => 0,
		system_usec                  => 0,
		'core_sched.force_idle_usec' => 0,
		nr_periods                   => 0,
		nr_throttled                 => 0,
		throttled_usec               => 0,
		nr_bursts                    => 0,
		burst_usec                   => 0,
		anon                         => 0,
		file                         => 0,
		kernel                       => 0,
		kernel_stack                 => 0,
		pagetables                   => 0,
		sec_pagetables               => 0,
		percpu                       => 0,
		sock                         => 0,
		vmalloc                      => 0,
		shmem                        => 0,
		zswap                        => 0,
		zswapped                     => 0,
		file_mapped                  => 0,
		file_dirty                   => 0,
		file_writeback               => 0,
		swapcached                   => 0,
		anon_thp                     => 0,
		file_thp                     => 0,
		shmem_thp                    => 0,
		inactive_anon                => 0,
		active_anon                  => 0,
		inactive_file                => 0,
		active_file                  => 0,
		unevictable                  => 0,
		slab_reclaimable             => 0,
		slab_unreclaimable           => 0,
		slab                         => 0,
		workingset_refault_anon      => 0,
		workingset_refault_file      => 0,
		workingset_activate_anon     => 0,
		workingset_activate_file     => 0,
		workingset_restore_anon      => 0,
		workingset_restore_file      => 0,
		workingset_nodereclaim       => 0,
		pgscan                       => 0,
		pgsteal                      => 0,
		pgscan_kswapd                => 0,
		pgscan_direct                => 0,
		pgscan_khugepaged            => 0,
		pgsteal_kswapd               => 0,
		pgsteal_direct               => 0,
		pgsteal_khugepaged           => 0,
		pgfault                      => 0,
		pgmajfault                   => 0,
		pgrefill                     => 0,
		pgactivate                   => 0,
		pgdeactivate                 => 0,
		pglazyfree                   => 0,
		pglazyfreed                  => 0,
		zswpin                       => 0,
		zswpout                      => 0,
		thp_fault_alloc              => 0,
		thp_collapse_alloc           => 0,
	};

	#
	# get podman ID to name mappings
	#
	my $podman_output = `podman ps --format json 2> /dev/null`;
	if ( $? == 0 ) {
		my $podman_parsed;
		eval { $podman_parsed = decode_json($podman_output); };
		if ( defined($podman_parsed) && ref($podman_parsed) eq 'ARRAY' ) {
			foreach my $pod ( @{$podman_parsed} ) {
				if ( defined( $pod->{Id} ) && defined( $pod->{Names} ) && defined( $pod->{Names}[0] ) ) {
					$self->{podman_mapping}{ $pod->{Id} } = {
						podname  => $pod->{PodName},
						Networks => $pod->{Networks},
					};
					if ( $self->{podman_mapping}{ $pod->{Id} }{podname} ne '' ) {
						$self->{podman_mapping}{ $pod->{Id} }{name} = $self->{podman_mapping}{ $pod->{Id} }{podname} . '-'
							. $pod->{Names}[0];
					}else {
						$self->{podman_mapping}{ $pod->{Id} }{name} = $pod->{Names}[0];
					}
				} ## end if ( defined( $pod->{Id} ) && defined( $pod...))
			} ## end foreach my $pod ( @{$podman_parsed} )
		} ## end if ( defined($podman_parsed) && ref($podman_parsed...))
	} ## end if ( $? == 0 )

	#
	# gets of procs for finding a list of containers
	#
	my $ps_output = `ps -haxo cgroupns,pid,cgroup 2> /dev/null`;
	if ( $? != 0 ) {
		$self->{cgroupns_usable} = 0;
		$ps_output = `ps -haxo pid,cgroup 2> /dev/null`;
	}
	my @ps_output_split=split(/\n/, $ps_output);
	my %found_cgroups;
	foreach my $line (@ps_output_split) {
		my ($cgroupns, $pid, $cgroup);
		if ($self->{cgroupns_usable}) {
			($cgroupns, $pid, $cgroup) = split(/\s+/, $line);
		}else {
			($pid, $cgroup) = split(/\s+/, $line);
		}
		if ($cgroup =~ /^0\:\:\//) {
			$found_cgroups{$cgroup}=$cgroupns;
		}
	}

	#
	# build a list of mappings
	#
	foreach my $cgroup (keys(%found_cgroups)) {
		my $cgroupns = $found_cgroups{$cgroup};
		my $map_to=$self->cgroup_mapping($cgroup, $cgroupns);
		if (defined($map_to)) {
			$self->{mapping}{$cgroup}=$map_to;
		}
	}

	#
	# get the stats
	#
	foreach my $cgroup (keys(%{ $self->{mappings} })) {
		my $name= $self->{mappings}{$cgroup};

		$data->{oslvms}{$name}=clone($base_stats);

		my $base_dir=$cgroup;
		$base_dir=~s/^0\:\://;
		$base_dir='/sys/fs/cgroup'.$base_dir;

		eval{
			my $cpu_stats_raw=read_file($base_dir.'/cpu.stat');
			my @cpu_stats_split=split(/\n/, $cpu_stats_raw);
			foreach my $line (@cpu_stats_split) {
				my ($stat, $value)=split(/\s+/, $line, 2);
				if (defined( $data->{oslvms}{$name}{$stat}) && defined($value) && $value=~/[0-9\.]+/) {
					$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $value;
					$data->{totals}{$stat} = $data->{totals}{$stat} + $value;
				}
			}
		};
		if ($@) {
			push(@{$data->{errors}}, 'Error processing '.$base_dir.'/cpu.stat ... '.$@);
		}

		eval{
			my $memory_stats_raw=read_file($base_dir.'/memory.stat');
			my @memory_stats_split=split(/\n/, $memory_stats_raw);
			foreach my $line (@memory_stats_split) {
				my ($stat, $value)=split(/\s+/, $line, 2);
				if (defined( $data->{oslvms}{$name}{$stat}) && defined($value) && $value=~/[0-9\.]+/) {
					$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $value;
					$data->{totals}{$stat} = $data->{totals}{$stat} + $value;
				}
			}
		};
		if ($@) {
			push(@{$data->{errors}}, 'Error processing '.$base_dir.'/memory.stat ... '.$@);
		}

		eval{
			my $io_stats_raw=read_file($base_dir.'/io.stat');
			my @io_stats_split=split(/\n/, $io_stats_raw);
			foreach my $line (@io_stats_split) {
				my @line_split=split(/\s/, $line);
				shift(@line_split);
				foreach my $item (@line_split) {
					my ($stat, $value)=split(/\=/, $line, 2);
					if (defined( $data->{oslvms}{$name}{$stat}) && defined($value) && $value=~/[0-9]+/) {
						$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $value;
						$data->{totals}{$stat} = $data->{totals}{$stat} + $value;
					}
				}
			}
		};
		if ($@) {
			push(@{$data->{errors}}, 'Error processing '.$base_dir.'/io.stat ... '.$@);
		}
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

	if ( $^O !~ 'linux' ) {
		die '$^O is "' . $^O . '" and not "linux"';
	}

	return 1;
} ## end sub usable

=head2 mapping

=cut

sub cgroup_mapping {
	my $self        = $_[0];
	my $cgroup_name = $_[1];
	my $cgroupns    = $_[2];

	if ( !defined($cgroup_name) ) {
		return undef;
	}

	if ( $cgroup_name eq '0::/init.scope' ) {
		return 'init';
	}

	if ( $cgroup_name =~ /^0\:\:\/system\.slice\// ) {
		$cgroup_name =~ s/^.*\///;
		$cgroup_name =~ s/\.serverice$//;
		return 's_'.$cgroup_name;
	} elsif ( $cgroup_name =~ /^0\:\:\/user\.slice\// ) {
		$cgroup_name =~ s/^0\:\:\/user\.slice\///;
		$cgroup_name =~ s/\.slice.*$//;
		return 'u_'.$cgroup_name;
	} elsif ($cgroup_name =~ /^0\:\:\/machine\.slice\/libpod\-/) {
		$cgroup_name =~ s/^^0\:\:\/machine\.slice\/libpod\-//;
		$cgroup_name =~ s/\.scope.*$//;
		if (defined($self->{podman_mapping}{$cgroup_name})) {
			return 'p_'.$self->{podman_mapping}{$cgroup_name}{name};
		}
		return 'libpod';
	}

	$cgroup_name =~ s/^0\:\:\///;
	$cgroup_name =~ s/\/.*//;
	return $cgroup_name;
} ## end sub cgroup_mapping

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
