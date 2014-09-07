#!/usr/bin/perl
#############################################################################
#
#  levguide.pl [link_maps=0] [num=0]
#
#    Output map data for website.
#
#    A HTML page can be generated for each map, and is meant to appear in
#    a pop up window when you click the map name in the HTML table.
#
#    link_maps : 1 to create HTML link of each map, and write the
#          corresponding HTML page with map data
#
#    num  : set to xxx to limit output, speeds up testing the program..
#
#  CHANGES
#
#    23 Jan 2004 : monster level affected downwards by area level !
#
#  USAGE
#
#    perl levguide.pl 0 > ../wiki/experience.html
#
#############################################################################

require './dd-lib.pl';
require './tmpl-lib.pl';
use strict;

# HTML template for the main page with map list
my $TEMPLATE_MAPMAIN = 'templates/_TMPL_experience.html';

# where to ouput map data pages
my $MAP_DATA_URL     = 'mapdata/';

# HTML template for the map data pages
my $TEMPLATE_MAPDATA = 'templates/_TMPL_mapdata_temp.html';

my $LINK_MAPS = 0;
my $DO_MAPS = 0;

my $MAX_MONSTER_COLS = 10;
my $MAX_NMONSTER_COLS = 10;

my @ACT_NUMS = ('Act I', 'Act II', 'Act III', 'Act IV', 'Act V');

my $line;
my $lastmap = '';


  #  Set program options
  $LINK_MAPS = $ARGV[0] if $ARGV[0];
  $DO_MAPS = $ARGV[1] if $ARGV[1];

  DD::GetLocalizedStrings();

  my $LEVELS = DD::MPQ_Open('Levels');
    

  #  Get column indexes
  $line = <$LEVELS>;
  my %col_levels = DD::GetColumnIndexes($line);
  my $COL_MAPNAME = $col_levels{'LevelName'};
  my $COL_MAPID = $col_levels{'Id'};
  my $COL_ACT = $col_levels{'Act'};
  my $COL_NUMMON = $col_levels{'NumMon'};
  my $COL_MON1 = $col_levels{'mon1'};
  my $COL_NMON1 = $col_levels{'nmon1'};
  my $COL_MONLVL1EX = $col_levels{'MonLvl1Ex'};
    

  #  Create lookup table for MonLvl, use 'Level' as key
  my %mlvl_data;

  my $MONLVL = DD::MPQ_Open('MonLvl');

  $line = <$MONLVL>;
  my %col_monlvl = DD::GetColumnIndexes($line);
  my $COL_ML_LEVEL = $col_monlvl{'Level'};
  my $COL_ML_XP = $col_monlvl{'XP'};

  while (<$MONLVL>)
  {
    chomp;
    my @cols = DD::GetColData($_);
    my $data = "$cols[$COL_ML_XP]\t$cols[$COL_ML_XP+1]\t$cols[$COL_ML_XP+2]";
    $mlvl_data{$cols[$COL_ML_LEVEL]} = $data;
  }
    
  close ($MONLVL);

  #  Create lookup table for monstats, use monster code as key
  my %mon_data;

    my $MONSTATS = DD::MPQ_Open('MonStats');

    $line = <$MONSTATS>;
    my %col_monstats = DD::GetColumnIndexes($line);
    my $COL_M_ID = $col_monstats{'Id'};
    my $COL_M_NAMESTR = $col_monstats{'NameStr'};
    my $COL_M_LEVEL = $col_monstats{'Level'};
    my $COL_M_EXP = $col_monstats{'Exp'};
    my $COL_M_EXPN = $col_monstats{'Exp(N)'};
    my $COL_M_EXPH = $col_monstats{'Exp(H)'};

  while (<$MONSTATS>)
  {
    chomp;
    my @cols = DD::GetColData($_);
    if ($cols[$COL_M_ID] && $cols[$COL_M_ID] ne 'Expansion') {
      my $data = "$cols[$COL_M_NAMESTR]\t$cols[$COL_M_LEVEL]\t$cols[$COL_M_LEVEL+1]\t$cols[$COL_M_LEVEL+2]\t$cols[$COL_M_EXP]\t$cols[$COL_M_EXPN]\t$cols[$COL_M_EXPH]";
      $mon_data{$cols[$COL_M_ID]} = $data;
    }
  }

  close ($MONSTATS);

  #  Create the subdirectory to store generated map HTML pages
  if ($LINK_MAPS)
  {
    my $path = $MAP_DATA_URL;
    unless (-e $path) {
      $path =~ s/(.+)\/$/$1/g;  # remove trailing slash
      mkdir ($path, 0777) or die "Cannot make directory : $!";
    }
  }


  #  Open template
  my $TMPL_MAPDATA = TMPL::Open ($TEMPLATE_MAPDATA);

  #  Page header
  my $TMPL_MAPMAIN = TMPL::Open ($TEMPLATE_MAPMAIN);

  TMPL::CopyTo ($TMPL_MAPMAIN, '#maptable', *STDOUT);

  my $curAct = 0;

  while (<$LEVELS>)
  {
    my @data = DD::GetColData($_);     
    my @levels = ($data[$COL_MONLVL1EX], $data[$COL_MONLVL1EX+1], $data[$COL_MONLVL1EX+2]);
    
    if (not exists $data[$COL_NUMMON] or ($data[$COL_NUMMON] eq ''))
    {
      #  print "Skipped : $data[0]\n";
      next
    };

    # Skip the duplicate Tombs of Tal Rasha
    next if ($data[$COL_MAPNAME] eq $lastmap);
    $lastmap = $data[$COL_MAPNAME];
  
    # Separation in table between Acts (easier to read)
    if ($data[$COL_ACT] != $curAct) {
      $curAct = $data[$COL_ACT];
      print "\n<tr class=\"head\"><td colspan=4>$ACT_NUMS[$curAct]</td></tr>\n\n";
    }
  
    my $tr = '<TR>';
    my $levelname = $DD::STRINGTABLE{$data[$COL_MAPNAME]};

    if ($LINK_MAPS)
    {
      my $href = DD::FormatHref($data[$COL_MAPNAME]);
    
      $tr .= "<TD><A HREF=\"javascript:showmap('$href')\">$levelname</A></TD>";
      
      # Create map info html page
      my $filename = $MAP_DATA_URL . $href . $DD::EXT_HTML;
      open (MAPPAGE, ">$filename") or die "Cannot open $filename for writing: $!";
      output_map (@data);
      close (MAPPAGE);
    }
    else
    {
      $tr .= "<TD>$levelname</TD>";
    }
  
    # Highlight level 85 areas.
    $levels[2] = "<span class=\"L83\">$levels[2]</span>" if ($levels[2] eq '83');
    $levels[2] = "<span class=\"L84\">$levels[2]</span>" if ($levels[2] eq '84');
    $levels[2] = "<span class=\"L85\">$levels[2]</span>" if ($levels[2] eq '85');
       
    $tr .= '<TD>' . $levels[0] . '</TD><TD>' . $levels[1] . '</TD><TD>' . $levels[2] . '</TD></TR>';
  
    print "$tr\n";
  
    # If counter was set, stop after a few loops to test faster
    last if ($DO_MAPS && (--$DO_MAPS <= 0));
  }

  TMPL::Flush ($TMPL_MAPMAIN, *STDOUT);

  close ($TMPL_MAPDATA);
  close ($LEVELS);

sub output_map
{
  my @data = @_;
#    my @ilvls = ($data[$COL_MONLVL1EX], $data[$COL_MONLVL1EX+1], $data[$COL_MONLVL1EX+2]);

  TMPL::Rewind ($TMPL_MAPDATA);

  # Print monsters in level.

  if (exists $data[$COL_MON1])
  {
    my $i = 0;
    my $j = $COL_MON1;
    
    TMPL::CopyTo ($TMPL_MAPDATA, '#mondata1', *MAPPAGE);

    while (($i < $MAX_MONSTER_COLS) && $data[$j])
    {
      my $m_code = $data[$j];    # Monster code
      my @m_data = split /\t/, $mon_data{$m_code};
      
      #  Calculate experience NORMAL
      my $mlvl = $m_data[1];
      my @mlvls = split /\t/, $mlvl_data{$mlvl};    # lookup 'Level'
      my $m_exp_mul = 0 + $m_data[4];               # 'Exp'
      my $m_exp_val = 0 + $mlvls[0];                # 'XP'
      my $m_exp = int($m_exp_val * $m_exp_mul / 100);
      
      my $monsterstr = $DD::STRINGTABLE{$m_data[0]};
      
    #  print MAPPAGE "<tr><td>$monsterstr</td><td>$mlvl</td><td>$m_exp</td></tr>\n";
      print MAPPAGE "[\"$monsterstr\",$mlvl,$m_exp],\n";
      $i++;
      $j++;
    }

    TMPL::CopyTo ($TMPL_MAPDATA, '#mondata2', *MAPPAGE);

    $i = 0;
    $j = $COL_NMON1;

    while (($i < $MAX_NMONSTER_COLS) && $data[$j])
    {
      # monster id from columns 'nmon1' - 'nmon10'
      my $m_code = $data[$j];
      # monstats.txt : name, level, level(n), level(h), exp, exp(n), exp(h)
      my @m_data = split /\t/, $mon_data{$m_code};
      
      my ($mlvl, $exp_mul, $exp_val);
      
      #  Calculate experience NIGHTMARE
      #      
      # NOTE: not testing noRatio, all monsters (as opposed to player summons & misc) have noRatio empty.
      
      # Use the area level (noRatio appears to be always 0 for regular monsters)
      my $mlvlN = $data[$COL_MONLVL1EX+1];

      # monlvl.txt : XP, XP(N), XP(H)      
      my @nmlvls = split /\t/, $mlvl_data{$mlvlN};  # lookup adjusted monster level
      $exp_mul = 0 + $m_data[5];          # Exp(N)
      $exp_val = 0 + $nmlvls[1];          # XP(N)
      my $nm_exp = int($exp_val * $exp_mul / 100);
      
      #  Calculate experience HELL
      #
      # Use the area level 
      my $mlvlH = $data[$COL_MONLVL1EX+2];

      # monlvl.txt : XP, XP(N), XP(H)      
      my @hlvls = split /\t/, $mlvl_data{$mlvlH};  # lookup adjusted monster level
      $exp_mul = 0 + $m_data[6];          # Exp(H)
      $exp_val = 0 + $hlvls[2];          # XP(H)
      my $h_exp = int($exp_val * $exp_mul / 100);
      
      my $monsterstr = $DD::STRINGTABLE{$m_data[0]};
      
    #  print MAPPAGE "<tr><td>$monsterstr</td><td>$mlvlN</td><td>$nm_exp</td><td>$mlvlH</td><td>$h_exp</td></tr>\n";
      print MAPPAGE "[\"$monsterstr\",$mlvlN,$nm_exp,$mlvlH,$h_exp],\n";
      $i++;
      $j++;
    }
  }

  TMPL::CopyTo ($TMPL_MAPDATA, '#mapname', *MAPPAGE);
  print MAPPAGE "<b>$data[$COL_MAPNAME]</b><br>\n\n";

  TMPL::Flush ($TMPL_MAPDATA, *MAPPAGE);
}
