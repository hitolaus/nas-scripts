#!/usr/bin/perl
#
# Jakob Hilarius <http://syscall.dk>, 2012
#
# 1. Unrar media files and deletes the archive
# 2. Remove sample media files
# 3. Move series episodes out of own directories to season directory
##
use strict;
use File::Find;
use File::Copy;
use File::Basename;
use Getopt::Long;
use POSIX qw/strftime/;
use OpenSubtitles;

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
    elsif (is_sample_file($_))
    {
    	process_sample($abs_file);
    }
    elsif (is_video_file($_))
    {
    	process_video($abs_file, $dir);
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
		system("unrar e -o+ -p- \"$abs_file\" > /dev/null");
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
				print "DRY RUN: delete $dir/$file\n";			
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

sub process_video
{
	my ($abs_file, $dir) = @_;
	
	my $dest_file = process_episode_directory($abs_file, $dir);
	
	download_subtitles($dest_file);
}

sub process_episode_directory
{
	my ($abs_file, $dir) = @_;
	
	if (has_episode_dir($dir))
	{
		my $dest_file = dirname($dir) . "/" . basename($abs_file);
		if ($dry_run)
		{
			print "DRY RUN: move $abs_file $dest_file\n";
		}
		else
		{
			move($abs_file, $dest_file);
			return $dest_file;
		}
	}
	
	return $abs_file;
}

sub download_subtitles
{
	my ($abs_file) = @_;
	
    if (!subtitles_exist($abs_file)) {
	    my $os = OpenSubtitles->new();
        $os->download($abs_file);
    }
}

sub subtitles_exist
{
    my ($abs_file) = @_;
    
    my ($name, $path, $suffix) = fileparse( $abs_file, qr/\.[^.]*/ );
    
    if (has_nosub($path, $name)) {
        return 1;
    }
        
    my $found_subtitle = 0;
    foreach my $subtitle_ext ("srt")
    {
        if ( -e "$path$name.$subtitle_ext") {
            $found_subtitle = 1;
        }
    }
    
    if (!$found_subtitle) {
        register_nosub($path, $name);
    }
    
    return $found_subtitle;
}

sub has_nosub
{
    my ($path, $name) = @_;
    
    return nosub_count($path, $name) > 24;
}

sub register_nosub
{
    my ($path, $name) = @_;
    
    my $cnt = nosub_count($path, $name);
    
    open (NOSUB_FILE, ">".nosub($path, $name));
    
    print NOSUB_FILE $cnt + 1;
    
    close(NOSUB_FILE);
}

sub nosub_count
{
    my ($path, $name) = @_;
    
    my $cnt = 0;
    
    open (NOSUB_FILE, nosub($path, $name));
    
    while (<NOSUB_FILE>) {
     	chomp;
     	$cnt = $_;
    }
    
    close(NOSUB_FILE);
    
    return $cnt;
}

sub nosub
{
    my ($path, $name) = @_;
    
    return "$path.$name.nosub";
}

############################
# Helper subroutines
############################
sub has_episode_dir
{
	my ($dir_name) = @_;

	return $dir_name =~ /.*S[0-9]{1,2}E[0-9]{1,2}.*/i;
}
sub is_video_file
{
	my $file = $_;
	return $file =~ /.*(avi|mpg|mpeg|mkv|mp4|mpeg4)$/i;
}
sub is_sample_file
{
	my $file = $_;
	return $file =~ /.*sample.*(avi|mpg|mkv|mp4|mpeg4)$/i;
}