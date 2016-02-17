#!/usr/bin/perl

#####################################################################################
#  SYNOPSYS:
#  filter_gttf.pl <input_gttf_file> <key_for_filter> <output_gttf_file>
#####################################################################################



##################################################################################
#				     ReadGTTF			                 #
##################################################################################

sub ReadGTTF($input_gttf_name)
  {
    # Open GTTF file for reading
    open (F_INPUT_GTTF, $input_gttf_name) || die "Unable to open file - ". $input_gttf_name; 


    $#input_gttf = -1;
    foreach $line (<F_INPUT_GTTF>) {
      #chomp($line);
      push( @input_gttf, $line);
    }
    close F_INPUT_GTTF;
    return @input_gttf;
  }
#End of sub ReadGTTF



##################################################################################
#				     WriteFilteredGTTF                           #
##################################################################################

sub WriteFilteredGTTF(@filtered_gttf, $output_gttf_name)
  {
    open( F_OUTPUT_GTTF, ">".$output_gttf_name );
    print F_OUTPUT_GTTF @filtered_gttf;
  }


##################################################################################
#				     GetSelectedHyperf                           #
##################################################################################

sub GetSelectedHyperf( @input_gttf, $keyword, $current_line, $n_of_hyperf )  {
  $#selection = -1;

  # Check keyword to see whether it has epoch selection criteria or not
  if ($keyword =~ '_ep') {
    $tmpKeyword = $keyword;
    $tmpKeyword =~ s/_ep/_ep\(/;
    $tmpKeyword =~ s/,/\|/g;
    $tmpKeyword = $tmpKeyword . ")_";
    $keyword = $tmpKeyword;
  }

  for ( $ind_line = ( $current_line + 1 ); $ind_line < ( $current_line + 2 * $n_of_hyperf ); $ind_line += 2 ) {
	
    if ( $exclude ) { 
      if ( ( $input_gttf[$ind_line] =~ /$keyword/ ) ) {
	if ( ! ( ( $input_gttf[$ind_line] =~ /$exclude/ ) ) ) {
	  push( @selection, $input_gttf[$ind_line - 1] );
	  push( @selection, $input_gttf[$ind_line] );
	}
      }
    } else {
      if ( ( $input_gttf[$ind_line] =~ /$keyword/ ) ) {
	push( @selection, $input_gttf[$ind_line - 1] );
	push( @selection, $input_gttf[$ind_line] );
      }
    }
  }

  return @selection;
}


##################################################################################
#				    SelectGTTFKeywords                           #
##################################################################################

sub SelectGTTFKeywords( @input_gttf, $current_line )
  {
    

    push( @key_to_select,  "use_medium_conducting_sphere" );
    push( @key_to_select, 1 );
    push( @key_to_select, "use_mri_info" );
    push( @key_to_select, 1 );

    #$n_of_key = $#key_to_select / 2;
    
    for ($ind_key = 0; $ind_key < $#key_to_select; $ind_key+=2 ) {
      for ( $ind_line = $current_line; $ind_line < ( $current_line + $#input_gttf ); $ind_line++  ) {
	if ( $input_gttf[$ind_line] =~ /$key_to_select[$ind_key]/ ) {
	  # Number of lines to read with keyword
	  $n_of_key_lines = $key_to_select[$ind_key + 1]; 
		
	  # Copy all staff concerned key
	  for ( $ind_tmp = 0; $ind_tmp < $n_of_key_lines + 1; $ind_tmp++ ) {
	    push( @selected_keys, $input_gttf[$ind_line + $ind_tmp] );
	  }
	}
      }
    }

    return @selected_keys;
  }


##################################################################################
#				     FilterGTTF	                                 #
##################################################################################

sub FilterGTTF(@input_gttf)  {
  # Stores position of the current line beeing proceed
  $current_line = 0;

  # Copy first 4 lines without any changes
  # It is a radius and transformation matrix 
  for ( $ind_line = 0; $ind_line < 4; $ind_line++ ) {
    push(@filtered_gttf, $input_gttf[$ind_line]);
  }
  $current_line = $ind_line;

  # Store number of source space levels
  $n_of_levels = $input_gttf[4];
  push ( @filtered_gttf, $n_of_levels );
  $current_line++;

  # Copy all levels to output gttf
  for ($ind_line = $current_line; $ind_line < ( $current_line + $n_of_levels ) ; $ind_line++) {
    push ( @filtered_gttf, $input_gttf[$ind_line] );
  }
  $current_line = $ind_line;

  # Store number of hyperfiles
  $n_of_hyperf = $input_gttf[$current_line];
  $current_line++;

  # Check keyword to see whether it has epoch selection criteria or not
  
  #Select hyperfiles according to the given keyword
  @selected_hypf = GetSelectedHyperf( @input_gttf, $keyword, $current_line, $n_of_hyperf );

  # Write number of selected hyperfiles
  $n_of_selected_hypf = ( $#selected_hypf + 1 )/2; 
  push( @filtered_gttf, $n_of_selected_hypf . "\n");
    
  # Write names of the hyperfiles which are selected
  print "FOUND " . $n_of_selected_hypf . " MATHCES\n";
  for ( $ind_tmp = 0; $ind_tmp < $n_of_selected_hypf ; $ind_tmp++ ) {
    print $selected_hypf[$ind_tmp * 2 - 1];
  }

  push( @filtered_gttf, @selected_hypf );

  # If nothing was selected, then produce error message end quit
  if ($#selected_hypf == -1) {
    print "Could not find any matches to the given keyword - " . $keyword . "\n";
    exit;
  }
    
  # Jump to the end of the hyperfiles section
  $current_line += ( 2 * $n_of_hyperf ); 

  # !!! PAY ATTENTION TO THIS LINE AND NEXT LINES, 
  # BECAUSE UNCOMMENTING THEM TOGETHER WILL PRODUCE CONTAMINATION
  # Select particular keywords from input gttf and ignore everything else
  # @selected_keywords = &SelectGTTFKeywords(@input_gttf);
  # Attach selected keywords with their values to the end of the file
  #   push( @filtered_gttf, @selected_keywords );
    
  # Copy the rest of the input gttf to the end of the output gttf
  for ( $ind_line = $current_line; $ind_line < ( $current_line + $#input_gttf ); $ind_line++ ) {
    push( @filtered_gttf, $input_gttf[$ind_line] );
  }
    
  return @filtered_gttf;
}

##################################################################################
#				     RegularExpressionCorrection                 #
##################################################################################

sub RegularExpressionCorrection {
  local($pattern) = @_;
  # Scan pattern for the symbols '*', '?'
  # if they exist then make corrections so later 
  # perl can deal with them as a correct regular expression
  $pattern =~ s/\s*\*\s*/.*/g;
  $pattern =~ s/\s*\?\s*/.?/g;
  return $pattern;
}



##################################################################################
#				     MAIN			                 #
##################################################################################

# Begin main steps

if ($#ARGV == 2) {
  $input_gttf_name = $ARGV[0];
  $output_gttf_name = $ARGV[1];
  # Keyword for selection
  $keyword = $ARGV[2];
  $exclude = "";
} else {
  if ($#ARGV == 3 ) {
    $input_gttf_name = $ARGV[0];
    $output_gttf_name = $ARGV[1];
    # Keyword for selection
    $keyword = $ARGV[2];
    # Keyword for exclusion
    $exclude = $ARGV[3];


  } else {
    print "\nUSAGE: filter_gttf <input_gttf_file> <output_gttf_file> <include keyword> <exclude keyword>\n";
    print "When using regular expressions be aware to precede * and ? with backslash symbol\n";
    print "Example:  filter_gttf input.gttf output.gttf \\*str1\\*str2 excl\\*\n";
    print "To select epochs you want write \"_ep\" plus epoch numbers separated by commas.\n";
    print "!!! DON'T USE THE SPACE BETWEEN THE EPOCH NUMBERS\n";      
    print "Example: filter_gttf input.gttf output.gttf _ep1,2,3,10";
    print "\nNOTE: Exclude keyword is optional\n";
    exit 1;
  }
}

# Here we are trying to find out whether it is regular expression or no
# If it is a case then we have to make a little changes, with the keywords,
# so perl can understand them correctly
$keyword = &RegularExpressionCorrection($keyword);
$exclude = &RegularExpressionCorrection($exclude);

if ( $input_gttf_name =~ $output_gttf_name ) {
  print " ERROR - input and output file names could not be similar\n";
  exit;
}

@input_gttf = &ReadGTTF($input_gttf_name);
@filtered_gttf = &FilterGTTF(@input_gttf);
&WriteFilteredGTTF(@filtered_gttf, $output_gttf_name);



