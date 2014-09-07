#!/usr/bin/perl
#############################################################################
#
#  super_uniques.pl
#
#    Outputs a list of all Super Unique monsters in order of progression
#    through the game.
#
#  REQUIRES
#
#    ./templates/_DATA_superuniques.txt   (tab delimited file)
#
#  USAGE
#
#    perl super_uniques.pl > ../wiki/super-uniques.md
#
#############################################################################

require './dd-lib.pl';
require './tmpl-lib.pl';
use strict;
use CGI;
use Data::Dumper;

my $TMPL_HTML = 'templates/_TMPL_superuniques.html';
my $TMPL_DATA = 'templates/_DATA_superuniques';

my $line;

  DD::GetLocalizedStrings();

  #  Super Uniques table template
  my $SUD_TABLE        = DD::TXT_Open($TMPL_DATA);
  $line = <$SUD_TABLE>;
  my %col_sudata       = DD::GetColumnIndexes($line);
  my $COL_SUD_NAME     = $col_sudata{'Name'};
  my $COL_SUD_MONTYPE  = $col_sudata{'Monster Type'};   # use this if provided, otherwise from MonStats
  my $COL_SUD_BOSS     = $col_sudata{'$Boss'};
  my $COL_SUD_LOCATION = $col_sudata{'$LevelName'};
  my $NUM_SUD_COLS     = 7;

  #  Get column indexes
  my $SUPERUNIQUES = DD::MPQ_Open('SuperUniques');
  $line = <$SUPERUNIQUES>;
  my %col_superuni   = DD::GetColumnIndexes($line);
  my $COL_SU_NAMESTR = $col_superuni{'Name'};
  my $COL_SU_CLASS   = $col_superuni{'Class'};

  #  Get column indexes
  my $LEVELS         = DD::MPQ_Open('Levels');
  $line = <$LEVELS>;
  my %col_levels       = DD::GetColumnIndexes($line);
  my $COL_LV_LEVELNAME = $col_levels{'LevelName'};
  my $COL_LV_MONLVL1EX = $col_levels{'MonLvl1Ex'};

  #  Create lookup table for monstats, use monster code as key
  my $MONSTATS = DD::MPQ_Open('MonStats');
  $line = <$MONSTATS>;
  my %col_monstats = DD::GetColumnIndexes($line);
  my $COL_M_ID      = $col_monstats{'Id'};
  my $COL_M_NAMESTR = $col_monstats{'NameStr'};
  my $COL_M_LEVEL   = $col_monstats{'Level'};
  my $COL_M_MONTYPE = $col_monstats{'MonType'};

  my %mondata;
  while (<$MONSTATS>)
  {
    my @cols = DD::GetColData($_);
    if ($cols[$COL_M_NAMESTR])
    {
      my $data = "$cols[$COL_M_NAMESTR]\t$cols[$COL_M_LEVEL]\t$cols[$COL_M_LEVEL+1]\t$cols[$COL_M_LEVEL+2]\t$cols[$COL_M_MONTYPE]";

      $mondata{$cols[$COL_M_ID]} = $data;
    }
  }
  close ($MONSTATS);



  #
  #  Create the Super Uniques table
  #
  my $TMPL_SUPER = TMPL::Open ($TMPL_HTML);

  TMPL::CopyTo ($TMPL_SUPER, '#superlist', *STDOUT);

  while (<$SUD_TABLE>)
  {
    # Table section to separate Acts
    if ($_ =~ /^##(.+)\t/)
    {
      print "<tr class=\"head\"><td colspan=\"$NUM_SUD_COLS\">$1</td></tr>\n";
      next;
    }
      
    my @sud_data = DD::GetColData($_);     
    my $sud_name = $sud_data[$COL_SUD_NAME];
    my $map_name = $sud_data[$COL_SUD_LOCATION];
    DD::verbose("SU Name: $sud_name");

    # SuperUnique data
    my @su_data   = DD::MPQ_Seek ($SUPERUNIQUES, 'Name', $sud_name);

    # Levels data for the area where Super Unique spawns
    my @lvl_data  = DD::MPQ_Seek ($LEVELS, 'LevelName', $sud_data[$COL_SUD_LOCATION]) or DD::Error ("Level '$map_name' not found");

    my $mon_id    = @su_data ? $su_data[$COL_SU_CLASS] : $sud_name;
    my @mon_stats = DD::GetColData($mondata{$mon_id});
    my $mon_name  = @su_data ? $DD::STRINGTABLE{$sud_name} : $DD::STRINGTABLE{$mon_stats[0]};
    my $mon_type  = WhicheverIsSet ($sud_data[$COL_SUD_MONTYPE], $DD::STRINGTABLE{$mon_stats[0]});
DD::verbose($sud_data[$COL_SUD_MONTYPE]);
    my $act_boss  = $sud_data[$COL_SUD_BOSS] ? ' class="bold"' : '';

    #my $mon_name = $DD::STRINGTABLE{$data[$COL_SU_NAMESTR]};  
    my @levels   = splice @lvl_data, $COL_LV_MONLVL1EX, 3, (1..3);

    # Adjust the super uniques levels to area level in Nightmare and Hell
    if (!$sud_data[$COL_SUD_BOSS]) {
      $levels[1] = '<span title="Area level '.$levels[1].' + 3">'.($levels[1] + 3).'</span>';
      $levels[2] = '<span title="Area level '.$levels[2].' + 3">'.($levels[2] + 3).'</span>';
    }

    $map_name = $DD::STRINGTABLE{$map_name};
    
    print "<tr$act_boss><td>$mon_name</td><td>$mon_type</td><td>$levels[0]</td><td>$levels[1]</td><td>$levels[2]</td><td>$map_name</td></tr>\n";
  }
  
  TMPL::Flush ($TMPL_SUPER, *STDOUT);

  close ($MONSTATS);
  close ($SUPERUNIQUES);


sub WhicheverIsSet {
  my ($columnOne, $columnTwo) = @_;
  return $columnOne ne '' ? $columnOne : $columnTwo;
}

