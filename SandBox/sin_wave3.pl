use strict;
use warnings;
use Audio::PortAudio;
use Math::Trig qw( pi );

my $table_size = 4096;
my @wave_table = map {
    #my $tmp = sin( 2.0 * pi() * ($_ / $table_size) );
    my $tmp = ( $_ < ($table_size / 2.0) ) ? -1.0 : +1.0; # 矩形波
    #my $tmp = -0.5 + ( $_ / ($table_size - 1) ); # のこぎり波
    int( $tmp * 0x10000 );
} 0..($table_size - 1);

# アルファベットと+/-で表現した音程から周波数に変換する
sub note_to_freq {
    my $note = shift;

    # オクターブ = +3, ラの音の周波数
    my $FREQ_OF_A3 = 440.0;

    my %NOTE_TO_OFFSET = (
        C => -9,
        D => -7,
        E => -5,
        F => -4,
        G => -2,
        A =>  0,
        B =>  2
    );

    # MIDIだとオクターブは-2から+8まであるが、
    # 0から+8までサポートする
    my $freq = 0;
    if ( $note =~ /^[A-G][+|-]?[0-8]?/ ) {
        my @tmp = split //, $note;
        my $idx = $NOTE_TO_OFFSET{ shift @tmp };

        # A3の場合、$idx=0で440Hzが算出される
        foreach my $ch (@tmp) {
            if ( $ch eq '+' ) {
                $idx++;
            }
            elsif ( $ch eq '-' ) {
                $idx--;
            }
            else { 
                $idx += ( (int($ch) - 3) * 12 );
            }
        }

        $freq = $FREQ_OF_A3 * ( 2 ** ($idx / 12.0) );
    }
    else {
        warn '"' . $note . '" is not note.';
    }

    return int( $freq * 0x100 );
}

use integer;

sub create_osc {
    my $samples_per_sec = shift;
    my $freq = shift;

    my $samples_per_cycle = ($samples_per_sec * 0x1000) / ($freq >> 4); # u.8
    my $t = 0;
    my $dt = ($table_size * 0x10000) / $samples_per_cycle; # u.8

#printf "cycle=%f, dt=0x%08X\n", $samples_per_cycle, $dt;

    return sub {
        my $mod = shift;
        my $ret = $wave_table[($t >> 8)];
        $t = ( ($t + (($dt * (0x100 + $mod)) >> 8)) & 0x0FFFFF );
        #$t = ( ($t + $dt) & 0x0FFFFF );
        return $ret;
    };
}

my $sample_rate = 44100;
play( $sample_rate );

sub play {
    my $sample_rate = shift;

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

    my $bpm = 180;
    my @pattern = (
        [ 0, 0, 'D4',   7 ],
        [ 0, 4, 'D4',   7 ],
        [ 0, 8, 'D4',   7 ],

        [ 1, 0, 'D4',  28 ],

        [ 2, 0, 'C4',  22 ],

        [ 3, 0, 'E4',  22 ],

        [ 4, 0, 'D4',  84 ],

        [ 999, 0, 'C4', 0x10 ] # 不正参照しないためだけのダミーデータ
    );
    my $pattern_length = 7 * 12;

    # 1秒間に4分音符が鳴る間隔
    my $interval = ($sample_rate * 0x100 * 60) / $bpm; # u.8
    # 以下のように分割すると、3倍すると16分音符, 4倍すると3連符の間隔になる
    $interval /= 12;

    my $i = 0;
    my $index = 0;
    my $gate_time = 0;
    my $amp = 0;
    my $beat = 0;
    my $osc = sub { 0; };

    # Infinite loop...
    my $next_note_posi = ($pattern[$index][0] * 12) + $pattern[$index][1];
    my $step = 32;
    while (1) {
        my $wa = $stream->write_available;
        my $buffer = '';

        if ( $next_note_posi <= $beat ) {

            # 鳴らす音を変える
            $osc = create_osc( $sample_rate, note_to_freq($pattern[$index][2]) );
            $gate_time = ( $pattern[$index][3] * $interval ) >> (8 + 2);
            $gate_time -= 256;
            $amp = 0;

            $index++;
            $next_note_posi = ($pattern[$index][0] * 12) + $pattern[$index][1];
        }

        if ( $wa < $step ) {
            # nop
        }
        else {
            for ( 1..$step ) {
                my $val = ( $osc->(0) * $amp) >> 8;
                $val = ( $val < -32767 ) ? -32767 : ((32767 < $val) ? 32767 : $val);
                $buffer .= pack( 's', $val );

                if ( 0 < $gate_time ) {
                    if ( $amp < 256 ) { $amp++; }
                    $gate_time--;
                }
                else {
                    if ( 0 < $amp) { $amp--; }
                }
            }

            $i += $step;
            if ( ($interval >> 8) < $i ) {
                $i -= ($interval >> 8);
                $beat++;
            }

            if ( $pattern_length <= $beat ) {
                $beat -= $pattern_length;
                $index = 0;
                $next_note_posi = ($pattern[$index][0] * 12) + $pattern[$index][1];
            }
        }
        $stream->write( $buffer );
    }
}

__END__
