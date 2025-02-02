#!/usr/bin/env perl
#
# TODO: properly parse YAML
#
# -r releasedir
# -s min-testset-size
# -t                        only extract scores for Tatoeba-test sets (all releases)
# -T release                only extract scores for Tatoeba-test-<release>
# -S                        include test set size statistics

use Getopt::Std;

our ($opt_r, $opt_s, $opt_t, $opt_S, $opt_T);
getopts('tr:s:ST:');

my $ReleaseDir  = $opt_r || 'data/test';
my $MinTestSize = $opt_s || 0;

my %scores = ();
my %sizes = ();
my $testset = ();

my $type = undef;
my $model = undef;
my $langpair = undef;
my $key = undef;

while (<>){
    # $type = undef unless (/^\s+\-\s+/);
    $type = undef unless (/^\s+/);
    $type = 'bleu' if (/BLEU-scores/);
    $type = 'chrf' if (/chr-F-scores/);

    if (/^(\S+):/){
	$key = $1;
    }

#    if (/^release: (.*)\-[0-9]{4}\-[0-9]{2}\-[0-9]{2}/){
#	$model = $1;
#    }
    if (/^release: (.*)$/){
	$model = $1;
	($langpair) = split(/\//,$model);
    }
    if ($key eq 'test-data'){
	if (/^\s+\-?\s*(\S+)\.(\S+)[\.\-](\S+):\s+(.*)$/){
	    my ($testset,$src,$trg,$size) = ($1,$2,$3,$4);
	    my ($sents, $words) = split(/\//,$size);
	    $sizes{"$model\t$src-$trg"}{$testset}{sents} = $sents;
	    $sizes{"$model\t$src-$trg"}{$testset}{words} = $words;
	}
    }
    if ($type){
	if (/^\s+\-?\s*(\S+)\.(\S+)[\.\-](\S+):\s+(.*)$/){
	    my ($testset,$src,$trg,$score) = ($1,$2,$3,$4);
	    if ($opt_t){
		# next unless ($testset eq 'Tatoeba-test');
		next unless ($testset=~/^Tatoeba-test/);
	    }
	    if ($opt_T){
		# next unless ($testset eq 'Tatoeba-test');
		next unless ($testset=~/^Tatoeba-test-$opt_T/);
	    }
	    if ($opt_t || $opt_T){
		next unless (($src eq 'multi') or 
			     ($trg eq 'multi') or 
			     ("$src-$trg" eq $langpair));
	    }
	    ## TODO: NORMALISATION IS OBSOLETE NOW?
	    $testset=~s/\.$src\-$trg$//;
	    $testset=~s/\-$src$trg$//;
	    # $testset=~s/(Tatoeba\-test).$src\-$trg/$1/;
	    $scores{"$model\t$src-$trg"}{$testset}{$type} = $score;
	}
    }
}

foreach my $l (sort keys %scores){
    foreach my $t (sort keys %{$scores{$l}}){

	## ugly hard-coded way of excluding pure cmn scores
	## without script extension
	next if ($l=~/\tcmn\-/);
	next if ($l=~/\-cmn$/);

	next if ($sizes{$l}{$t}{sents} < $MinTestSize);
	if ($opt_S){
	    print $l,"\t",$t,"\t",$scores{$l}{$t}{chrf},"\t",$scores{$l}{$t}{bleu},
	          "\t",$sizes{$l}{$t}{sents},"\t",$sizes{$l}{$t}{words},"\n";
	}
	else{
	    print $l,"\t",$t,"\t",$scores{$l}{$t}{chrf},"\t",$scores{$l}{$t}{bleu},"\n";
	}
    }
}
