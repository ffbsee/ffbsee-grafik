#! /usr/bin/perl
#
#   Lizenz: CC-BY-SA
#   Creared by L3D & FFBSee
#
#
#	Dies ist ein Perl-Script, dass für den Webserver gedacht ist.
#	Sobald es etwas mehr hermacht, könnte man es als live-Map oder
#	Echtzeitlogo oder vergleichbares in der Webseite einbinden.
#
#	Dieses Script generierte bis vor kurzen noch ein statisches SVG in einer HTML  Webseite.
#	Nun ist es auch schon fast in der lage zu einem animierten SVG zu werden.
#
#   Am anfang des Scriptes werden Variablen deklariert, 
#   mit denen das SVG und die Webseite beeinflussbar sind:
#   

# Perl Module laden
use JSON;                       # Zum verwenden der nodes.json | wenn nicht installiert: 'sudo cpan install JSON' eingeben!
use Data::Dumper;               # Zum testen, wie die nodes.json aussieht, wird zwar nicht benötigt, ist aber extrem praktisch beim debuggen und entwickeln von neuen Features...
use LWP::Simple;		# For getting the json
use strict;                     # Good practice
use warnings;                   # Good practice

#Head
our $content_type = "text/html";

# HTML Header
our $generate_html = "true"; # Soll ein HTML generiert werden? Empfehlug: JA 
our $author = "L3D";
our $title = "bodensee.freifunk.net | Status";
our $html_refresh = 150;
our $style =  #CSS
"
body {background-color:transparent;}
p {color:blue;}
.svg { 
text-align: center;
margin-left: auto;
margin-right: auto;
}

";

# Wo befindet sich das Script:
our $script_location = "internet"; # "vpn" oder "internet". it VPN ist einer der Freifunk-VPN Server gemeint!

#
# SVG - Ab hier gehts um die Vectorgrafik:
#

# Hier werden Headerdaten festgelegt:
our $svg_viewbox = "0.0 0.15 1.6 1.1";
our $svg_width = "160.0mm";
our $svg_height = "130.0mm";
our $svg_id = "l3d-svg1";
our $svg_docname = "ffbsee.svg";

# Animation:
our $animate_svg = "true";
our $animate_svg_viewbox = "false";
our $animate_svg_nodes = "true";
our $svg_animation;
our $geo_anzahl_nodes_animation_xtratime = "0.5";

our $svg_animation_node_dur = "1.5s";
our $svg_animation_node_repeatCount = '1';
our $svg_animation_node_fill = "freeze";
our $svg_animation_node_startanimationtime = "0.18";
our $svg_animation_node_delaycountownforxnodes = int(rand(14));
# Elemente
# FFNodes:
our $svg_circle_style = 'fill:#ffffff;fill-opacity:0.01337';#	;filter:url(#filter-circle01)
our $svg_circle_style2 = 'fill:#dc0067;fill-opacity:0.3';
our $svg_circle_style3 = 'fill:#dc0067;fill-opacity:0.1';
our $svg_circle_style4 = 'fill:#dc0067;fill-opacity:1';
#FFNodes, animated_svg
our $svg_circle_stylea = 'fill:#ffffff;fill-opacity:0.01337';#	;filter:url(#filter-circle01)
our $svg_circle_style2a = 'fill:#000000;fill-opacity:0.3';
our $svg_circle_style3a = 'fill:#000000;fill-opacity:0.1';
our $svg_circle_style4a = 'fill:#000000;fill-opacity:1';
our $svg_circle_radius = "0.0073";
our $svg_circle_radius2 = "0.0038";
our $svg_circle_radius3 = "0.006";
our $svg_circle_radius4 = "0.0023";
#Ebene 1:
#Bodensee (weiter unten)
#
#Ebene 2- Freifunk kreise:
# Circle Inside (small, right)
our $svg_circle_inside_style = "fill:none;stroke:#de2c68;stroke-width:0.007;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1";
our $svg_circle_inside_cx = "0.68";
our $svg_circle_inside_cy = "0.99";
our $svg_circle_inside_stroke_miterlimit = "4.0";
our $svg_circle_inside_rx = "0.123";
our $svg_circle_inside_ry = "0.123";
# Circle inside (small left)
our $svg_circle2_inside_style = "fill:none;stroke:#de2c68;stroke-width:0.007;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1";
our $svg_circle2_inside_cx = "0.465";
our $svg_circle2_inside_cy = "1.015";
our $svg_circle2_inside_stroke_miterlimit = "5.0";
our $svg_circle2_inside_rx = "0.142";
our $svg_circle2_inside_ry = "0.142";
#Circle outside (big, white, background)
our $svg_circle_outside_style = "fill:white;stroke:#de2c68;stroke-width:0.036;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1";
our $svg_circle_outside_cx = "0.68";
our $svg_circle_outside_cy = "0.99";
our $svg_circle_outside_stroke_miterlimit = "4.0";
our $svg_circle_outside_rx = "0.17";
our $svg_circle_outside_ry = "0.17";
# Circle outside (red border)
our $svg_circle_outside2_style = "fill:white;stroke:#ffffff;stroke-width:0.046;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1";
our $svg_circle_outside2_cx = "0.68";
our $svg_circle_outside2_cy = "0.99";
our $svg_circle_outside2_stroke_miterlimit = "4.0";
our $svg_circle_outside_rx2 = "0.17";
our $svg_circle_outside_ry2 = "0.17";



# Globale Variabeln für den Inhalt:
our $svg_head; 
our $svg_meta;
our $svg_ebene_01;
our $svg_ebene_02;
# ... und für die FFNodes:
our @node_name;   # Global Array for Node-Names
our $anzahl;      # How many nodes exist
our $clients;     # How many Clients are connected...
our $url = "http://vpn1.ffbsee.de/nodes.json"; #Link zur nodes.json
our $path = "/var/www/modes.json"; #Pfad zur nodes.json
our $ffnodes_json;
our $svg_ebene_03;
our $geo_nodes_percent_y = "1.442";
our $geo_nodes_mv_y = "69.44";
our $geo_nodes_mv_x = "-8.7";


sub animated_svg {
    if ($animate_svg_viewbox eq "true"){
        $svg_animation .='
            <animate attributeName="viewBox"
                values="12.0 42.45 1.7 1.7;12.9 42.45 1.7 1.7;12.7 42.55 1.7 1.7; 12.7 41.45 1.7 1.7"
                begin="2s" 
                dur="6s"
                repeatCount="indefinite"
                keyTimes="0; 0.1; 0.1; 1"
                fill="freeze"
            />
        ';
    }
}


# Vectorgrafik - HEAD:
$svg_head .= "\n<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<!-- Created by $author with perl -->\n\n";
$svg_head .= " <svg\n   xmlns:dc=\"http://purl.org/dc/elements/1.1/\"\n   xmlns:cc=\"http://creativecommons.org/ns#\"\n   xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n   xmlns:svg=\"http://www.w3.org/2000/svg\"\n";
$svg_head .= "   xmlns=\"http://www.w3.org/2000/svg\"\n   xmlns:sodipodi=\"http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd\"\n   xmlns:inkscape=\"http://www.inkscape.org/namespaces/inkscape\"";
$svg_head .= "   width=\"$svg_width\"\n   height=\"$svg_height\"\n   viewBox=\"$svg_viewbox\"\n";
$svg_head .= "   id=\"$svg_id\"   version=\"1.1\"   inkscape:version=\"0.91 r13725\"   sodipodi:docname=\"$svg_docname\">";


# Vectorgrafik - META:
$svg_meta = "
<metadata
    id=\"metada7a\">
    <rdf:RDF>
    <cc:Work
        rdf:about=\"\">
    <dc:format>image/svg+xml</dc:format>
    <dc:type
        rdf:resource=\"http://purl.org/dc/dcmitype/StillImage\" />
    <dc:title>bodensee.freifunk.net</dc:title>
    </cc:Work>
    </rdf:RDF>
</metadata>
";

#  Ebene 1
#  Der Bodensee

$svg_ebene_01 .="\n  <g\n     inkscape:groupmode=\"layer\"\n     id=\"layer1\"\n     inkscape:label=\"Bodensee\">\n";
#Bodensee
$svg_ebene_01 .= '
    <path
        inkscape:connector-curvature="0"
        id="bodensee"
        d="M 0.8,1  c -0.0216199,0.00281 -0.0213078,-0.023783 -0.0328063,-0.028204 -0.002985,-0.00106 -0.005563,-0.00266 -0.006716,-0.0049 -8.8189e-4,-0.00181 -0.004477,-0.00468 -0.007666,-0.00628 -0.00658,-0.00351 -0.0112882,4.899e-4 -0.0120344,-0.00703 -9.4973e-4,-0.00426 0.010542,-0.00287 0.00926,-0.012116 -0.007347,-0.00586 -0.0230309,-0.00224 -0.0323247,-0.012244 -0.002035,-0.00213 -0.00407,-0.00405 -0.004816,-0.00415 -5.4474e-4,-3.81e-5 -0.005088,-0.00447 -0.009579,-0.010115 -0.005088,-0.00564 -0.011295,-0.011594 -0.0129706,-0.013138 -0.004884,-0.00373 -0.008724,-0.010405 -0.007231,-0.018636 6.6616e-4,-0.00319 0.002985,-0.00805 0.002781,-0.010715 -3.9007e-4,-0.00394 -0.001085,-0.00475 -0.006105,-0.00869 -0.003188,-0.00245 -0.006716,-0.00458 -0.007666,-0.00458 -0.001153,-9.28e-5 -0.002103,-5.888e-4 -0.002374,-0.00117 -2.8967e-4,-5.518e-4 -0.005223,-0.00383 -0.0114985,-0.00735 -0.005766,-0.00341 -0.0115867,-0.00703 -0.0123058,-0.00809 -8.1405e-4,-0.00102 -0.002103,-0.00181 -0.003121,-0.00202 -0.001153,-9.55e-5 -0.002985,-8.798e-4 -0.004274,-0.0017 -0.010542,-0.00692 -0.0156773,-0.01102 -0.0213892,-0.016663 -0.0147344,-0.014267 -0.0146801,-0.014374 -0.0301199,-0.0227 -0.005088,-0.00255 -0.0233701,-0.013522 -0.0331862,-0.019495 -0.004681,-0.00298 -0.0117427,-0.010008 -0.0147276,-0.010541 -0.005291,-0.00106 -0.015121,-0.00256 -0.0165999,-0.00469 -7.4621e-4,-0.00138 -0.0158537,-0.010434 -0.0179295,-0.010541 -7.4621e-4,-5.32e-5 -0.005088,-0.00213 -0.00905,-0.00458 -0.008622,-0.00479 -0.0143816,-0.011861 -0.0156094,-0.018356 -4.7079e-4,-0.00213 -0.001289,-0.00755 -0.002103,-0.00862 -0.002578,-0.00298 -0.0158604,-0.00335 -0.0229088,-0.00111 -0.0130927,0.005 -0.0162607,0.00696 -0.0240213,0.00483 -0.003867,-0.00103 -0.0117563,-0.00286 -0.0188046,-0.00393 -0.010949,0.0019 -0.0137982,8.263e-4 -0.0188046,-0.0013 -0.00734,-0.00539 -0.0213282,-0.00373 -0.024408,-0.0069 -0.009341,-0.00266 -0.0304252,-0.00418 -0.0399021,-0.00609 -0.0426563,-0.00339 -0.0511293,0.010254 -0.0637199,0.015525 -0.007774,0.00449 -0.0103317,0.01201 -0.0181805,0.011656 -0.002035,2.537e-4 -0.00563,0.0016 -0.007876,0.00287 -0.002239,0.00138 -0.004817,0.00245 -0.005563,0.00234 -7.4622e-4,-4.27e-5 -0.003188,7.028e-4 -0.005563,0.00192 -0.002239,0.00117 -0.005834,0.00202 -0.0081948,0.00181 -0.0028492,-2.005e-4 -0.005427,5.431e-4 -0.0082016,0.00234 -0.0024422,0.00181 -0.0038667,7.13e-4 -0.0074147,9.26e-4 -0.0077742,0.00105 -0.0157587,0.00622 -0.02731146,0.00359 -0.0016281,-0.00149 -0.0065803,-0.00377 -0.0083644,-0.00431 -0.0089885,-0.00539 -0.01806518,-0.00953 -0.0224475,-0.011007 -0.0099043,-0.00287 -0.02845112,-0.019933 -0.03788056,-0.024873 0.0050878,5.323e-4 0.03174125,0.018728 0.0389931,0.019899 0.00502,7.517e-4 0.01746821,0.00763 0.02476076,0.010402 0.0050878,0.00224 0.0091581,0.00351 0.02101612,-0.00149 0.0052913,-0.00149 0.0144155,-0.00841 0.01885887,-0.00905 0.0041381,-9.124e-4 0.0079845,-0.00202 0.0090495,-0.00277 7.4622e-4,-6.818e-4 0.0023743,-0.00117 0.0033241,-0.00106 0.001153,8.48e-5 0.004545,-0.00202 0.007984,-0.00479 0.003528,-0.00266 0.008195,-0.00575 0.0110847,-0.0066 0.002646,-0.00107 0.002849,-0.00107 0.005766,-0.00298 0.0250592,-0.016196 0.0403499,-0.028072 0.0510954,-0.041334 0.002374,-0.00163 3.8328e-4,-0.00513 -6.7838e-4,-0.0063 -8.8189e-4,-0.00138 -0.005224,3.109e-4 -0.007557,-4.347e-4 -0.002442,-6.359e-4 -0.005766,-0.00234 -0.007028,-0.00373 -0.0274465,-0.01936 -0.034739,-0.01795 -0.0440667,-0.024593 -0.03288093,-0.023417 0.0113764,-0.027598 0.0243877,-0.021173 0.0134386,0.00447 0.0206227,0.010617 0.0305338,0.013742 0.0121904,0.00663 0.003121,-0.00348 -0.004749,-0.00886 -0.003867,-0.00198 -0.0207923,-0.00986 -0.0150396,-0.012467 0.01255,-0.00366 0.026823,0.00726 0.0320465,0.011195 0.0139474,0.011583 0.0301742,0.013971 0.0436603,0.021787 0.003324,0.00192 0.006811,0.00351 0.007557,0.00362 7.4622e-4,5.4e-5 0.003188,0.00138 0.005563,0.00266 0.003799,0.00221 0.008351,0.00327 0.0117156,0.00543 0.002103,0.00138 0.006173,0.00319 0.008731,0.00426 0.0104334,0.00373 0.027515,0.0209 0.0277185,0.027257 -3.9753e-4,0.00511 -0.004274,0.00607 -0.0170747,0.00426 -0.0306626,-0.0033 -0.0204666,-0.011254 -0.0389049,-0.020425 -0.0224068,-0.011345 -0.0221558,-0.013952 -0.0207855,-0.00178 6.7838e-4,0.00551 -0.002374,0.00997 0.009334,0.014318 0.002849,0.00102 0.0142527,0.00552 0.0151074,0.00637 0.001085,9.741e-4 0.004884,0.00255 0.008622,0.0033 0.003799,8.975e-4 0.008412,2.981e-4 0.009796,9.368e-4 0.001832,8.846e-4 0.004816,0.00149 0.007028,0.00106 0.004342,-6.029e-4 0.007557,4.832e-4 0.0125093,-8.54e-5 0.0139474,-9.274e-4 0.0174071,0.00128 0.0220269,0.014001 0.003324,0.00809 0.006797,0.013187 0.008622,0.013149 0.0165728,4.17e-5 0.0274675,-0.0056 0.0389185,-0.00458 0.010542,7.957e-4 0.0207787,0.005 0.0306965,0.00905 0.0106709,0.00289 0.0181737,-0.00286 0.008894,-0.018251 -0.001696,-0.017931 3.0256e-4,-0.016027 -0.009572,-0.025378 -0.0316531,-0.021938 -0.0240349,-0.026813 -0.023967,-0.042324 -6.7838e-4,-0.00905 -0.007428,-0.019824 -0.0139203,-0.025978 -0.0312121,-0.030868 -0.0168984,-0.00416 -0.0321347,-0.015786 -0.00597,-0.00607 -0.0176039,-0.016113 -0.0305744,-0.022256 -0.005834,-0.00277 -0.0107998,-0.00558 -0.0116749,-0.00621 l -0.0162607,-0.010903 c -0.003595,-0.00277 -0.0171833,-0.021148 -0.0274539,-0.028887 -0.003256,-0.00379 -0.0121158,-0.012048 -0.014368,-0.013645 -0.006512,-0.00669 -0.005698,-0.010044 -0.00251,-0.010891 0,0 -0.002103,-0.0084 0.00947,-0.013039 0.002714,-7.666e-4 0.0125296,9.985e-4 0.0195576,0.00428 0.004002,0.00154 0.009952,0.00892 0.0197543,0.017836 0.0107726,0.00639 0.0158876,0.00555 0.0217759,0.010551 0.001696,0.0016 0.003731,0.00458 0.005427,0.00522 0.001628,6.155e-4 0.003935,0.00202 0.005224,0.0033 0.001357,0.00138 0.00407,0.00256 0.005766,0.0033 0.001832,5.302e-4 0.004342,0.00234 0.005766,0.00394 0.001357,0.00181 0.002985,0.00309 0.003528,0.00309 6.0579e-4,4.55e-5 0.002713,0.00578 0.007008,0.010572 0.009104,0.01205 0.0212468,0.016367 0.0259411,0.016499 0.005224,8.527e-4 0.009735,9.762e-4 0.0113289,0.00257 0.001628,0.00138 0.006811,0.00331 0.006811,0.00331 7.4622e-4,5.32e-5 0.0120751,0.00846 0.0143137,0.010055 0.0416591,0.021319 0.0361575,0.020454 0.0397529,0.046148 0.004952,0.022475 0.0207312,0.030031 0.0379484,0.042783 0.002781,0.00245 0.0089,0.00461 0.0107116,0.00589 0.002103,0.00138 0.006038,0.00436 0.00852,0.00639 0.0229834,0.027618 0.0370258,0.020806 0.0642152,0.036013 0.006811,0.00415 0.008181,0.00544 0.0165321,0.00282 0.003528,-0.00138 0.007557,-0.00245 0.008839,-0.00234 0.001153,6.93e-5 0.003935,-6.144e-4 0.006512,-0.00181 0.005291,-0.00224 0.0128349,-0.00489 0.0242723,-0.00414 0.009904,5.847e-4 0.0272504,0.00658 0.0299503,0.011603 0.001696,0.00287 0.0113289,9.748e-4 0.0183433,0.00545 0.008086,0.00517 0.0123668,0.01 0.019042,0.00936 0.0209415,-0.00199 0.0348618,0.00645 0.0405534,0.01348 0.007666,0.00926 0.005766,0.00829 0.008636,0.020314 0.002578,0.012801 0.009267,0.011331 0.0120005,0.027369 0.001018,0.00586 0.0103588,0.020997 0.0157858,0.026949 0.0138389,0.011052 0.0281255,0.011998 0.0463196,0.011888 0.0199375,0.00254 0.0136557,0.020799 0.0341631,0.019564 0.009104,-3.735e-4 0.0225696,0.017832 0.0312257,0.01894 0.0139949,0.0022 0.0319244,0.00679 0.0385861,0.00836 0.0290956,0.00212 0.0290345,0.013062 0.0470861,0.028933 0.0272911,0.024138 0.015121,0.051401 -1.9537e-4,0.045843 -0.0202767,-0.00582 -0.0366527,-0.0064 -0.0471201,0.00575 -0.0204802,0.030061 -0.0219659,0.00535 -0.0287428,0.00784 -0.0183569,0.00565 -0.018825,0.028955 -0.0271826,-0.012143 -0.005291,-0.00888 -0.0304863,0.032706 -0.0530423,0.021279 -0.003867,-0.00312 -0.007523,-0.00682 -0.0116409,-0.00837 -0.0103995,-0.00389 -0.009362,-0.00782 -0.0124889,-0.00821 -0.006811,-0.00279 -0.0136286,0.014893 -0.0155281,0.01978 -0.002374,0.00586 -0.003595,0.00709 -0.0113425,0.00794 -0.003324,4.636e-4 -0.0103249,0.00224 -0.0166745,0.00224 -0.006038,1.473e-4 -0.0117359,5.342e-4 -0.0128756,7.828e-4 -0.003867,3.062e-4 -0.005224,-0.00154 -0.009253,-8.385e-4 z"
        style="opacity:1;fill:#009ee0;fill-opacity:1;stroke:#ffffff;stroke-width:0.0023;stroke-linecap:square;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none"
    />
';
$svg_ebene_01 .= '</g>'; #Ende der Ebene 1

# FFStyle:

$svg_ebene_02 .="\n  <g\n     inkscape:groupmode=\"layer\"\n     id=\"layer2\"\n     inkscape:label=\"FF Style\">\n";
$svg_ebene_02 .="\n      <ellipse\n         style=\"$svg_circle_outside2_style\"\n         cx=\"$svg_circle_outside2_cx\"\n         cy=\"$svg_circle_outside2_cy\"\n         stroke-miterlimit=\"$svg_circle_outside2_stroke_miterlimit\"\n         id=\"circleFFBseeOutsideWhite\"\n         rx=\"$svg_circle_outside_rx2\"\n         ry=\"$svg_circle_outside_ry2\" />\n";
$svg_ebene_02 .="\n      <ellipse\n         style=\"$svg_circle_outside_style\"\n         cx=\"$svg_circle_outside_cx\"\n         cy=\"$svg_circle_outside_cy\"\n         stroke-miterlimit=\"$svg_circle_outside_stroke_miterlimit\"\n         id=\"circleFFBseeOutside\"\n         rx=\"$svg_circle_outside_rx\"\n         ry=\"$svg_circle_outside_ry\" />\n";
$svg_ebene_02 .="\n      <ellipse\n         style=\"$svg_circle_inside_style\"\n         cx=\"$svg_circle_inside_cx\"\n         cy=\"$svg_circle_inside_cy\"\n         stroke-miterlimit=\"$svg_circle_inside_stroke_miterlimit\"\n         id=\"circleFFBseeInside\"\n         rx=\"$svg_circle_inside_rx\"\n         ry=\"$svg_circle_inside_ry\" />\n";
$svg_ebene_02 .="\n      <ellipse\n         style=\"$svg_circle2_inside_style\"\n         cx=\"$svg_circle2_inside_cx\"\n         cy=\"$svg_circle2_inside_cy\"\n         stroke-miterlimit=\"$svg_circle2_inside_stroke_miterlimit\"\n         id=\"circleFFBseeInside2\"\n         rx=\"$svg_circle2_inside_rx\"\n         ry=\"$svg_circle2_inside_ry\" />\n";
$svg_ebene_02 .= #Freifunk-Pfeile
'<polygon
    style="fill:#ffcc33;fill-opacity:1"
    points="81,59 75,53 88,53 88,47 75,47 81,41 73,41 64,50 73,59 "
    transform="matrix(0.0055,0,0,0.0055,0.28,0.76)"
    id="polygon5366"
/>
<polygon
    inkscape:transform-center-y="2.2182592"
    inkscape:transform-center-x="-268.40935"
    id="polygon5363"
    transform="matrix(-0.0042,0,0,0.0042,0.74,0.826)"
    points="88,47 75,47 81,41 73,41 64,50 73,59 81,59 75,53 88,53 "
    style="fill:#ffcc33;fill-opacity:1" 
/>
';
$svg_ebene_02 .= '</g>'; #Ende der Ebene 2

#
#  Ebene 3: Freifunk Nodes:



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




# Ab hier werden die Freifunk Nodes gesucht:
our $ffclients = 0;
sub svg_nodes{
    if (!defined $anzahl) { nodes(); }
    my $geo_anzahl_nodes = 0;
    my $geo_anzahl_nodes2 = 0;
    while($geo_anzahl_nodes < $anzahl - 1){
	$ffclients = $ffclients + int($ffnodes_json->{"nodes"}->[$geo_anzahl_nodes]->{"clientcount"});
        my $geo_nodes_y = $ffnodes_json->{"nodes"}->[$geo_anzahl_nodes]->{"geo"}->[0];
        my $geo_nodes_x = $ffnodes_json->{"nodes"}->[$geo_anzahl_nodes]->{"geo"}->[1];
        if ((defined $geo_nodes_x) and (defined $geo_nodes_y)){
            $svg_ebene_03 .= "\n     <circle\n       style=\"$svg_circle_style\"\n       id=\"svgCircle$geo_anzahl_nodes\"\n";
    #GEO Location:
            $geo_nodes_y = $geo_nodes_y * $geo_nodes_percent_y;
#           $geo_nodes_y = $geo_nodes_y + 6;

            $geo_nodes_y = $geo_nodes_y * -1;
            $geo_nodes_y = $geo_nodes_y + $geo_nodes_mv_y;
            $geo_nodes_y = $geo_nodes_y * 1.012;
            $geo_nodes_x = $geo_nodes_x * 1.0;
            $geo_nodes_x = $geo_nodes_x + $geo_nodes_mv_x;
            $svg_ebene_03 .= '       cx="'.$geo_nodes_x."\"\n";
            $svg_ebene_03 .= "       cy=\"$geo_nodes_y\"\n";
            $svg_ebene_03 .= "       r=\"$svg_circle_radius\" />";
        }
        $geo_anzahl_nodes = $geo_anzahl_nodes + 1;
        $geo_anzahl_nodes2 = $geo_anzahl_nodes2 + $svg_animation_node_startanimationtime;
#Und hier der 2. kreis...
        $svg_ebene_03 .= "\n     <circle\n       style=\"$svg_circle_style2\"\n       id=\"svgCircle2$geo_anzahl_nodes\"\n";
		
#GEO Location:
        $svg_ebene_03 .= '       cx="'.$geo_nodes_x."\"\n";
        $svg_ebene_03 .= "       cy=\"$geo_nodes_y\"\n";

        if ($animate_svg_nodes eq "true"){	
            $svg_ebene_03 .= "       r=\"0\" >";
            if ($geo_anzahl_nodes >= $anzahl - $svg_animation_node_delaycountownforxnodes - 0) {
                my $geo_anzahl_nodes_animation_xtratimelocal = $geo_anzahl_nodes_animation_xtratime + $geo_anzahl_nodes2 - 0.5;
                my $svg_animation_node_durlocal = $svg_animation_node_startanimationtime + $svg_animation_node_dur + 0.8;
                $svg_ebene_03 .= '
                    <animate attributeName="r" attributeType="XML"
                        from="0"  to="'.$svg_circle_radius2.'"
                        begin="'.$geo_anzahl_nodes_animation_xtratimelocal.'s" dur="'.$svg_animation_node_durlocal.'"
                        fill="'.$svg_animation_node_fill.'" repeatCount="'.$svg_animation_node_repeatCount.'"
                    />
                ';
                
            }
            else {
                $svg_ebene_03 .= '
                    <animate attributeName="r" attributeType="XML"
                        from="0"  to="'.$svg_circle_radius2.'"
                        begin="'.$geo_anzahl_nodes2.'s" dur="'.$svg_animation_node_dur.'"
                        fill="'.$svg_animation_node_fill.'" repeatCount="'.$svg_animation_node_repeatCount.'"
                    />
                ';
            }
        }
        else {
            $svg_ebene_03 .= "       r=\"$svg_circle_radius2\" >";
        }
        $svg_ebene_03 .= "\n</circle>\n";
# 3
        $svg_ebene_03 .= "\n     <circle\n       style=\"$svg_circle_style3\"\n       id=\"svgCircle3$geo_anzahl_nodes\"\n";
# GEO Location:
        $svg_ebene_03 .= '       cx="'.$geo_nodes_x."\"\n";
        $svg_ebene_03 .= "       cy=\"$geo_nodes_y\"\n";
        if ($animate_svg_nodes eq "true"){
            $svg_ebene_03 .= "       r=\"0\" >";
            if ($geo_anzahl_nodes >= $anzahl - $svg_animation_node_delaycountownforxnodes - 0) {
                my $geo_anzahl_nodes_animation_xtratimelocal = $geo_anzahl_nodes_animation_xtratime + $geo_anzahl_nodes2 - 0.5;
                my $svg_animation_node_durlocal = $svg_animation_node_startanimationtime + $svg_animation_node_dur + 0.8;
                $svg_ebene_03 .= '
                     <animate attributeName="r" attributeType="XML"
                         from="0"  to="'.$svg_circle_radius2.'"
                         begin="'.$geo_anzahl_nodes_animation_xtratimelocal.'s" dur="'.$svg_animation_node_durlocal.'"
                         fill="'.$svg_animation_node_fill.'" repeatCount="'.$svg_animation_node_repeatCount.'"
                     />
                '; 			
            
            }
            else {
                $svg_ebene_03 .= '
                     <animate attributeName="r" attributeType="XML"
                         from="0"  to="'.$svg_circle_radius2.'"
                         begin="'.$geo_anzahl_nodes2.'s" dur="'.$svg_animation_node_dur.'"
                         fill="'.$svg_animation_node_fill.'" repeatCount="'.$svg_animation_node_repeatCount.'"
                     />
                '; 			
            }    
        }
        
        else {
            $svg_ebene_03 .= "       r=\"$svg_circle_radius3\" >";
        }
        
        $svg_ebene_03 .= "\n</circle>\n";
# 4
        $svg_ebene_03 .= "\n     <circle\n       style=\"$svg_circle_style4\"\n       id=\"svgCircle4$geo_anzahl_nodes\"\n";
# GEO Location:
        $svg_ebene_03 .= '       cx="'.$geo_nodes_x."\"\n";
        $svg_ebene_03 .= "       cy=\"$geo_nodes_y\"\n";
        if ($animate_svg_nodes eq "true"){
            $svg_ebene_03 .= "       r=\"0\" >";
            			
            $svg_ebene_03 .= '
                <animate attributeName="r" attributeType="XML"
                    from="0"  to="'.$svg_circle_radius2.'"
                    begin="'.$geo_anzahl_nodes2.'s" dur="'.$svg_animation_node_dur.'"
                    fill="'.$svg_animation_node_fill.'" repeatCount="'.$svg_animation_node_repeatCount.'"
                />
            '; 
        }
        else {
            $svg_ebene_03 .= "       r=\"$svg_circle_radius4\" >";
        }
        $svg_ebene_03 .= "\n</circle>\n";
        
        if ($animate_svg_nodes eq "true"){
            $svg_ebene_03 .= '		
                <text 
                     id="text" font-size="0.0" x="0.95" y="1.12" fill="#000000">
                     '.$geo_anzahl_nodes.'

                          <animate attributeName="font-size"

            ';
            if ($geo_anzahl_nodes >= $anzahl - 1){   
 
            my $geo_anzahl_nodes_animation_xtratimelocal = $geo_anzahl_nodes_animation_xtratime + $geo_anzahl_nodes2 - 0.5;
my $geo_anzahl_nodes_1plus = $geo_anzahl_nodes + 1;
                $svg_ebene_03 .= '
                              values="0.15"
                              begin="'.$geo_anzahl_nodes_animation_xtratimelocal.'s" 
                              dur="'.$svg_animation_node_startanimationtime.'s"
                              repeatCount="'.$svg_animation_node_repeatCount.'"
                              fill="remove"
                          />
                     
                     
                </text>


 <text 
                     id="text" font-size="0.0" x="0.95" y="1.12" fill="#000000">
                     '.$geo_anzahl_nodes_1plus.'


                          <animate attributeName="font-size"
                ';

my $geo_anzahl_nodes_1plus = $geo_anzahl_nodes + 1;
my $geo_anzahl_nodes_animation_xtratimelocal2x = $geo_anzahl_nodes_animation_xtratimelocal + $svg_animation_node_startanimationtime;
                $svg_ebene_03 .= '
                              values="0.15"
                              begin="'.$geo_anzahl_nodes_animation_xtratimelocal2x.'s" 
                              dur="'.$svg_animation_node_startanimationtime.'s"
                              repeatCount="'.$svg_animation_node_repeatCount.'"
                              fill="freeze"
                          />
                     
                     
                </text>
 <text 
';

            }
            elsif ($geo_anzahl_nodes >= $anzahl - $svg_animation_node_delaycountownforxnodes - 0) {
                my $geo_anzahl_nodes_animation_xtratimelocal = $geo_anzahl_nodes_animation_xtratime + $geo_anzahl_nodes2 - 0.5;
                my $svg_animation_node_startanimationtimelocal = $svg_animation_node_startanimationtime + 0.8;
                $geo_anzahl_nodes_animation_xtratime = $geo_anzahl_nodes_animation_xtratime + 0.8;
                $svg_ebene_03 .= '
                              values="0.15"
                              begin="'.$geo_anzahl_nodes_animation_xtratimelocal.'s" 
                              dur="'.$svg_animation_node_startanimationtimelocal.'s"
                              repeatCount="'.$svg_animation_node_repeatCount.'"
                              fill="remove"
                          />
                     
                     
                    </text>
                ';            }
            else {
                $svg_ebene_03 .= '
                              values="0.15"
                              begin="'.$geo_anzahl_nodes2.'s" 
                              dur="'.$svg_animation_node_startanimationtime.'s"
                              repeatCount="'.$svg_animation_node_repeatCount.'"
                              fill="remove"
                          />
                     
                     
                </text>	
            ';

            }
        }
    }

#	$svg_ebene_03 .='
#	   <circle
#	      style="fill:#009ee0;fill-opacity:1;filter:url(#filter-circle01)"
#	      id="path4137"
#	      cx="500.0"
#	      cy="200.0"
#	      r="23.0" />';  
}



sub nodeanzahl() {
    my $client = 0;
    while ($client < $ffclients) {
        my $begintxt = $client / 6;
        $begintxt = $begintxt . "s";
        print <<EOF; 
id="nodekeanzahl" font-size="0.0" x="0.95" y="0.4" fill="#9aeffe">
$client

<animate attributeName="font-size"

            
                              values="0.13"
                              begin="$begintxt" 
                              dur="0.16667"
                              repeatCount="1"
                              fill="remove"
                          />
</text>                     

<text
EOF
        $client = $client + 1;
    }
my $begintxt = $ffclients / 6 ;
print <<EOF; 
id="nodekeanzahl" font-size="0.0" x="0.95" y="0.4" fill="#9aeffe">
$ffclients

<animate attributeName="font-size"

            
                              values="0.13"
                              begin="$begintxt" 
                              dur="16"
                              repeatCount="1"
                              fill="freeze"
                          />
</text>                     

<text
EOF


}



#
#  Ab hier wird die eigendliche Webseite mit den vorher generierten Variabeln erstellt:
#
print "Content-type: $content_type\n";
if ( $generate_html == "true" ){
    print "\n<!DOCTYPE html>\n";
    print "<html lang=\"de\">\n<head>\n\t\n\t<title>$title</title>\n";
    print '<meta http-equiv="refresh" content="'.$html_refresh.'"> ';
    print "\n<meta charset=\"UTF-8\">\n<meta name=\"description\" content=\"A ffbsee logo - written in perl\">\n<meta name=\"author\" content=\"$author\">\n\n";
    print "<style>$style</style>\n</head>\n\n<body>\n\n<div id='svg'>";
}

# Hier wird das SVG eigendlich zusammengebastelt:
print $svg_head;
print $svg_meta;
if ( $animate_svg eq "true" ){
    animated_svg();
    print $svg_animation;
}
print $svg_ebene_01;
print $svg_ebene_02;	
# In Ebene #03 sind die Freifunk Nodes
nodes();
svg_nodes();
print $svg_ebene_03;

#Neue SVG Features:
print <<EOF;
id="nodekennzeichnung" font-size="0.06" x="0.985" y="1.19" fill="#000000">
Nodes
</text>
<text id="ianzahlkennzeichnung" font-size="0.06" x="0.985" y="0.475" fill="#9aeffe">
Clients
</text>
EOF

nodeanzahl();
# Ende der SVG:
print "\n</svg>\n</div>\n";
	
	
if ( $generate_html eq "true" ){
    print  "</body>\n</html>";
}


