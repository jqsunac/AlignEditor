package Nazuna;
use strict;
use warnings;
use Data::Dumper;

=header1 Nazuna

Nazuna is the package for editing aligment which aligned by est2genome or sim4.
The pakcage need input three arguments.

=over
=item 1 The EST sequence of string.
=item 2 The genome sequence of string.
=item 3 THe result of est2genome or sim4.
=back

Two main methods implement in Nazuna package.
Using getNodes for getting the all junctions of exon and intron.
After edit the sequence around junctions, then use the updateNodes save to
the edeted informations.

=cut


=head1 Constructor of Nazuna class.

The constructor of Nazuna need the alignment file and the sequences of EST and genome.

=over
=item * -align_file         : The file path of the result of est2genome or sim4.
=item * -align_format       : The format of files. est2genome or sim4.
=item * -signature_intron   : The signature for indicating intron.
=item * -signature_gap    : The signature for indicating gaps.
=back

=cut
sub new {
	my $class = shift;
	my $self = {};
	$self = {@_};
	$self->{'-signature_intron'} = '.';
	$self->{'-signature_gap'} = '-';

	if ($self->{'-signature_intron'} eq $self->{'-signature_gap'}) {
		die "Nazuna::ERROR: It needs different signature for gaps and introns.\n";
	}

	bless($self, $class);
	return $self;
}


=head1 Map est to reference sequence.

 The function of this method is for reading the result of est2genome or sim4.
 It inserts signatures of introns and gaps to est sequence and inserts gaps
 to genome sequence. After extending the sequence of est and genome, it lets 
 the length of sequence of est and genome to equal.
 Then fill the object extend_est, extend_genome and sigunatures.

=cut
sub align_seq {
	my $self = shift;
	# Read information from file.
	if ($self->{'align_format'} eq 'nazuna') {
		$self->_read_nazuna;
	} elsif ($self->{'align_format'} eq 'est2genome') {
		$self->_read_est2genome;
	} else {
		die;
	}

	# Check the sequences are existed.
	if ((!defined $self->{'est_seq'}) || ($self->{'est_seq'} eq '')) {
		die "Nazuna::ERROR: No EST sequence.\n";
	}
	if ((!defined $self->{'genome_seq'}) || ($self->{'genome_seq'} eq '')) {
		die "Nazuna::ERROR: No genome sequence.\n";
	}

	# The est2genome will try aligned the reversed EST to genome.
	# It needs complementary strand. (Why ???)
	if ($self->{'est_strand'} eq '-') {
		$self->{'est_seq'} = reverse($self->{'est_seq'});
		$self->{'est_seq'} =~ tr/ACGTacgt/TGCAtgca/;
	}

	# Copy the position informations to prepare insert intron, gaps to genome and est.
	# It needn't intron in this features reference.
	# Because any intron should appear between two exons.
	my $features = [];
	foreach my $ft (@{$self->{'features'}}) {
		my $cp_ft = {};
		$cp_ft->{'type'} = $ft->{'type'};
		$cp_ft->{'est_start'} = $ft->{'est_start'};
		$cp_ft->{'est_end'} = $ft->{'est_end'};
		$cp_ft->{'genome_start'} = $ft->{'genome_start'};
		$cp_ft->{'genome_end'} = $ft->{'genome_end'};
		push(@{$features}, $cp_ft);
	}
	my $segments = [];
	foreach my $sg (@{$self->{'segments'}}) {
		my $cp_sg = {};
		$cp_sg->{'est_start'} = $sg->{'est_start'};
		$cp_sg->{'est_end'} = $sg->{'est_end'};
		$cp_sg->{'genome_start'} = $sg->{'genome_start'};
		$cp_sg->{'genome_end'} = $sg->{'genome_end'};
		push(@{$segments}, $cp_sg);
	}
	
	# Insert introns to est sequence and adjust the positions of est.
	$self->_insert_introns($features, $segments);
	# Insert gaps to est and genome sequence and adjust the positions of est and genome.
	$self->_insert_gaps($features, $segments);
	# Set the aligned annotations (extends from $self->{features}).
	$self->{'annotations'} = $features;
}




sub _update_junctions {
	my $self = shift;
	my $junctions = shift;
	my $len = shift;

	my $genome_shift = 0;
	my $est_shift = 0;
	for (my $i = 0; $i < @{$self->{'annotations'}}; $i++) {
		my $ann = $self->{'annotations'}->[$i];

		# The first junctions of the first exon starting side.
		if ($i == 0) {
			my $seq = $junctions->[$i]->{'est_seq'};
			$seq =~ s/ //g;
			if ($len < length($seq)) {
				substr($self->{'est_seq'},
					$ann->{'est_start'} - length($seq) + $len - 1, 
					length($seq), $seq);
			} else {
				substr($self->{'est_seq'},
					$ann->{'est_start'} - 1, length($seq), $seq);
  			}
			substr($self->{'genome_seq'},
				$ann->{'genome_start'} - $len - 1, $len * 2,
				$junctions->[$i]->{'genome_seq'});
		}

		# Update the junctions of this segment starting side.
		if ($i != 0) {
			$ann->{'est_start'} = $ann->{'est_start'} + $est_shift;
			$ann->{'genome_start'} = $ann->{'genome_start'} + $genome_shift;
			substr($self->{'est_seq'}, $ann->{'est_start'} - $len - 1, $len * 2,
				$junctions->[$i]->{'est_seq'});
			substr($self->{'genome_seq'}, $ann->{'genome_start'} - $len - 1, $len * 2,
				$junctions->[$i]->{'genome_seq'});
			# If the length of replacement is not equal to junctions, shift the position.
			my $this_est_shift = length($junctions->[$i]->{'est_seq'}) - $len * 2;
			my $this_genome_shift = length($junctions->[$i]->{'genome_seq'}) - $len * 2;
			$est_shift = $est_shift + $this_est_shift;
			$genome_shift = $genome_shift + $this_genome_shift;
		}

		# The last junctions of tha last exon ending side.
		if ($i == @{$self->{'annotations'}}) {
			my $seq = $junctions->[$i + 1]->{'est_seq'};
			$seq =~ s/ //g;
			substr($self->{'est_seq'}, $ann->{'est_end'} - $len - 1, length($seq), $seq);
			substr($self->{'genome_seq'}, $ann->{'genome_end'} + 1 - $len - 1, $len * 2,
				$junctions->[$i + 1]->{'genome_seq'});
			$self->{'annotations'}->[-1]->{est_end} += $est_shift;
			$self->{'annotations'}->[-1]->{genome_end} += $genome_shift;
		}
	}
}


sub _update_create_annotations {
	my $self = shift;

	my $annotations = [];
	my $seq = $self->{'est_seq'};

	my $es = $self->{'annotations'}->[0]->{'est_start'};
	my $gs = $self->{'annotations'}->[0]->{'genome_start'};
	my $ee = $self->{'annotations'}->[-1]->{'est_end'};
	my $ge = $self->{'annotations'}->[-1]->{'genome_end'};

	my $segs = [];
	my $i = 0;
	$segs->[0]->{'start'} = 1;
	while ((my $pos = index($seq, ".", 0)) > 0) {
		# Exon.
		$segs->[$i]->{type} = 'exon';
		$segs->[$i]->{start} = $segs->[$i - 1]->{end} + 1 if $i != 0;
		$segs->[$i]->{end} = $segs->[$i]->{start} + $pos - 1;
		$segs->[$i]->{ofs} = $segs->[$i]->{end} - $segs->[$i]->{start} + 1;
		$i++;
		#Intron.
		$seq = substr($seq , $pos);
		$seq =~ m/^(\.+)([^\.].*)$/;
		$segs->[$i]->{seq} = $1;
		$segs->[$i]->{start} = $segs->[$i - 1]->{end} + 1;
		$segs->[$i]->{end} = $segs->[$i - 1]->{end} + length($1) ;
		$segs->[$i]->{type} = 'intron';
		$segs->[$i]->{ofs} = $segs->[$i]->{end} - $segs->[$i]->{start} + 1;
		$seq = $2;
		$i++;
	}
	$segs->[$i]->{type} = 'exon';
	$segs->[$i]->{start} = $segs->[$i - 1]->{end} + 1;
	$segs->[$i]->{end} = $segs->[$i - 1]->{end} + length($seq);
	$segs->[$i]->{ofs} = $segs->[$i]->{end} - $segs->[$i]->{start} + 1;

	foreach my $seg (@{$segs}) {
		my $ann = {};
		$ann->{'type'} = $seg->{'type'};
		$ann->{est_start} = $seg->{start};
		$ann->{est_end} = $seg->{end};
		$ann->{genome_start} = $seg->{start};
		$ann->{genome_end} = $seg->{end};
		push(@{$annotations}, $ann);
	}
	$annotations->[0]->{'est_start'} = $es;
	$annotations->[0]->{'genome_start'} = $gs;
	$annotations->[-1]->{'est_end'} = $ee;
	$annotations->[-1]->{'genome_end'} = $ge;
	$self->{'annotations'} = $annotations;
}

sub update_seq {
	my $self = shift;
	my $type = shift;
	my $junctions = shift;
	my $len = shift;
	$self->_update_sequences($type, $junctions, $len);
}

sub update_junctions {
	my $self = shift;
	my $junctions = shift;
	my $len = shift;
	$self->_update_sequences('junction', $junctions, $len);
}

sub update_introns {
	my $self = shift;
	my $introns = shift;
	$self->_update_sequences('intron', $introns);
}

sub update_exons {
	my $self = shift;
	my $exons = shift;
	$self->_update_sequences('exon', $exons);
}

sub _update_sequences {
	my $self = shift;
	my $type = shift;
	my $segments = shift;
	my $len = shift;

	# Replace sequences from orignal to editon.
	if ($type eq 'exon' ) {
		$self->_update_segments('exon', $segments);
	} elsif ($type eq 'intron') {
		$self->_update_segments('intron', $segments);
	} else {
		$self->_update_junctions($segments, $len);
	}
	# Make new annotations.
	$self->_update_create_annotations;
	# Make new features.
	my $features = [];
	foreach my $ann (@{$self->{'annotations'}}) {
		my $cp_ft = {};
		$cp_ft->{'type'} = $ann->{'type'};
		$cp_ft->{'est_start'} = $ann->{'est_start'};
		$cp_ft->{'est_end'} = $ann->{'est_end'};
		$cp_ft->{'genome_start'} = $ann->{'genome_start'};
		$cp_ft->{'genome_end'} = $ann->{'genome_end'};
		push(@{$features}, $cp_ft);
	}
	$self->{'features'} = $features;
	$self->_delete_intron;
	$self->_delete_gaps;
}



=header _make_segs
 make segments information with given sequences.
 example) 
                1 3 5        16 17     25 26   32
                | | |         | |       | |     |
   est_seq     -CAGTCGATCATGTCA-CGATCGATT-CAGACAGT
   index       012345678901234567890123456789012345
   genome_seq  ACA-TCGATCATGTCACCGATCGATTCAGACAGT-
                || |          | |       | |     |
                23 4         15 17     25 27   33

 $pos               [0]   [1]   [2]   [3]
   ->est_start       1     5    17    26
   ->est_end         3    16    25    32
   ->genome_start    2     4    17    27
   ->genome_end      3    15    25    33
=cut
sub _make_segs {
	my $self = shift;
	my $est_seq = shift;
	my $genome_seq = shift;

	# Make index file of each sequences.
	my $tmp_idx = 1;
	my $est_idx = [];
	for (my $i = 0; $i < length($est_seq); $i++) {
		if (substr($est_seq, $i, 1) ne '-') {
			push(@{$est_idx}, $tmp_idx++);
		} else {
			push(@{$est_idx}, -1);
		}
	}
	$tmp_idx = 1;
	my $genome_idx = [];
	for (my $i = 0; $i < length($genome_seq); $i++) {
		if (substr($genome_seq, $i, 1) ne '-') {
			push(@{$genome_idx}, $tmp_idx++);
		} else {
			push(@{$genome_idx}, -1);
		}
	}
	# Record gaps position.
	my $segs = [];
	my $idx = 0;
	my $start_pos = -1;
	for(my $i = 0; $i < length($est_seq); $i++) {
		if (substr($est_seq, $i, 1) eq '-' || substr($genome_seq, $i, 1) eq '-') {
			if ($start_pos != -1) {
				my $seg = {};
				$seg->{'est_start'} = $est_idx->[$start_pos];
				$seg->{'est_end'} = $est_idx->[$i - 1];
				$seg->{'genome_start'} = $genome_idx->[$start_pos];
				$seg->{'genome_end'} = $genome_idx->[$i - 1];
				push (@{$segs}, $seg);
			}
			$start_pos = -1;
		} else {
			if ($start_pos == -1) {
				$start_pos = $i;
			}
		}
		# Because the last segemnt without gaps cannot detect from above process.
		if ($i == length($est_seq) - 1) {
			my $seg = {};
			$seg->{'est_start'} = $est_idx->[$start_pos];
			$seg->{'est_end'} = $est_idx->[$i];
			$seg->{'genome_start'} = $genome_idx->[$start_pos];
			$seg->{'genome_end'} = $genome_idx->[$i];
			push (@{$segs}, $seg);
		}
	}
	return $segs;
}

sub _delete_gaps {
	my $self = shift;
	my $features = $self->{'features'};
	my $segments = [];
	
	my $est_gaps = 0;
	my $genome_gaps = 0;
	for (my $j = 0; $j < @{$features}; $j++) {
		my $ft = $features->[$j];
		if ($ft->{'type'} eq 'intron') {
			$ft->{'genome_start'} = $ft->{'genome_start'} - $genome_gaps;
			$ft->{'genome_end'} = $ft->{'genome_end'} - $genome_gaps;
		} elsif ($ft->{'type'} eq 'exon') {
			my $est_seq = substr($self->{'est_seq'}, $ft->{est_start} - 1, 
					$ft->{est_end} - $ft->{est_start} + 1);
			my $genome_seq = substr($self->{'genome_seq'}, $ft->{genome_start} - 1,
					$ft->{genome_end} - $ft->{genome_start} + 1);
			# detec the all gaps
			my $this_segs = $self->_make_segs($est_seq, $genome_seq);
			# Renew position informations.
			my $est_gap_len = ($est_seq =~ tr/\-//);
			my $genome_gap_len = ($genome_seq =~ tr/\-//);
			$ft->{'est_start'} = $ft->{'est_start'} - $est_gaps;
			$ft->{'genome_start'} = $ft->{'genome_start'} - $genome_gaps;
			$est_gaps += $est_gap_len;
			$genome_gaps += $genome_gap_len;
			$ft->{'est_end'} = $ft->{'est_end'} - $est_gaps;
			$ft->{'genome_end'} = $ft->{'genome_end'} - $genome_gaps;
			foreach my $this_seg (@{$this_segs}) {
				my $seg = {};
				$seg->{'est_start'} = $this_seg->{'est_start'} + $ft->{'est_start'} - 1;
				$seg->{'est_end'} = $this_seg->{'est_end'} + $ft->{'est_start'} - 1;
				$seg->{'genome_start'} = $this_seg->{'genome_start'} + $ft->{'genome_start'} - 1;
				$seg->{'genome_end'} = $this_seg->{'genome_end'} + $ft->{'genome_start'} - 1;
				push(@{$segments}, $seg);
			}
		}
	}
	$self->{'segments'} = $segments;
	$self->{'est_seq'} =~ tr/\-//;
	$self->{'genome_seq'} =~ tr/\-//;
}

sub _delete_intron {
	my $self = shift;
	my $features = $self->{'features'};
	
	my $genome_begin = $self->{'features'}->[0]->{'genome_start'};
	my $est_begin = $self->{'features'}->[0]->{'est_start'};
	my $cumsum_len = 0;

	my $intron_len = 0;
	foreach my $ft (@{$features}) {
		$ft->{'genome_start'} = $ft->{'est_start'} - $est_begin + $genome_begin;
		$ft->{'genome_end'} = $ft->{'est_end'} - $est_begin + $genome_begin;
		if ($ft->{'type'} eq 'exon') {
			$ft->{'est_start'} = $ft->{'est_start'} - $intron_len;
			$ft->{'est_end'} = $ft->{'est_end'} - $intron_len;
		} elsif ($ft->{'type'} eq 'intron') {
			$intron_len = $intron_len + $ft->{'est_end'} - $ft->{'est_start'}  + 1;
			$ft->{'est_start'} = '';
			$ft->{'est_end'} = '';
		}
	}
	$self->{'est_seq'} =~ s/\.//g;
}


sub get_alignments {
	my $self = shift;
	my $seq_type = shift;
	my $param = shift;
	if ($seq_type =~ /junction/i) {
		return $self->get_junctions($param);
	} elsif ($seq_type =~ /exon/i) {
		return $self->get_exons($param);
	} elsif ($seq_type =~ /intro/i) {
		return $self->get_introns($param);
	}
}



=header Get junctions of exon and intron

 The function of this method is generate the all junctions of exon and intron.
 The method generate array of reference of all junctions such as:
 (The junction length = 20)

 The image:
   [0]      position: 2212
                      |
   genome   GGACAGCGCCGACTGGTAGC
   est      GGACAGCGCC----------
             exon    |    intron
                     188

   [1]                3190
                      |
   genome   CGTAATTATGCAGTATTCGT
   est      ----------GCAGTATTCGT
             exon     |   intron
                      189


 The data structure likes under on this situation:

 junction[0]->{index} = 0            # The index of junctions.
        ->{type}  = 'E/I'        # The junction in exon and intron.
        ->{est_end} = 188        # The end position of this junction.
        ->{genome_start} = 2212  # The start position of this junction.
        ->{genome_seq} = GGACAGCGCCGACTGGTAGC
        ->{est_seq}    = GGACAGCGCC----------
 junction[1]->{index} = 1            # The index of junctions.
        ->{type}  = 'I/E'        # The junction in exon and intron.
        ->{est_start} = 190      # The start position of this junction.
        ->{genome_start} = 3190  # The start position of this junction.
        ->{genome_seq} = CGTAATTATGCAGTATTCGT
        ->{est_seq}    = ----------GCAGTATTCGT
   
=cut
sub get_junctions {
	my $self = shift;
	my $len = shift;


	if (!defined $self->{'annotations'}) {
		die "Nazuna::ERROR: Run Nazuna->align_seq blign_efore Nazuna->get_junctions.\n";
	}

	my $junctions = [];	

	for (my $i = 0; $i < @{$self->{'annotations'}}; $i++) {
		my $ann = $self->{'annotations'}->[$i];
		# Get the first junctions of first exon side.
		if ($i == 0) {
			my $junction = {};
			$junction->{'index'} = $i;
			$junction->{'type'} = '-/E';
			$junction->{'est_start'} = $self->{'features'}->[$i]->{'est_start'};
			$junction->{'genome_start'} = $self->{'features'}->[$i]->{'genome_start'};
			$junction->{'genome_seq'} = substr($self->{'genome_seq'},
				$ann->{'genome_start'} - $len - 1, $len * 2);
			# Full up the length of string of junction to $len with blank.
			if ($ann->{'est_start'} < $len) {
				my $blank = $len - $ann->{'est_start'} + 1;
				$junction->{'est_seq'} = substr($self->{'est_seq'},
					0, 2 * $len - $blank);
				$junction->{'est_seq'} = sprintf("%s", ' ' x $blank) . $junction->{'est_seq'};
			} else {
				$junction->{'est_seq'} = substr($self->{'est_seq'},
					$ann->{'est_start'} - $len - 1, $len * 2);
			}
			push(@{$junctions}, $junction);
		}

		# Get the junction of this segment starting side.
		# (include the starting side of last exon, but donot incluede eding side of that.)
		if ($i != 0) {
			my $junction = {};
			$junction->{'index'} = $i;
			$junction->{'est_seq'} = substr($self->{'est_seq'}, 
				$ann->{'est_start'} - $len - 1, $len * 2);
			$junction->{'genome_seq'} = substr($self->{'genome_seq'},
				$ann->{'genome_start'} - $len - 1, $len * 2);
			if ($ann->{'type'} eq 'exon') {
				$junction->{'type'} = 'I/E';
				$junction->{'genome_start'} =  $self->{'features'}->[$i]->{'genome_start'};
				$junction->{'est_start'} =  $self->{'features'}->[$i]->{'est_start'};
			} else {
				$junction->{'type'} = 'E/I';
				$junction->{'genome_start'} =  $self->{'features'}->[$i]->{'genome_start'};
				$junction->{'est_start'} = -1;
			}
			push(@{$junctions}, $junction);
		}

		# Get the last junctions of last exon ending side.
		if ($i == @{$self->{'annotations'}} - 1) {
			my $junction = {};
			$junction->{'index'} = $i + 1;
			$junction->{'type'} = 'E/-';
			$junction->{'genome_start'} = $self->{'features'}->[$i]->{'genome_end'} + 1;
			$junction->{'genome_seq'} = substr($self->{'genome_seq'},
				$ann->{'genome_end'} + 1 - $len - 1, $len * 2);
			$junction->{'est_seq'} = substr($self->{'est_seq'},
				$ann->{'est_end'} + 1 - $len - 1, $len * 2);
			# Full up the length of string of junction to $len with blank.
			my $blank = $len * 2 - length($junction->{'est_seq'});
			# If the sequence has poly-A, record the start position of poly-A.
			if (length($junction->{'est_seq'}) > $blank) {
				$junction->{'est_start'} = $self->{'features'}->[$i]->{'est_end'} + 1;
			} else {
				$junction->{'est_start'} = -1;
			}
			if ($blank > 0) {
				$junction->{'est_seq'} = $junction->{'est_seq'} . sprintf("%s", ' ' x $blank);
			}

			push(@{$junctions}, $junction);
		}
	}
	return $junctions;
}


=header
 get_exons
 Get all exons.
=cut
sub get_exons {
	my $self = shift;
	return $self->_get_segments('exon');
}
sub get_introns {
	my $self = shift;
	return $self->_get_segments('intron');
}
sub _get_segments {
	my $self = shift;
	my $type = shift;

	
	if (!defined $self->{'annotations'}) {
		die "Nazuna::ERROR: Run Nazuna->align_seq blign_efore Nazuna->get_junctions.\n";
	}

	my $seg_type = '';
	if ($type eq 'exon') {
		$seg_type = 'E';
	} elsif ($type eq 'intron') {
		$seg_type = 'I';
	}

	my $segs = [];
	my $idx = 0;
	for (my $i = 0; $i < @{$self->{'annotations'}}; $i++) {
		my $ann = $self->{'annotations'}->[$i];
		next if ($ann->{'type'} ne $type);
		my $seg = {};
		$seg->{'index'} = $idx++;
		$seg->{'type'} = $seg_type . $idx;
		$seg->{'est_start'} = $self->{'features'}->[$i]->{'est_start'};
		$seg->{'genome_start'} = $self->{'features'}->[$i]->{'genome_start'};
		$seg->{'est_end'} = $self->{'features'}->[$i]->{'est_end'};
		$seg->{'genome_end'} = $self->{'features'}->[$i]->{'genome_end'};
		$seg->{'est_seq'} = substr($self->{'est_seq'}, $ann->{'est_start'} - 1,
					$ann->{'est_end'} - $ann->{'est_start'} + 1);
		$seg->{'genome_seq'} = substr($self->{'genome_seq'}, $ann->{'genome_start'} - 1,
						$ann->{'genome_end'} - $ann->{'genome_start'} + 1);
		push(@{$segs}, $seg);
	}
	return $segs;
}


sub _update_segments {
	my $self = shift;
	my $type = shift;
	my $segments = shift;

	my $seg_idx = 0;
	my $est_shift = 0;
	my $genome_shift = 0;

	for (my $i = 0; $i < @{$self->{'annotations'}}; $i++) {
		my $ann = $self->{'annotations'}->[$i];

		$ann->{'est_start'} += $est_shift;
		$ann->{'est_end'} += $est_shift;
		$ann->{'genome_start'} += $genome_shift;
		$ann->{'genome_end'} += $genome_shift;

		if ($ann->{'type'} eq $type) {
			my $est_len = $ann->{'est_end'} - $ann->{'est_start'} + 1;
			my $genome_len = $ann->{'genome_end'} - $ann->{'genome_start'} + 1;
			my $est_replaced_len = length($segments->[$seg_idx]->{'est_seq'});
			my $genome_replaced_len = length($segments->[$seg_idx]->{'genome_seq'});
			if ($est_replaced_len != $genome_replaced_len) {
				die "Nazuna::ERROR: The length of est and genome sequence must be equal.\n";
			}
			
			my $this_est_shift = $est_replaced_len - $est_len;
			my $this_genome_shift = $genome_replaced_len - $genome_len;


#warn Dumper	substr($self->{'est_seq'}, $ann->{'est_start'} - 1,
#				$ann->{'est_end'} - $ann->{'est_start'} + 1);
#warn Dumper $segments->[$seg_idx]->{est_seq};
#warn Dumper length($self->{est_seq});
			substr($self->{'est_seq'}, $ann->{'est_start'} - 1,
				$ann->{'est_end'} - $ann->{'est_start'} + 1, $segments->[$seg_idx]->{'est_seq'});
			substr($self->{'genome_seq'}, $ann->{'genome_start'} - 1,
				$ann->{'genome_end'} - $ann->{'genome_start'} + 1, $segments->[$seg_idx]->{'genome_seq'});
			$ann->{'est_end'} += $this_est_shift;
			$ann->{'genome_end'} += $this_genome_shift;
#warn Dumper length($self->{est_seq});

			$est_shift += $this_est_shift;
			$genome_shift += $this_genome_shift;
			$seg_idx++;
		}
	}
#die;
}

=pod
 
 _insert_introns

Intert introns usage the result of est2genome.
This method should run before _insert_gaps.

=cut
sub _insert_introns {
	my $self = shift;
	my $features = shift;
	my $segments = shift;

	for (my $f = 0; $f < @{$features}; $f++) {
		next if $features->[$f]->{'type'} eq 'exon';

		# features annotations for $self->{annotations}.
		my $ft = {};

		# If this segment is intron, insert the intron signature after prev-exon of EST sequence.
		my $intron_length = $features->[$f]->{'genome_end'} 
				- $features->[$f]->{'genome_start'} + 1;
		substr($self->{'est_seq'}, $features->[$f - 1]->{'est_end'}, 0, 
				sprintf("%s", $self->{'-signature_intron'} x $intron_length));
		# Renew the position information of EST.
		$features->[$f]->{'est_start'} = $features->[$f - 1]->{'est_end'} + 1;
		$features->[$f]->{'est_end'} = $features->[$f - 1]->{'est_end'} + $intron_length;


		# shift the all position after this position because the effect by inserted intron.
		# (Because inserted intron do not affect the genome sequence.)
		for (my $fi = $f + 1; $fi < @{$features}; $fi++) {
			$features->[$fi]->{'est_start'} += $intron_length;
			$features->[$fi]->{'est_end'} += $intron_length;
		}
		for (my $si = 0; $si < @{$segments}; $si++) {
			# Because the position of genome did not change.
			# Let this be absoluted conditions for changing that of EST.
			if ($features->[$f - 1]->{'genome_end'} < $segments->[$si]->{'genome_start'}) {
				$segments->[$si]->{'est_start'} += $intron_length;
				$segments->[$si]->{'est_end'} += $intron_length;
			} 
		}
	}

}




=pod

_insert_gaps

Insert the gaps to est sequence and genome sequence.
It is the pricate method that doesn't recommend to use directly. 

The process for inserting gaps.

 1) Check the gaps position. For example:
     segments       genome          EST
     No.         start   end    start   end
      n - 1       2120  2180      120   180
      n           2181  2200      182   201
    => In this case, there is one gap in genome sequence.
                            181
                          180|182
       segments [n - 1]     |||        [n]
       est     ACCACGTAGCTAGCTAGTGCACGAGCAGCTAGCAGCATCGT
       genome  ACCACGTAGCTAGC-AGTGCACGAGCAGCTAGCAGCATCGT
                            | |
                         2180 2181
 2) Insert the gaps to the target sequence.
 3) Refresh(increment) the number of position of features.

=cut
sub _insert_gaps {
	my $self = shift;
	my $features = shift;
	my $segments = shift;

	for (my $f = 0; $f < @{$features}; $f++) {
		my $num_of_seg_in_the_ft = 0;
		for (my $s = 0; $s < @{$segments}; $s++) {
			# Only process the segments in this feature such as below three types.
			#
			# feature  GACTGTAGCTAGCTGAGCAGCTTTATGCATCGGTGTGTAGCA
			# segments GACTGTAGCT
			#
			# feature  GACTGTAGCTAGCTGAGCAGCTTTATGCATCGGTGTGTAGCA
			# segments       AGCTAGCTGAGCAGCTTTATGCATCGGTGT
			#
			# feature  GACTGTAGCTAGCTGAGCAGCTTTATGCATCGGTGTGTAGCA
			# segments             CTGAGCAGCTTTATGCATCGGTGTGTAGCA
			#
			if (($features->[$f]->{'genome_start'} <= $segments->[$s]->{'genome_start'})
				&& ($segments->[$s]->{'genome_end'} <= $features->[$f]->{'genome_end'})
				&& ($features->[$f]->{'est_start'} <= $segments->[$s]->{'est_start'})
				&& ($segments->[$s]->{'est_end'} <= $features->[$f]->{'est_end'})) {

				# Calculate gaps length.
				my $gap_len_est = 0;
				my $gap_len_genome = 0;
				if (++$num_of_seg_in_the_ft == 1) {
					$gap_len_est = $segments->[$s]->{'genome_start'} - $features->[$f]->{'genome_start'};
					$gap_len_genome = $segments->[$s]->{'est_start'} - $features->[$f]->{'est_start'};
				} else {
					$gap_len_est = $segments->[$s]->{'genome_start'} - $segments->[$s - 1]->{'genome_end'} - 1;
					$gap_len_genome = $segments->[$s]->{'est_start'} - $segments->[$s - 1]->{'est_end'} - 1;
				}

				# Insert the gaps BEFORE this segment.
				# Segment >>    [n - 1]   |    [n]
				# Before  >> CCAGCTAGCGGTAGCTAGCTGCGTAGCTAGT
				# After   >> CCAGCTAGCGGTAG---CTAGCTGCGTAGCTAGT
				if ($gap_len_est > 0) {
					substr($self->{'est_seq'}, 
						$segments->[$s]->{'est_start'} - 1, 0,
						sprintf("%s", $self->{'-signature_gap'} x $gap_len_est));
				}
				if ($gap_len_genome > 0) {
					substr($self->{'genome_seq'}, 
						$segments->[$s]->{'genome_start'} - 1, 0,
						sprintf("%s", $self->{'-signature_gap'} x $gap_len_genome));
				}
				# Adjust the position of this segment and the afters.
				# 1 ) Adjust the position of this segment.
				# 2 ) Adjust the position of next segment from this one.
				# Position >>           112  113         129  130       141
				#                 [n-1]    ||     [n]       ||          |
				# Before   >> CCAGCTAGCGGTAGCTAGCTGCGTAGCTAGTAAAAAAAAACCA
				# After    >> CCAGCTAGCGGTAG---CTAGCTGCGTAGCTAGTAAAAAAAAACCA
				#                          |   |               ||          |
				# Position >>           112     116         132  133       144
				$features->[$f]->{'genome_end'} += $gap_len_genome;
				$features->[$f]->{'est_end'} += $gap_len_est;
				$segments->[$s]->{'genome_end'} += $gap_len_genome;
				$segments->[$s]->{'est_end'} += $gap_len_est;
				for (my $fi = $f + 1; $fi < @{$features}; $fi++) {
					$features->[$fi]->{'genome_start'} += $gap_len_genome;
					$features->[$fi]->{'genome_end'} += $gap_len_genome;
					$features->[$fi]->{'est_start'} += $gap_len_est;
					$features->[$fi]->{'est_end'} += $gap_len_est;
				}
				for (my $si = $s + 1; $si < @{$segments}; $si++) {
					$segments->[$si]->{'genome_start'} += $gap_len_genome;
					$segments->[$si]->{'genome_end'} += $gap_len_genome;
					$segments->[$si]->{'est_start'} += $gap_len_est;
					$segments->[$si]->{'est_end'} += $gap_len_est;
				}
			}
		}

	}

}





=head1 Reading est2genome result.
 
_read_est2genome

Read the result of est2genome to Nazuna class object.
 
=cut
sub _read_est2genome {
	my $self = shift;
	$self->{'features'} = ();
	$self->{'segments'} = ();
	open(my $fh, '<', $self->{'align_file'}) or die 'Nazuna:: Cannot open est2genome file.';
	while (my $buff = <$fh>) {
		chomp($buff);
		# Read the segments informations(Intron and Exon positions).
		if ($buff =~ /^(Exon|\+Intron|\-Intron)/) {
			my $ft = {};
			if ($1 =~ /exon/i) {
				$ft->{'type'} = 'exon';
			} else {
				$ft->{'type'} = 'intron';
			}
			my @rds = split(/\s+/, $buff);
			$ft->{'genome_start'} = $rds[3];
			$ft->{'genome_end'} = $rds[4];
			$ft->{'est_start'} = $rds[6];
			$ft->{'est_end'} = $rds[7];
			push(@{$self->{'features'}}, $ft);
		}
		# Read the segments informations(Intron, Exon and Gaps positions).
		if ($buff =~ /^Segment/) {
			my $seg = {};
			my @rds = split(/\s+/, $buff);
			$seg->{'genome_start'} = $rds[3];
			$seg->{'genome_end'} = $rds[4];
			$seg->{'est_start'} = $rds[6];
			$seg->{'est_end'} = $rds[7];
			push(@{$self->{'segments'}}, $seg);
		}
		if ($buff =~ /^Note Best alignment is between (forward|reversed) est and (forward|reversed) genome, (and|but) splice sites imply (forward gene|REVERSED GENE)$/) {
			$self->{'header'} = $buff;
			if ($1 eq 'forward') {
				$self->{'est_strand'} = '+';
			} else {
				$self->{'est_strand'} = '-';
			}
			if ($2 eq 'forward') {
				$self->{'genome_strand'} = '+';
			} else {
				$self->{'genome_strand'} = '-';
			}
			if ($4 eq 'forward gene') {
				$self->{'strand'} = '+';
			} else {
				$self->{'strand'} = '-';
			}
		}
	}
	close($fh);
}



=head1 Reading nazuna result.
 
_read_nazuna

Read the result of nazuna to Nazuna class object.
 
=cut
sub _read_nazuna {
	my $self = shift;
	$self->{'features'} = ();
	$self->{'segments'} = ();
	$self->{'est_seq'} = '';
	$self->{'genome_seq'} = '';
	open(my $fh, '<', $self->{'align_file'}) or die 'Nazuna:: Cannot open est2genome file.';
	while (my $buff = <$fh>) {
		chomp($buff);
		# Read the segments informations(Intron and Exon positions).
		if ($buff =~ /^(Exon|\+Intron|\-Intron)/) {
			my $ft = {};
			if ($1 =~ /exon/i) {
				$ft->{'type'} = 'exon';
			} else {
				$ft->{'type'} = 'intron';
			}
			my @rds = split(/\s+/, $buff);
			$ft->{'genome_start'} = $rds[3];
			$ft->{'genome_end'} = $rds[4];
			$ft->{'est_start'} = $rds[6];
			$ft->{'est_end'} = $rds[7];
			push(@{$self->{'features'}}, $ft);
		}
		# Read the segments informations(Intron, Exon and Gaps positions).
		if ($buff =~ /^Segment/) {
			my $seg = {};
			my @rds = split(/\s+/, $buff);
			$seg->{'genome_start'} = $rds[3];
			$seg->{'genome_end'} = $rds[4];
			$seg->{'est_start'} = $rds[6];
			$seg->{'est_end'} = $rds[7];
			push(@{$self->{'segments'}}, $seg);
		}
		if ($buff =~ /^Note Best alignment is between (forward|reversed) est and (forward|reversed) genome, (and|but) splice sites imply (forward gene|REVERSED GENE)$/) {
			$self->{'header'} = $buff;
			if ($1 eq 'forward') {
				$self->{'est_strand'} = '+';
			} else {
				$self->{'est_strand'} = '-';
			}
			if ($2 eq 'forward') {
				$self->{'genome_strand'} = '+';
			} else {
				$self->{'genome_strand'} = '-';
			}
			if ($4 eq 'forward gene') {
				$self->{'strand'} = '+';
			} else {
				$self->{'strand'} = '-';
			}
		}

		if ($buff =~ /^ES/) {
			$self->{'est_seq'} .= substr($buff, 3);
		}
		if ($buff =~ /^GS/) {
			$self->{'genome_seq'} .= substr($buff, 3);
		}
	}
	close($fh);
}












=header1 Save the informations.
 The method of write_seq for saving the result of est2genome to Nazuna format.
 
 Nazuna Format:
 ------------------------------------------------
 Note Best alignment is between ....                    Same to est2genome headre.
 Exon	0	0	6119	13000	Genome	1	618	0	EST        Tab separater.
 +Intron	0	0	13001	20101	Genome		
 ...
 
 Span	0	0	6119	110000	Genome	1	1992	EST 0

 Segment	123	0	6119	13000	Genome	1	618	0	EST
 ...
 -----------------------------------------------
=cut
sub write_seq {
	my $self = shift;
	my $path = shift;

	open (my $fh, '>', $path) or die "Nazuna::ERROR: Cannot create file. $!\n";

	# header
	print $fh $self->{'header'} . "\n";
	
	# features
	my $max_len = length("$self->{'features'}->[-1]->{'genome_end'}");
	my $ft_exon = '%-10s %5d %4d %' . $max_len . 'd %' . $max_len . 'd Features %' .
						 $max_len .'d %' . $max_len .'d 0 Alignment EXON %-2d.' . "\n";
	my $ft_intron = '%-10s %5d %4d %' . $max_len . 'd %' . $max_len . 'd Features' . "\n";

	my $exon_num = 0;
	if ($self->{'est_strand'} eq '+') {
		$exon_num++;
	} else {
		$exon_num = (@{$self->{'features'}} + 1) / 2;
	}
	foreach my $ft (@{$self->{'features'}}) {
		if ($ft->{'type'} eq 'exon') {
			if ($self->{'est_strand'} eq '+') {
				print $fh sprintf($ft_exon, 'Exon', 100, 100, 
							$ft->{'genome_start'}, $ft->{'genome_end'},
							$ft->{'est_start'}, $ft->{'est_end'}, $exon_num++);
			} else {
				print $fh sprintf($ft_exon, 'Exon', 100, 100, 
							$ft->{'genome_start'}, $ft->{'genome_end'},
							$ft->{'est_start'}, $ft->{'est_end'}, $exon_num--);
			}
		} else {
			if ($self->{'strand'} eq '+') {
				print $fh sprintf($ft_intron, '+Intron', -20, 0,
							$ft->{'genome_start'}, $ft->{'genome_end'});
			} else {
				print $fh sprintf($ft_intron, '-Intron', -20, 0,
							$ft->{'genome_start'}, $ft->{'genome_end'});
			}
		}
	}
	
	# Span
	print $fh sprintf('Span           0    0 %' . $max_len . 'd %' . $max_len . 'd Alignment %'
				. $max_len . 'd %' . $max_len . 'd 0 Alignment' . "\n", 
				$self->{'features'}->[0]->{'genome_start'},
				$self->{'features'}->[-1]->{'genome_end'},
				$self->{'features'}->[0]->{'est_start'},
				$self->{'features'}->[-1]->{'est_end'});

	# segments.
	my $ft_seg = 'Segment    %5d %4d %' . $max_len . 'd %' . $max_len . 'd Segments %' . $max_len .'d %' . $max_len .'d 0 Segment.' . "\n";
	foreach my $seg (@{$self->{'segments'}}) {
		my $len = $seg->{'est_end'} - $seg->{'est_start'} + 1;
		print $fh sprintf ($ft_seg, $len, 100, $seg->{'genome_start'}, $seg->{'genome_end'},
						$seg->{'est_start'}, $seg->{'est_end'});
	}

	# seq
	my $seq = '';
	$seq = $self->{'est_seq'};
	if ($self->{'est_strand'} eq '-') {
		$seq = reverse($seq);
		$seq =~ tr/ACGTacgt/TGCAtgca/
	}
	$seq =~ s/\.|\-//g;
	for (my $i = 0; $i < length($seq); $i += 100) {
		print $fh 'ES ' . substr($seq, $i, 100) . "\n";
	}
	$seq = $self->{'genome_seq'};
	$seq =~ s/\.|\-//g;
	for (my $i = 0; $i < length($seq); $i += 100) {
		print $fh 'GS ' . substr($seq, $i, 100) . "\n";
	}
	close($fh);
}




1;
