use strict;
use warnings;
use Audio::PortAudio;
use Math::Trig qw( pi );

my $table_size = 1024;
my @wave_table = map {
    my $tmp = sin( 2.0 * pi() * ($_ / $table_size) );
    if ( $tmp < 0.0 ) {
        int( ($tmp * 0x10000) - 0.5 );
    }
    else {
        int( ($tmp * 0x10000) + 0.5 );
    }
} 0..($table_size - 1);

sub create_osc {
    my $samples_per_sec = shift;
    my $freq = shift;

    my $samples_per_cycle = $samples_per_sec / $freq;
    my $t = 0;
    my $dt = int( ($table_size / $samples_per_cycle) * 0x10000 ); # u10.16

printf "cycle=%f, dt=0x%08X\n", $samples_per_cycle, $dt;

    return sub {
        my $mod = shift;
        my $ret = $wave_table[($t >> 16)];
        $t = ( ($t + $dt + $mod) & 0x3FFFFFF );
        return $ret;
    };
}

my $sample_rate = 44100;
my $osc = create_osc( $sample_rate, 440 );

my ( $frames_per_buffer, $stream_flags ) = ( 512, undef );
my $api = Audio::PortAudio::default_host_api();
printf STDERR "Going to play via %s\nCtrl+c to stop...", $api->name;
my $device = $api->default_output_device;
my $stream = $device->open_write_stream( {
        channel_count => 1, # 1:mono, 2:stereo
        sample_format => 'int16' #  'float32', 'int16', 'int32', 'int24', 'int8', 'uint8'
    },
    $sample_rate,
    $frames_per_buffer,
    $stream_flags,
);

# Infinite loop...
while (1) {
    my $wa = $stream->write_available;
    my @buffer_ary = map {
        my $vol = $osc->( 0 );
        ( $vol < -32767 ) ? -32767 : ((32767 < $vol) ? 32767 : $vol);
    } (0..($wa - 1));
    my $buffer = pack("s*", @buffer_ary);
    $stream->write($buffer);
}

__END__
