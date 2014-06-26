#!/usr/bin/perl
#################################################################
#
#  ias-breakpoints.pl
#
#    This program outputs a HTML page with an IAS Breakpoints table
#    for each weapon class, wielded by an Amazon, no skills/aura.
#
#    It's possible to output the tables for other character classes,
#    by editing 'WCLASS_TO_BASE' in dd-lib.pl, however this will only
#    be valid for a simple weapon attack with no skills/aura involved.
#
#  USAGE
#
#    $ perl ias-breakpoints.pl > ../wiki/ias-breakpoints.html
#
#################################################################

require 'dd-lib.pl';
use strict;

my $FPA_COLS = 16;        # number of breakpoints columns
my $MINIMUM_FPA = 7;      # rightmost fpa column in table
my $MAXIMUM_IAS = 500;    # maximum IAS to search breakpoints

#  Use weapons.pl to output weapon tables, then look at what
#  'Base Speed' are present and include in here. This is to make
#  the IAS/Breakpoints table directly applicable to the weapon table
#  of the same weapon class (1hs, 2ht, ...) and avoid to include
#  WSM's which have no items, and so will not be looked up in the
#  IAS/Breakpoints table.
my %WCLASS_TO_WSM = (
  '1hs' => '-30,-20,-10,0,10,20',
  '1ht' => '-20,-10,0,10,20',
  '2hs' => '-15,-10,-5,0,5,10,20',
  '2ht' => '-20,-10,0,10,20',
  'stf' => '-15,-10,-5,0,5,10,20',
  'bow' => '-10,0,5,10',
  'xbw' => '-60,-40,-10,0,10'
);

  DD::head("td.base {color: #40cf40;}");
  DD::body();

  my @bpts;

  #
  #  Make one IAS Breakpoints table for each weapon class
  #
  foreach my $wclass (keys %DD::WCLASS_TO_BASE)
  {
    my @wsm_rows = split /,/, $WCLASS_TO_WSM{$wclass};
    
    # Title
    print "<p>$DD::WCLASS_TO_STR{$wclass} weapons<br>\n";
    
    # Table
    DD::table(0, 1);

    # Colgroups
    my @aligns;
    push (@aligns, 'center');
    for (my $i=0 ; $i<$FPA_COLS ; $i++) {
      push (@aligns, 'right');
    }
    DD::colgroup(@aligns);

    # HTML for table header
    print "<tr class=\"head\"><td align=center width=50 rowspan=2>Base<br>Speed</td><td colspan=$FPA_COLS align=center>Frames per attack</td></tr>\n";
    print "<tr class=\"head\">";
    my @cells;
    for (my $col = 1; $col<=$FPA_COLS; $col++) {
      print "<td width=30 align=\"right\">" . ($MINIMUM_FPA + $FPA_COLS - $col) . "</td>";
    }
    DD::end_tr();
    
    foreach my $wsm (@wsm_rows)
    {
      my $i;
      
      DD::tr();
      DD::td($wsm);

      # Clear breakpoints
      for ($i = $FPA_COLS ; $i ; $i--) {
        $bpts[$MINIMUM_FPA+$i-1] = '-';
      }

      # Calculate breakpoints, start at base fpa for weapon type
      # Start with 0% IAS, increase by 5% increments, store each
      # breakpoint until max IAS or lowest FPA attained.
      my $ias = 0;
      my $prevfpa = 999;
      do {
        my $fpa = DD::ComputeFPA($wsm, $wclass, $ias);
        if ($fpa != $prevfpa) {
        #  print "FPA : $fpa ($wsm, $wclass, $ias)\n";
          $bpts[$fpa] = $ias;
          $prevfpa = $fpa;
        }
        $ias += 5;
      } while ($prevfpa > $MINIMUM_FPA && $ias < $MAXIMUM_IAS);

      for ($i = $MINIMUM_FPA + $FPA_COLS - 1 ; $i >= $MINIMUM_FPA ; $i--)
      {
        if ($bpts[$i] eq '0') {
          print "<td class=\"base\">0</td>";
        } else {
          DD::td($bpts[$i]);
        }
      }
      
      DD::end_tr();
    }
    DD::end_table();
  }

  DD::footer();
