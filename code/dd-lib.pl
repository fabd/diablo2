#############################################################################
#
# Simple Helpers for Diablo II Excel Data Extracting
#
#############################################################################

package DD;
#use strict;
use POSIX;

# Path to the data files extracted from patch_d2.mpq
$MPQ_PATH = 'd2_113_data/';

# Language to use for localized strings.
# If you change this, you must create the corresponding
# TBL/xxx/ directory where xxx is LANG, and you have to
# extract the .tbl files to that directory:
#  TBL/xxx/string.tbl
#  TBL/xxx/expansionstring.tbl
#  TBL/xxx/patchstring.tbl
# You then have to run the script 'tbl_merge.pl' to create
# the stringtable file in that directory:
#  TBL/xxx/merged.txt
# You then re-run other scripts that use DD::GetLocalizedStrings()
# and they will output strings in the specified language.
$LANG = 'ENG';

# Excel file with localized in-game strings. Call GetLocalizedStrings()
# in your scripts to fill in the   %STRINGTABLE hash.
$MPQ_STRINGS_PATH = $MPQ_PATH . 'TBL/' . $DD::LANG . '/';
$STRINGTABLE_FILE = $MPQ_STRINGS_PATH . 'merged.txt';

# Path of Diablo 2 Excel Data files

$DATA_ARMORS      = $MPQ_PATH . 'Armor.txt';
$DATA_ITEMTYPES   = $MPQ_PATH . 'ItemTypes.txt';
$DATA_LEVELS      = $MPQ_PATH . 'Levels.txt';
$DATA_MONLVL      = $MPQ_PATH . 'MonLvl.txt';
$DATA_MONSTATS    = $MPQ_PATH . 'MonStats.txt';
$DATA_RUNES       = $MPQ_PATH . 'Runes.txt';
$DATA_SETITEMS    = $MPQ_PATH . "SetItems.txt";
$DATA_UNIQUEITEMS = $MPQ_PATH . "UniqueItems.txt";
$DATA_WEAPONS     = $MPQ_PATH . 'Weapons.txt';

# Extension of html; documents to use
$EXT_HTML = '.html';

# Weapon Classes (cf. weapons.txt wclass/2handedwclass)
# A unique Base frames value correspond to each weapon class
%WCLASS_TO_STR = (
  '1hs' => 'One Handed Slash',
  '1ht' => 'One Handed Thrust',
#  'ht1' => 'Assasin',
  '2hs' => 'Two Handed Slash',
  '2ht' => 'Two Handed Thrust',
  'stf' => 'Two Handed Else',
  'bow' => 'Bow',
  'xbw' => 'Crossbow'
);

# Weapon Class To Base FPA for the Amazon
%WCLASS_TO_BASE = (
  '1hs' => 13,
  '1ht' => 12,
  '2hs' => 17,
  '2ht' => 15,
  'stf' => 17,
  'bow' => 13,
  'xbw' => 19
);


# Weapon Types (cf. weapons.txt 'type' column)
%WTYPE = (
  'abow' => 'Amazon Bow',
  'ajav' => 'Amazon Javelin',
  'aspe' => 'Amazon Spear',
  'axe'  => 'Axe',
  'bow'  => 'Bow',
  'club' => 'Club',
  'hamm' => 'Hammer',
  'h2h'  => 'Katar',
  'h2h2' => 'Katar2',
  'jave' => 'Javelin',
  'knif' => 'Dagger',
  'mace' => 'Mace',
  'orb'  => 'Orb',
  'pole' => 'Polearm',
  'scep' => 'Sceptre',
  'spea' => 'Spear',
  'staf' => 'Staff',
  'swor' => 'Sword',
  'taxe' => 'Throwing Axe',
  'tkni' => 'Throwing Dagger',
  'tpot' => 'Throwing Potion',
  'wand' => 'Wand',
  'xbow' => 'Crossbow'
);


#---------------------------------------------------------------------------
#  Error ('errormsg')
#  End program with error message
#---------------------------------------------------------------------------
sub Error {
    print "ERROR: $_[0]\n";
    exit;
  }

#---------------------------------------------------------------------------
#  Opens MPQ file, returns file handle.
#---------------------------------------------------------------------------
sub MPQ_Open {
  my $path = $MPQ_PATH . shift() . '.txt';
  local *FH;
  open (FH, $path) or die "Cannot open MPQ file '$path: $!";
  return *FH;
}

#---------------------------------------------------------------------------
#  GetColData ($rowdata)
#  $rowdata : one line read from data file
#  Returns array with data split by column
#---------------------------------------------------------------------------
sub GetColData {
  chomp $_[0];
  my @data = split /\t/, $_[0];
  return @data;
}

#---------------------------------------------------------------------------
#  GetColumnIndexes ($rowdata)
#  $rowdata : first line read from file, contains column headers
#  Returns hash with (column name, column index) pairs.
#   Use it to find column indexes for specific columns.
#---------------------------------------------------------------------------
sub GetColumnIndexes {
  my @cols = GetColData($_[0]);
  my %cols;
  my $idx = 0;
  foreach (@cols)
  {
#    print "$_ = $idx\n";
    $cols{$_} = $idx++;
  }
  return %cols;
}


#---------------------------------------------------------------------------
#  GetLocalizedStrings()
#  Fills in DD::STRINGTABLE hash with key/value pairs for translating
#   MPQ name strings to in-game localized strings.
#
#  Call this routine once at the beginning of a script to fill in the hash.
#
#  NOTE ! -->  Use tbl_merge.pl to generate the localized strings file.
#---------------------------------------------------------------------------
sub GetLocalizedStrings {
  if (scalar(keys %STRINGTABLE) > 0)
  {
    Error('GetLocalizedStrings() called more than once!');
  }
  
  open FILE, "$STRINGTABLE_FILE" or die "Cannot open $STRINGTABLE_FILE (Run tbl_merge.pl first!): $!";
  while (<FILE>)
  {
    chomp;
    my @data = split(/\t/, $_);
    $STRINGTABLE{$data[0]} = $data[1];
  }
  close (FILE);
}

#---------------------------------------------------------------------------
#  ComputeFPA (wsm, wclass, ias)
#---------------------------------------------------------------------------
sub ComputeFPA {
  my $wsm = 0 + $_[0];
  my $base = 0;
  my $ias = 0 + $_[2];
  my $eias = 0;
  my $frames = 0;
 
   # Debug
   if (!exists $WCLASS_TO_BASE{$_[1]}) {
     Error "ComputeFPA() : bad wclass parameter '$_[1]'";
   }
  $base = $WCLASS_TO_BASE{$_[1]};
  $eias = POSIX::floor( $ias/(1+$ias/120) - $wsm );
#print "Input:\n wsm  : $wsm\n base : $base\n ias  : $ias\n";
  $eias = 75 if ($eias > 75);

  if ($eias != -100) {
    $frames = POSIX::ceil( (256*($base+1)) / POSIX::floor(((100 + $eias)/100)*256) ) - 1;
  } else {
    $frames = $base;
  }
  $frames = 1 if ($frames < 1);
#print "Output:\n eias : $eias\n frames: $frames\n\n";
    
  return $frames;
}


sub FormatHref {
#---------------------------------------------------------------------------
#  FormatHref ($string)
#  Reformats string to use as web page name
#  - removes spaces or '''
#  - replaces 'levelx' by '_x' to make URL a little shorter
#---------------------------------------------------------------------------
  my $href = lc($_[0]);
  $href =~ s/[ ']//g;
  $href =~ s/level([0-9]+)/_$1/g;
  return $href;
}


#---------------------------------------------------------------------------
#  HTML Functions to output my website pages
#---------------------------------------------------------------------------
sub mime()
{
  print "Content-type: text/html\n\n";
}

#  DD::head();
#  DD::head("optional stylesheet");
sub head()
{
#  mime();
  print <<'EIOIO';
<html>
<head>
<title>Diablo 2 Data</title>
  <link rel="stylesheet" type="text/css" href="../../css/main.css">
EIOIO

  if ($_[0]) {
    print "<style type=\"text/css\">\n<!--\n$_[0]\n-->\n</style>\n";
  }

  print <<'EIOIO';
</head>
EIOIO
}

sub body {
  print "<body>\n";
}

sub h1 {
  print "<h1>$_[0]</h1>\n\n";
}

sub h2 {
  print "<h2>$_[0]</h2>\n\n";
}

sub bold {
  print "<b>$_[0]</b>";
}
sub underline {
  print "<u>$_[0]</u>";
}

sub p {
  print "<p>$_[0]</p>\n\n";
}

sub footer {
  print <<EIOIO;
</body>
</html>
EIOIO
}

sub blockquote {
  print "<blockquote>\n";
}
sub end_blockquote {
  print "</blockquote>\n";
}

sub table {
  my ($a, $b, $c) = (0, 0, 4);
  #  Really crappy way to do this, fix me!!
  $a = $_[0] if $_[0];
  $b = $_[1] if $_[1];
  $c = $_[2] if $_[2];
  print "<table BORDER=$a CELLSPACING=$b CELLPADDING=$c>\n";
}

sub end_table {
  print "</table>\n\n";
}

sub thead {
  print "<thead><tr class=\"head\">";
  print "<td>$_</td>" foreach (@_);
  print "</tr></thead>\n";
}

sub colgroup {
  # Does not work in Mozilla  even though it is HTML 4.01 ... grrrr
  print "<colgroup>";
  print "<col align=\"$_\">" foreach (@_);
  print "</colgroup>\n";
}

sub tr {
  print "<tr>";
}
sub end_tr {
  print "</tr>\n";
}

sub td {
  foreach (@_)
  {
    #chomp if $_;
    print "<td>$_</td>";
  }
}

1;
