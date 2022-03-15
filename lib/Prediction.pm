package Prediction;
use strict;
use warnings;
# use utf8;
# use open qw(:std :utf8);
use Data::Dumper qw(Dumper);
use Storable;
use 5.10.0;
use JSON;
use JSON::Parse qw /parse_json valid_json/;
use feature qw /say state/;
use Exporter qw (import);
our @EXPORT=qw !disorders_to_syms! ;

no warnings 'uninitialized';

#default parameters
my $num_of_quest = 3;			#Number of interesting symptoms per disorder
my $num_of_dis = 10;			#Number of top disorders
my $prevalence = 1/4000;


my $symptom_number = retrieve("/ram/SAMS/hashes/symptom_number");
my $disorder_symptom_freq = retrieve("/ram/SAMS/hashes/disorder_symptom_freq");
my $prob_uniq_disorders = retrieve("/ram/SAMS/hashes/prob_uniq_disorders") ;
my %symps_for_disorder = %{ retrieve("/ram/SAMS/hashes/symps_for_disorder") };

my $num_of_diff_syms = scalar keys %{$symptom_number};
my $product_not_disorders_number = 1;

my @sympvec;
my @no_sympvec;
my %input_hash;
my @prediction_array;

#A lot of variables are global to prevent useless copying 

#Main function of the script, gets the %input_hash as a input, fills the @prediction_array and return it.
sub disorders_to_syms {  

	%input_hash = %{$_[0]};
	
	if ( defined($input_hash{"num_of_quest"}) && defined($input_hash{"num_of_dis"})) {					#Check if the %input_hash contains the parameter.

			$num_of_quest = $input_hash{"num_of_quest"};											#Set the number of interesting symptoms per disorder.
			delete $input_hash{"num_of_quest"};
			$num_of_dis = $input_hash{"num_of_dis"};												#Set the number of top disorders.
			delete $input_hash{"num_of_dis"};

		  }
			
	#Convert the %input_hash into two arrays for symptoms(value=2) and not symptoms(value=0).
	sub hash_to_arrays {


		foreach my $symp_key (keys %input_hash) {

			if ( $input_hash{$symp_key} > 0) {
				push(@sympvec,$symp_key);
			}

			elsif ( $input_hash{$symp_key} == 0) {
				push(@no_sympvec,$symp_key);
			}

		}
		return 1;
	}


	#Checks if they are any symptoms, which are not in the database and delete them. 



	#Gets a disorder and the @sympvec as an input and return the product of the freuquencies to the symptoms in @sympvec.



	

	#Returns array filled with the top $num_of_dis(default = 10) most likely diseases 


	#Writes maximum $num_of_quest(default = 3) symptoms per disorder in @prediction_array by filtering used symptoms and sort them by the frequnecy.
	#Thats a suggestion for the doctor to check if a patient has a specific disorder, help to decide if there are more than one disorder with a high score.
	#The Symptom IDs are in the @prediction_array[disorder index][4] and @prediction_array[disorder index][5], but @prediction_array[disorder index][5] will
	#be translated in DecisionTree.cgi.

	
	
	delete_not_existing_symps(\%input_hash);			#deletes symptoms, which are not in the Database
	my %sym_hash=%input_hash;
	hash_to_arrays(\%sym_hash);										#creates two arrays @symvec and @no_symvec
	my @input_hash_keys = keys %sym_hash;							#crates an array of the keys to look if the input_hash is empty

	if ( scalar(@input_hash_keys) eq 0) {								#if the script gets an hash with no symptoms or not existing symptoms

		my @prediction_array = ();				
		return(\@prediction_array);
	}

	else{

	prop_calculation();												#Calculate the top $num_of_dis disorders probability in %prob_uniq_disorders 
	top_elements();													#writes the top $num_of_dis(default = 10) disorders in @prediction_array							
	CleanUpElements();
	symps_to_quest(); 												#writes maximum $num_of_quest(default = 3) symptoms per disorder in @prediction_array
	return(\@prediction_array);										#return the @prediction_array
	}
	
}

sub freq_score {
	my $disorder_id = $_[0];
	my @temp_vec = @{$_[1]};
	my $x = 1;
	for (my $i; $i < scalar(@temp_vec); $i++) {
		my $element = $temp_vec[$i];
		if ($disorder_symptom_freq->{$disorder_id}{$element} eq -1) {					#Some symptoms exclude a disorder, but to prevent the devision of 0 it 
			$x *= 10**(-11);														#mulitplys with 10^(-11), which is nearly zero. 
		}
		elsif (defined($disorder_symptom_freq->{$disorder_id}{$element})) {				#If there is an entry in %disorder_symptom_freq
			$x *= $disorder_symptom_freq->{$disorder_id}{$element};
		}
		else{
			$x *=  0.01;
		}
	}
	return $x;
}

sub delete_not_existing_symps {
	my $input_hash=shift;
	foreach my $symptom (keys %$input_hash) {
		delete $input_hash{$symptom} unless $symptom_number->{$symptom};
	}
}

sub symps_to_quest {
	say STDERR "PA ",$#prediction_array;
	for (my $j = 0; $j <= $#prediction_array; $j++) {
		say STDERR "j $j";
		my @sym_for_disorder = @{$symps_for_disorder{$prediction_array[$j][0]}}; 
		my @unused_sym = ();
		for (my $i = 0; $i < @sym_for_disorder; $i++) {
			unless ($input_hash{$sym_for_disorder[$i]}) {
				push(@unused_sym,$sym_for_disorder[$i]);					#filters all the symptoms, which weren't asked yet
			}
		}
		if (@unused_sym <= $num_of_quest ) {						#if their are less symptoms left, we dont need to sort them
			push @{$prediction_array[$j][4]},@unused_sym; # warum muß das in 4 _und_ 5 stehen?
			push @{$prediction_array[$j][5]},@unused_sym;
		}
		else{
			my @sym_for_disorder = sort{
				$disorder_symptom_freq->{$prediction_array[$j][0]}{$b} <=> $disorder_symptom_freq->{$prediction_array[$j][0]}{$a}
				} (@unused_sym);
			splice @sym_for_disorder,$num_of_quest;
			push @{$prediction_array[$j][4]},@sym_for_disorder;
			push @{$prediction_array[$j][5]},@sym_for_disorder;
		}
	}
	say STDERR "done";
	#	print Dumper(\@prediction_array);
}

sub top_elements {
	my %prob_uniq_disorders_reduced = %{$prob_uniq_disorders};
	my @disorder_keys = keys %{$prob_uniq_disorders};
	my $max;
	for (my $i = 0; $i < $num_of_dis; $i++) {
		my $max = $disorder_keys[0];
		my $key_delete_index = 0;
		for (my $j = 0; $j < scalar(@disorder_keys); $j++) {
			my $entry = $disorder_keys[$j];
			if ($prob_uniq_disorders_reduced{$max} < $prob_uniq_disorders_reduced{$entry}) {
				$max = $entry;				
				$key_delete_index = $j;
			}
		}
		delete $prob_uniq_disorders_reduced{$max};		#deletes hash entry of the maximum
		splice(@disorder_keys,$key_delete_index,1);		#deletes the key index from the maximum
		$prediction_array[$i][0] = $max;					#adds maximum to return array 
		$prediction_array[$i][1] = $max;														
		$prediction_array[$i][2] = $prob_uniq_disorders->{$max};
			
		if ($prob_uniq_disorders->{$max} > 0.8) {
  			$prediction_array[$i][3] = "++"; #"very high";
  		}
		elsif ($prob_uniq_disorders->{$max} > 0.6) {
	  		$prediction_array[$i][3] = "+"; #"high";
  		}
  		elsif ($prob_uniq_disorders->{$max} > 0.4) {
	  		$prediction_array[$i][3] = "0"; #"mid";
	 	}
	 	else{
			$prediction_array[$i][3] = "-"; #"low";
	 	}
	}

}
#

sub CleanUpElements {
	my $max_score='-';
	for my $i (0..$#prediction_array) {
		if ($prediction_array[$i][3] eq '++') {
			$max_score='++';
			last;
		}
		elsif ($prediction_array[$i][3] eq '+') {
			$max_score='+';
			last;
		}
		elsif ($prediction_array[$i][3] eq '0') {
			$max_score=0;
			last;
		}		
	}
	if ($max_score eq '-') {
		@prediction_array=();
		return
	}
	say STDERR "MS $max_score ",scalar @prediction_array;
	for my $i (0..$#prediction_array) {
		say STDERR "X $i";
		if ($prediction_array[$i][3] ne $max_score) {
			@prediction_array=@prediction_array[0..($i-1)];
			say STDERR "X $i last",scalar @prediction_array;
			return;
		}
	}
}


sub prop_calculation {
	my $product_not_disorders_number = 1;
	foreach my $symptom (@sympvec) {
		$product_not_disorders_number = ($symptom_number->{$symptom} / $num_of_diff_syms) *	$product_not_disorders_number;
	}
		#update all keys in hash of disorders
	foreach my $disorder_key (keys %{$prob_uniq_disorders}) {
		my $current_freq_score = freq_score($disorder_key,\@sympvec);
#Bayes Theorem:
		$prob_uniq_disorders->{$disorder_key} =					
			($current_freq_score*$prevalence)/
				(($prevalence * $current_freq_score) + ((1-$prevalence)*$product_not_disorders_number));
	
		my $count_no_symps = 0;
		for (my $i = 0; $i < scalar(@no_sympvec); $i++) {
			if ( defined($disorder_symptom_freq->{$disorder_key}{$no_sympvec[$i]}) && not($disorder_symptom_freq->{$disorder_key}{$no_sympvec[$i]} eq -1)) {
				$count_no_symps += 1; 
			}
		}
			
		my $number_of_symptoms = @{$symps_for_disorder{$disorder_key}};

		SYMPTOMS:foreach my $symptom ( @{$symps_for_disorder{$disorder_key}}) {
			if ( $disorder_symptom_freq->{$disorder_key}{$symptom} eq -1) {
				$number_of_symptoms -= 1;
				last SYMPTOMS;
			}
		}
		unless ($count_no_symps eq $number_of_symptoms) {
			my $penalty_function = ($number_of_symptoms-$count_no_symps)/$number_of_symptoms;					#if a disorder has more symptoms 
			$prob_uniq_disorders->{$disorder_key} = $prob_uniq_disorders->{$disorder_key}*$penalty_function;		#Reduces the probability if symptoms of that specicfic disorder 
		}
		else {
			$prob_uniq_disorders->{$disorder_key} = 0.000000001
		}																								#are in @no_symp.
	}
}

return 1;











 

 
