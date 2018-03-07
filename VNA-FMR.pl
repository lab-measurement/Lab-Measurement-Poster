#!/usr/bin/env perl
use 5.010;
use Lab::Moose;

# Define the two instruments
my $ips = instrument(
    type               => 'OI_Mercury::Magnet',
    connection_type    => 'Socket',
    connection_options => { host => '192.168.3.15' },
);

my $vna = instrument(
    type               => 'RS_ZVA',
    connection_type    => 'VXI11',
    connection_options => { host => '192.168.3.27' },
);

# Set VNA's IF filter bandwidth (Hz)
$vna->sense_bandwidth_resolution( value => 1 );

# The outer sweep: continuous magnetic field sweep
my $field_sweep = sweep(
    type       => 'Continuous::Magnet',
    instrument => $ips,
    from       => 2,    # Tesla
    to         => 0,    # Tesla
    rate       => 0.01, # Tesla/min
    start_rate => 1,    # Tesla/min (rate to approach start point)
    interval   => 0,    # run slave sweep as often as possible
);

# The inner sweep: set frequency to 1GHz, 2GHz, ..., 10GHz
my $frq_sweep = sweep(
    type       => 'Step::Frequency',
    instrument => $vna,
    from       => 1e9,
    to         => 10e9,
    step       => 1e9
);

# The data file: gnuplot-style, VNA data prefixed with B
my $datafile = sweep_datafile(
    columns => [ 'B', 'f', 'Re', 'Im', 'r', 'phi' ] );

# Add a live plot of the transmission amplitude
$datafile->add_plot( x => 'B', y => 'r' );

# Define the measurement instructions per (B,f) point
my $meas = sub {
    my $sweep = shift;

    say "frequency f: ", $sweep->get_value();
    my $field = $ips->get_field();

    # this is not really a VNA "sweep", but only a
    # point measurement at one frequency
    my $pdl = $vna->sparam_sweep( timeout => 10 );

    # Record the result, prefixed with B
    $sweep->log_block(
        prefix => { field => $field },
        block  => $pdl
    );
};

# And go!
$field_sweep->start(
    slave       => $frq_sweep,
    datafile    => $datafile,
    measurement => $meas,
    folder      => 'Magnetic_Resonance',
);
