#!/usr/bin/perl
#
# 2011-2012, Jakob Hilarius <http://syscall.dk>
#
# Generates a random playlist file from the video files
# found in a list of directories.
#
# TODO:
# - Configurable base and output dir
# - Configurable serie names (maybe through thetvdb.com or trakt.tv)
# - Support for multiple outputs
# - Auto update Boxee queue
##
use strict;
use File::Find;
use List::Util qw(shuffle);
use Socket;
use Sys::Hostname;
use File::Basename;

my $max_pls_files = 50;

my $pls_output_file = "/c/media/Series/Comedy.pls";
my $m3u_output_file = "/c/media/Series/Comedy.m3u";

my $base_dir = "/c/media/Series";
my @series_names = (
	"Two and a Half Men", 
	"The Big Bang Theory", 
	"Rules of Engagement", 
	"Joey", 
	"How I Met Your Mother", 
	"8 Simple Rules", 
	"Dharma & Greg", 
	"According to Jim", 
	"Two and a Half Men", 
	"Will & Grace", 
	"Melissa and Joey", 
	"Friends", 
	"Anger Management"
);


my $host = hostname();
my $addr = inet_ntoa(scalar(gethostbyname($host)) || 'localhost');

my $share_prefix = "smb://".$addr."/Media/Series";


my @series_dirs;

foreach my $series (@series_names)
{
	push(@series_dirs, "$base_dir/$series");
}

my @pls_urls = ();

find(\&process, @series_dirs);

my @random_pls_urls = shuffle(@pls_urls);

&create_m3u;

#print prettyprint_series(".../Two and a half Men/Season 4/two.and.a.half.men.s04e10.bla.mkv") . "\n";
#print prettyprint_series(".../Two and a half Men/Season 4/The.Big.Bang.Theory.1x01.Pilot.720p.HDTV.x264.AC3-CTU.mkv") . "\n";
#print prettyprint_series(".../Two and a half Men/Season 4/s04e11 - bla.mkv") . "\n";
#print prettyprint_series(".../Two and a half Men/Season 4/two.and.a.half.men.412.bla.mkv") . "\n";
#print prettyprint_series(".../Two and a half Men/Season 4/foo.bar.mkv") . "\n";
#print prettyprint_series(".../Two and a half Men/Season 4/Dharma & Greg  - S03E23 - Hell to the chief.avi") . "\n";

#################################
# Subroutines
#################################

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

	my $entries = 0;

	print PLS "[playlist]\n";
	for (my $i = 0; $i < $#random_pls_urls+1; $i++) {
		if ($i < $max_pls_files) {
			print PLS "Title".($i+1)."=".prettyprint_series($random_pls_urls[$i])."\n";
			print PLS "File".($i+1)."=".$random_pls_urls[$i]."\n";
			#LengthX
			
			$entries++;
		}
	}
	print PLS "NumberOfEntries=".($entries)."\n";
	print PLS "Version=2\n";
	
	close(PLS);
}

sub create_m3u
{
	open (M3U, '>'.$m3u_output_file);
    
	print M3U "#EXTM3U\n";
	for (my $i = 0; $i < $#random_pls_urls+1; $i++) {
		if ($i < $max_pls_files) {
			print M3U "#EXTINF:-1, ".prettyprint_series($random_pls_urls[$i])."\n";
			print M3U $random_pls_urls[$i]."\n";;
		}
	}
	
	close(M3U);
}

# Input: .../Two and a half Men/Season 4/two.and.a.half.men.s04e10.bla.mkv
# Supported filenames:
# - two.and.a.half.men.s04e10.bla.mkv
# - s04e10 - bla.mkv
# - two.and.a.half.men.410.bla.mkv
# - The.Big.Bang.Theory.1x01.Pilot.720p.HDTV.x264.AC3-CTU.mkv
# - Dharma & Greg  - S03E23 - Hell to the chief.avi
sub prettyprint_series
{
	my ($path) = @_;

	my($filename, $dir, $suffix) = fileparse($path);

	my $regex1 = '[sS]([0-9]{2})[eE]([0-9]{2})';
	my $regex2 = '([1-9])([0-9]{2})';
	my $regex3 = '([1-9]{1,2})x([0-9]{2})';

	if ($filename =~ /(.*?)($regex1|$regex2|$regex3)/) 
	{
		my $name = $1;
		# A bit nasty would be a lot more simple with named capture groups but
		# we need to run using Perl 5.8.8 which doesn't support named groups
		my $season  = ($3) ? $3 : (($5) ? $5 : $7);
		my $episode = ($4) ? $4 : (($6) ? $6 : $8);
		
		if ($name eq "") 
		{
			my @dir_array = split('/', $dir);
			$name = $dir_array[@dir_array-2];
		}
		$name =~ s/\./ /g; # Translate dots to spaces: two.and.a.half.men => two and a half men
		$name =~ s/\s+$//; # Remove leading spaces
		$name =~ s/-$//;   # Remove leading dashes: Joey - => Joey
		$name =~ s/\s+$//; # Remove leading spaces again. This may happen if there was a leading dash
		$name =~ s/([\w']+)/\u\L$1/g; # Transform each word to uppercase
	
		$season  =~ s/^0+//;
		$episode =~ s/^0+//;
		
		return "$name - Season $season Episode $episode";
	}
	else 
	{
		my $name = $filename;
		$name =~ s/\.[^.]*$//;
		$name =~ s/\./ /g;
		$name =~ s/\s+$//;
		
		return "$name";
	}
}