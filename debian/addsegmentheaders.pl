#!/usr/bin/perl
#
# Try to add segment headers to binary .t1 files without them.
# See https://personal.math.ubc.ca/~cass/piscript/type1.pdf
#
# (c) 2023 Roland Rosenfeld <roland@debian.org>

use strict;
use warnings;
use autodie;

if ($#ARGV != 0) {
   print STDERR "usage: $0 infile\n";
   exit 1;
}

my $infile = $ARGV[0];

open my $in, '<:raw', $infile;
my $bytes_read = read $in, my $bytes, 10000;
if (index($bytes, '%!PS-AdobeFont-1') != 0) {
   die "input does not start with %!PS-AdobeFont-1";
}
my $len = index($bytes, "file eexec\r");
die "file eexec not found" if $len == 0;
$len += length('file eexec.');
close $in;
print gen_segment(1, $len);

open $in, '<:raw', $infile;
$bytes_read = read $in, $bytes, $len;
print $bytes;

my $max_size = 1000000;
$bytes_read = read $in, $bytes, $max_size;
die "file too big" if $bytes_read == $max_size;
print gen_segment(2, $bytes_read);
print $bytes;
print gen_header(3);
close $in;

sub gen_header {
   my ($seq) = @_;
   return pack("C*", 128, $seq);
}

sub gen_segment {
   my ($seq, $length) = @_;
   my $b0 = $length % 256;
   $length -= $b0;
   $length /= 256;
   my $b1 = $length % 256;
   $length -= $b1;
   $length /= 256;
   my $b2 = $length % 256;
   $length -= $b2;
   $length /= 256;
   my $b3  = $length;
   return gen_header($seq).pack("C*", $b0, $b1, $b2, $b3);
}

