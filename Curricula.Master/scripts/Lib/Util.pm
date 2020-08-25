package Util;
use strict;
use Carp::Assert;
use Text::Balanced qw<extract_bracketed>;

# use Term::ANSIColor; # http://pueblo.sourceforge.net/doc/manual/ansi_color_codes.html
# use POSIX;
# use POSIX qw(setsid);
# use POSIX qw(:errno_h :fcntl_h);

our %control	= ();
# ok
sub precondition($)
{
	my ($key) = (@_);
	if(not defined($control{$key}))
	{
		Util::print_color("precondition $key is not fulfilled ...")
	}
	assert(defined($control{$key}));
	assert($control{$key} == 1);
}

# ok
sub check_point($)
{
	my ($key) = (@_);
	$control{$key} = 1;
}

# ok
sub uncheck_point($)
{
	my ($key) = (@_);
	$control{$key} = 0;
}

sub is_checked_point($)
{
        my ($key) = (@_);
        if(defined($control{$key}) and $control{$key} == 1)
        {    return 1;          }
        return 0;
}

# ok
sub print_message($)
{
	my ($msg) = (@_);
	print "$msg\n";
}

# ok
sub print_error($)
{
	my ($msg) = (@_);
	print_soft_error("** ERROR ** :$msg\n");
	assert(0);
	exit;
}

# https://pypi.python.org/pypi/colorama
sub print_soft_error($)
{
	my ($msg) = (@_);
	print "\x1b[41m$msg\x1b[0m\n";
}

# ok # https://pypi.python.org/pypi/colorama
sub print_color($)
{
	my ($msg) = (@_);
	print "\x1b[43m\x1b[30m$msg\x1b[39m\x1b[49m\n";
}

# https://pypi.python.org/pypi/colorama
sub print_warning($)
{
	my ($msg) = (@_);
	print "\x1b[44m\x1b[30m ** WARNING ** : $msg\x1b[0m\n";
}

# https://pypi.python.org/pypi/colorama
sub print_success($)
{
	my ($msg) = (@_);
	print "\x1b[44m $msg\x1b[0m\n";
}

#  ok
sub halt($)
{
	my ($msg) = (@_);
	print_error($msg);
	assert(0);
	exit;
}

sub get_ang_base($)
{
	my ($nareas) = (@_);
	return (2*3.14159)/$nareas;
}

sub rotate($$$)
{
	my ($x, $y, $ang)  = (@_);
	my ($xp,$yp) = ($x*cos($ang)-$y*sin($ang), $x*sin($ang)+$y*cos($ang));
	return ($xp,$yp);
}

sub round($)
{
	my ($f) = (@_);
	my $txt = "$f";
	if( $txt =~ m/(.*?\...)/)
 	{	return $1;	}
 	return $f;
}

sub calc_percent($$)
{
	my ($part, $total) = (@_);
	my $percent = 100 * $part/$total;
	if($percent =~ m/(.*\..).*/)
	{	$percent  = $1;
	}
	return $percent;
}

our $flag = 0;
# ok
sub read_file($)
{
	my ($filename) = (@_);
	open(IN, "<$filename") or Util::halt("read_file: $filename does not open");
	my @lines = <IN>;
	close(IN);
	return join("", @lines);
}

sub trim_comments($)
{
	my ($txt) = (@_);
	my @lines = split("\n", $txt);
	my $cline = 0;
	foreach (@lines)
	{
		$lines[$cline] =~ s/^%.*$//g;
		pos($lines[$cline])   =  0;
		while( $lines[$cline] =~ m/(.)%(.*)/g )
		{
			my $matchpos = $-[0];
			my ($char, $comment) = ($1, $2);
			if( not $char eq "\\" )
			{
				$lines[$cline] =~ s/$char%$comment/$char/g;
			}
			#Util::print_message("Entró ! ($matchpos)$cline:$char%$comment");
			pos($lines[$cline]) = $matchpos + 1;
			#exit;
		}
		$cline++;
	}
	return join("\n", @lines);
}
# ok

sub write_file($$)
{
	my ($filename, $txt) = (@_);
	open(OUT, ">$filename") or die Util::halt("write_file: $filename does not open");
	print OUT $txt;
	close(IN);
	#system("chgrp curricula $filename");
}

my @list_of_files_to_gen_fig;
sub write_file_to_gen_fig($$)
{
    # First: write this file
	my ($fullname, $txt) = (@_);
	write_file($fullname, $txt);
	print_message("writing file: $fullname OK!");

	$fullname =~ m/(.*)\/(.*)\.tex/;
	my ($dir, $filename) = ($1, $2);

	# Second: generate the main to gen the fig
	my $main_txt = $Common::config{main_to_gen_fig};
	$main_txt =~ s/<OUTPUT_FILE>/$filename/g;
	$main_txt =~ s/<ENCODING>/$Common::config{tex_encoding}/g;
	$main_txt =~ s/<LANG_FOR_LATEX>/$Common::config{LANG_FOR_LATEX}/g;
	write_file("$dir/$filename-main.tex", $main_txt);
	print_message("writing file: $dir/$filename-main.tex OK!");
	
    # Third: register this main to compile later
	push(@list_of_files_to_gen_fig, $filename);
}

sub generate_batch_to_gen_figs($)
{
	my ($output_file) = (@_);
    #print_message("generate_batch_to_gen_figs($output_file)");
	my $output_txt  = "";
	foreach my $fig_file (@list_of_files_to_gen_fig)
	{
                $output_txt .= "latex main-to-gen-fig-$fig_file\n";
                #$output_txt .= "dvips -Ppdf -Pcmz -o $fig_file.ps main-to-gen-fig-$fig_file\n";
                $output_txt .= "dvips -o $fig_file.ps main-to-gen-fig-$fig_file\n";
                $output_txt .= "ps2eps -f $fig_file.ps\n";
                $output_txt .= "mv $fig_file.eps ../fig/.\n";
                $output_txt .= "\n";
	}
    write_file($output_file, $output_txt);
    system("chmod 774 $output_file");
    print_message("generate_batch_to_gen_figs($output_file) OK!");
}

my ($start_time, $end_time) = ("", "");
sub begin_time()
{	$start_time	= time();	}

sub end_time()
{	$end_time	= time();	}

sub print_time_elapsed()
{
	Util::end_time();
	my $time_elapsed 	= $end_time - $start_time;
	Util::print_message("Time elapsed: $time_elapsed seconds ...");
}

1;
