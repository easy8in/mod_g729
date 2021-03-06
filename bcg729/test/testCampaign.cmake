#!/usr/bin/perl -w
use Term::ANSIColor;
# testCampaign
#
# Copyright (C) 2011 Belledonne Communications, Grenoble, France
# Author : Johan Pascal
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# This script allow testing of g729 encoder/decoder functional blocs
# by default each bloc output is supposed to be identical to the pattern
# it can be configured to monitor and accept a (setable) difference between output
# and pattern(which can occur if a bloc or macros are modified).
# Tune the defaultMaxDiff associative array definition to modify
# the behavior of this script for any functional bloc under test

my $binDirectory = "./";
my $patternDirectory = "./patterns";
# softDiff: compare two CSV files with a margin of acceptance between the values found
# arguments : file1, file2, maximumDiff tolerated(value), maximum percentage abs((val1-val2)/val1)*100 tolerated
# maximum condition ignored when set to 0 so it might be used:
# - with one maximum condition
# - with both maximum condition : trigger a warning if both maxima are exceded

sub softDiff
{
	my $filename1 = shift;
	my $filename2 = shift;
	my $maxDiff = shift;
	my $percentMaxDiff = shift;
	my $printStats = shift;
	
	# open the file1 and file2
	open (FP1, $filename1) or die "Can't open $filename1: $!";
	open (FP2, $filename2) or die "Can't open $filename2: $!";

	# remove path from filename2 as it might be used in error report
	$filename2 =~ s/.*\/(.*?)\..*$/$1/;

	# total values number count variables for stats
	my $nbr_values = 0;
	my $total_diff = 0;
	my $total_values = 0;
	my $maxMaxDiff = 0;
	my $maxPercentDiff = 0;

	# boolean for return value: 0 no warning, 1 warning(s)
	my $warnings  = 0;

	# loop over file1
	while(<FP1>) {
		# get line number to display in potential message 
		my $lineNb = $.;
		# get file1 and file2 CSV line into an array
		my @line1 = ();
		my @line2 = ();
		@line1 = split (',', $_);
		@line2 = split (',', <FP2>);

		# check they have the same number of values
		my $line1length = @line1;
		my $line2length = @line2;
		if ($line1length != $line2length) {
			die "at line $., $filename1 and $filename2 doesn't have the same number of values";
		}

		# loop on the values and compare them
		for (my $i=0; $i<$line1length; $i++) {
			chomp($line1[$i]);
			chomp($line2[$i]);
			my $diff = abs($line1[$i]-$line2[$i]);
			
			my $percentDiff;
			if (abs($line1[$i])+abs($line2[$i]) == 0) {
				$percentDiff = 0;
			} else {
				$percentDiff = $diff/(abs($line1[$i])+abs($line2[$i]))*200;
			}

			# Stats if needed 
			if ($printStats) {
				$nbr_values++; # increment values counts
				$total_diff += $diff;
				$total_values += (abs($line1[$i])+abs($line2[$i]))/2;
				if ($diff>$maxMaxDiff) {$maxMaxDiff=$diff;$maxPercentDiff=$percentDiff;}
			}
			
			if ($maxDiff> 0 && $percentMaxDiff> 0) {
				if (($diff>$maxDiff) && ($percentDiff>$percentMaxDiff)) {
					$warnings =1;
					print "WARNING : $filename2: line $lineNb value $i ($line1[$i] and $line2[$i]) differ by $diff(".$percentDiff."%)\n";
				}
			} else { # on a une ou zero condition */
				if ($maxDiff> 0) { # if we shall check the absolute value difference 
					if ($diff>$maxDiff) {
						$warnings =1;
						print "WARNING : $filename2: line $lineNb value $i ($line1[$i] and $line2[$i]) differ by $diff\n";
					}
				}
				if ($percentMaxDiff> 0) { # if we shall check the percentage of difference 
					if ($percentDiff>$percentMaxDiff) {
						$warnings =1;
						print "WARNING : $filename2: line $lineNb. value $i ($line1[$i] and $line2[$i]) differ by ".$percentDiff."%\n";
					}
				}
			}
		}
	}
	close (FP1);
	close (FP2);
	if ($printStats) {printf ("Stats: Max Diff: %d(%f) mean diff: %0.3f mean percent diff : %0.2f\n",$maxMaxDiff, $maxPercentDiff, $total_diff/$nbr_values, $total_diff*100/$total_values);}

	return $warnings;
}

if ((@ARGV < 1) || (@ARGV > 2))
{
	print "##############################################################################\n";
	print "#                                                                            #\n";
	print "#  testCampaign [-s] <test name>                                             #\n";
	print "#     test name in the following list :                                      #\n";
	print "#       - decoder                                                            #\n";
	print "#       - CNGdecoder                                                         #\n";
	print "#       - decodeLSP                                                          #\n";
	print "#       - interpolateqLSPAndConvert2LP                                       #\n";
	print "#       - decodeAdaptativeCodeVector                                         #\n";
	print "#       - decodeFixedCodeVector                                              #\n";
	print "#       - decodeGains                                                        #\n";
	print "#       - LPSynthesisFilter                                                  #\n";
	print "#       - postFilter                                                         #\n";
	print "#       - postProcessing                                                     #\n";
	print "#                                                                            #\n";
	print "#       - encoder                                                            #\n";
	print "#       - preProcessing                                                      #\n";
	print "#       - computeLP                                                          #\n";
	print "#       - LP2LSPConversion                                                   #\n";
	print "#       - LSPQuantization                                                    #\n";
	print "#       - computeWeightedSpeech                                              #\n";
	print "#       - findOpenLoopPitchDelay                                             #\n";
	print "#       - adaptativeCodebookSearch                                           #\n";
	print "#       - computeAdaptativeCodebookGain                                      #\n";
	print "#       - fixedCodebookSearch                                                #\n";
	print "#       - gainQuantization                                                   #\n";
	print "#                                                                            #\n";
	print "#       - all : perform all tests                                            #\n";
	print "#     Options switch:                                                        #\n";
	print "#       -s : Display stats on each test (when running softDiff)              #\n";
	print "#                                                                            #\n";
	print "##############################################################################\n";
	exit;
}

# check command validity
# TODO

my $printStats = 0;

# Get the test name
my $command=$ARGV[@ARGV-1];

# is there a switch?
if ($ARGV[0] eq "-s") {
	$printStats= 1;
}


# define the default values to use for maxDiff and percentualMaxDiff for each test
# "<testedBlocName> => [<absolut maximum difference>,<percentual maximum difference>]"
# if both set to 0, the diff command will be used
%defaultMaxDiff = (	"preProcessing" => [0,0],
			"computeLP" => [0,0],
			"LP2LSPConversion" => [0,0],
			"LSPQuantization" => [0,0],
			"computeWeightedSpeech" => [0,0],
			"findOpenLoopPitchDelay" => [0,0],
			"adaptativeCodebookSearch" => [0,0],
			"computeAdaptativeCodebookGain" => [0,0],
			"fixedCodebookSearch" => [0,0],
			"gainQuantization" => [0,0], 
			"encoder" => [0,0], 

			"decodeLSP" => [0,0],
			"interpolateqLSPAndConvert2LP" => [0,0],
			"decodeAdaptativeCodeVector" => [0,0],
			"decodeFixedCodeVector" => [0,0],
			"decodeGains" => [0,0],
			"LPSynthesisFilter" => [0,0],
			"postFilter" => [0,0],
			"postProcessing" => [0,0],
			"decoder" => [0,0],
			"CNGdecoder" => [0,0]
		);


# check command: 
if ($command eq "all") { # if run all tests, just get the defaultMaxDiff array as testsList as the test directory are retrieved from keys
	%testsList = %defaultMaxDiff;
} else {
	%testsList = ($command, 0); # we run one test: create an associative array with one element having a key matching the test name
}

#return value for autotools make check
my $exitVal = 0;

foreach my $testDirectory (keys %testsList) {
	# get the files
	opendir(DIR, $patternDirectory."/".$testDirectory) or die "can't open directory $patternDirectory/$testDirectory: $!";
	my @files = grep { /\.in$/ } readdir(DIR);
	closedir(DIR);
	my $testExec = $binDirectory.$testDirectory."Test";

	print "Test $testDirectory bloc\n";
	# for each *.in file found in the test directory
	foreach my $file (@files) {
		# run the testExecutable
		my $filebase = $file;
		$filebase =~ s/^(.*?)\..*/$1/;
		print "  $filebase";
		print `$testExec $patternDirectory/$testDirectory/$file`;

		# compare the output file with the pattern file
		my $filepattern = $file;
		$filepattern =~ s/\.in$/\.pattern/;
		my $fileout = $file;
		$fileout =~ s/\.in$/\.out/;

		my $maxDiffTolerated = $defaultMaxDiff{$testDirectory}[0];
		my $maxPercentualDiffTolerated = $defaultMaxDiff{$testDirectory}[1];
		if ($maxDiffTolerated==0 && $maxPercentualDiffTolerated==0) { # no difference accepted, use the classic diff function
			$differs = `diff $patternDirectory/$testDirectory/$filepattern $patternDirectory/$testDirectory/$fileout`;
			if ($differs ne "") {
				print " ... ";
				print colored("Fail\n", "red");
				$exitVal = 1;
			} else {
				printf "  ... Pass\n"
			}
		} else { # accept difference => use the softDiff function
			if (softDiff($patternDirectory."/".$testDirectory."/".$filepattern, $patternDirectory."/".$testDirectory."/".$fileout, $maxDiffTolerated, $maxPercentualDiffTolerated, $printStats) == 0) {
				printf "  ... Pass\n"
			} else {
				printf "  $filebase  ... ";
				print colored("Fail\n", "red");
				$exitVal = 1;
			}
		}
	}
}
exit($exitVal);
