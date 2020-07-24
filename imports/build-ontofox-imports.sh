#!/bin/bash

# This script takes as argument a file that lists OBO ontology term IRIS, one per line
# It then builds an Ontofox request file for each of the involved ontologies,
#  and then generates a request to Ontofox, downloading an OWL file
#
# Here is an example of what the input file's contents might look like:
#     
#     http://purl.obolibrary.org/obo/OGMS_0000116
#     http://purl.obolibrary.org/obo/OBI_0000968
#     http://purl.obolibrary.org/obo/OBI_0000011
#     http://purl.obolibrary.org/obo/OBI_0000374
#     http://purl.obolibrary.org/obo/CHEBI_30216
#     http://purl.obolibrary.org/obo/CHEBI_30225
#
# The output would be:
# 1) Three Ontofox files, one each for OGMS, OBI, and CHEBI
# 2) Three OWL files, each the result of posting its corresponding file to Ontofox


if $1
then
    terms=$1
else
    terms=../radont-terms.txt
    printf "No input filename specifed, so trying $terms\n"
fi


function generate_ontofox(){
    fname="$1-ontofox-input.txt"
    printf "Generating Ontofox request file for ontology $o, $fname\n"

    printf "[URI of the OWL(RDF/XML) output file]\n\n" > $fname

    printf "[Source ontology]\n" >> $fname
    printf "$o\n\n" >> $fname

    printf "[Low level source term URIs]\n" >> $fname
    # get, loop through the terms we're importing for this ontology, and write them to the file
    for t in $(grep $o $terms);
    do
	printf "$t\n" >> $fname
    done;

    # BFO 0000001 works as the top level source term
    printf "\n[Top level source term URIs and target direct superclass URIs]\n" >> $fname
    printf "http://purl.obolibrary.org/obo/BFO_0000001\n" >> $fname


    printf "\n[Source term retrieval setting]\nincludeAllIntermediates\n\n" >> $fname
    printf "[Source annotation URIs]\nincludeAllAnnotationProperties\n\n" >> $fname
    printf "[Source annotation URIs to be excluded]" >> $fname
}




# get, loop through ontology abbreviations. E.g. CHEBI, OGMS, etc.
for o in $(sed 's/http:\/\/purl.obolibrary.org\/obo\///' $terms | sed 's/\_.*//' | sort | uniq);	 
do
    # build the ontofox request files
    generate_ontofox $o

    # generate the web request and save to an OWL file
    printf "Requesting OWL file from Ontofox for ontology $o, saving as $fname.owl\n"
    curl -s -F file=@"$fname" -o $fname.owl http://ontofox.hegroup.org/service.php
done; 



