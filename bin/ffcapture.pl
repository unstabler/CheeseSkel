#!/usr/bin/env perl
#
# ffcaputre.pl       
#  - by unstabler / cheesekun (doping.cheese@gmail.com)
#    http://unstabler.pl / twitter: @unstable_cheese
#
# ffmpeg를 이용하여 X 윈도우의 화면을 쉽게 동영상으로 캡쳐할 수 있도록 도와주는 스크립트입니다.
#
# TODO : 특정 영역 녹화 추가 ($ ffcapture.pl -x 0 -y 0 -w 1280 -h 720 out.avi)

use 5.010;
use utf8;
use strict;
use warnings;

BEGIN {
    # 출력 버퍼를 비활성화합니다.
    local $| = 1;

    # STDERR로 메시지를 UTF-8로 출력합니다.
    binmode "STDERR", ":encoding(utf8)";
}

my %apps;
{
    my %options = (default_options(), parse_argv(), check_dependencies());
    my %window  = capture_window($options{target});
    start_capture(\%window, \%options);
}
sub check_dependencies {

    my %options;

    # 실행 전 의존성을 체크합니다.
    my @dependencies = qw/ffmpeg xwininfo/;
    for (@dependencies) {
        my $apppath = check_which($_);
        die $_."가 설치되어 있지 않습니다. 패키지 관리자를 통해 설치해 주십시오." unless $apppath;
        $apps{$_} = $apppath;
    }

    $options{display} = $ENV{DISPLAY};
    die '$DISPLAY not defined. Please run this script on X11.' unless $options{display};


    return %options;
}

sub check_which {
    # which 명령어로 프로그램이 설치되어 있는지 체크합니다.
    # which로 찾을 수 없거나 따로 빌드해둔 버전을 사용하고 싶은 경우 FORCE_USE_FFMPEG 등의 환경 변수를 지정해 주세요.
    my $appname = shift;

    my $user_defined = $ENV{"FORCE_USE_".uc($appname)};
    if ($user_defined) {
        return $user_defined if -e $user_defined;
        warn (sprintf "경고: %s를 %s로 사용하도록 지정했지만 존재하지 않았습니다.", $appname, $user_defined); 
    }

    my $which = `which $appname` || "";
    chomp $which;

    return if !$which || $which =~ /not found/;
    
    return $which;
}

sub check_x11grab {
    my $ffmpeg_buildconf = `$apps{ffmpeg} -buildconf 2>&1`;
    return if $ffmpeg_buildconf !~ m/--enable-x11grab/;

    return 1;
}

sub parse_argv {
    
    # TODO: FIXME: 부실한 @ARGV 파싱
    # 졸리니까 어쩔 수 없어.. 아 내일 데이터베이스.. 시험.. 아.. 9시까지.. 

    # usage: ffcapture.pl [options] outfile
    # $ ffcapture.pl --fullscreen "동영상.mp4"
    # 
    # ffcapture.pl --help
    # ffcapture.pl "치즈.avi"
    
    my %parsed_options;

    for (my $i = 0; $i <= $#ARGV; $i++) {
        my $option = $ARGV[$i];
        
        if ($option eq "--help") {
            warn usage();
            exit;
        }
        
        if ($option eq "--ffmpeg-options") {
            # read more
            my $value = $ARGV[++$i];
            $parsed_options{ffmpeg} = $value;
        } elsif ($option eq "--fullscreen") {
            $parsed_options{target} = "fullscreen";
        } elsif ($option eq "--disable-audio") {
            $parsed_options{audio}{enable} = 0;
        } elsif ($option eq "--overwrite") {
            $parsed_options{overwrite} = 1;
        } elsif ($i == $#ARGV) {
            $parsed_options{outfile} = $option;
        } 
    }

    return %parsed_options;
}

sub usage {
    my ($script_name) = $0 =~ m{([^/]+)$};
    return qq{
usage: $script_name [options] [outfile] 
X 윈도우의 동영상 캡쳐를 도와주는 스크립트입니다.


옵션 : 
--ffmpeg-options '[ffmpeg options]'
    ffmpeg의 인코딩 옵션을 지정합니다.
    (예시: --ffmpeg-options '-acodec libfaac -b:a 64k')


--fullscreen    전체 화면을 녹화합니다.
--disable-audio 오디오 녹음을 하지 않습니다.
--overwrite     파일이 이미 있어도 덮어씁니다.
--help          이 도움말을 표시합니다.


치즈군★ (doping.cheese\@gmail.com)\n".
Seoul.pm 파이팅! :-)\n";
}
}

sub capture_window {
    my $target = shift;
    my $option;
    my %window_info;
    if ($target eq 'fullscreen') {
        $option = '-root';
    } elsif ($target eq 'window') {
        warn "캡쳐하실 창을 마우스로 선택해 주세요.\n";
        $option = '-frame';
    } elsif ($target eq 'window_noframe') {
        $option = '';
    }

    my $xwininfo = `$apps{xwininfo} $option`;
    
    ($window_info{geometry}) = $xwininfo =~ m/-geometry\s+(\d+x\d+)/;
    ($window_info{corners}{x}, $window_info{corners}{y}) = $xwininfo =~ m/Corners:\s+([+-]+?\d+)([+-]+?\d+)/;
    return %window_info;
}

sub start_capture {
    my $ffmpeg_options = to_ffmpeg_options(@_);
    my %window_info    = %{(shift)};   

    # TODO : ffmpeg에서 스크립트로 파이프 열고 SIGINT 캐치해서 좀 정상적으로 종료할 수 있도록 해야 합니다
    warn "q 키를 눌러서 녹화를 종료할 수 있습니다.\n";
    system("ffmpeg $ffmpeg_options");
}

sub to_ffmpeg_options {
    my %window_info = %{(shift)};
    my %options     = %{(shift)};

    my (@opt_input, @opt_encode);
    
    if ($options{overwrite}) {
        push @opt_input, '-y';
    }

    if ($options{audio}{enable}) {
        push @opt_input,
            sprintf "-f %s -i %s", $options{audio}{f}, $options{audio}{i};
    } else {
        push @opt_encode, "-an";
    }

    push @opt_input,
        sprintf '-f x11grab -s "%s" -i "%s%s,%s"', $window_info{geometry}, $options{display}, 
        $window_info{corners}{x}, $window_info{corners}{y};

    push @opt_encode, ($options{ffmpeg}, "'$options{outfile}'");
    
    return (join $", @opt_input)." ".(join $", @opt_encode);
}

###################
# Default Options #
###################################
# 기본 설정을 변경할 수 있습니다. #
# 설정값 변경은 조심조심!         #
###################################

sub default_options {
    return (
        'audio' => {
            'enable' => 1,

            # ffmpeg 오디오 입력 설정입니다.

            # ALSA 사용 시에는 다음 링크의 문서를 참고하시면 좋습니다. 
            # 다들 ALSA 쓰시는데 전 안써서 어떻게 도움을 못 드려요.. :-(
            # https://trac.ffmpeg.org/wiki/Capture/ALSA

            #'f' => 'alsa',
            #'i' => 'hw:0', 

            # PulseAudio의 경우 Monitor of ... 으로 스테레오 믹스와 같이 오디오 루프백도 가능합니다.
            # pactl list sources 명령으로 사용 가능한 장치를 확인해 보세요!
            #
            'f' => 'pulse',
            'i' => 'alsa_output.pci-0000_00_1b.0.analog-stereo.monitor',

        },

        # ffmpeg의 인코딩 설정을 지정합니다.
        # 기본값으로도 충분히 멋진 결과물이 나올거에요!
        'ffmpeg'    => '-vcodec libx264 -r 60 -preset ultrafast -crf 18 -strict -2 -acodec aac -b:a 160k',
        
        'target'    => 'window',

        # 출력 파일 이름
        'outfile'   => 'out.mp4',

        # 파일 덮어쓰기 여부
        'overwrite' => 0,
    );
}

