#!/usr/bin/perl
#################################################################
#
#	tbl_merge.pl
#
#	  This script merges the TBL key/value pairs, and take care
#	  of duplicates in this order :
#
#		  string.txt
#		  expansionstring.txt
#		  patchstring.txt
#
#	  First, use tbl_to_txt.sh to convert .tbl to .txt files.
#
#	  It will then ouput a tab delimited (excel) file that can be
#	  loaded into a hash in my other scripts, for localized
#	  translations.
#
#	  USAGE
#
#	  $ perl tbl_merge.pl
#
#################################################################

require './dd-lib.pl';
use strict;

#	Files to lookup, this is used to filter out all the localized strings
#	that we don't need such as NPC dialogues, which take a lot of space.
#	Specify excel file and the column with the string key, all the corresponding
#	key/value pairs will be output in the lookup file.
my %lookup_files = (
	'Armor'        => 'code',
  'Levels'       => 'LevelName',
	'Misc'         => 'code',
  'MonStats'     => 'NameStr',
	'Runes'        => 'Name',
	'SetItems'     => 'index',
	'Sets'         => 'index',
  'SuperUniques' => 'Name',
	'UniqueItems'  => 'index',
	'Weapons'      => 'namestr'
);

my %mergedstr;
my %outputstr;

	my $tblstring1 = $DD::MPQ_STRINGS_PATH . 'string.txt';
	my $tblstring2 = $DD::MPQ_STRINGS_PATH . 'expansionstring.txt';
	my $tblstring3 = $DD::MPQ_STRINGS_PATH . 'patchstring.txt';
	
	open TBL1, "$tblstring1" or die "Cannot open $tblstring1 (Run tbl_to_str.bat): $!";
	open TBL2, "$tblstring2" or die "Cannot open $tblstring2 (Run tbl_to_str.bat): $!";
	open TBL3, "$tblstring3" or die "Cannot open $tblstring3 (Run tbl_to_str.bat): $!";

	#	Store string.txt key/value pairs
	#
	while (<TBL1>) {
		chomp;
		my @data = split /\t/, $_;
		if ($data[0] && $data[1]) {
			$mergedstr{$data[0]} = $data[1];
			#print "$data[0] = $data[1]\n";
		}
	}

	#	Add expansion strings
	#
	while (<TBL2>) {
		chomp;
		my @data = split /\t/, $_;
		if ($data[0] && $data[1]) {
			#if (exists $mergedstr{$data[0]}) {
			#	print "EXPAN UPDATE '$data[0]' = $data[1] (was '$mergedstr{$data[0]}')\n";
			#}
			$mergedstr{$data[0]} = $data[1];
			#print "$data[0] = $data[1]\n";
		}
	}

	#	Add patch strings
	#
	while (<TBL3>) {
		chomp;
		my @data = split /\t/, $_;
		if ($data[0] && $data[1]) {
			#if (exists $mergedstr{$data[0]}) {
			#	print "PATCH UPDATE '$data[0]' = $data[1] (was '$mergedstr{$data[0]}')\n";
			#}
			$mergedstr{$data[0]} = $data[1];
			#print "$data[0] = $data[1]\n";
		}
	}

	close (TBL3);
	close (TBL2);
	close (TBL1);

	#	Lookup various files for which we need translations,
	#	and output just those key/value pairs.
	#	(filter out all unneeded localized strings like NPC dialogues etc)

	foreach my $file (keys (%lookup_files))
	{
		my $excelfile = $DD::MPQ_PATH . $file . '.txt';
		my $strkey = $lookup_files{$file};
		
		open FIN, "$excelfile" or die "Cannot open $excelfile: $!";
	   	my $line = <FIN>;
	   	my %columns = DD::GetColumnIndexes($line);
	   	my $COL_STR = $columns{$strkey};
		while (<FIN>)
		{
	    	my @cols = DD::GetColData($_);
	    	if ($cols[$COL_STR])
	    	{
	    		my $key = $cols[$COL_STR];
	    		my $value = $mergedstr{$key};	# This is the localized string for the key.
	    		if ($value && (not exists $outputstr{$key})) {
	    			#print "$key = $value\n";
	    			$outputstr{$key} = $value;
	    		}
	    	}
		}
    close FIN;
	}

	#	Special code for itemtypes.txt, there appear to be no localized strings for the item types
	#	the column 'ItemType' will be used instead.
	#
	open ITEMTYPES, "$DD::DATA_ITEMTYPES" or die "Cannot open $DD::DATA_ITEMTYPES: $!";
	my $line = <ITEMTYPES>;
	my %col_itemtypes = DD::GetColumnIndexes($line);
	my $COL_IT_NAME = $col_itemtypes{'ItemType'};
	my $COL_IT_CODE = $col_itemtypes{'Code'};
	while (<ITEMTYPES>)
	{
    	my @cols = DD::GetColData($_);
    	my $key = $cols[$COL_IT_CODE];
		if ($key)
		{
			#print "KEY '$key' EXIST WITH VALUE '$outputstr{$key}' NOW '$cols[$COL_IT_NAME]'\n" if (exists $outputstr{$key});
			$outputstr{$key} = $cols[$COL_IT_NAME];
		}
	}
	close (ITEMTYPES);

	#	We write the selected localized key/string pairs on a separate
	#	step, cause we needed to check for duplicate keys.

  open FOUT, ">$DD::STRINGTABLE_FILE";
	foreach (keys (%outputstr))
	{
		print FOUT 	"$_\t$outputstr{$_}\n";
	}
	close (FOUT);
