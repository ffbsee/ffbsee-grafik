#!/usr/bin/perl
# Perl Module laden
use JSON;                       # Zum verwenden der nodes.json | wenn nicht installiert: 'sudo cpan install JSON' eingeben!
use Data::Dumper;               # Zum testen, wie die nodes.json aussieht, wird zwar nicht benötigt, ist aber extrem praktisch beim debuggen und entwickeln von neuen Features...
use LWP::Simple;                # For getting the json
use strict;                     # Good practice
use warnings;                   # Good practice

# ... und für die FFNodes:
our @node_name;   # Global Array for Node-Names
our $anzahl;      # How many nodes exist
our $clients;     # How many Clients are connected...
our $channelName = "ffbsee"; #Operate in this channel !1ELF
our $secoundChannel = "see-base-talk"; #A 2. channel for testing...
our $url = "http://vpn1.ffbsee.de/nodes.json"; #Link zur nodes.json
our $path = "/var/www/modes.json"; #Pfad zur nodes.json
our $ffnodes_json;

our $script_location = "internet";

our $json_text;
sub nodes{
    my $name;
    if ($script_location eq "internet"){
        $json_text = get( $url );   # Download the nodes.json
    }
    if ($script_location eq "vpn"){
        open(DATEI, "/var/www/nodes.json") or die "Datei wurde nicht gefunden\n";
            my $daten;
            while(<DATEI>){
                $daten = $daten.$_;
            }
        close (DATEI);
        $json_text = $daten;
    }
    my $json        = JSON->new->utf8; #force UTF8 Encoding
    $ffnodes_json = $json->decode( $json_text ); #decode nodes.json
    $anzahl = 0; #Resette Anzahl auf 0
#   print Dumper $ffnodes_json;
    my $json_list = $ffnodes_json->{"nodes"}->[$anzahl]->{"name"};
    my $json_list_test = $ffnodes_json->{"nodes"}->[$anzahl]->{"id"};
    while (defined $json_list_test){
        $json_list = $ffnodes_json->{"nodes"}->[$anzahl]->{"name"} ; # Suche nach "name" in der node.json
        if ( not defined $json_list){ #Falls der $name nicht gesetzt wurde!
            $json_list = $ffnodes_json->{"nodes"}->[$anzahl]->{"id"};
        }
        $anzahl = $anzahl + 1;
        $json_list_test = $ffnodes_json->{"nodes"}->[$anzahl]->{"id"};
        push(@node_name, "$json_list, "); #Füge die Node-Names dem Array zu.
    }
    @node_name = sort @node_name;
#    print @node_name;
#    print $anzahl;
}

nodes();
