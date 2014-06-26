# Writes a new string.tbl file
#
# Parameter: The string.tbl file to read, and the data file with stuff to change
#
# Data File format: either a or c as first character on each line
#   If a, then have two words in double quotes on that line, the key and the value
#   If c, then have 4 words in double quotes, the key/value pair to change and what to change it to.
#   If either of the pair to match are a null string (""), then just match the other one.
#	If either of the other pair are null, that item is not replaced.

# A intro to the string.tbl format.
#
# There are four main sections to the string.tbl file.
# First, the header.  This is 21 bytes long.
# Second, an array with two bytes per entry, that gives an index into the next table.
#  This allows lookups of strings by number.
# Third, a hash array, with 17 bytes per entry, which has the pointers to the key and value strings, and has the strings sorted basically by hash value.
#	This allows lookups of strings by key.
# Fourth, the actual strings themselves.

###### Modified by Mephansteras June 2001 ################
#
# Ondo made the original script, so most of the credit goes to him. I've just modified it 
# a bit. :)
#
# This modified version is designed to take the string.tbl and create a txt file that can viewed
# and changed in excel. This txt file will then be read in, and a new string.tbl file will be created.
#
# NOTE: New Usage: perl EnquettarM.pl -[e|i] [string.tbl to export from or txt file to import from]
# -e extract to txt file or -i import from txt file, anything else will print a help message
#  ex: perl EnquettarM.pl -e mystring.tbl

use strict;

$/ = v0;
my $input;
my $outputtext = "ModString.txt";
my $outputtable = "ModString.tbl";

#My changes to this program

my $eamode = shift;

if ($eamode eq "-e")  ### Export data to txt file
{
    # First, we read in the original string.tbl file.
    
    open (FOUT, ">$outputtext");
    my $inkey;
    my $inval;
    open (INPUT, shift @ARGV); # Open the file specified.
    binmode INPUT;             # set it to binary mode, otherwise it does nasty newline conversion on DOS-damaged machines.
    read (INPUT, $input, 2);   # read the first two bytes into the variable $input.  This is usCRC, an unsigned short which contains the CRC (Cyclical Redundacy Check) which we don't care about.
    read (INPUT, $input, 2);   # read the next two bytes.  This is usNumElements, the total number of elements (key/value string pairs) in the file.
    my $numElements = unpack ("S", $input);    # We then store this value in the variable $numElements, because we will need it later.
    read (INPUT, $input, 4);   # read the next four bytes.  This is iHashTableSize, the number of entries in the HashTable.  This has to be at least equal to usNumElements, and if higher it can speed up the hash table look up.  Blizzard has this number be 2 higher than usNumElements in the english version.  I just leave the hash table size the same as usNumElements, which is not optimal, but easier.
    read (INPUT, $input, 1);   # read the next byte.  I don't know what this is used for, I always set it to 1, which is what it is in the english version.
    read (INPUT, $input, 4);   # read the next four bytes.  This is dwIndexStart, the offset of the first byte of the actual strings.  This offset is from the start of the file, as are the other offsets mentioned herein.  We don't really need it when reading.
    read (INPUT, $input, 4);   # Read the next 4 bytes.  When the number of times you have missed a match with a hash key equals this value, you give up because it is not there.  We don't care what this value was in the original.
    read (INPUT, $input, 4);   # Read the next 4 bytes.  This is dwIndexEnd, the offset just after the last byte of the actual strings.
    print "\nReading strings...";
    my @elements;              # Creates an array named @elements.
    foreach my $i (0 .. $numElements - 1)   # Sets $i to be each number in turn from 0 to 1 less than the number of elements.  Much like the C statement for (i = 0; i < numElements; i++).  Unless my C is worse than I think it is. :)
    {
    	read (INPUT, $input, 2);  # Reads in 2 bytes for each element.  This is the offset into the hash array for the element with this number.
    	$elements[$i] = unpack ("S", $input);   # store that number in the @elements array at index $i
    }
    
    my @keys;                  # Creates an array named @keys.
    my @values;                # Creates an array named @values.
    my $nodeStart = tell (INPUT);  # Sets $nodeStart to the current offset we are at in the file.  This is equal to (21 + ($numElements * 2)).  This is the offset at the start of the hash table.
    print "done!\nWriting to $outputtext...";
    foreach my $i (0 .. $numElements - 1)   # Same thing as last time, $i goes from 0 to 1 less than the number of elements.
    {
    	seek (INPUT, $nodeStart + ($elements[$i] * 17), 0);  # Set the offset that we are reading from in the file to be (Start of Hash Table + (17 * the ith element in array elements)), meaning the start of the hash table entry that was indicated by entry #i in the previous table.
    	read (INPUT, $input, 1);  # read 1 byte.  This is bUsed, which is set to 1 if this entry is used.  This may be set to 0 if this entry is just in there to add to the size of the hash table to get better performance.  We just ignore it, assuming it is 1.  We could assert that it is one if we wanted, though.
    	read (INPUT, $input, 2);  # read 2 bytes.  This is the index number.  Basically, this should always be equal to the value of $i as we read it.  That is, the index in the previous array whose value is this index in this array.
    	read (INPUT, $input, 4);  # read 4 bytes.  This is the hash number.  This is the number you get from sending this entry's key string through the hashing algorithim.  We don't care about it right now.
    	read (INPUT, $input, 4);  # read 4 bytes.  This is dwKeyOffset, the offset of the key string.  The key is the same in every language.
    	my $keyOffset = unpack ("L", $input);   # Store it in local variable $keyOffset
    	read (INPUT, $input, 4);  # read 4 bytes.  This is dwStringOffset, the offset to the value string.  The value is translated into the appropriate language.
    	my $stringOffset = unpack ("L", $input); # Store it in local variable $stringOffset
    	read (INPUT, $input, 2);  # read 2 bytes.  This is the length of the value string.
    	seek (INPUT, $keyOffset, 0);   # Go to the key's offset now.
    	my $key = <INPUT>;        # read into local variable $key everything up to and including the next null byte.
    	chomp $key;               # get rid of the trailing null byte on $key
    	seek (INPUT, $stringOffset, 0);  # Go to the value string's offset
    	my $string = <INPUT>;     # read into local variable $string everything up to and including the next null byte.
    	chomp $string;            # get rid of the trailing null byte on $string
    	$keys[$i] = $key;         # Set entry number $i in array @keys to equal $key
    	$values[$i] = $string;    # Set entry number $i in array @values to equal $string
          $inkey = $keys[$i];          # Make temp variable for output
          $inkey =~ tr/\r//d;          # Strip Carriage Return
          $inkey =~ tr/\n/\}/;         # Replace Newlines with }
          $inkey =~ tr/\t/\\t/;        # Replace any Tabs with \t
          $inval = $values[$i];        # Make temp variable for output
          $inval =~ tr/\r//d;          # Strip Carriage Return
          $inval =~ tr/\n/\}/;         # Replace Newlines with }
          $inval =~ tr/\t/\\t/;        # Replace any Tabs with \t
          print FOUT "${inkey}\t${inval}\n";  # Add line to the txt file, sperated by tabs
   }
    print "Done!\n";
    # We have now finished reading in the string.tbl file.
}
elsif ($eamode eq "-i")  #### Import data from txt file
{
    my @keys;                  # Creates an array named @keys.
    my @values;                # Creates an array named @values.
    my $numElements++;
    # Now we read in the txt file.
    print "Reading in text file...";
	open (DATA, shift @ARGV);  # Open the file named in the second argument
	$/ = "\n";
	READDATA: while (<DATA>)   # Read in a line at a time from the data file, until there are no more lines, running this loop on each line
	{
		my $command = substr ($_, 0, 1);   # Set local variable $command to the first character on the line.
		my ($key, $value) = split("\t");   # Set $key to the first item on the line, and set $value to the second thing on the line.
		$value =~ s/}/\n/g;    # Replace every instance of the character } in the value with an actual new line.
          $value =~ s/^\"//;     # Strip out leading "
          $value =~ s/\"$//;     # Strip out trailing "
          $value =~ s/\n$//;     # Strip out trailing newline. Chomp wasn't working properly, for some reason
          $key =~ s/}/\n/g;      # Replace every instance of the character } in the key with an actual new line.
		$key =~ s/^\"//;       # Strip out leading "
          $key =~ s/\"$//;       # Strip out trailing "
          $key =~ s/\n$//;       # Strip out trailing newline. Chomp wasn't working properly, for some reason
          push (@keys, $key);    # Add $key to the end of the @keys array.
		push (@values, $value);# Add $value to the end of the @values array.
		$numElements++;        # add one to the number of elements.
    }
    
    # Finished reading in the data file.
    #
    # Now output the new string.tbl file
    		
    my $stringOffset = (21 + ($numElements * 2) + ($numElements * 17));  # This is where the offset of the first string will be.  This is the size of the header, plus the size each of the two table.  Not that the hash table size should be substituted for the number of elements the second time if they are different.
    my $allStrings = '';	# The $allStrings variable will have each string appended to it as we go.  It will be used to write the fourth section.
    my @hashIndices;		# Creates the array @hashIndices.  It will be used to write the second section.
    my @nodes;				# Creates the array @nodes.  It will be used to write the third section.
    my $highestNumberOfMisses = 0;	# This is the greatest number of times a hash lookup fails.  This variable will be used for writing a header field.
    print "Done!\nWriting to $outputtable..."; 
    foreach my $i (0 .. $numElements - 1)  # Once again, $i is set to each number from 0 to 1 less than the number of elements
    {
    	my $hashValue = Hash ($keys[$i], $numElements);  # Sets the local variable $hashValue to be equal to the output of the Hash function when passed the element $i's key and the number of elements.  See the Hash function comments for more info.  Note that it should be passed the hash table size instead, if this is different from the number of entries.
    	my $numberOfMisses = 0;   # initialize local variable $numberOfMisses to 0.
    	my $hashOffset = $hashValue;   # initialize $hashOffset to $hashValue.
    	while (defined ($nodes[$hashOffset]))  # We would like to store this entry at $hashValue, so that we can find it by running the hash function on the key again and then looking at that entry.  However, this entry may already be taken, so we check if it is.  If so, we increment $numberOfMisses and $hashOffset (setting $hashOffset back to 0 if it goes above the hash table's size), and try the next entry until we find one that hasn't been taken yet.
    	{
    		$numberOfMisses++;
    		$hashOffset++;
    		$hashOffset %= $numElements;
    	}
    	$highestNumberOfMisses = $numberOfMisses if ($numberOfMisses > $highestNumberOfMisses);  # Set $highestNumberOfMisses if we set a new record.
    	$hashIndices[$i] = pack ("S", $hashOffset);  # Set the hashIndex to point to the $hashOffset that we finally got.
    	my $nodeString = v1 . pack ("S", $i) . pack ("L", $hashValue) . pack ("L", $stringOffset + length ($allStrings));  # Set our node string to be: the byte 1 (bUsed, because this entry is used); this entry's index; the hash value we got; $stringOffset, the offset to the beginning of the strings, plus the current length of the variable $allStrings (dwKeyOffset).
    	$allStrings .= $keys[$i] . v0;               # Appends the key string and an ending null byte to the $allStrings variable.
    	my $valueLength = length ($values[$i]);      # Sets $valueLength to the length of the value string.
    	$nodeString .= pack ("L", $stringOffset + length ($allStrings)) . pack ("S", $valueLength);  # Appends to $nodeString: the offset to the beginning of the strings plus the current length of the varable $allStrings (dwStringOffset); the length of the value string.
    	$allStrings .= $values[$i] . v0;             # Appends the value string and an ending null byte to the $allStrings variable.
    	$nodes[$hashOffset] = $nodeString;           # Sets entry $hashOffset in array @nodes to $nodeString.
    }
    
    open NEWOUT, ">$outputtable";
    binmode NEWOUT;
    print "Done!\n";
    print NEWOUT (pack ("SSL", CRC ($allStrings), $numElements, $numElements), v1, pack ("LLL", $stringOffset, $highestNumberOfMisses + 1, $stringOffset + length ($allStrings)));  # Output the Header: First, the result of the CRC function called on $allStrings, then the number of elements, the number of elements again (unless hash size is greater), then the byte 1, then the offset to the start of the strings, then the highest number of misses plus 1, then the string offset plus the length of $allStrings.
    print NEWOUT (@hashIndices);  # Output the second section
    print NEWOUT (@nodes);  # Output the third section
    print NEWOUT ($allStrings);  # Output the fourth section, the strings

}
else
{
    print "Usage: perl EnquettarM.pl -[e|i] [string.tbl to export\n";
    print "from or txt file to import from]\n";
    print "-e extract to txt file or -i import from txt file\n";
    print "anything else will print this message\n";
    print "ex: perl EnquettarM.pl -e mystring.tbl\n\n";
    print 'Special notes: newlines are converted to the }';
    print "\nsymbol in the txt file, so if you want to\n";
    print "use returns and blank lines, put that in instead.\n";
    print "Also, don't try to put in tabs or leading\n";
    print 'or trailing quote (") symbols. They mess everything up.' . "\n";
    print "Currently, the txt file created is named ModString.txt\n";
    print "and the table ModString.tbl.\n";
    print "If you want to change that, just edit the beginning\n";
    print "of the script. There are two variables\n";
    print '$outputtext and $outputtable. Change their respective values to whatever you want.' . "\n";;
}
exit;
# That is the end of the script.

sub Hash ($$)  # Hash takes two arguments, the key to hash, and the number of different results that can be returned.
{
	my $string = $_[0];   # Sets the variable $string to the first arg
	my $hashSize = $_[1]; # Sets the variable $hashSize to the second arg
	my $value = 0;        # Sets the value to initially be 0.
	foreach my $character (split (//, $string))  # Sets $character to be each byte in $string, starting with the first and ending with the last.
	{
		my $charValue = unpack ("c", $character);  # this sets $charValue to be equal to character, interpreted as a signed byte
		$value <<= 4;    # Shift $value left by 4.
		$value += $charValue;  # Add $charValue to $value
		if ($value & 0xF0000000)
		{
			my $temp = $value & 0xF0000000;
			$temp >>= 24;         # shift $temp right by 24
			$value &= 0x0FFFFFFF;
			$value ^= $temp;      # $value = $value XOR $temp
		}
	}
	$value %= $hashSize;          # $value = $value modulo $hashSize
	return $value;                # return $value
}

sub CRC ($)  # The CRC function, this is called on a string that contains all the keys and values in the file, seperated by null bytes.  Not that this must be all the stuff between dwIndexStart (inclusive) and dwIndexEnd (exclusive).
{
	my @multiplyTable = (0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50A5, 0x60C6, 0x70E7, 0x8108, 0x9129, 0xA14A, 0xB16B, 0xC18C, 0xD1AD, 0xE1CE, 0xF1EF, 0x1231, 0x0210, 0x3273, 0x2252, 0x52B5, 0x4294, 0x72F7, 0x62D6, 0x9339, 0x8318, 0xB37B, 0xA35A, 0xD3BD, 0xC39C, 0xF3FF, 0xE3DE, 0x2462, 0x3443, 0x0420, 0x1401, 0x64E6, 0x74C7, 0x44A4, 0x5485, 0xA56A, 0xB54B, 0x8528, 0x9509, 0xE5EE, 0xF5CF, 0xC5AC, 0xD58D, 0x3653, 0x2672, 0x1611, 0x0630, 0x76D7, 0x66F6, 0x5695, 0x46B4, 0xB75B, 0xA77A, 0x9719, 0x8738, 0xF7DF, 0xE7FE, 0xD79D, 0xC7BC, 0x48C4, 0x58E5, 0x6886, 0x78A7, 0x0840, 0x1861, 0x2802, 0x3823, 0xC9CC, 0xD9ED, 0xE98E, 0xF9AF, 0x8948, 0x9969, 0xA90A, 0xB92B, 0x5AF5, 0x4AD4, 0x7AB7, 0x6A96, 0x1A71, 0x0A50, 0x3A33, 0x2A12, 0xDBFD, 0xCBDC, 0xFBBF, 0xEB9E, 0x9B79, 0x8B58, 0xBB3B, 0xAB1A, 0x6CA6, 0x7C87, 0x4CE4, 0x5CC5, 0x2C22, 0x3C03, 0x0C60, 0x1C41, 0xEDAE, 0xFD8F, 0xCDEC, 0xDDCD, 0xAD2A, 0xBD0B, 0x8D68, 0x9D49, 0x7E97, 0x6EB6, 0x5ED5, 0x4EF4, 0x3E13, 0x2E32, 0x1E51, 0x0E70, 0xFF9F, 0xEFBE, 0xDFDD, 0xCFFC, 0xBF1B, 0xAF3A, 0x9F59, 0x8F78, 0x9188, 0x81A9, 0xB1CA, 0xA1EB, 0xD10C, 0xC12D, 0xF14E, 0xE16F, 0x1080, 0x00A1, 0x30C2, 0x20E3, 0x5004, 0x4025, 0x7046, 0x6067, 0x83B9, 0x9398, 0xA3FB, 0xB3DA, 0xC33D, 0xD31C, 0xE37F, 0xF35E, 0x02B1, 0x1290, 0x22F3, 0x32D2, 0x4235, 0x5214, 0x6277, 0x7256, 0xB5EA, 0xA5CB, 0x95A8, 0x8589, 0xF56E, 0xE54F, 0xD52C, 0xC50D, 0x34E2, 0x24C3, 0x14A0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405, 0xA7DB, 0xB7FA, 0x8799, 0x97B8, 0xE75F, 0xF77E, 0xC71D, 0xD73C, 0x26D3, 0x36F2, 0x0691, 0x16B0, 0x6657, 0x7676, 0x4615, 0x5634, 0xD94C, 0xC96D, 0xF90E, 0xE92F, 0x99C8, 0x89E9, 0xB98A, 0xA9AB, 0x5844, 0x4865, 0x7806, 0x6827, 0x18C0, 0x08E1, 0x3882, 0x28A3, 0xCB7D, 0xDB5C, 0xEB3F, 0xFB1E, 0x8BF9, 0x9BD8, 0xABBB, 0xBB9A, 0x4A75, 0x5A54, 0x6A37, 0x7A16, 0x0AF1, 0x1AD0, 0x2AB3, 0x3A92, 0xFD2E, 0xED0F, 0xDD6C, 0xCD4D, 0xBDAA, 0xAD8B, 0x9DE8, 0x8DC9, 0x7C26, 0x6C07, 0x5C64, 0x4C45, 0x3CA2, 0x2C83, 0x1CE0, 0x0CC1, 0xEF1F, 0xFF3E, 0xCF5D, 0xDF7C, 0xAF9B, 0xBFBA, 0x8FD9, 0x9FF8, 0x6E17, 0x7E36, 0x4E55, 0x5E74, 0x2E93, 0x3EB2, 0x0ED1, 0x1EF0);   # This defines an array used in the CRC.
	my $string = $_[0];  # Sets $string to the first argument.
	my $value = 0xFFFF;  # Initializes $value to 0xFFFF;
	foreach my $character (split (//, $string))   # Sets it to go through each byte in $string in order.
	{
		my $charValue = unpack ("C", $character); # $charValue equals the bytes value, interpreted as as unsigned byte.
		$charValue ^= ($value & 0xFFFF) >> 8;     # ^= is like +=, but doing XOR instead of addition.
		my $temp = ($value & 0xFF) << 8;
		$value = $multiplyTable[$charValue];      # $value equals entry $charValue in array @multiplyTable, defined at the start of this function
		$value ^= $temp;
	}
	return $value;                                # hope that that is clear.
}
