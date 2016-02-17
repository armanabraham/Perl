#!/usr/bin/perl


#Globals 

$kept_ROIs_file_name  = "all_kept";
$other_ROIs_file_name = "all_others";



##################################################################################
#				     FilterInterestingROIs	                 #
##################################################################################

sub FilterInterestingROIs
{
    $n_of_ROIs = @_[0];   # number of ROIs taken from acdat header
    @acdat_copy = @_;

    # Perform initial assignings
    $#filtered_acdat = -1;
    $n_of_ROIs = $acdat_copy[0];      # number of ROIs taken from acdat header
    $ind_ROI = 0;                     # Index for going through ROI 
    
    for ($ind_ROI=0; $ind_ROI < $n_of_ROIs; $ind_ROI++)
    {
	$tmp = $acdat_copy[ $ind_ROI * 3 + 3];
	if  ($tmp =~ s/\s*qaz/kept/)
	{
		push ( @filtered_acdat, $acdat_copy[ $ind_ROI * 3 + 1] );
		push ( @filtered_acdat, $acdat_copy[ $ind_ROI * 3 + 2] );
		push ( @filtered_acdat, $tmp );
	}
    }
    return @filtered_acdat;
}
# End of sub FilterInterestingROIs

##################################################################################
#				     FilterInterestingROIs	                 #
##################################################################################

sub FilterNonInterestingROIs
{
    @acdat_copy = @_;

    # Perform initial assignings
    $#filtered_acdat = -1;
    $n_of_ROIs = $acdat_copy[0];     # number of ROIs taken from acdat header
    $ind_ROI = 0;                    # Index for going through ROI 
    
    for ($ind_ROI=0; $ind_ROI < $n_of_ROIs; $ind_ROI++)
    {
	$tmp = $acdat_copy[ $ind_ROI * 3 + 3];
	if ( !($tmp =~ /qaz/) )
	{
	    push ( @filtered_acdat, $acdat_copy[ $ind_ROI * 3 + 1] );
	    push ( @filtered_acdat, $acdat_copy[ $ind_ROI * 3 + 2] );
	    push ( @filtered_acdat, $tmp );
	}
    }
    return @filtered_acdat;    
}
# End of sub FilterNonInterestingROIs

##################################################################################
#				     ReadACDAT			                 #
##################################################################################

sub ReadACDAT($file_to_chop)
{
    # Open ACDAT file for reading
    open (ACDAT_INPUT, @_[0]) || die "Unable to open file ".  $acdat_f_name; 
    #Clear array 
    $#one_file = -1;
    foreach $line (<ACDAT_INPUT>)
    {
	push( @one_file, $line);
    }
    close ACDAT_INPUT;
    return @one_file;
}
# End of sub ReadACDAT
    
##################################################################################
#				     WriteACDATFooter	                         #
##################################################################################

sub WriteACDATFooter(@one_acdat)
{
    # Perform initial assignings
    @acdat_copy = @_;
    $n_of_ROIs = $acdat_copy[0];     # number of ROIs taken from acdat header

    for ($ind_tmp = 0; $ind_tmp < 4; $ind_tmp++)
    {
	print  FINAL_KEPT_ACDAT $acdat_copy[$n_of_ROIs * 3 + 1 + $ind_tmp];
	print  FINAL_NON_KEPT_ACDAT $acdat_copy[$n_of_ROIs * 3 + 1 + $ind_tmp];
    }
    print  FINAL_KEPT_ACDAT $kept_ROIs_file_name;
    print  FINAL_NON_KEPT_ACDAT $other_ROIs_file_name;

    print FINAL_KEPT_ACDAT "\n";
    print  FINAL_NON_KEPT_ACDAT "\n"
}
# End of sub WriteACDATFooter


##################################################################################
#				     WriteACDATHeader	                         #
##################################################################################

sub WriteACDATHeader
{
    seek FINAL_KEPT_ACDAT, 0, 0;
    seek FINAL_NON_KEPT_ACDAT, 0, 0;
    print FINAL_KEPT_ACDAT  @_[0];
    print FINAL_NON_KEPT_ACDAT  @_[1];
}
# End of sub WriteACDATHeader

##################################################################################
#				     WriteTagFile                                #
##################################################################################

sub WriteTagFile($n_of_kept_ROIs, $n_of_other_ROIs)
{
    open (TAG_FILE_OUT, ">kept_and_others.tag");
    $work_dir = `/bin/pwd`; chomp($work_dir);
    print TAG_FILE_OUT "[acv\n\n";
    print TAG_FILE_OUT "desctemplate:\n\n";
    print TAG_FILE_OUT "ROI_TYPE = ";
    if ($n_of_kept_ROIs) 
    {
	print TAG_FILE_OUT "kept";
    }
    if ($n_of_other_ROIs)
    {
	if ($n_of_kept_ROIs)
	{
	    print TAG_FILE_OUT ", others\n\n";
	}
	else
	{
	    print TAG_FILE_OUT "others\n\n";
	}
    }
    else
    {
	print TAG_FILE_OUT "\n\n";
	}
    print TAG_FILE_OUT "path:\n\n";
    print TAG_FILE_OUT "file:\n\n";
    if ($n_of_kept_ROIs) 
    {
	print TAG_FILE_OUT $work_dir . "\/". $kept_ROIs_file_name . ".acv\n";
    }
 
    if ($n_of_other_ROIs)
    {
	print TAG_FILE_OUT $work_dir . "\/". $other_ROIs_file_name  . ".acv\n";
    }
    print TAG_FILE_OUT "acv]\n";
    close TAG_FILE_OUT;

}


##################################################################################
#				      Main			                 #
##################################################################################


#$n_of_kept_ROIs = 0;
#$n_of_other_ROIs = 0;

$n_of_ROIs_per_file = 30;

$file_to_chop = "blobs_in_regions_sorted";
$acdat_f_name = $file_to_chop . ".acdat";
@one_acdat = &ReadACDAT($acdat_f_name);
$n_of_ROIs = $one_acdat[0];

for ($ind_line = 1; $ind_line <= 3 * $n_of_ROIs; $ind_line++)
{

#    print $ind_line;
#    print "\n";
#    print  ( ( $ind_line / 3.0) % $n_of_ROIs_per_file ) ;
#    print " - " . ($ind_line / 3.0) . " - " . $ind_line;
    print 510.666666666667 % 30.0;
    print "\n";

#    if ( ( ( ($ind_line) / 3) % $n_of_ROIs_per_file )  == 0 )  
#    {
#	close (CURRENT_OUT_FILE);
#	$curr_f_name = $file_to_chop . "_" . ( ($ind_line) / 3);
#	open (CURRENT_OUT_FILE, ">".$curr_f_name) || die "Unable to open file ".$curr_f_name;
#    }
}


close CURRENT_OUT_FILE;
exit 1;



print @one_acdat;

exit 1;


foreach $file_to_split (<*qaz*acdat*>)
{
    # Open ACDAT file for reading
    @one_acdat = &ReadACDAT($file_to_split);
    @kept_ROIs = &FilterInterestingROIs(@one_acdat);
    @other_ROIs = &FilterNonInterestingROIs(@one_acdat);

    $n_of_kept_ROIs  +=  (($#kept_ROIs+1)/3) if ($#kept_ROIs > 0);
    $n_of_other_ROIs +=  (($#other_ROIs+1)/3) if ($#other_ROIs > 0);

    print FINAL_KEPT_ACDAT @kept_ROIs;
    print FINAL_NON_KEPT_ACDAT @other_ROIs;
}

&WriteACDATFooter(@one_acdat);
&WriteACDATHeader($n_of_kept_ROIs, $n_of_other_ROIs);

&WriteTagFile($n_of_kept_ROIs, $n_of_other_ROIs);

# Generate activation curves 

open (ACV_GEN_SCRIPT, ">gen_acv.sh");
print ACV_GEN_SCRIPT "#!/bin/sh\n";

$command ="/usr/bin/echo \"2\\n".$kept_ROIs_file_name.".acdat\\n\"|/data1_l4/pub_tools/BIN/browser2k"; 
print ACV_GEN_SCRIPT $command ."\n";
$command ="/usr/bin/echo \"2\\n".$other_ROIs_file_name.".acdat\\n\"|/data1_l4/pub_tools/BIN/browser2k";
print ACV_GEN_SCRIPT $command ."\n";
close ACV_GEN_SCRIPT;

system("chmod a+x gen_acv.sh");
#system("/bin/sh ./gen_acv.sh");


