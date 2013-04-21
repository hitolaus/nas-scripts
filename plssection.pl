#!/usr/bin/perl
#
# 2013, Jakob Hilarius <http://syscall.dk>
#
# Generates symbolic links in a random order in a given directory. This directory
# is meant to be added as a section in Plex as "Home Video".
#
# TODO:
# - Also link subtitles if they exists
##

use strict;
use File::Find;
use List::Util qw(shuffle);
use Getopt::Long;
use File::Basename;
use POSIX qw/strftime/;

my $max_pls_files = 25;


my $default_base_dir = "/Volumes/Media/Series";
my $default_dest_dir = "/Volumes/Media/Random Series";

my $dry_run = 0;
my $base_dir;
my $dest_dir;

GetOptions ('test' => \$dry_run, 'src=s' => \$base_dir, 'dest=s' => \$dest_dir);

if ($dry_run) {
	print "\n";
	print "############## WARNING #############\n";
	print "Running as dry run\n";
	print "####################################\n";
	print "\n";
}

if ($base_dir eq "") {
	$base_dir = $default_base_dir;
}

if ($dest_dir eq "") {
	$dest_dir = $default_dest_dir;
}

my @series_names = (
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
	"Anger Management",
	"Spin City"
);

my @series_dirs = ();
foreach my $series (@series_names) {
	push(@series_dirs, "$base_dir/$series");
}


print "Starting [" . strftime('%D %T',localtime) .  "]\n\n";

print "Checking status of directories:\n";
foreach (@series_dirs) {
	print "$_";
  	if (-d) {
  		print " [OK]";
  	}
  	else {
  		print " [FAILED]";
  	}
  	print "\n";
}
print "\n";


my @pls_files = ();

find(\&process, @series_dirs);

my @random_pls_files = shuffle(@pls_files);
@random_pls_files = splice(@random_pls_files, 0, $max_pls_files);

# Cleanup dir
find(\&delete_links, $dest_dir);

my $i = 1;
foreach my $src (@random_pls_files) {

	#my($filename, $dir, $suffix) = fileparse($src, qr/[^.]*$/);
    if ($dry_run) {
        #print "Linking $src to $dest_dir/$i - ".generate_random_string(8).".$suffix\n";
        print "Linking $src to $dest_dir/$i - ".prettyprint_series($src)."\n";
    }
    else {
        #symlink($src, "$dest_dir/$i - ".generate_random_string(8).".$suffix");
        symlink($src, "$dest_dir/$i - ".prettyprint_series($src));
    }

	$i++;
}

#################################
# Subroutines
#################################

sub delete_links
{
    my $abs_file = $File::Find::name;
    if ( -l "$abs_file" ) {

        if ($dry_run) {
            print "Deleting file $abs_file\n";
        }
        else {
            unlink "$abs_file"
                or die "Failed to remove file $abs_file: $!\n";
        }

    }
}

sub process
{
    my $abs_file = $File::Find::name;
    my $rel_file = substr($abs_file, length($base_dir)+1);

    # Ignore some OSX junk files
    if ($abs_file =~ /\/\.AppleDouble\//)
    {
        return;
    }

    if (/\.mpg$|\.avi$|\.mkv$|\.ts|\.mp4$/i)
    {
        push(@pls_files, "$abs_file");
    }
}

sub generate_random_string
{
 my $length_of_randomstring=shift;# the length of
 # the random string to generate

 my @chars=('a'..'z','A'..'Z','0'..'9','_');
 my $random_string;
 foreach (1..$length_of_randomstring)
 {
   # rand @chars will generate a random
   # number between 0 and scalar @chars
   $random_string.=$chars[rand @chars];
 }

 return $random_string;
}

# Input: .../Two and a half Men/Season 4/two.and.a.half.men.s04e10.bla.mkv
# Supported filenames:
# - two.and.a.half.men.s04e10.bla.mkv
# - s04e10 - bla.mkv
# - two.and.a.half.men.410.bla.mkv
# - The.Big.Bang.Theory.1x01.Pilot.720p.HDTV.x264.AC3-CTU.mkv
# - Dharma & Greg  - S03E23 - Hell to the chief.avi
# - Two and A Half Men S6E14 - David Copperfield Slipped Me a Roofie.avi
sub prettyprint_series
{
	my ($path) = @_;

	my($filename, $dir, $suffix) = fileparse($path, qr/[^.]*$/);
	my $regex1 = '[sS]([0-9]{1,2})[eE]([0-9]{1,2})';
	my $regex2 = '([1-9])([0-9]{2})';
	my $regex3 = '([1-9]{1,2})x([0-9]{2})';

	my $pretty_name;

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
		$name =~ s/\s+$//; # Remove leading/trailing spaces
		$name =~ s/-$//;   # Remove leading/trailing dashes: Joey - => Joey
		$name =~ s/\s+$//; # Remove leading/trailing spaces again. This may happen if there was a leading dash
		$name =~ s/([\w']+)/\u\L$1/g; # Transform each word to uppercase

		$season  =~ s/^0+//; # Remove leading 0's
		$episode =~ s/^0+//; # Remove leading 0's

		$pretty_name = "$name - Season $season Episode $episode";
	}
	else
	{
		# Try to format the string as best as possible
		my $name = $filename;
		$name =~ s/\.[^.]*$//; # Remove extension
		$name =~ s/\./ /g; # . to spaces
		$name =~ s/\s+$//; # Remove leading/trailing spaces

		$pretty_name = "$name";
	}

	return "$pretty_name.$suffix"
}