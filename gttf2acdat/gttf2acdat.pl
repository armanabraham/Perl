#!/usr/bin/perl


##################################################################################
#				     ReadGTTF			                 #
##################################################################################

sub ReadGTTF($inputGTTFFileName)  {
  # Open GTTF file for reading
  open (hInputGTTFFile, $inputGTTFFileName) || die "ERROR: Unable to open file - ". $inputGTTFFileName;
  
  
  @inputGTTF = ();
  foreach $line (<hInputGTTFFile>) {
    #chomp($line);
    push( @inputGTTF, $line);
    }
  close hInputGTTFFile;
#  print @inputGTTF;
  return @inputGTTF;
}
#End of sub ReadGTTF


##################################################################################
#				     PrepareACDAT  	                         #
##################################################################################

sub PrepareACDAT(@GTTFContents, @inputParams) {
  # find first occurency of the word ".hyp" which indicates hyperfile
  @ACDATContents = ();
  # Start of loop
  foreach $line (@GTTFContents) {
    if ( $line =~ /.hyp$/) {
      # Check whether we have to select epoch by given numbers or no
      $selectionCriteria = @inputParams[0];
      if ($selectionCriteria =~ '_ep') {
	$tmpStr = $selectionCriteria;
	$tmpStr =~ s/_ep/_ep\(/;
	$tmpStr =~ s/,/\|/g;
	$tmpStr = $tmpStr . ")_";
	$selectionCriteria = $tmpStr;
      }
      # Scan pattern for the symbol '*'
      # if it exist then make corrections so later
      # perl can deal with them as a correct regular expression
      $selectionCriteria =~ s/\s*\*\s*/.*/g;
      if ( $line =~ $selectionCriteria ) {
	chop($line);
	push(@ACDATContents, $line);
	# Get name of the file
	@splitedFileName = ();
	@splitedFileName = split m!/!, $line;
	@reversed = reverse(@splitedFileName);
	@fileNameNoExt = split /\./, @reversed[0];
	$fileNameNoExt = @fileNameNoExt[0];
	$newName = $fileNameNoExt;
	for ($ixInputPar = 1; $ixInputPar <= $#inputParams; $ixInputPar++) {
	  @replacement = split /,/, @inputParams[$ixInputPar];
	  if ( $#replacement != 1) {
	    print "ERROR: processing parameter   ", @inputParams[$ixInputPar], "\n";
	    print "Please check the syntax and run program again\n";
	    exit;
	  }
	  # Make correction for the regular expression
	  @replacement[0] =~ s/\s*\*\s*/.*/g;
	  $newName =~ s/@replacement[0]/@replacement[1]/g;
	}
	#	  $newName =~ s/balerito/brall/;
	#	  $newName =~ s/$whatToReplace/$replaceWith/;
	push(@ACDATContents, $newName)
      }
    }
  }
  return @ACDATContents;
}
# END OF PrepareACDAT

##################################################################################
#				     WriteACDAT                                  #
##################################################################################

sub WriteACDAT(@ACDATContents, $outputACDATFileName)  {
  # Check to see whether file exists or no
  if ( open(test, "<".$outputACDATFileName)) {
    print "Output file  " . $outputACDATFileName . "  exist. Results will be appended\n";
    close test;
  } else {
    print "Outputing to the file - " . $outputACDATFileName . "\n";
  }
  open( hOutputACDATFile, ">>".$outputACDATFileName ) || die "ERROR writing to the output file - " . $outputACDATFileName;
  foreach $line (@ACDATContents) {
    print hOutputACDATFile $line . "\n";
  }
}
# END OF WriteACDAT


##################################################################################
#				     MAIN			                 #
##################################################################################

if ($#ARGV < 1) {
  print "\nERROR: probably missing parameter(s)";
  print "\nUSAGE: gttf2acdat <*GTTFFile> <*OutputFileName> <SelectionCriteria> <TextToReplace,ReplaceWith> <TextToReplace,ReplaceWith> ... \n";
  print "Items marked with * are mandatory\n";
  print "Program treats * sa a regular expression. Please precede it with \ to avoid ambiguity with shell\n";
  print "To select epoch numbers use keyword _ep followed by the epochs numbers separeted by comma.\n";
  print "EXAMPLE:   gttf2acdat   example.gttf   test.txt   WhatToSelect\*_ep1,2,3,19  textToReplace,ReplaceWith\n";
  exit;
} else {
  $inputGTTFFileName = $ARGV[0];
  $outputACDATFileName = $ARGV[1];
  @inputParams = ();
  for ($ixNextParams = 2; $ixNextParams <= $#ARGV; $ixNextParams++) {
    push(@inputParams, @ARGV[$ixNextParams]);
  }
}

@GTTFContents = &ReadGTTF($inputGTTFFileName);
@ACDATContents = &PrepareACDAT(@GTTFContents, @inputParams);

###########
# This part is obsolete now because user has to enter output file name
# Prepare ACDAT file name
# @outputACDATFileName = split /\./, $inputGTTFFileName;
# $outputACDATFileName = @outputACDATFileName[0];
# $outputACDATFileName = $outputACDATFileName . ".acdat";
###########

if ( $#ACDATContents == -1 ) {
  print "WARNING: Could find no hyperfile(s) for the given parameters\n";
} else {
  &WriteACDAT(@ACDATContents, $outputACDATFileName);
}



