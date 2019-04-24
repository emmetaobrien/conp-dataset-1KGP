#!/usr/bin/perl
#
#  1000genomes_output_BioSchema_json.pl - writing 1000 Genomes Project metadata from MySQL
#                                         as JSON files in BioSchema format
#                                       - EOB - Apr 04 2019
#
# usage: 1000genomes_output_BioSchema_json.pl $home_directory
#
########################################

use DBI;
use DBD::mysql;

# connect to local database

my $dsn = 'dbi:mysql:genomes_metadata:localhost:3306';
my $user = 'emmet';
my $password = 'neuro';
my $dbh = DBI->connect($dsn, $user, $password) or die ("Can't connect to database");

# initialise project-level constants

# and remember to spell organisation with a 'z' in this context !

$home_directory       = $ARGV[0];
$species_name         = "Homo sapiens";
$species_id           = "9606";   # NCBI taxonomic identifier for H. sapiens
$species_URL          = "https://www.ncbi.nlm.nih.gov/taxonomy/$species_id";
$project_name         = "1000 Genomes Project";
$project_abbr         = "1KGP";
$data_host            = "Canadian Centre for Computational Genomics";
$publication_doi      = "https://doi.org/10.1038/nature15393";
$publication_id_short = "nature15393";
$publication_title    = "A global reference for human genetic variation";
$publication_ref      = "Nature 526 68-74"; 
$publication_date     = "01 October 2015";
$distribution_URL     = "https://datahub-khvul4ng.udes.genap.ca";
$master_file_brief    = $project_abbr."_BioSchema_master.json";
$master_filename      = "$home_directory/1000genomes_data/".$master_file_brief;

# retrieve each row from database and write dataset-level JSON
# for now we are selecting only the columns that contain data in the 1KGP dataset

@dataset_id_array    = ();
@dataset_name_array  = ();
@dataset_url_array   = ();
@dataset_desc_array  = ();
$dataset_array_count = 0;

$sql_retrieve_genome  = "SELECT chromosome, project_date, resource_link,";
$sql_retrieve_genome .=       " reference_sequence_link, number_of_SNPs, number_of_indels";
$sql_retrieve_genome .=  " FROM 1000genomes ORDER BY chromosome";  
$exec_select = $dbh->prepare($sql_retrieve_genome);
$exec_select->execute();
while (@row = $exec_select->fetchrow_array) {
	write_dataset(@row);
	$chromosome = $row[0];
	$dataset_id_array[$dataset_array_count]   = $project_abbr."_".$chromosome.".json";
	$dataset_url_array[$dataset_array_count]  = $resource_link;
	$dataset_name_array[$dataset_array_count] = $chr_name;
	$dataset_desc_array[$dataset_array_count] = $description;
	++$dataset_array_count;
}


# write master dataset 

write_master();

exit();

# functions

# write_dataset : write a dataset JSON file for a 1000 Genomes chromosome file 

sub write_dataset {
	
	($chromosome, $date, $resource_link, $refseq_link, $SNP_count, $indel_count) = @_;
	
	$dataset_identifier = $project_abbr."_BioSchema_".$chromosome;

	$dataset_filename = "$home_directory/1000genomes_data/".$dataset_identifier.".json";

	my $dataset_text = "{\n";

	open (DATASET_JSON, ">$dataset_filename")|| die "Cannot open $dataset_filename for write\n";

	# generate a human-friendly name from the chromosome ID

	$chromosome =~/chr(.*)/;
	$chr_significant = $1;
	if ($chr_significant eq 'MT') {
		$chr_name = "Mitochondrial genome";
	}
	else {
		$chr_name = "Chromosome $chr_significant";
	}
	
 	$description = "Variant call format file containing information about sequence polymorphisms on $chr_name in 1092 human genomes";

	# mandatory fields

	$dataset_text .= "\t\"description\": \"$description\",\n";
        $dataset_text .= "\t\"identifier\": \"$dataset_identifier\",\n";
	$dataset_text .= "\t\"keywords\" :\"genomics\",\n";
	$dataset_text .= "\t\"name\": \"$project_name"." "."$chr_name\",\n";
	$dataset_text .= "\t\"url\": \"$resource_link\",\n";


	# recommended fields

	$dataset_text .= "\t\"includedInDataCatalog\": \"$master_file_brief\",\n";
	$dataset_text .= "\t\"creator\": \"$project_name\",\n";
	$dataset_text .= "\t\"version\": \"1.0\",\n";
	$dataset_text .= "\t\"license\": \"to be determined\",\n";

	# calculated variables

	$dataset_text .= "\t\"variableMeasured\": [\n";
	$dataset_text .= "\t\t{\n"; 
	$dataset_text .= "\t\t\t\"name\": \"Count of Single Nucleotide Polymorphism variants\",\n";
	$dataset_text .= "\t\t\t\"value\": \"$SNP_count\"\n";
	$dataset_text .= "\t\t},\n"; 
	$dataset_text .= "\t\t{\n"; 
	$dataset_text .= "\t\t\t\"name\": \"Count of single-nucleotide insertion and deletion events\",\n";
	$dataset_text .= "\t\t\t\"values\": \"$indel_count\"\n";
	$dataset_text .= "\t\t}\n";
	$dataset_text .= "\t]\n";

	$dataset_text .= "}\n"; 
	print DATASET_JSON $dataset_text;
	close DATASET_JSON;

}

# write_master: write a master JSON file for the whole dataset

sub write_master {
	
	my $master_text = "{\n";

	open (MAST_JSON, ">$master_filename")|| die "Cannot open $master_filename for write\n";


	$master_text .= "\t\"description\": \"Variant call format files containing information about sequence polymorphisms in 1092 human genomes\",\n";
	$master_text .= "\t\"keywords\" :\"genomics\",\n";
	$master_text .= "\t\"name\": \"$project_name\",\n";
	$master_text .= "\t\"provider\": \"$data_host\",\n";
	$master_text .= "\t\"url\": \"$distribution_URL\",\n";

        $master_text .= "\t\"identifier\": \"$project_abbr\",\n";
	$master_text .= "\t\"license\": \"to be determined\",\n";
	$master_text .= "\t\"sourceOrganization\":\"$project_name\",\n";  # happens to be the same in this case

	@date_now     = localtime(); # reformat this to a date format JSON likes:
	$date_out     = ($date_now[5]+1900)."-".sprintf("%02d",$date_now[4]+1);
	$date_out    .=  "-".sprintf("%02d",$date_now[3])." ";  # YYYY-MM-DD
	$date_out    .= sprintf("%02d",$date_now[2]).":";
	$date_out    .= sprintf("%02d",$date_now[1]).":";
	$date_out    .= sprintf("%02d",$date_now[0]);      # hh:mm:ss
	$master_text .= "\t\"date\": \"$date_out\",\n";

	# publication info

	$master_text .= "\t\"citation\": \"$project_name; $publication_title, $publication_ref, $publication_date, $publication_id_short, $publication_doi\",\n";

	# taxonomic information

	$master_text .= "\t\"about\": {\n";
	$master_text .= "\t\t\"name\":\"$species_name\",\n";
	$master_text .= "\t\t\"url\":\"$species_URL\"\n";
	$master_text .= "\t},\n";
	
	# list subdatasets with required fields

	$master_text .= "\t\"dataset\": [\n";
	$temp_counter = 0;
	while ($temp_counter < ($dataset_array_count)) {
		$master_text .= "\t\t{\n";
		$master_text .= "\t\t\t\"identifier\": \"$dataset_id_array[$temp_counter]\",\n";
		$master_text .= "\t\t\t\"name\":\"$dataset_name_array[$temp_counter]\",\n";
		$master_text .= "\t\t\t\"keywords\":\"genomics\",\n";
		$master_text .= "\t\t\t\"description\": \"$dataset_desc_array[$temp_counter]\",\n";
		$master_text .= "\t\t\t\"url\": \"$dataset_url_array[$temp_counter]\",\n";
		
		$master_text .= "\t\t}";
		unless ($temp_counter == $dataset_array_count - 1) {
			$master_text .= ",";  # comma needed after every entry except the last
		}
		$master_text .= "\n";

		++$temp_counter;
	}

	$master_text .= "\t]\n";

	$master_text .= "}\n";
	print MAST_JSON $master_text;
	close MAST_JSON;

}


