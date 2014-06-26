#!/usr/bin/perl
#################################################################
#
#  itemswith.pl
#
#    Lists all Diablo II items grouped by magic properties.
#
#  USAGE
#
#    $ perl itemswith.pl > ../wiki/itemswith.html
#
#  CHANGES
#   03 Jan 2004: Added Set Items
#   03 Jan 2004: Added Set (Partial)
#
#   11 Jan 2004: Added 'Class Skills', 'pierce elemental resistance', '+ elemental damage %'
#   11 Jan 2004: Added 'Ladder'
#
#   17 Jan 2004: Added 'ac-miss' (Defense vs Missiles)
#         Added 'ease' (-XX% Requirements)
#
#   18 Jan 2004: Added Complete Set Bonuses
#         Added 'mana', 'regen-mana', 'dmg-to-mana'
#         Finished Sets : Green bonuses, Gold bonuses
#         Finished Runewords : Added effect of runes
#         Fixed 'res-all' + 'res-xxxx' (add values, skip 'res-all' on list)
#         (technically buggy, if we have res-all and res-fire, it wont list res-cold for ex.)
#         (in this case, it only happened with Ancients Pledge, which lists every res in the mods)
#
#   19 Jan 2004: Added 'res-all-max', 'res-xxxx-max'
#   22 Jan 2004: Added Runes in the list, TO DO: avoi duplicates if same effect in weapon/shield/armour..
#
#  To Do :
#  - Swing2 (IAS) for all BUT weapons
#
#################################################################

require './dd-lib.pl';
require './tmpl-lib.pl';
use strict;
use POSIX;

# HTML template for bonus page
my $TEMPLATE_BONUSPAGE = 'templates/_TMPL_itemswith.html';

my %gemsockets;    # We have to check the Socketed items min/max against the item type # of sockets
          # The lowest value is the cap.
my $FH;
my $line;
my $prop;

my $MAX_UNIQUEITEMS_PROPS = 12;
my $MAX_RUNEWORDS_PROPS= 7;
my $MAX_RUNEWORDS_RUNES = 6;
my $MAX_SETITEMS_PROPS = 9;    # Set Item Bonuses (n x [prop,par,min,max])
my $MAX_SETITEMS_PPROPS = 10;  # Partial Set Bonuses (n x [aprop,apar,amin,amax])
my $MAX_SETS_PPROPS = 8;    # Partial Gold Bonuses (n x [PProp,PParam,Pmin,Pmax])
my $MAX_SETS_FPROPS = 8;    # Full Set Bonuses (n x [FCode,FParam,FMin,FMax])
my $MAX_GEMS_PROPS = 3;      # Number of mods per slot type (weap/helm/shield) (n x [code,par,min,max])


my %ITEMGROUP_TO_STR = (
  'p' => 'set',  # Set (Partial)
  'r' => 'run',  # Runeword
  's' => 'set',  # Set
  'u' => 'uni',  # Unique
  'g' => 'gem'   # Runes
);
 
my %skills;      # Skill Id -> Skill string.

#  'properties.txt code' => 'String'
#
#  Output format of bonuses:
#  +  Print '+' before value
#  -  Print '-' before value
#  1  Append value as-is
#  0  No value appended, just the property
#  %  Print '%' after value

my %ITEMPROP_TO_STR = (
  'abs-cold' => 'Absorb Cold|+',
  'abs-fire' => 'Absorb Fire|+',
  'abs-ltng' => 'Absorb Lightning|+',
#  'abs-pois' => 'YUYU1|+',          # no items with this
  'abs-cold%' => 'Absorb Cold %|+%',
  'abs-fire%' => 'Absorb Fire %|+%',
  'abs-ltng%' => 'Absorb Lightning %|+%',
#  'abs-pois%' => 'YUYU2|+',          # no items with this
  'abs-cold/lvl' => 'Absorb Cold/Level|+',
  'abs-fire/lvl' => 'Absorb Fire/Level|+',
#  'abs-ltng/lvl' => 'Ab3|+',          # no items with this
#  'abs-pois/lvl' => 'Ab4|+',          # no items with this
#  'abs-mag' => 'Magic Absorb|+',
#  'ac%' => 'Defense %|+',
  'ac-miss' => 'Defense Vs Missiles|+',
  'ac/lvl' => 'Defense/Level|+',
  'allskills' => 'All Skills|+',
  'att%' => 'Attack Rating %|+%',
#  'att%/lvl' => 'Attack Rating %/Level|+%',  # no items with this
   'att' => 'Attack Rating|+',
   'att/lvl' => 'Attack Rating/Level|+',
#   'att-und/lvl' =>
  'balance2' => 'Faster Hit Recovery|%',
  'block' => 'Increased Chance of Blocking|%',
  'block2' => 'Faster Block Rate|%',
  'cast1' => 'Faster Cast Rate|%',  # Special code groups with 'cast2' & 'cast3'
#  'charged' => 'Charged|1',
  'crush' => 'Crushing Blow|%',
#  'crush/lvl' => 'AAAA|+%',          # no items with this
  'deadly' => 'Deadly Strike|+%',
  'deadly/lvl' => 'Deadly Strike/Level|+%',
#'dmg-ac' => '-XXX To Monster Defense Per Hit|',
  'dmg-demon' => 'Damage To Demons|+%',
#  'dmg-min' => 'Damage Min|+',
#  'dmg-norm' => 'Adds Damage|+',
  'dmg-to-mana' => 'Damage To Mana|%',
  'dmg-undead' => 'Damage To Undead|+%',
#  'dmg-und/lvl' =>
  'dmg/lvl' => 'Maximum Damage/Level|+',
#  'dmg%' => 'Enhanced Maximum Damage|+%',    # too many items
  'dmg%/lvl' => 'Enhanced Maximum Damage/Level|+%',
#  'dmg-cold/lvl' => 'YADA1|+',    # No items with this
#  'dmg-fire/lvl' => 'YADA2|+',    # No items with this
#  'dmg-ltng/lvl' => 'YADA3|+',    # No items with this
#  'dmg-pois/lvl' => 'YADA4|+',    # No items with this
  'ease' => 'Requirements|%',
  'fireskill' => 'Fire Skill|+',
  'freeze' => 'Hit Freezes Target|+',
  'gold%' => 'Extra Gold|%',
  'gold%/lvl' => 'Extra Gold/Level|%',
  'hp' => 'Life|+',
  'hp%' => 'Max Life|%',
  'hp/lvl' => 'Life/Level|+',
  'ignore-ac' => 'Ignore Target Defense|0',
  'indestruct' => 'Indestructible|0',
  'knock' => 'Knockback|0',
  'lifesteal' => 'Life Steal|%',
  'mag%' => 'Magic Find|+%',
  'mag%/lvl' => 'Magic Find/Level|+%',
  'mana' => 'Mana|+',
  'mana%' => 'Maximum Mana|%',
  'mana/lvl' => 'Mana/Level|+',
  'manasteal' => 'Mana Steal|%',
  'move2' => 'Faster Run/Walk|+%',
  'nofreeze' => 'Cannot Be Frozen|0',
  'noheal' => 'Prevent Monster Heal|0',
  'openwounds' => 'Open Wounds|%',
  'reduce-ac' => '-XX% Target Defense|-%',
  'red-dmg' => 'Damage Reduced By|1',
  'red-dmg%' => 'Damage Reduction|%',
  'red-mag' => 'Magic Damage Reduced By|1',
  'regen-mana' => 'Regenerate Mana|+%',
  'rep-quant' => 'Replenish Quantity|1',
  'res-all' => 'All Resistances|+%',
  'res-all-max' => 'Maximum All Resistances|+%',
  'res-fire-max' => 'Maximum Fire Resist|+%',
  'res-cold-max' => 'Maximum Cold Resist|+%',
  'res-ltng-max' => 'Maximum Lightning Resist|+%',
  'res-pois-max' => 'Maximum Poison Resist|+%',
#  'res-fire/lvl' => 'DADA1|+%',    # No items with this
#  'res-cold/lvl' => 'DADA2|+%',    # No items with this
#  'res-pois/lvl' => 'DADA4|+%',    # No items with this
  'res-ltng/lvl' => 'Resist Lightning/Level|+%',
  'res-fire' => 'Resist Fire|+%',
  'res-cold' => 'Resist Cold|+%',
  'res-ltng' => 'Resist Lightning|+%',
#  'res-mag' => 'Magic Resist|+%',
  'res-pois' => 'Resist Poison|+%',
#  'skill' => 'Skills|+',        # UNFINISHED
  'slow' => 'Slows Target|%',
  'sock' => 'Socketed|1',
#  'swing2' => 'Increased Attack Speed|+%',
  'str' => 'Strength|+',
  'str/lvl' => 'Str/Level|+',
  'dex' => 'Dexterity|+',
  'dex/lvl' => 'Dex/Level|+',
  'vit' => 'Vitality|+',
  'vit/lvl' => 'Vit/Level|+',
  'enr' => 'Energy|+',
#  'enr/lvl' => 'Energy/Level|+',    # no items with this property
  'stupidity' => 'Hit Blinds Target|+',

#   Class Skills
  'ama' => 'Skills Amazon|+',
  'ass' => 'Skills Assassin|+',
  'bar' => 'Skills Barbarian|+',
  'dru' => 'Skills Druid|+',
  'nec' => 'Skills Necromancer|+',
  'pal' => 'Skills Paladin|+',
  'sor' => 'Skills Sorceress|+',

#  1.10 'Passive' Elemental Mastery
  'extra-fire' => 'Skill Damage: Fire|+%',
  'extra-ltng' => 'Skill Damage: Lightning|+%',
  'extra-cold' => 'Skill Damage: Cold|+%',
  'extra-pois' => 'Skill Damage: Poison|+%',
  
#  1.10 -XX% To Enemy Elemental Resistance
  'pierce-fire' => 'Pierce Resistance: Fire|-%',
  'pierce-ltng' => 'Pierce Resistance: Lightning|-%',
  'pierce-cold' => 'Pierce Resistance: Cold|-%',
  'pierce-pois' => 'Pierce Resistance: Poison|-%'
);

  DD::GetLocalizedStrings();

#  Lookup # of Sockets in itemtypes/weapons/armors to correct the values
#  in the other files (Unique or Set with a higher number of sockets than permitted by the item type and qlvl)
#  faB : quick dirty patch: we just check the weapons gemsockets (Aldur's Rythm, AliBaba..) the rest seems fine.
  
    $FH = DD::MPQ_Open ('Weapons');
    $line = <$FH>;
    my %col_weapons = DD::GetColumnIndexes($line);
    my $COL_W_CODE = $col_weapons{'code'};
  my $COL_W_GEMSOCKETS = $col_weapons{'gemsockets'};
    while (<$FH>) {
      my @cols = DD::GetColData($_);
      $gemsockets{$cols[$COL_W_CODE]} = $cols[$COL_W_GEMSOCKETS] if $cols[$COL_W_GEMSOCKETS];
    }
    close ($FH);
    
    $FH = DD::MPQ_Open ('Armor');
    $line = <$FH>;
    my %col_armors = DD::GetColumnIndexes($line);
    my $COL_A_CODE = $col_armors{'code'};
  my $COL_A_GEMSOCKETS = $col_armors{'gemsockets'};
    while (<$FH>) {
      my @cols = DD::GetColData($_);
      $gemsockets{$cols[$COL_A_CODE]} = $cols[$COL_A_GEMSOCKETS] if $cols[$COL_A_GEMSOCKETS];
    }
    close ($FH);

#
#  Fill hash with skill names.
#
  my $SKILLS = DD::MPQ_Open ('Skills');
  $line = <$SKILLS>;
  my %col_skills = DD::GetColumnIndexes($line);
  my $COL_SKILLS_NAME = $col_skills{'skill'};
  my $COL_SKILLS_ID = $col_skills{'Id'};
  while (<$SKILLS>) {
    my @cols = DD::GetColData($_);
    $skills{$cols[$COL_SKILLS_ID]} = $cols[$COL_SKILLS_NAME];
  }
  close ($SKILLS);

    my $RUNEWORDS = DD::MPQ_Open('Runes');
    my $UNIQUES = DD::MPQ_Open('UniqueItems');
  my $SETITEMS = DD::MPQ_Open('SetItems');
  my $SETS = DD::MPQ_Open('Sets');
  my $GEMS = DD::MPQ_Open('Gems');

#
#  Get column indexes
#
    $line = <$UNIQUES>;
    my %col_uniques = DD::GetColumnIndexes($line);
    my $COL_INDEX = $col_uniques{'index'};
    my $COL_ENABLED = $col_uniques{'enabled'};
    my $COL_LADDER = $col_uniques{'ladder'};
    my $COL_CODE = $col_uniques{'code'};
    my $COL_PROP1 = $col_uniques{'prop1'};

  $line = <$RUNEWORDS>;
  my %col_runewords = DD::GetColumnIndexes($line);
  my $COL_R_NAME = $col_runewords{'Name'};
  my $COL_R_COMPLETE = $col_runewords{'complete'};
  my $COL_R_RUNE1 = $col_runewords{'Rune1'};
  my $COL_R_PROP1 = $col_runewords{'T1Code1'};
  my $COL_R_TYPE = $col_runewords{'itype1'};

  $line = <$SETITEMS>;
  my %col_setitems = DD::GetColumnIndexes($line);
  my $COL_SI_INDEX = $col_setitems{'index'};
  my $COL_SI_SET = $col_setitems{'set'};
  my $COL_SI_CODE = $col_setitems{'item'};
  my $COL_SI_FUNC = $col_setitems{'add func'};
  my $COL_SI_PROP1 = $col_setitems{'prop1'};
  my $COL_SI_PPROP1 = $col_setitems{'aprop1a'};

  $line = <$SETS>;
  my %col_sets = DD::GetColumnIndexes($line);
  my $COL_S_INDEX = $col_sets{'index'};
  my $COL_S_VERSION = $col_sets{'version'};
  my $COL_S_PCODE = $col_sets{'PCode2a'};    # Partial Set Gold Bonuses
  my $COL_S_FCODE = $col_sets{'FCode1'};    # Complete Set Gold Bonuses

  $line = <$GEMS>;
  my %col_gems = DD::GetColumnIndexes($line);
  my $COL_G_NAME = $col_gems{'name'};        # full name i.e. 'El Rune'
  my $COL_G_LETTER = $col_gems{'letter'};
  my $COL_G_CODE = $col_gems{'code'};        # r01-r33
  my $COL_G_WEAPON = $col_gems{'weaponMod1Code'};
  my $COL_G_HELM = $col_gems{'helmMod1Code'};
  my $COL_G_SHIELD = $col_gems{'shieldMod1Code'};

#
#  Fill in hash with runes as key, and weapon/helm/shield mods as referenced arrays
#  One array = [code,par,min,max] x 9 (3x weapon, 3x helm, 3x shield) = 24 values 
#
  my %runes;
  my %runes_str;
  seek $GEMS, 0, 0;
  $line = <$GEMS>;
  while (<$GEMS>) {
      my @data = DD::GetColData($_);      
    next if (!$data[$COL_G_LETTER]);
    my @mods;
    my $iCol;
    push (@mods, splice (@data, $COL_G_WEAPON, $MAX_GEMS_PROPS*4*3));
    $runes{$data[$COL_G_CODE]} = \@mods;
    #print "$data[$COL_G_CODE] = @mods LEN " . scalar(@mods). "<BR><BR>";
    $runes_str{$data[$COL_G_CODE]} = $data[$COL_G_LETTER];
  }

#
#  Count number of items in each set
#
  my %itemsperset;
  seek $SETITEMS, 0, 0;
  $line = <$SETITEMS>;
  while (<$SETITEMS>) {
      my @data = DD::GetColData($_);      
    next if (!$data[$COL_SI_CODE]);
    if (exists $itemsperset{$data[$COL_SI_SET]}) {
      $itemsperset{$data[$COL_SI_SET]}++;
    } else {
      $itemsperset{$data[$COL_SI_SET]} = 1;
    }
  }

#
#  Fill in hash with ladder items
#
  seek $UNIQUES, 0, 0;
  $line = <$UNIQUES>;  # skip col headers
  my %ladderitems;
  while (<$UNIQUES>) {
      my @data = DD::GetColData($_);      
    next if (!$data[$COL_ENABLED]);
    $ladderitems{$DD::STRINGTABLE{$data[$COL_INDEX]}} = '1' if ($data[$COL_LADDER]);
  }

#
#  Output header with links (jumps) to sections with item bonuses
#

  my $TMPL_BONUS = TMPL::Open ($TEMPLATE_BONUSPAGE);
  TMPL::CopyTo ($TMPL_BONUS, '#header', *STDOUT);

  print "<a name=\"top\"></a>\n";
  foreach (sort { $ITEMPROP_TO_STR{$a} cmp $ITEMPROP_TO_STR{$b} } keys %ITEMPROP_TO_STR)
  {
    my @prop_data = split /\|/, $ITEMPROP_TO_STR{$_};
    print "<a class=\"sma\" href=\"#$_\">$prop_data[0]</a> | ";
  }

  TMPL::CopyTo ($TMPL_BONUS, '#mainlist', *STDOUT);

  foreach (sort { $ITEMPROP_TO_STR{$a} cmp $ITEMPROP_TO_STR{$b} } keys %ITEMPROP_TO_STR)
  {
    items_with_prop ($_);
  }

  TMPL::Flush ($TMPL_BONUS, *STDOUT);

  close ($SETITEMS);
  close ($UNIQUES);
  close ($RUNEWORDS);

sub items_with_prop {

  my $prop = $_[0];
  my @prop_data = split /\|/, $ITEMPROP_TO_STR{$_[0]};
  my $prop_full = $prop_data[0];
  my $prop_fmt = $prop_data[1];

  print "<a name=\"$prop\"></a>\n";
  print "<p>\n";
  DD::bold($prop_full);
  print " [ <a class=\"sma\" href=\"#top\">top</a> ]<br>\n";

#  DD::underline("Items with '$prop_full' :");
#  print "<br>\n";

  my @itemz;

  #
  #  Find RUNES with the property
  #
  foreach (keys %runes) {
    my $rune_str = 
    # weapon / helm / shield x 3 props x [prop, par, min, max]
    my $mods = $runes{$_};
    for (my $i=0; $i < $MAX_GEMS_PROPS*4*3; $i+=4) {
      next if (!@$mods[$i]);
      if (@$mods[$i] eq $prop) {
        my $group = 'g';
        my $name = $runes_str{$_}. ' Rune';
        my $type;
        my $par = @$mods[$i+1];
        my $min = @$mods[$i+2];
        my $max = @$mods[$i+3];
        if (($i>>2) < $MAX_GEMS_PROPS) {
          $type = '(in weapon)';
        } elsif (($i>>2) < $MAX_GEMS_PROPS*2) {
          $type = '(in helm/armour)';
        } else {
          $type = '(in shield)';
        }
        my $fkey = GetSortKey ($par, $min, $max);      
        push (@itemz, "$fkey\t$group\t$name\t$type\t$min\t$max\t$par");
      }
    }
  }

  #
  #  Find RUNEWORDS with the property
  #
  seek $RUNEWORDS, 0, 0;
  $line = <$RUNEWORDS>;  # skip col headers

  while (<$RUNEWORDS>)
    {
      my @data = DD::GetColData($_);
    next if (!$data[$COL_R_COMPLETE]);
    
    my $isprop = 0;    # if set we have found the prop
    my $rpar = 0;
    my $rmin = 0;
    my $rmax = 0;
    my ($res_all, $res_any) = (0, 0);  # gonna have to split that one if separate resist mods are found

    #
    #   Search the property in the runes for the runeword
    #   Property can be present twice in runeword! (i.e. 'KoKoMal')
    #
    #my $runename = '';
    for (my $r=0 ; $r < $MAX_RUNEWORDS_RUNES && $data[$COL_R_RUNE1+$r] ; $r++) {
      my $mods = $runes{$data[$COL_R_RUNE1+$r]};
      my @d;
      if ($data[$COL_R_TYPE] eq 'shld' || $data[$COL_R_TYPE] eq 'pala') {
        @d = @$mods[24 .. 27] if (@$mods[24] eq $prop);    #shield (par,min,max) mod 1
        @d = @$mods[28 .. 31] if (@$mods[28] eq $prop);    #shield (par,min,max) mod 2
        $res_all = @$mods[26] if (@$mods[24] eq 'res-all');
      } elsif ($data[$COL_R_TYPE] eq 'helm' || $data[$COL_R_TYPE] eq 'tors') {
        @d = @$mods[12 .. 15] if (@$mods[12] eq $prop);    #helm (par,min,max) mod 1
        @d = @$mods[16 .. 19] if (@$mods[16] eq $prop);    #helm (par,min,max) mod 2
        $res_all = @$mods[14] if (@$mods[12] eq 'res-all');
      } else {
        @d = @$mods[0 .. 3] if (@$mods[0] eq $prop);    #weapon (par,min,max) mod 1
        @d = @$mods[4 .. 7] if (@$mods[4] eq $prop);    #weapon (par,min,max) mod 2
      }
      if (defined $d[0]) {
        $isprop = 1;
        $rpar += $d[1] if ($d[1]);
        $rmin += $d[2] if ($d[2]);
        $rmax += $d[3] if ($d[3]);
      }
      #$runename .= $runes_str{$data[$COL_R_RUNE1+$r]};
    }

    #  Search the property in the runeword
    for (my $i=0, my $iCol=$COL_R_PROP1 ; $i<$MAX_RUNEWORDS_PROPS ; $i++,$iCol+=4 )
    {
      # Hardcoded grouping of 'cast1', 'cast2', 'cast3'
      $data[$iCol] = 'cast1' if ($data[$iCol] eq 'cast2' || $data[$iCol] eq 'cast3');

      # Check for presence of 'res-all' (need to be added to 'res-xxxx')
      # Check for presence of other resist (skip item in res-all list if res-all was split)
      if ($data[$iCol] eq 'res-all') {
        $res_all += $data[$iCol+2];    # assumes min = max
      } elsif ($data[$iCol] =~ /res\-/) {
        $res_any = 1;
      }
      
      # If we have res-all and other separate resists, we do not list this item with 'res-all' (inconsistent)  
      if ($prop eq 'res-all' && $res_all && $res_any) {
        #print "AAARGH $DD::STRINGTABLE{$data[$COL_R_NAME]} $data[$iCol]<BR>";
        $isprop = 0;
        last;
      }

      if ($data[$iCol] eq $prop) {
        $isprop = 1;
        $rpar += $data[$iCol+1] if ($data[$iCol+1]);
        $rmin += $data[$iCol+2] if ($data[$iCol+2]);
        $rmax += $data[$iCol+3] if ($data[$iCol+3]);
        #last;    # cannot do that now since we need to check the presence of 'res-all'
      }
    }

    #  Add the item to the list if the property was found
    if ($isprop)
    {
      # Add 'All Resistances' to specific Resists
      if ($prop =~ /res\-/ && $res_all && $prop ne 'res-all') {
        $rmin += $res_all;
        $rmax += $res_all;
      }
      
      # Add to itemz array, with min-max range for sorting
      my $group = 'r';
      my $type = $DD::STRINGTABLE{$data[$COL_R_TYPE]};
      my $name = $DD::STRINGTABLE{$data[$COL_R_NAME]};  # . " '$runename'";
      my $fkey = GetSortKey ($rpar, $rmin, $rmax);

      # Lookup item types allowed for that Runeword
      for (my $j=1 ; $data[$COL_R_TYPE+$j] && $j<=6 ; $j++)
      {
        $type .= "/$DD::STRINGTABLE{$data[$COL_R_TYPE+$j]}";
      }

      push (@itemz, "$fkey\t$group\t$name\t$type\t$rmin\t$rmax\t$rpar");
    }
    }


  #
  #  Find UNIQUES with the property
  #
  seek $UNIQUES, 0, 0;
  $line = <$UNIQUES>;  # skip col headers

  while (<$UNIQUES>)
    {
      my @data = DD::GetColData($_);      
    next if (!$data[$COL_ENABLED]);    
    #  Search the property
    for (my $i=0, my $iCol=$COL_PROP1 ; $i<$MAX_UNIQUEITEMS_PROPS ; $i++,$iCol+=4 )
    {
      # Hardcoded grouping of 'cast1', 'cast2', 'cast3'
      $data[$iCol] = 'cast1' if ($data[$iCol] eq 'cast2' || $data[$iCol] eq 'cast3');
      
      if ($data[$iCol] &&
        $data[$iCol] eq $prop)
      {
        # Add to itemz array, with min-max range for sorting
        my $group = 'u';
        my $type = $DD::STRINGTABLE{$data[$COL_CODE]};
        my $name = $DD::STRINGTABLE{$data[$COL_INDEX]};  
        my $par = $data[$iCol+1];
        my $min = $data[$iCol+2];
        my $max = $data[$iCol+3];
        
        CheckMaxSockets ($prop, $par, $min, $max, $data[$COL_CODE]);
        my $fkey = GetSortKey ($par, $min, $max);
        
        # Quick hack for "The Humongous", Requirements are POSITIVE, sort it last.
        $fkey = '-0000' if ($prop eq 'ease' && ($min>0 || $max>0));
        
        push (@itemz, "$fkey\t$group\t$name\t$type\t$min\t$max\t$par");
        last;
      }
    }
  }

  #
  #  Find SETITEMS with the property
  #
  seek $SETITEMS, 0, 0;
  $line = <$SETITEMS>;
  while (<$SETITEMS>)
    {
      my $i;
      my $iCol;
      my @data = DD::GetColData($_);
    next if (!$data[$COL_SI_CODE]);
    
    #
    #  This Set Item's bonuses
    #
    for ($i=0, $iCol=$COL_SI_PROP1 ; $i<$MAX_SETITEMS_PROPS ; $i++,$iCol+=4 )
    {
      # Hardcoded grouping of 'cast1', 'cast2', 'cast3'
      $data[$iCol] = 'cast1' if ($data[$iCol] eq 'cast2' || $data[$iCol] eq 'cast3');

      if ($data[$iCol] &&
        $data[$iCol] eq $prop)
      {
        my $group = 's';
        my $type = $DD::STRINGTABLE{$data[$COL_SI_CODE]};
        my $name = $DD::STRINGTABLE{$data[$COL_SI_INDEX]};
        my $par = $data[$iCol+1];
        my $min = $data[$iCol+2];
        my $max = $data[$iCol+3];
        
        CheckMaxSockets ($prop, $par, $min, $max, $data[$COL_SI_CODE]);
        my $fkey = GetSortKey ($par, $min, $max);
        
        push (@itemz, "$fkey\t$group\t$name\t$type\t$min\t$max\t$par");
        last;
      }
    }

    #
    #  Partial Set (Green) Bonuses
    #
    my $maxpprops = ($itemsperset{$data[$COL_SI_SET]} - 1) * 2;
    for ($i=0, $iCol=$COL_SI_PPROP1 ; $i<$maxpprops ; $i++,$iCol+=4 )
    {
      # Hardcoded grouping of 'cast1', 'cast2', 'cast3'
      $data[$iCol] = 'cast1' if ($data[$iCol] eq 'cast2' || $data[$iCol] eq 'cast3');

      if ($data[$iCol] &&
        $data[$iCol] eq $prop)
      {
        my $greenbonus = '';
        
        #  addfunc = 2 : green bonuses
        if ($data[$COL_SI_FUNC] eq '2') {
          my $numitems = ($i >> 1) + 2;
          if ($numitems == $itemsperset{$data[$COL_SI_SET]}) {
            #  Display 'Complete' instead of 'n items' when n = all items
            $numitems = 'Complete';
          } else {
            $numitems .= ' items';
          }
          $greenbonus = " <span class=\"set\">($numitems)</span>";
        } elsif ($data[$COL_SI_FUNC] eq '1') {
        #  addfunc = 1 : special case Civerb's Ward + specific other item of the set
          $greenbonus = ($i == 0) ? ' <span class="set">(with Civerb\'s Icon)</span>' :
                        ' <span class="set">(with Civerb\'s Cudgel)</span>';
        }
        # else : if addfunc = 0, bonuses are blue.
        
        my $group = 's';
        my $type = $DD::STRINGTABLE{$data[$COL_SI_CODE]} . $greenbonus;
        my $name = $DD::STRINGTABLE{$data[$COL_SI_INDEX]};
        my $par = $data[$iCol+1];
        my $min = $data[$iCol+2];
        my $max = $data[$iCol+3];

        CheckMaxSockets ($prop, $par, $min, $max, $data[$COL_SI_CODE]);
        my $fkey = GetSortKey ($par, $min, $max);
        push (@itemz, "$fkey\t$group\t$name\t$type\t$min\t$max\t$par");
      }
    }
    }

  #
  #  Find Set Gold Bonuses
  #
  seek $SETS, 0, 0;
  $line = <$SETS>;
  while (<$SETS>)
    {
    my $i;
    my $iCol;
      my @data = DD::GetColData($_);
    next if (!defined $data[$COL_S_VERSION]);

    #
    #  Search Partial Set Gold Bonuses
    #
    for ($i=0, $iCol=$COL_S_PCODE ; $i<$MAX_SETS_PPROPS ; $i++,$iCol+=4 )
    {
      # Hardcoded grouping of 'cast1', 'cast2', 'cast3'
      $data[$iCol] = 'cast1' if ($data[$iCol] eq 'cast2' || $data[$iCol] eq 'cast3');

      my $numitems = ($i >> 1) + 2;
      
      if ($data[$iCol] &&
        $data[$iCol] eq $prop)
      {
        # Add to itemz array, with min-max range for sorting
        my $group = 's';
        my $type = "<span class=\"gld\">($numitems items)</span>";
        my $name = $DD::STRINGTABLE{$data[$COL_S_INDEX]};
        my $par = $data[$iCol+1];
        my $min = $data[$iCol+2];
        my $max = $data[$iCol+3];
        my $fkey = GetSortKey ($par, $min, $max);
        push (@itemz, "$fkey\t$group\t$name\t$type\t$min\t$max\t$par");
        last;
      }
    }
    
    #
    #  Search Full Set Gold Bonuses
    #
    for ($i=0, $iCol=$COL_S_FCODE ; $i<$MAX_SETS_FPROPS ; $i++,$iCol+=4 )
    {
      # Hardcoded grouping of 'cast1', 'cast2', 'cast3'
      $data[$iCol] = 'cast1' if ($data[$iCol] eq 'cast2' || $data[$iCol] eq 'cast3');
      
      if ($data[$iCol] &&
        $data[$iCol] eq $prop)
      {
        # Add to itemz array, with min-max range for sorting
        my $group = 's';
        my $type = '<span class="gld">(Complete)</span>';
        my $name = $DD::STRINGTABLE{$data[$COL_S_INDEX]};
        my $par = $data[$iCol+1];
        my $min = $data[$iCol+2];
        my $max = $data[$iCol+3];
        my $fkey = GetSortKey ($par, $min, $max);
        push (@itemz, "$fkey\t$group\t$name\t$type\t$min\t$max\t$par");
        last;
      }
    }
  }

  #
  #  Sort the list of items found, and print it out
  #
  my @sorted = sort itemsort @itemz;

#  DD::table(0,0,1);
  print '<table class="itb">'."\n";

  foreach (@sorted) {
    my @cols = DD::GetColData($_);
    my $group = $cols[1];
    my $name = $cols[2];
    my $type = $cols[3];
    my $prop_min = $cols[4];
    my $prop_max = $cols[5];
    my $prop_par = $cols[6];
    # Item code is only for uniques and set items (not runewords, not partial/complete set bonuses)
    # It is only used where the 'Socketed' property can be found.
    my $minmax = '';

    if ($prop_fmt ne '0')
    {
      $minmax .= '+' if ($prop_fmt =~/\+/);
      $minmax .= '-' if ($prop_fmt =~/\-/);
    
      if ($prop =~ /\/lvl/)
      {
        #   If min and max are empty, it's a /lvl property
        my $div = 0;
        
        #  Special case, 'Leaf' has /lvl but par is in min/max
        $prop_par = $prop_min if (!$prop_par);
        
        if ($prop eq 'att/lvl') {
          $div = 2;
        } else { #if ($prop =~ /\/lvl/) {
          $div = 8;
        }
        if ($div > 0) {
          $prop_par /= $div;
          my $low = POSIX::floor($prop_par);
          my $high = POSIX::floor($prop_par * 99);  # Bonus at character level 99
          $minmax .= "$low-$high";
          $minmax .= '%' if ($prop_fmt =~/%/);
          $minmax .= " ($prop_par Per Character Level) ";
        }
      }
      elsif ($prop eq 'rep-quant')
      {
        # Replenishes Quantity, 1 in (100/par) seconds
        my $delay = POSIX::floor (100 / $prop_par);
        $minmax = "1 in $delay sec.";
      }
      elsif ($prop eq 'charged')
      {
        $minmax = "Level $prop_max Skill #$prop_par, $prop_min charges)";
      }
      elsif ($prop eq 'skill')
      {
        my $skilldesc = exists $skills{$prop_par} ? $skills{$prop_par} : $prop_par;
        $minmax .= $prop_min;
        $minmax .= "-$prop_max" if ($prop_max ne $prop_min);
        $minmax .= " To $skilldesc";
      }
      else
      {
        if (!$prop_min && !$prop_max)
        {
          #  Exception for Griswold's Honor, using par instead of min-max 
          $prop_min = $prop_par;
          $prop_max = $prop_par;
        }
        if ($prop_max ne $prop_min) {
          $minmax .= "$prop_min-$prop_max";  # Range
        }
        else {
          $minmax .= $prop_min;      # Single value
        }    
        $minmax .= '%' if ($prop_fmt =~/%/);
      }
      #$minmax = " ($minmax)" if $minmax;
    }

    my $ladder = exists($ladderitems{$name}) ? ' <b>(Ladder Only)</b>' : '';
    
    my $style = $ITEMGROUP_TO_STR{$group};
#    print("<span class=\"$style\">$name</span> $type <span class=\"bo1\">$minmax</span>$ladder<br>\n");
    print("<tr><th><span class=\"$style\">$name</span> $type$ladder</th><td><span class=\"bo1\">$minmax</span></td></tr>\n");

  }
  DD::end_table();

  print "\n";
}


#
#  Returns a 4 digit key for sorting array
#
sub GetSortKey {
  my ($par, $min, $max) = @_;

  # min-max empty, use par
  $min = $par if ($par && !$min);
  $max = $par if ($par && !$max);

  $min = 0 if (!$min);
  $max = 0 if (!$max);
  #  Sort by max, but also count min, two min-max pairs with the same max, must be sorted
  #  with the min : 20-30 > 10-30.
  my $score = $min + $max * 10;
  my $fkey = sprintf('%05d', $score);
  return $fkey;
}

#  CheckMaxSockets ($prop, $par, $min, $max, $itemcode);
sub CheckMaxSockets {
  if ($_[0] eq 'sock') {
    my ($prop, $par, $min, $max, $itemcode) = @_;
    #  Verify sockets max against item type values
#  print "HAHA ! $itemcode $max -> $gemsockets{$itemcode}<BR>" if (exists ($gemsockets{$itemcode}) && $gemsockets{$itemcode} < $max);
    $min = $par if ($par && !$min);
    $max = $par if ($par && !$max);
    $max = $gemsockets{$itemcode} if (exists $gemsockets{$itemcode} && $gemsockets{$itemcode} < $max);
    $min = $max if ($min > $max);
    $_[2] = $min;
    $_[3] = $max;
  }
}

#  Sort in desdcending order on the key (bonus value)
#  If the keys are identical, group runeword/set/uniques together, and then sort item names alphabetically
sub itemsort {
  my $key_a = substr $a, 0, 5;
  my $key_b = substr $b, 0, 5;
  if ($key_a gt $key_b) {
      return -1;
    } elsif ($key_a lt $key_b) { 
    return 1;
  } else {
    my $name_a = substr $a, 6;    # begin with 'group' (runeword/unique/set)
    my $name_b = substr $b, 6;    # .. so, sort on group, and then iten name
    return 1 if ($name_a gt $name_b);
    return -1 if ($name_a lt $name_b);
  }
  return 0; 
}
