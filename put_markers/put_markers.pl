#!/usr/bin/perl

###############################################################################################################
#  This program selects ROIs according to the numbers provided in the file.
#  Program scans current direcotry and finds all ACDAT files, then selects
#  from current ACDAT ROIs (according to numbers) and makes two new ACDATs,
#  where one of them contains selected ROIs another one the rest of original
#  ACDAT. Same procedure repeated for every ACDAT in the current direcotry.
#  New ACDATs are genereted in the subdirectory SELECTED of the current
#  direcotry
#  
#  USAGE:
#  put_markers.pl <file_with_markers>
################################################################################################################



##################################################################################
#				     ReadACDAT			                 #
##################################################################################

sub ReadACDAT($input_acdat_name)
{
    # Open ACDAT file for reading
    open (ACDAT_INPUT, $input_acdat_name) || die "Unable to open file $file_to_split"; 
    #Clear array 
    $#one_file = -1;
    foreach $line (<ACDAT_INPUT>)
    {
	chomp($line);
	push( @one_file, $line);
    }
    close ACDAT_INPUT;
    return @one_file;
}
#End of sub ReadACDAT


##################################################################################
#				     ReadMarkers	                         #
##################################################################################

sub ReadMarkers($markers_name)
{
    # Open ACDAT file for reading
    $temp_file_name = "tmp_sort_markers";

    # Create temporary file which only contains unique numbers
    system("cat " . $markers_name . "|sort|uniq >> " . $temp_file_name);
    system("chmod a+rw " . $temp_file_name);
    open (MARKERS_INPUT, $temp_file_name) || die "Unable to open file" . $temp_file_name; 
    #Clear array 
    $#marker_file = -1;
    foreach $line (<MARKERS_INPUT>)
    {
	chomp($line);
	$n_of_zeros_to_add = 4 - length($line);
	for ($ind_tmp = 0; $ind_tmp < $n_of_zeros_to_add; $ind_tmp++)
	{
	    $line = "0" . $line;
	}
	push( @marker_file, $line);
    }
    close MARKERS_INPUT;
    system("rm " . $temp_file_name);
    return @marker_file;
}
# End of sub ReadMarkers


##################################################################################
#				     FindInterestingROIs	                 #
##################################################################################

sub FindInterestingROIs(@acdat, @markers)
{
    $#ROI_numbers = -1;

    $n_of_ROIs = $acdat[0];

    for ($ind_ROI = 0; $ind_ROI < $n_of_ROIs; $ind_ROI++ )
    {
	$tmp = $acdat[ $ind_ROI * 3 + 3 ];
	for ($ind_marker = 0; $ind_marker <= $#markers; $ind_marker++)
	{
	    $marker_str = $markers[$ind_marker];
	    if ($tmp =~ /$marker_str$/)
	    {
		chomp ($acdat[ $ind_ROI * 3 + 3 ]);
		push(@ROI_numbers, $ind_ROI);
#		print $ind_ROI . " - " . $ind_marker . " - " .  $markers[$ind_marker] .  "\n";
	    }

	} 
    }
    return @ROI_numbers;
}

##################################################################################
#				     WriteACDATFooter	                         #
##################################################################################

sub WriteACDATFooter(FILE, $case)
{
    open (OUT_FILE, ">>" . @_[0]);
    
    $footer_position = $acdat[0] * 3 + 1;

    for ($ind_line = $footer_position; $ind_line <= $#acdat; $ind_line++)
    {
	chomp($acdat[$ind_line]);
	print OUT_FILE $acdat[$ind_line];
	if ( ($ind_line - $footer_position > 3) )
	{
	    if ( ! ( ($ind_line - $footer_position) % 2 ) )
	    {
		print OUT_FILE "_" . $_[1] ;
	    }
	    
	}
	print OUT_FILE "\n";
    }
    close OUT_FILE;
}

##################################################################################
#				     WriteACDATForRest	                         #
##################################################################################

sub WriteACDATForRest(@acdat, @ROI_numbers, $input_acdat_name)
{
    chdir $selected_dir_name;
    
    $out_acdat_name = $input_acdat_name;
    $out_acdat_name =~ s/\.acdat$/_rest.acdat/;
    
    open (ACDAT_REST, ">" . $out_acdat_name);
    
    $n_of_ROIs = $acdat[0];

    print ACDAT_REST ($n_of_ROIs - $#ROI_numbers - 1) . "\n";

    $from_rest = 1;
    $ind_tmp = 0;

    for ($ind_ROI = 0; $ind_ROI < $n_of_ROIs; $ind_ROI++ )
    {
	foreach $one_marker (@markers)
	{
	    if ($ind_ROI == $one_marker)
	    {
		$from_rest = 0;
	    }
	}

	if ($from_rest == 1)
	{
	    print ACDAT_REST $acdat[ $ind_ROI * 3 + 1] . "\n";
	    print ACDAT_REST $acdat[ $ind_ROI * 3 + 2] . "\n";
	    printf ACDAT_REST ("%s_rest_%04d\n", $acdat[ $ind_ROI * 3 + 3], $ind_rest_ROI);
	    $ind_rest_ROI++;
	}
	$from_rest = 1;
    }

    seek ACDAT_REST, -1, 1;
    close ACDAT_REST;;

    &WriteACDATFooter($out_acdat_name, "rest");
    
    $command ="/usr/bin/echo \"2\\n".$out_acdat_name."\\n\"|/data1_l4/pub_tools/BIN/browser2k"; 
    print ACV_GEN_SCRIPT "# " . $command ."\n";
    chdir "..";
}

##################################################################################
#				     WriteACDATForSelected                       #
##################################################################################

sub WriteACDATForSelected(@acdat, @ROI_numbers, $input_acdat_name)
{
    chdir $selected_dir_name;

    $out_acdat_name = $input_acdat_name;
    $out_acdat_name =~ s/\.acdat$/_selected.acdat/;
    
    open (ACDAT_SELECTED, ">" . $out_acdat_name);

    $n_of_ROIs = $acdat[0];
    print ACDAT_SELECTED ($#ROI_numbers + 1) . "\n";

#    $ind_tmp = 0;

    foreach $ind_ROI (@ROI_numbers)
    {
	print ACDAT_SELECTED $acdat[ $ind_ROI * 3 + 1] . "\n";
	print ACDAT_SELECTED $acdat[ $ind_ROI * 3 + 2] . "\n";
	printf ACDAT_SELECTED ("%s_selected_%04d\n", $acdat[ $ind_ROI * 3 + 3], $ind_sel_ROI);
	$ind_sel_ROI++;
    }
    close ACDAT_SELECTED;
    &WriteACDATFooter($out_acdat_name, "selected");

    $command ="/usr/bin/echo \"2\\n".$out_acdat_name."\\n\"|/data1_l4/pub_tools/BIN/browser2k";
    print ACV_GEN_SCRIPT $command ."\n";
    chdir "..";
}



##################################################################################
#				     MAIN			                 #
##################################################################################

# Begin main steps

if ($#ARGV != 0) 
{
    print "Please give marker file name\n";
    exit 1;
}

$markers_name = $ARGV[0];

# Check if files exist
open (TEST, $markers_name ) || die "Unable to open file - " . $markers_name; close TEST;

# Create directory 
$selected_dir_name = "selected";
mkdir $selected_dir_name, 0777;
system("chmod a+rwx " . $selected_dir_name);

open (ACV_GEN_SCRIPT, ">" . $selected_dir_name . "/gen_acv.sh");
print ACV_GEN_SCRIPT "#!/bin/sh\n";

@markers = &ReadMarkers($markers_name);

# Global indexes for the labeling selected and non selected ROIs
$ind_sel_ROI = 0;
$ind_rest_ROI = 0;

foreach $input_acdat_name (<*acdat>) 
{
    if ( (!($input_acdat_name =~ /selected.acdat/ )) &&
	 (!($input_acdat_name =~ /rest.acdat/)))
    {
	# Read acdat into memory
	@acdat = &ReadACDAT($input_acdat_name);
	
	# Read markers into memory
	
	# Change names of the ROIs accrding to markers
	@ROI_numbers = &FindInterestingROIs(@acdat, @markers);
	
	if ($#ROI_numbers == -1)
	{
	    print "Skiped file : " . $input_acdat_name . "\n";
	}
	else
	{
	    print "FILE : " . $input_acdat_name . " FOUND : " . ($#ROI_numbers + 1) . " ROIs\n";
	    &WriteACDATForSelected(@acdat, @ROI_numbers);
	    if ($#ROI_numbers != $acdat[0])
	    {
		&WriteACDATForRest(@acdat, @ROI_numbers, $input_acdat_name);
	    }   
	}
    }
}

close ACV_GEN_SCRIPT;
system("chmod a+x " . $selected_dir_name . "/gen_acv.sh");
#system("/bin/sh ./" .$selected_dir_name . "/gen_acv.sh");

