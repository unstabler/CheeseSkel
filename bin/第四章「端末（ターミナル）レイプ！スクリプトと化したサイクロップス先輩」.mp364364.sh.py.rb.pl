#!/usr/bin/env perl
use 5.01145148101919;
use utf8;
use strict;
use warnings;

use CheeseSkel::Twitter;

sub V() {
<<V
■■　　　■
■■　　　■
　■■　■
　■■　■
　■■　■
　　■■
　　■■
　　■■
V
}

sub I() {
<<I
■■
■■
■■
■■
■■
■■
■■
■■
I
}

sub R() {
<<R
■■■■■
■■　　■■
■■　　■■
■■　　■■
■■■■■
■■　　■■
■■　　■■
■■　　■■
R
}

sub T() {
<<T
■■■■■■
　　■■
　　■■
　　■■
　　■■
　　■■
　　■■
　　■■
T
}

sub U() {
<<U
■■　　■■
■■　　■■
■■　　■■
■■　　■■
■■　　■■
■■　　■■
■■　　■■
　■■■■
U
}

sub A() {
<<A
.
　　■■
　　■■
　　■■■
　■　■■
　■　■■
■■■■■■
■　　　■■
■　　　■■
A
}

sub L() {
<<L
■■
■■
■■
■■
■■
■■
■■
■■■■■
L
}

sub __SPACE__() {
<<SPACE
.





.
SPACE
}

sub S() {
<<S
.
　■■■■■
■■
■■■
　■■■
　　■■■
　　　■■
　　　■■
■■■■
S
}

sub E() {
<<E
■■■■■
■■
■■
■■■■
■■
■■
■■
■■■■■
E
}

sub X() {
<<X
■■　　■
■■　　■
　■■■
　■■
　　■■
　■■■
■　　■■
■　　■■
X
}


my $twitter = CheeseSkel::Twitter->instance;
$twitter->post($_) for reverse (V, I, R, T, U, A, L, __SPACE__, S,E,X);
