#!/usr/bin/env perl
# Read out SR830 Lock In Amplifier at GPIB address 13
use 5.010;
use Lab::Moose;

my $lia = instrument(
    type               => 'SR830',
    connection_type    => 'LinuxGPIB',
    connection_options => { pad => 13 }
);

my $amp = $lia->get_amplitude();
say "Reference output amplitude: $amp V";

my $freq = $lia->get_freq();
say "Reference frequency: $freq Hz";

my $r_phi = $lia->get_rphi();
my ( $r, $phi ) = ( $r_phi->{r}, $r_phi->{phi} );
say "Signal: r=$r V, phi=$phi degree";
