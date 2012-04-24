#!/usr/bin/perl
#
# Jakob Hilarius <http://syscall.dk>, 2012
#
# 1. Unrar media files and deletes the archive
# 2. Remove sample media files
#
use strict;
use File::Find;
use Getopt::Long;

my @default_series_dirs = ("/c/media/Series", "/c/media/Movies");

my $dry_run = 0;
my @series_dirs = ();

GetOptions ('test' => \$dry_run, 'directory=s' => \@series_dirs);

if ($dry_run) {
	print "\n";
	print "############## WARNING #############\n";
	print "Running as dry run\n";
	print "####################################\n";
	print "\n";
}

if (@series_dirs == 0) {
	@series_dirs = @default_series_dirs;
}

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

find(\&process, @series_dirs);

sub process
{
    my $abs_file = $File::Find::name; 
	my $dir = $File::Find::dir;

    # Ignore some OSX junk files
    if ($abs_file =~ /\/\.AppleDouble\//) 
    {
        return;
    }
    
    if (/\.rar$/i)
    {
        process_rar($_, $abs_file, $dir);
    }
    elsif (/.*sample.*(avi|mpg|mkv)$/i)
    {
    	process_sample($abs_file);
    }
}

sub process_rar
{
	my ($name, $abs_file, $dir) = @_;
	print "Unpacking: $abs_file ... ";
	
	if ($dry_run) {
		$? = 0;
	}
	else {
		chdir($dir);
		system("unrar e -o+ \"$abs_file\" > /dev/null");
	}
	
	if ( $? == -1)
	{
		print "[ABORTED]\n";
		print "ERROR: unrar failed: $!\n";
		exit 7;
	}
	elsif ( $? != 0 ) {
		print "[FAILED]\n";
	}
	else {
		cleanup_rar($name, $dir);
		print "[DONE]\n";
	}
}

sub cleanup_rar
{
	my ($name, $dir) = @_;
	
	# Strip extension
	$name =~ s/\.[^.]*$//;
	
	opendir (DIR, $dir) or die $!;
	while (my $file = readdir(DIR)) {
		if ($file =~ /$name\.r(ar|[0-9]{2})$/i) {
			if ($dry_run) {
				print "Would have deleted: $dir/$file\n";			
			}
			else {
				unlink("$dir/$file");
			}
	    }
    }
}

sub process_sample
{
	my ($abs_file) = @_;
	print "Deleting: $abs_file ... ";
	
	my $result = 1;
	if (!$dry_run) {
		$result = unlink($abs_file);
	}
	
	if ( $result == 0 )
	{
		print "[FAILED]\n";
	}
	else {
		print "[DONE]\n";
	}
}