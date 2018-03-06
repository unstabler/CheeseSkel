#!/usr/bin/env perl
use 5.018;
use utf8;
use strict;
use warnings;

use Cwd qw/abs_path/;
use File::Path qw/make_path/;
use File::Copy;
use IPC::Run qw/run/;
use Term::ANSIColor qw/:constants/;

BEGIN {
    binmode STDOUT, ":encoding(utf-8)";
    binmode STDERR, ":encoding(utf-8)";
}

my %DEP_RESOLVED = ();

sub DEP_REQUIREMENTS () { qw/git wget zsh vim/;  }
sub DEP_OPTIONAL     () { qw/ffmpeg xwininfo tmux mpv/; }

sub MSG_E($)  { sprintf("[%s오류%s] %s\n", BRIGHT_RED,    RESET, shift); }
sub MSG_W($)  { sprintf("[%s경고%s] %s\n", BRIGHT_YELLOW, RESET, shift); }
sub MSG_I($)  { sprintf("[%s알림%s] %s\n", BRIGHT_BLUE,   RESET, shift); }
sub MSG_O($)  { sprintf("[%s OK %s] %s\n", BRIGHT_GREEN,  RESET, shift); }
sub PROMPT($) { sprintf("\n%s==>%s %s%s\n", BRIGHT_BLUE, BRIGHT_WHITE, shift, RESET); }

sub which {
    my ($command, $is_required) = @_;
    my $result = run ['/usr/bin/which', $command], '>', \my $path, '2>', \my $stderr;
    chomp $path;

    if ($result) {
        warn MSG_O("$command 를 찾았습니다: $path");
        return $path; 
    } else {
        if ($is_required) {
            die MSG_E("$command 가 설치되어 있지 않습니다. 더 이상 진행할 수 없습니다.");
        }
        warn MSG_W("$command 가 설치되어 있지 않습니다. 일부 기능이 동작하지 않을 수 있습니다.");
    }
}

sub check_dependencies {
    say PROMPT("의존성을 검사합니다");
    $DEP_RESOLVED{$_} = which($_, 1) for DEP_REQUIREMENTS;
    $DEP_RESOLVED{$_} = which($_, 0) for DEP_OPTIONAL;
    say "";
}

sub install {
    my ($method, $description, $source, $destination, $filename) = @_;

    my $resolved_source = abs_path($source);
    my $resolved_destination = $destination . '/' . $filename;

    say PROMPT($description . '을 설치합니다');
    warn MSG_I(sprintf(
        "파일을 다음 위치로 %s합니다.\n\t%s => %s",
        ($method eq 'copy') ? '복사' : '링크',
        $resolved_source,
        $resolved_destination
    ));

    unless (-d $destination) {
        warn MSG_W(sprintf(
            "%s 디렉토리가 없습니다. 새로 만듭니다.",
            $destination
        ));
        make_path($destination);
    }

    if (-e $resolved_destination) {
        warn MSG_W(sprintf(
            "%s가 이미 존재합니다. 이 파일은 %s.old로 이름이 변경됩니다.",
            $resolved_destination, $filename
        ));
        rename($resolved_destination, $resolved_destination . '.old');
    }

    if ($method eq 'copy') {
        copy($resolved_source, $resolved_destination);
    } elsif ($method eq 'link') {
        symlink($resolved_source, $resolved_destination);
    }
}

sub install_exec {
    my ($description, $commands) = @_;
    say PROMPT('다음 작업을 실행합니다: '. $description);

    for my $command (@$commands) {
        warn MSG_I(sprintf(
            "명령 실행: %s",
            join($", (@$command))
        ));
        system(@$command);
    }

    if ($? != 0) {
        warn MSG_W("명령이 정상적으로 종료되지 않았을 수도 있습니다. (retval = $?)");
    }
}

say "cheeseskel installer";
say "====================";

check_dependencies();
install('copy', 'zshrc 설정 파일', './zsh/zshrc.sample', $ENV{HOME}, '.zshrc');
install('link', 'vimrc 설정 파일', './vim/vimrc', $ENV{HOME}, '.vimrc');
install_exec('dein.vim 설치', [
    ['wget', '-O', '/tmp/dein-installer.sh', 'https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh'],
    ['sh', '/tmp/dein-installer.sh', $ENV{HOME} . '/.vim/bundles']
]);
install('copy', 'fontconfig 설정 파일', './fontconfig/fonts.conf', $ENV{HOME} . '/.config/fontconfig', 'fonts.conf');
install('copy', 'mpv 설정 파일', './mpv/mpv.conf', $ENV{HOME} . '/.config/mpv', 'mpv.conf');
install_exec('zsh로 기본 쉘 변경', [
    ['chsh', '-s', $DEP_RESOLVED{zsh}]
]) if -e $DEP_RESOLVED{zsh};

say "설치가 잘 끝났습니다.";
