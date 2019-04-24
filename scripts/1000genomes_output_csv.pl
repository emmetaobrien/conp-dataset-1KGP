#!/usr/bin/perl
#
#  1000genomes_output_txt.pl - writing 1000 Genomes Project metadata from MySQL
#                              as csv file - will be basis for a DATS JSON extractor
#                 - EOB - Mar 18 2019
#
# usage: 1000genomes_output_txt.pl
#
########################################

use DBI;
use DBD::mysql;

# connect to local database

my $dsn = 'dbi:mysql:genomes_metadata:localhost:3306';
my $user = 'emmet';
my $password = 'neuro';
my $dbh = DBI->connect($dsn, $user, $password) or die ("Can't connect to database");

# initialise constants

$output_filename = "/home/emmet/1000genomes_data/1000genomes_metadata.csv";

open (OUTPUT_CSV, ">$output_filename") || die "Can't open $output_filename to write\n";

# write list of columns as headers

$sql_retrieve_header  = "SELECT column_name FROM information_schema.columns";
$sql_retrieve_header .= " WHERE table_name = '1000genomes'";
$exec_select = $dbh->prepare($sql_retrieve_header);
$exec_select->execute();
@header = $exec_select->fetchrow_array;
print OUTPUT_CSV $header[0];
while (@header = $exec_select->fetchrow_array) {
	print OUTPUT_CSV ", $header[0]";
}
print OUTPUT_CSV "\n";

# retrieve each row and write

$sql_retrieve_genome  = "SELECT * FROM 1000genomes ORDER BY chromosome";  
$exec_select = $dbh->prepare($sql_retrieve_genome);
$exec_select->execute();
while (@row = $exec_select->fetchrow_array) {
	print OUTPUT_CSV join(", ",@row), "\n";
}

close (OUTPUT_CSV);

exit();
