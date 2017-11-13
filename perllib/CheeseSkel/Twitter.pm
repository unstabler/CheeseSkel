package CheeseSkel::Twitter;
use 5.010;
use strict;
use warnings;

use utf8;

use Net::Twitter;
use JSON;

sub DEFAULT_TOKEN_PATH () { $ENV{HOME}."/.twitter-token.json" }

my $_INSTANCE = undef;

sub _build_twitter () {
    return Net::Twitter->new(
        traits          => [qw/API::RESTv1_1/],
        ssl             => 1,
        consumer_key    => 'Z9lDR38LEiSWcUG4gs1mA',
        consumer_secret => 'hya7C82K4cx8ASEjEqSL4zAGMm0FzGX4T3VOGxnRyo',
    );
}

sub instance {
    unless (defined $_INSTANCE) {
        my $class = shift;
        my $twitter = _build_twitter;

        $_INSTANCE = bless {
            '_twitter' => $twitter    
        }, $class;

        $_INSTANCE->load_token;
    }
    return $_INSTANCE;
}

sub twitter {
    my $self = shift;
    return $self->{_twitter};
}

sub load_token {
    my $self = shift;
    my $token;

    unless (-e DEFAULT_TOKEN_PATH) {
        $token = $self->request_new_token;
        $self->write_token($token, DEFAULT_TOKEN_PATH);
    } else {
        $token = $self->read_token;
    }

    $self->twitter->access_token($token->{access_token});
    $self->twitter->access_token_secret($token->{access_token_secret});
}

sub request_new_token {
    my $self = shift;
    my $auth_url = $self->twitter->get_authorization_url;
    my ($token, $pin);
    
    say $auth_url;
    print "PIN >";

    $pin = <STDIN>;
    chomp $pin;

    my (
        $access_token, 
        $access_token_secret
    ) = $self->twitter->request_access_token(verifier => $pin);

    $token = {
        access_token        => $access_token,
        access_token_secret => $access_token_secret,
    };

    return $token;
}

sub write_token {
    my $self = shift;
    my ($token, $path) = @_;

    open my $fh, '>', $path or die "cannot open filehandle to $path";
    print $fh JSON::to_json($token);
    close $fh;
}

sub read_token {
    my $self = shift;
    my $path = DEFAULT_TOKEN_PATH;
    my $raw_json = '';

    open my $fh, '<', $path or return "cannot open filehandle to $path";
    $raw_json .= $_ while <$fh>;
    close $fh;

    return JSON::from_json($raw_json);
}

sub post {
    my $self = shift;
    my ($tweet, $media) = @_;

    eval {
        unless (defined $media) {
            $self->twitter->update($tweet);
        } else {
            $self->twitter->update_with_media($tweet, [$media]);
        }
    };

    warn $@ if $@;

    if ($ENV{DISPLAY}) {
        my $message = ($@)? "오류가 발생하였습니다 : \n".$@ : "포스트가 완료되었습니다.\n$tweet";
        system(qw/kdialog --title 노란나물무침 --passivepopup/, $message);
    }

    return (!defined $@);
}

1;
