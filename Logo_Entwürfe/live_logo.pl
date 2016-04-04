#! /usr/bin/perl

#	Dies ist ein Perl-Script, dass für den Webserver gedacht ist.
#	Sobald es etwas mehr hermacht, könnte man es als live-Map oder
#	Echtzeitlogo oder vergleichbares in der Webseite einbinden.
#
#	Dieses Script generiert bisher noch ein statisches SVG in einer HTML  Webseite.
#	Es wäre schön, wenn es sich mit der Zeit zu einem animierten SVG weiterentwickelt!


use JSON;                       # Zum verwenden der nodes.json
use LWP::Simple;                # Zum testen, wie die nodes.json aussieht, wird aber gerade nicht benötigt...
use Data::Dumper;				# Ausgabe der json zum testen (produktiv nicht benoetigt)
use strict;                     # Good practice
use warnings;                   # Good practice

our $author = "L3D";
our $title = "bodensee.freifunk.net";
our $svg_content;
our $style = 
"
body {background-color:transparent;}
p {color:blue;}

 

";
print "Content-type: text/html\n\n<!DOCTYPE html>\n";
print "<html lang=\"de\">\n<head>\n\t\n\t<title>$title</title>\n<meta charset=\"UTF-8\">\n<meta name=\"description\" content=\"A ffbsee logo - written in perl\">\n<meta name=\"author\" content=\"$author\">\n\n<style>$style</style>\n</head>\n\n<body>\n";

print '<div></div>';


#important Variables:
our $channelName = "ffbsee"; #Operate in this channel !1ELF
our $secoundChannel = "see-base-talk"; #A 2. channel for testing...
our $url = "https://vpn3.ffbsee.de/nodes.json"; #Pfad zur nodes.json


our @node_name;   # Global Array for Node-Names
our $anzahl_nodes;      # How many nodes exist
our $clients;     # How many Clients are connected...
my $json_text = get( $url );   # Download the nodes.json
my $json        = JSON->new->utf8; #force UTF8 Encoding
our $nodes_json_for_perl = $json->decode( $json_text ); #decode nodes.json
		
nodes();

#Hier werden die Informationen aus der nodes.json geholt...
sub nodes{
		$anzahl_nodes = 0; #Resette Anzahl auf 0
		my $anzanhl_korrektur = 0;
		#		print Dumper $nodes_json_for_perl;
		my $json_list = $nodes_json_for_perl->{"nodes"}->[$anzahl_nodes]->{"name"};
		while (defined $json_list){
                $json_list = $nodes_json_for_perl->{"nodes"}->[$anzahl_nodes]->{"name"} ; # Suche nach "name" in der node.json
				if ( not defined $json_list){ #Falls der $name nicht gesetzt wurde!
				$anzahl_nodes = $anzahl_nodes + 1;
				$anzanhl_korrektur = $anzanhl_korrektur + 1;
				$json_list = $nodes_json_for_perl->{"nodes"}->[$anzahl_nodes]->{"name"};
						if ( not defined $json_list){ #Falls der $name nicht gesetzt wurde!
						$anzahl_nodes = $anzahl_nodes + 1;
						$anzanhl_korrektur = $anzanhl_korrektur + 1;
						$json_list = $nodes_json_for_perl->{"nodes"}->[$anzahl_nodes]->{"name"};	
						}
				}
				else {
						$anzanhl_korrektur = 0;
						push(@node_name, "$json_list <br/>\n"); #Füge die Node-Names dem Array zu.
						$anzahl_nodes = $anzahl_nodes + 1;
				}
		}
		$anzahl_nodes = $anzahl_nodes - $anzanhl_korrektur;
		@node_name = sort @node_name;
}
#print "Es sind $anzahl_nodes Nodes online<br/>\n";
#print @node_name;
#print "\n<br/><br/><br/><br/><br/><br/><br/>\n";






# Vectorgrafik:
our $svg_width = "230.0mm";
our $svg_height = "230.0mm";
our $svg_viewbox = "12.7 42.45 1.7 1.7";
our $svg_id = "l3d-svg1";
our $svg_docname = "ffbsee.svg";
our $svg_circle_style = 'fill:#ffffff;fill-opacity:0.01337';#	;filter:url(#filter-circle01)
our $svg_circle_style2 = 'fill:#dc0067;fill-opacity:0.3';
our $svg_circle_style3 = 'fill:#dc0067;fill-opacity:0.1';
our $svg_circle_style4 = 'fill:#dc0067;fill-opacity:1';
our $svg_circle_radius = "0.0073";
our $svg_circle_radius2 = "0.0038";
our $svg_circle_radius3 = "0.006";
our $svg_circle_radius4 = "0.0023";
#Ebene 2:
our $svg_circle_inside_style = "fill:none;stroke:#de2c68;stroke-width:0.02;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1";
our $svg_circle_inside_cx = "13.542";
our $svg_circle_inside_cy = "43.30";
our $svg_circle_inside_stroke_miterlimit = "4.0";
our $svg_circle_inside_rx = "0.64";
our $svg_circle_inside_ry = "0.64";
our $svg_circle_outside_style = "fill:none;stroke:#de2c68;stroke-width:0.1024;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1";
our $svg_circle_outside_cx = "13.542";
our $svg_circle_outside_cy = "43.30";
our $svg_circle_outside_stroke_miterlimit = "4.0";
our $svg_circle_outside_rx = "0.78";
our $svg_circle_outside_ry = "0.78";
our $geo_nodes_percent_y = "1.442";
our $geo_nodes_mv_y = "112.20";
#Animation:
our $animate_svg = "false";
sub svg_animate {
  $svg_content .='
  
  <animate attributeName="viewBox"
           values="12.0 42.45 1.7 1.7;12.9 42.45 1.7 1.7;12.7 42.55 1.7 1.7; 12.7 41.45 1.7 1.7"
           begin="2s" 
           dur="4s"
           repeatCount="indefinite"
           keyTimes="0; 0.1; 0.1; 1"
           fill="freeze"/>
';
}

# Hier wird das SVG "generiert":
our $inkscape_header = "\n<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<!-- Created by $author with perl -->\n\n";
our $inkscape_meta;
$inkscape_meta .= "<svg\n   xmlns:dc=\"http://purl.org/dc/elements/1.1/\"\n   xmlns:cc=\"http://creativecommons.org/ns#\"\n   xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n   xmlns:svg=\"http://www.w3.org/2000/svg\"\n   xmlns=\"http://www.w3.org/2000/svg\"\n   xmlns:sodipodi=\"http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd\"\n   xmlns:inkscape=\"http://www.inkscape.org/namespaces/inkscape\"";
$inkscape_meta .= "   width=\"$svg_width\"\n   height=\"$svg_height\"\n   viewBox=\"$svg_viewbox\"\n";
$inkscape_meta .= "   id=\"$svg_id\"   version=\"1.1\"   inkscape:version=\"0.91 r13725\"   sodipodi:docname=\"$svg_docname\">";
#Filter:
$inkscape_meta .='
  <defs
     id="defs4">
  </defs>';
$inkscape_meta .= <<EOF;
  <sodipodi:namedview
     id="base"
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1.0"
     inkscape:pageopacity="0.0"
     inkscape:pageshadow="2"
     inkscape:zoom="0.42"
     inkscape:cx="-90.714286"
     inkscape:cy="520"
     inkscape:document-units="px"
     inkscape:current-layer="layer1"
     showgrid="false"
     inkscape:window-width="1920"
     inkscape:window-height="1080"
     inkscape:window-x="-8"
     inkscape:window-y="-8"
     inkscape:window-maximized="1" />
  <metadata
     id="metadata7">
    <rdf:RDF>
      <cc:Work
         rdf:about="">
        <dc:format>image/svg+xml</dc:format>
        <dc:type
           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <dc:title>bodensee.freifunk.net</dc:title>
      </cc:Work>
    </rdf:RDF>
  </metadata>
EOF

print $inkscape_header;
print $inkscape_meta;
if ( $animate_svg eq "true") {
svg_animate();
}
sub svg_bsee{
  #Ebene 1:
  $svg_content .="\n  <g\n     inkscape:groupmode=\"layer\"\n     id=\"layer1\"\n     inkscape:label=\"Bodensee\">\n";
#Bodensee
  $svg_content .= '
     <path
       inkscape:connector-curvature="0"
       id="bodensee"
       d="m 13.683437,43.735673 c -0.003,-0.0014 -0.006,-0.003 -0.0064,-0.0035 -4.46e-4,-5.69e-4 -0.0032,-0.0041 -0.0061,-0.008 -0.0062,-0.0081 -0.01202,-0.01281 -0.01831,-0.01499 -0.0028,-9.94e-4 -0.0052,-0.0025 -0.0063,-0.0046 -8.11e-4,-0.0017 -0.0042,-0.0044 -0.0072,-0.0059 -0.0062,-0.0033 -0.0106,4.6e-4 -0.0113,-0.0066 -9.09e-4,-0.004 0.0099,-0.0027 0.0087,-0.01138 -0.0069,-0.0055 -0.02163,-0.0021 -0.03036,-0.0115 -0.0019,-0.002 -0.0038,-0.0038 -0.0045,-0.0039 -5.14e-4,-3.5e-5 -0.0048,-0.0042 -0.009,-0.0095 -0.0048,-0.0053 -0.01061,-0.01089 -0.01218,-0.01234 -0.0046,-0.0035 -0.0061,-0.0095 -0.0047,-0.01723 6.26e-4,-0.003 9.18e-4,-0.0072 7.19e-4,-0.0097 -3.66e-4,-0.0037 -0.0012,-0.0051 -0.0059,-0.0088 -0.003,-0.0023 -0.0063,-0.0043 -0.0072,-0.0043 -0.0011,-8.7e-5 -0.002,-5.53e-4 -0.0022,-0.0011 -2.71e-4,-5.18e-4 -0.0049,-0.0036 -0.0108,-0.0069 -0.0054,-0.0032 -0.01088,-0.0066 -0.01156,-0.0076 -7.64e-4,-9.62e-4 -0.002,-0.0017 -0.0029,-0.0019 -0.0011,-8.9e-5 -0.0028,-8.26e-4 -0.004,-0.0016 -0.0099,-0.0065 -0.01472,-0.01035 -0.02009,-0.01565 -0.01384,-0.0134 -0.01379,-0.0135 -0.02829,-0.02132 -0.0048,-0.0024 -0.02195,-0.0127 -0.03117,-0.01831 -0.0044,-0.0028 -0.01103,-0.0094 -0.01383,-0.0099 -0.005,-0.001 -0.0142,-0.0024 -0.01559,-0.0044 -7.19e-4,-0.0013 -0.01489,-0.0098 -0.01684,-0.0099 -7.24e-4,-5e-5 -0.0048,-0.002 -0.0085,-0.0043 -0.0081,-0.0045 -0.01351,-0.01114 -0.01466,-0.01724 -4.44e-4,-0.002 -0.0014,-0.0047 -0.0022,-0.0057 -0.0024,-0.0028 -0.01533,-0.0039 -0.02195,-0.0018 -0.0123,0.0047 -0.01464,0.0049 -0.02193,0.0029 -0.0036,-9.71e-4 -0.01231,-0.0041 -0.01893,-0.0051 -0.0049,-0.0022 -0.0083,-0.0024 -0.013,-0.0044 -0.0041,-0.0035 -0.0079,-0.0017 -0.01136,-0.0013 -0.0023,2.87e-4 -0.0093,-0.0042 -0.028,-0.01224 -0.02999,-0.0024 -0.0239,0.0049 -0.05365,-0.0038 -0.0028,0.0012 -0.0077,0.0027 -0.01086,0.0032 -0.0066,0.0011 -0.01205,0.0068 -0.01892,0.0063 -0.0042,0.0045 -0.01351,0.01269 -0.01651,0.01278 -0.0019,2.38e-4 -0.0053,0.0015 -0.0074,0.0027 -0.0021,0.0013 -0.0045,0.0023 -0.0052,0.0022 -7.25e-4,-4e-5 -0.003,6.6e-4 -0.0052,0.0018 -0.0021,0.0011 -0.0055,0.0019 -0.0077,0.0017 -0.0027,-1.88e-4 -0.0051,5.1e-4 -0.0077,0.0022 -0.0023,0.0017 -0.0054,0.0026 -0.0087,0.0028 -0.0031,1.05e-4 -0.0087,-8.2e-4 -0.0104,3.8e-4 -0.0038,0.0031 -0.01118,0.0042 -0.01596,4.2e-4 -0.0015,-0.0014 -0.005,-0.002 -0.0067,-0.0025 -0.0017,-5e-4 -0.0077,-0.0014 -0.0086,-0.0026 -0.004,-3.4e-4 -0.0144,-3.8e-4 -0.0172,-0.0011 -0.0093,-0.0027 -0.01776,-0.0093 -0.02662,-0.01394 0.0048,5e-4 0.02346,0.0088 0.03027,0.0099 0.0047,7.06e-4 0.0198,-10e-4 0.02665,0.0016 0.0048,0.0021 0.0086,0.0033 0.01974,-0.0014 0.005,-0.0014 0.01354,-0.0079 0.01771,-0.0085 0.0039,-8.57e-4 0.0075,-0.0019 0.0085,-0.0026 7.14e-4,-6.4e-4 0.0022,-0.0011 0.0031,-10e-4 0.0011,8e-5 0.0043,-0.0019 0.0075,-0.0045 0.0033,-0.0025 0.0077,-0.0054 0.01041,-0.0062 0.0025,-0.001 0.0051,-0.0021 0.0054,-0.0028 4.52e-4,-6.16e-4 0.01068,-0.0069 0.0165,-0.0098 0.006,-0.0036 0.0084,-0.01259 0.017,-0.01565 0.0084,0.0014 0.01794,8.8e-4 0.01654,-6.2e-4 -0.0014,-0.0014 -0.0035,-0.0034 -0.0045,-0.0045 -8.36e-4,-0.0013 -0.0037,-0.0023 -0.0059,-0.003 -0.0023,-5.97e-4 -0.0052,-0.002 -0.0064,-0.0033 -0.0013,-0.0013 -0.004,-0.0026 -0.0058,-0.0031 -0.0019,-5.5e-4 -0.0041,-0.0016 -0.005,-0.0025 -0.001,-8.31e-4 -0.0035,-0.0022 -0.0058,-0.0031 -0.0023,-9.37e-4 -0.0049,-0.0022 -0.0057,-0.003 -0.0014,-0.0013 -0.0068,-0.0048 -0.01407,-0.0093 -0.0024,-0.0014 -0.0052,-0.0041 -0.0064,-0.0061 l -0.002,-0.0034 0.0051,-0.0039 c 0.0055,-0.0044 0.01835,-0.0084 0.02289,-0.007 0.01262,0.0042 0.01348,0.0046 0.02598,0.01252 0.0081,0.0055 0.01292,0.0065 0.01382,0.0035 1.2e-4,-0.0016 -0.0079,-0.0096 -0.01,-0.0098 -0.0011,-7.7e-5 -0.0097,-0.0072 -0.0112,-0.009 -8.36e-4,-0.0013 -6.2e-4,-0.0021 0.0015,-0.0043 0.0013,-0.0014 0.0032,-0.0026 0.0039,-0.0026 0.0015,1.04e-4 0.0094,0.0048 0.0143,0.0085 0.0068,0.0053 0.01647,0.01117 0.0292,0.01835 0.0029,0.0017 0.0079,0.0044 0.01101,0.0063 0.0031,0.0018 0.0064,0.0033 0.0071,0.0034 7.22e-4,5.1e-5 0.003,0.0013 0.0052,0.0025 0.0021,0.0013 0.0048,0.0024 0.0056,0.0025 8.68e-4,5.4e-5 0.0034,0.0013 0.0054,0.0026 0.002,0.0013 0.0058,0.003 0.0082,0.004 0.0098,0.0035 0.02584,0.01963 0.02603,0.0256 -3.7e-4,0.0048 -0.004,0.0057 -0.01604,0.004 l -0.01138,-0.0016 -0.0051,-0.0054 c -0.009,-0.0095 -0.01072,-0.0105 -0.01907,-0.01243 -0.01023,-0.0023 -0.01015,-0.0024 -0.01046,0.0029 -5.38e-4,0.0075 8.62e-4,0.01009 0.0064,0.01181 0.0027,9.58e-4 0.0057,0.0025 0.0065,0.0033 10e-4,9.15e-4 0.0046,0.0024 0.0081,0.0031 0.0036,8.43e-4 0.0079,2.8e-4 0.0092,8.8e-4 0.0017,8.31e-4 0.0045,0.0014 0.0066,10e-4 0.0041,-5.66e-4 0.0071,4.54e-4 0.01175,-8e-5 0.0131,-8.71e-4 0.01635,0.0012 0.02069,0.01315 0.0031,0.0076 0.0047,0.01002 0.0081,0.01235 l 0.0062,10e-4 0.0046,8e-5 c 0.0035,-0.0011 0.0076,-0.0029 0.0091,-0.004 0.0023,-0.0019 0.0039,-0.0019 0.01413,-9.07e-4 0.0084,-6.7e-4 0.01558,-0.0021 0.01809,-7.4e-4 0.0056,5.02e-4 0.01222,0.0019 0.0153,9.41e-4 0.0022,-6.11e-4 0.01218,-0.0021 0.0097,-0.0075 -0.0013,-0.0025 -0.0017,-0.0068 -0.002,-0.0089 -4.99e-4,-0.0052 -0.0049,-0.0091 -0.01256,-0.01635 -0.0036,-0.0033 -0.0068,-0.0073 -0.0079,-0.0096 -7.75e-4,-0.0021 -0.0023,-0.0051 -0.0037,-0.0063 -0.0024,-0.0027 -0.0026,-0.0039 -0.0043,-0.02507 -6.66e-4,-0.0085 -0.0032,-0.01284 -0.0093,-0.01862 -0.01592,-0.013 -0.01597,-0.01286 -0.02361,-0.01377 -0.0084,-0.0012 -0.01279,-0.0035 -0.02027,-0.01175 -0.0056,-0.0057 -0.01103,-0.0094 -0.02321,-0.01517 -0.0055,-0.0026 -0.01037,-0.0051 -0.01119,-0.0057 l -0.0041,-0.0033 c -0.0034,-0.0026 -0.0355,-0.03177 -0.03496,-0.0336 3.1e-5,-4.37e-4 -0.01454,-0.0169 -0.01584,-0.0179 -0.0029,-0.0023 -0.0095,-0.008 -0.01064,-0.01411 0,0 -0.0013,-0.0091 0.0096,-0.01346 0.005,-0.0018 0.01286,-2.8e-4 0.01946,0.0028 0.005,0.006 0.01882,0.01598 0.02803,0.02435 0.01012,0.006 0.01253,0.0084 0.01806,0.0131 0.0016,0.0015 0.0035,0.0043 0.0051,0.0049 0.0015,5.78e-4 0.0037,0.0019 0.0049,0.0031 0.0013,0.0013 0.0038,0.0024 0.0054,0.0031 0.0017,4.98e-4 0.0041,0.0022 0.0054,0.0037 0.0013,0.0017 0.0028,0.0029 0.0033,0.0029 5.7e-4,4.3e-5 0.0044,0.0037 0.0084,0.0082 0.01274,0.01371 0.01183,0.01343 0.02023,0.01515 0.0049,8.01e-4 0.01086,4e-4 0.01236,0.0019 0.0015,0.0013 0.0054,0.0044 0.0062,0.0045 7.24e-4,5e-5 0.0047,0.0014 0.0068,0.0029 0.0096,0.0076 0.01659,0.0095 0.01849,0.0097 7.25e-4,4e-5 0.003,0.0014 0.0052,0.0031 0.0021,0.0016 0.005,0.003 0.0065,0.0032 0.0015,1.04e-4 0.0038,0.0013 0.0052,0.0025 0.0013,0.0013 0.0034,0.0023 0.0043,0.0024 0.0097,0.0057 0.0096,0.01074 0.0084,0.01949 1.67e-4,0.0022 4e-6,0.006 6e-4,0.0086 6.83e-4,0.0028 0.0035,0.0071 0.0038,0.0094 2.55e-4,0.0034 0.0019,0.0059 0.0081,0.01234 0.0041,0.0047 0.0099,0.01005 0.01229,0.01187 0.0024,0.0019 0.0089,0.0039 0.012,0.0063 0.0026,0.0023 0.0039,0.0067 0.0056,0.0079 0.002,0.0013 0.0057,0.0041 0.008,0.006 0.0112,0.0073 0.01386,0.01011 0.02692,0.01374 0.0011,7.9e-5 0.0047,0.0019 0.0082,0.0039 0.0034,0.002 0.0057,0.0011 0.0064,0.0012 6.59e-4,4.7e-5 0.0019,0.0012 0.0029,0.0023 8.36e-4,0.0013 0.0034,0.0026 0.0056,0.0033 0.0021,5.47e-4 0.0064,0.0025 0.0087,0.0042 0.0064,0.0039 0.01362,0.0042 0.02266,3.37e-4 0.0033,-0.0013 0.0071,-0.0023 0.0083,-0.0022 0.0011,6.5e-5 0.0037,-5.77e-4 0.0061,-0.0017 0.005,-0.0021 0.01518,-0.0035 0.02592,-0.0028 0.0093,5.49e-4 0.01779,0.0066 0.02032,0.01132 0.0016,0.0027 0.005,0.0043 0.01996,0.0095 0.01888,0.0064 0.01982,0.0067 0.02509,0.0055 0.0027,-5.54e-4 0.0063,-8.05e-4 0.0082,-6.85e-4 0.0057,3.92e-4 0.01244,0.01296 0.0205,0.02247 0.0072,0.0087 0.0079,0.0097 0.01057,0.02099 0.002,0.008 0.0057,0.01101 0.0074,0.01246 0.0026,0.002 0.0084,-0.0044 0.0099,0.0052 9.55e-4,0.0055 0.0012,0.01124 0.0063,0.01683 0.0054,0.0061 0.0076,0.0079 0.01584,0.01328 0.0065,0.0043 0.02227,0.0073 0.03047,0.0031 0.0043,-0.0023 0.0061,-0.0027 0.0087,-0.0019 0.0041,0.0011 0.0097,0.0073 0.01044,0.0115 2.69e-4,0.0016 0.0015,0.0038 0.0023,0.0052 10e-4,0.0013 0.002,0.0026 0.0018,0.0034 -1.97e-4,0.0027 0.01204,-7.2e-4 0.01945,-9.2e-4 0.0063,-2.79e-4 0.0069,1e-6 0.0082,0.0024 0.0014,0.0033 0.0027,0.0043 0.0062,0.0046 0.0017,1.26e-4 0.0048,0.0022 0.0079,0.0056 l 0.0072,0.0054 0.009,-8.6e-4 c 0.01242,0.0016 0.01688,0.0061 0.01683,0.01122 3.4e-4,0.0047 -0.0085,0.0087 -0.0087,0.0095 -2.7e-4,6.74e-4 -0.0023,0.0021 -0.0048,0.0029 -0.0057,0.0022 -0.0054,0.0052 3.95e-4,0.0061 0.0037,5.66e-4 0.0051,-6.64e-4 0.0082,-0.0041 0.0024,-0.0025 0.0052,-0.0034 0.0084,-0.0039 0.01165,-0.0026 0.03544,-0.01126 0.04277,7.4e-4 0.0025,0.0044 0.0075,0.01126 0.0098,0.01337 0.002,0.0018 0.0065,0.0064 0.0099,0.0099 0.0071,0.0067 0.0087,0.01283 0.0057,0.02564 -0.0061,0.01078 -0.0108,0.01012 -0.02028,0.0096 -0.0052,-8.29e-4 -0.01114,0.0011 -0.02139,-0.0046 -0.0092,-0.0051 -0.0087,0.01576 -0.01721,0.0069 -7.38e-4,8.2e-5 -0.0074,6.6e-4 -0.01058,0.0032 -0.006,0.0047 -0.01471,0.0095 -0.01771,0.0096 -0.0011,-8.1e-5 -0.0025,-0.0014 -0.0036,-0.003 -9.96e-4,-0.0017 -0.0027,-0.003 -0.0037,-0.003 -0.006,0.0047 -0.0061,0.01029 -0.01797,0.0102 l -0.0022,-0.004 c -9.36e-4,-0.01406 0.02092,-0.02631 -0.0064,-0.01162 0,0 -0.0077,0.0027 -0.0077,0.0032 -1.12e-4,0.0016 -0.01177,0.01134 -0.01579,0.01311 -0.0021,7.77e-4 -0.0058,0.0032 -0.0085,0.0054 -0.0076,0.0059 -0.01169,0.006 -0.02575,-3.2e-5 -0.006,-0.0025 -0.008,-0.0039 -0.0097,-0.0073 -0.0023,-0.004 -0.0062,-0.0059 -0.0081,-0.0036 -3.88e-4,5.37e-4 -0.0023,5.97e-4 -0.0045,6.9e-5 -0.0035,-8.17e-4 -0.0038,-6.17e-4 -0.0047,0.0021 -5.59e-4,0.0018 -0.002,0.0043 -0.003,0.0057 -0.0013,0.0013 -0.0029,0.0044 -0.0037,0.0065 -0.0022,0.0055 -0.0069,0.0062 -0.0142,0.007 -0.0031,4.36e-4 -0.0097,0.0021 -0.01566,0.0021 -0.0057,1.39e-4 -0.01102,5.02e-4 -0.01209,7.35e-4 -9.1e-4,3.04e-4 -0.0042,-5.48e-4 -0.0073,-0.0019 z"
       style="opacity:1;fill:#009ee0;fill-opacity:1;stroke:#ffffff;stroke-width:0.00242754;stroke-linecap:square;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none"/>
';

#  $svg_content .="\n </svg>\n\n\n";
}
svg_bsee();


$svg_content .= "\n  <g\n";
$svg_content .='     inkscape:label="Nodes"'."\n";
$svg_content .='     inkscape:groupmode="layer"'."\n";
$svg_content .='     id="layer2">'."\n\n";
#Hier ist der eigendliche Inhalt des SVGs:
sub svg_nodes{
	if (!defined $anzahl_nodes) { nodes(); }
	 my $geo_anzahl_nodes = 0;
	while($geo_anzahl_nodes < $anzahl_nodes - 1){
		my $geo_nodes_y = $nodes_json_for_perl->{"nodes"}->[$geo_anzahl_nodes]->{"geo"}->[0];
		my $geo_nodes_x = $nodes_json_for_perl->{"nodes"}->[$geo_anzahl_nodes]->{"geo"}->[1];
		if ((defined $geo_nodes_x) and (defined $geo_nodes_y)){
		$svg_content .= "\n     <circle\n       style=\"$svg_circle_style\"\n       id=\"svgCircle$geo_anzahl_nodes\"\n";
#GEO Location:
		$geo_nodes_y = $geo_nodes_y * $geo_nodes_percent_y;
#		$geo_nodes_y = $geo_nodes_y + 6;
		$geo_nodes_y = $geo_nodes_y * -1;
		$geo_nodes_y = $geo_nodes_y + $geo_nodes_mv_y;
		$geo_nodes_x = $geo_nodes_x * 1.0;
		$geo_nodes_x = $geo_nodes_x + 4.195;
		$svg_content .= '       cx="'.$geo_nodes_x."\"\n";
		$svg_content .= "       cy=\"$geo_nodes_y\"\n";
		$svg_content .= "       r=\"$svg_circle_radius\" />";
		}
		$geo_anzahl_nodes = $geo_anzahl_nodes + 1;
		
		#Und hier der 2. kreis...
		$svg_content .= "\n     <circle\n       style=\"$svg_circle_style2\"\n       id=\"svgCircle2$geo_anzahl_nodes\"\n";
#GEO Location:
		$svg_content .= '       cx="'.$geo_nodes_x."\"\n";
		$svg_content .= "       cy=\"$geo_nodes_y\"\n";
		$svg_content .= "       r=\"$svg_circle_radius2\" />";
		#3
		$svg_content .= "\n     <circle\n       style=\"$svg_circle_style3\"\n       id=\"svgCircle3$geo_anzahl_nodes\"\n";
#GEO Location:
		$svg_content .= '       cx="'.$geo_nodes_x."\"\n";
		$svg_content .= "       cy=\"$geo_nodes_y\"\n";
		$svg_content .= "       r=\"$svg_circle_radius3\" />";
		#4
		$svg_content .= "\n     <circle\n       style=\"$svg_circle_style4\"\n       id=\"svgCircle4$geo_anzahl_nodes\"\n";
#GEO Location:
		$svg_content .= '       cx="'.$geo_nodes_x."\"\n";
		$svg_content .= "       cy=\"$geo_nodes_y\"\n";
		$svg_content .= "       r=\"$svg_circle_radius4\" />";
		
	}
#	$svg_content .='
#	   <circle
#	      style="fill:#009ee0;fill-opacity:1;filter:url(#filter-circle01)"
#	      id="path4137"
#	      cx="500.0"
#	      cy="200.0"
#	      r="23.0" />';  
}

svg_nodes();
$svg_content .="\n  </g>\n";

sub svg_ffbsee{
  #Ebene 2:
  $svg_content .="\n  <g\n     inkscape:groupmode=\"layer\"\n     id=\"layer3\"\n     inkscape:label=\"FF Style\">\n";
  $svg_content .="\n      <ellipse\n         style=\"$svg_circle_inside_style\"\n         cx=\"$svg_circle_inside_cx\"\n         cy=\"$svg_circle_inside_cy\"\n         stroke-miterlimit=\"$svg_circle_inside_stroke_miterlimit\"\n         id=\"circleFFBseeInside\"\n         rx=\"$svg_circle_inside_rx\"\n         ry=\"$svg_circle_inside_ry\" />\n";
  $svg_content .="\n      <ellipse\n         style=\"$svg_circle_outside_style\"\n         cx=\"$svg_circle_outside_cx\"\n         cy=\"$svg_circle_outside_cy\"\n         stroke-miterlimit=\"$svg_circle_outside_stroke_miterlimit\"\n         id=\"circleFFBseeOutside\"\n         rx=\"$svg_circle_outside_rx\"\n         ry=\"$svg_circle_outside_ry\" />\n";

$svg_content .='
      <polygon
       inkscape:transform-center-y="13.284184"
       inkscape:transform-center-x="1607.3876"
       id="polygon5366"
       points="73,59 81,59 75,53 88,53 88,47 75,47 81,41 73,41 64,50"
       transform="matrix(0.01909626,0,0,0.01976347,12.37816,42.080948)"
       style="fill:#ffcc33;fill-opacity:1" />
';

}
svg_ffbsee();

$svg_content .="\n </svg>\n\n\n";
print $svg_content;				   
				   
print  "</body>\n</html>";




