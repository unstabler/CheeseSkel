#!/usr/bin/env perl
use utf8;
use 5.010;
use strict;
use warnings;

use Encode qw/decode/;
use Data::Dumper;
use Net::DBus;
use CheeseSkel::Twitter;

my $twitter = CheeseSkel::Twitter->instance;

my $bus = Net::DBus->find;
my $clementine = $bus->get_service("org.mpris.clementine");
my $player     = $clementine->get_object('/Player');
my $metadata   = $player->GetMetadata;

exit unless $metadata->{title};

my $arturl = $metadata->{arturl} =~ s{^file://}{}r;
$twitter->post(build_tweet($metadata), $arturl) if $metadata->{title};

sub build_tweet {
    my $metadata = shift;
    my @hashtags = @_ || qw/nowlistening 노란나물무침/;

    my $tweet = "치즈군🧀은 지금 ";
    my ($artist, $title, $album) = map { decode("utf-8", $metadata->{$_} || "") } qw/artist title album/;

    $tweet .= sprintf "%s의 ", substr($artist, 0, 15) if $artist;
    $tweet .= sprintf "%s를 듣고 있어요!", substr($title, 0, 20);
    $tweet .= sprintf "(%s)", substr($album, 0, 20) if $album;

    $tweet .= sprintf " #%s", $_ for (@hashtags);

    return $tweet;
}
