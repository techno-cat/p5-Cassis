use strict;
use warnings;
use Audio::PortAudio;
use Math::Trig qw( pi );

# ノイズの初期化
srand( 2 ); # 好みの音が得られる乱数Seedで固定
my @noise = map { rand( 2.0 ) - 1.0; } 1..1024;

my %func_table = (
    'pulse' => sub { # 矩形波
        return ( $_[0] < 0.5 ) ? -1.0 : 1.0;
    },
    'sin'   => sub { # サイン波（正弦波）
        return sin( 2.0 * pi() * $_[0] );
    },
    'saw'   => sub { # のこぎり波
        return ( 2.0 * $_[0] ) - 1.0;
    },
    'tri'   => sub { # 三角波
        if ( $_[0] < 0.5 ) {
            # -1.0 -> +1.0
            return -1.0 + ( 4.0 * $_[0] );
        }
        else {
            # +1.0 -> -1.0
            return 1.0 - ( 4.0 * ($_[0] - 0.5) );
        }
    },
    'noise' => sub { # ノイズ
        if ( $_[0] < 1.0 ) {
            my $idx = int( $_[0] * scalar(@noise) );
            return $noise[$idx];
        }
        else {
            return 0.0;
        }
    }
);

# 種類を指定して、波形を生成する関数を返す
sub create_mod_func {
    my $func = $func_table{$_[0]} or die;
    return $func;
}

# 任意のパラメータで波形を生成する関数を返す
sub create_modulator {
    my $samples_per_sec = shift;
    my $arg_ref = shift;

    my $freq = $arg_ref->{freq};
    my $osc_func = create_mod_func( $arg_ref->{waveform} );
    my $t = 0.0;
    my $samples_per_cycle = $samples_per_sec / $freq;
    return sub {
        my $mod = shift;
        my $ret = $osc_func->(
            $t / $samples_per_cycle
        );

        my $dt = 1.0 + $mod;
        if ( 0.0 < $dt ) {
            $t += $dt;
            while ( $samples_per_cycle <= $t ) {
                $t -= $samples_per_cycle;
            }
        }

        return $ret;
    };
}

# 440Hzのサイン波を生成する例
my $osc = create_modulator(
    44100,                  # サンプリング周波数
    {
        freq => 440,        # 周波数
        waveform => 'sin'   # 波形の種類
    }
);

my ( $sample_rate, $frames_per_buffer, $stream_flags ) = ( 44100, 512, undef );
my $api = Audio::PortAudio::default_host_api();
printf STDERR "Going to play via %s\nCtrl+c to stop...", $api->name;
my $device = $api->default_output_device;
my $stream = $device->open_write_stream( {
        channel_count => 1, # 1:mono, 2:stereo
        sample_format => 'float32'
    },
    $sample_rate,
    $frames_per_buffer,
    $stream_flags,
);

# Infinite loop...
while (1) {
    my $wa = $stream->write_available;
    my @buffer_ary = map {
        $osc->( 0 );
    } (0..($wa - 1));
    my $buffer = pack("f*", @buffer_ary);
    $stream->write($buffer);
}

__END__
