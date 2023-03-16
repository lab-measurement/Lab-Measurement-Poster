use 5.010;

use Lab::Moose;
use Time::HiRes 'time';
use PDL;

# Record several VNA traces for increasing power

##################################################

my $sample = 'NK17'; #chip name

# VNA sweep range
my $freqstart  = 4500000000;
my $freqend    = 6500000000;
my $freqpoints = 10001;

my $vna_bw = 1000;
my $vna_AVG = 1;    # number of sweeps to average

# VNA power
my $powerstart = -20;
my $powerend   = +10;
my $powerstep  = +10;

##################################################

my $vna = instrument(
    type               => 'RS_ZVA',
    connection_type    => 'VISA::GPIB',
    connection_options => { pad => 20 },
);

# The power "sweep"
my $sweep_power = sweep(
    type => 'Step::Power', 
    instrument => $vna, 
    delay_before_loop => 5,
    from => $powerstart, to => $powerend, step => $powerstep
);

# The data file
my $datafile = sweep_datafile(
    type => 'Gnuplot',
    columns => [qw/time power f Re Im Amp phi/], 
);

# The measurement procedure
my $meas = sub {
    my $sweep = shift;
    
    my $pw = $vna->get_power();

    say "Sweeping at power ".$pw."dBm ...";
    my $pdl = $vna->sparam_sweep( timeout => 10000,
                                  average => $vna_AVG );
    say "... done.\n";

    $sweep->log_block(
        prefix => { time => time(), power => $pw },
        block => $pdl,
        add_newline => 1,
    );
};

# Set up the VNA parameters
$vna->sense_bandwidth_resolution( value => $vna_bw );
$vna->sense_frequency_start(value => $freqstart );
$vna->sense_frequency_stop(value => $freqend );
$vna->sense_sweep_points(value => $freqpoints );

# Start the measurement
$sweep_power->start(
    measurement => $meas,
    datafile   => $datafile,
    folder => "vnasweep_$sample",
);

# Set power to low value at end
$vna->set_power( value => -20 );
