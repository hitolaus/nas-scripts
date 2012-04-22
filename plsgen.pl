#!/usr/bin/perl
#
# 2011, Jakob Hilarius
#
# Generates a random playlist file from the video files
# found in a list of directories.
#
use strict;
use File::Find;
use List::Util qw(shuffle);

my $pls_output_file = "/c/media/Series/Comedy.pls";
my $m3u_output_file = "/c/media/Series/Comedy.m3u";

my $share_prefix = "smb://192.168.5.130/Media/Series";
my $base_dir = "/c/media/Series";
my @series_names = ("Two and a Half Men", "The Big Bang Theory", "Rules of Engagement", "Joey", "How I Met Your Mother", "8 Simple Rules", "Dharma & Greg", "According to Jim", "Shit My Dad Says", "Two and a Half Men", "Will & Grace", "Melissa and Joey", "Friends");

my @series_dirs;

foreach my $series (@series_names)
{
	push(@series_dirs, "$base_dir/$series");
}

my @pls_urls = ();

find(\&process, @series_dirs);

my @random_pls_urls = shuffle(@pls_urls);

&create_m3u;

sub process
{
    my $abs_file = $File::Find::name;
    my $rel_file = substr($abs_file, length($base_dir)+1);

    # Ignore some OSX junk files
    if ($abs_file =~ /\/\.AppleDouble\//) 
    {
        return;
    }
    
    if (/\.mpg$|\.avi$|\.mkv$/i)
    {
        push(@pls_urls, "$share_prefix/$rel_file");
    }
}

sub create_pls
{
	open (PLS, '>'.$pls_output_file);

	print PLS "[playlist]\n";
	for (my $i = 0; $i < $#random_pls_urls+1; $i++) {
		print PLS "File".($i+1)."=".$random_pls_urls[$i]."\n";
		#TitleX
		#LengthX
	}
	print PLS "NumberOfEntries=".($#random_pls_urls+1)."\n";
	print PLS "Version=2\n";
	
	close(PLS);
}

sub create_m3u
{
	open (M3U, '>'.$m3u_output_file);
    
	print M3U "#EXTM3U\n";
	for (my $i = 0; $i < $#random_pls_urls+1; $i++) {
		print M3U $random_pls_urls[$i]."\n";
		#TitleX
		#LengthX
	}
	
	close(M3U);
}