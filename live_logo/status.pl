#! /usr/bin/perl

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
use LWP::Simple;				# For getting the json
use strict;                     # Good practice
use warnings;                   # Good practice

#Head
our $content_type = "text/html";

# HTML Header
our $generate_html = "true"; # Soll ein HTML generiert werden? Empfehlug: JA 
our $author = "L3D";
our $title = "bodensee.freifunk.net";
our $style =  #CSS
"
body {background-color:transparent;}
p {color:blue;}

";

# Wo befindet sich das Script:
our $script_location = "internet"; # "vpn" oder "internet". it VPN ist einer der Freifunk-VPN Server gemeint!

#
# SVG - Ab hier gehts um die Vectorgrafik:
#
# Hier werden Headerdaten festgelegt:
our $svg_viewbox = "0 0 1.3 1.3";
our $svg_width = "230.0mm";
our $svg_height = "230.0mm";
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
our $channelName = "ffbsee"; #Operate in this channel !1ELF
our $secoundChannel = "see-base-talk"; #A 2. channel for testing...
our $url = "http://vpn3.ffbsee.de/nodes.json"; #Link zur nodes.json
our $path = "/var/www/modes.json"; #Pfad zur nodes.json
our $ffnodes_json;
our $svg_ebene_03;
our $geo_nodes_percent_y = "1.442";
our $geo_nodes_mv_y = "69.473";
our $geo_nodes_mv_x = "-8.68";


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
        d="M 0.8,1 C 0.797,0.9986 0.794,0.997 0.7936,0.9965 0.793154,0.995931 0.7904,0.9924 0.7875,0.9885 0.7813,0.9804 0.77548,0.97569 0.76919,0.97351 0.76639,0.972516 0.76399,0.97101 0.76289,0.96891 0.762079,0.96721 0.75869,0.96451 0.75569,0.96301 0.74949,0.95971 0.74509,0.96347 0.74439,0.95641 0.743481,0.95241 0.75429,0.95371 0.75309,0.94503 0.74619,0.93953 0.73146,0.94293 0.72273,0.93353 0.72083,0.93153 0.71893,0.92973 0.71823,0.92963 0.717716,0.929595 0.71343,0.92543 0.70923,0.92013 0.70443,0.91483 0.69862,0.90924 0.69705,0.90779 0.69245,0.90429 0.69095,0.89829 0.69235,0.89056 c 6.26e-4,-0.003 9.18e-4,-0.0072 7.19e-4,-0.0097 -3.66e-4,-0.0037 -0.0012,-0.0051 -0.0059,-0.0088 -0.003,-0.0023 -0.0063,-0.0043 -0.0072,-0.0043 -0.0011,-8.7e-5 -0.002,-5.53e-4 -0.0022,-0.0011 -2.71e-4,-5.18e-4 -0.0049,-0.0036 -0.0108,-0.0069 -0.0054,-0.0032 -0.01088,-0.0066 -0.01156,-0.0076 -7.64e-4,-9.62e-4 -0.002,-0.0017 -0.0029,-0.0019 -0.0011,-8.9e-5 -0.0028,-8.26e-4 -0.004,-0.0016 -0.0099,-0.0065 -0.01472,-0.01035 -0.02009,-0.01565 -0.01384,-0.0134 -0.01379,-0.0135 -0.02829,-0.02132 -0.0048,-0.0024 -0.02195,-0.0127 -0.03117,-0.01831 -0.0044,-0.0028 -0.01103,-0.0094 -0.01383,-0.0099 -0.005,-0.001 -0.0142,-0.0024 -0.01559,-0.0044 -7.19e-4,-0.0013 -0.01489,-0.0098 -0.01684,-0.0099 -7.24e-4,-5e-5 -0.0048,-0.002 -0.0085,-0.0043 C 0.506099,0.76038 0.500689,0.75374 0.499539,0.74764 0.499095,0.74564 0.498338,0.740547 0.497538,0.739547 0.495138,0.736747 0.482641,0.7364 0.476021,0.7385 0.463721,0.7432 0.4607486,0.745039 0.4534586,0.743039 0.4498586,0.742068 0.4424176,0.740349 0.4357975,0.739349 0.4255138,0.741137 0.4228389,0.74012506 0.4181388,0.738125 0.4112458,0.733062 0.3981098,0.734625 0.3952138,0.731641 0.3864418,0.729141 0.3666356,0.727717 0.3577396,0.725923 0.3176754,0.72274 0.3097194,0.735554 0.2978926,0.740504 c -0.007302,0.004218 -0.009703,0.01128 -0.017074,0.0109471 -0.0019,2.38e-4 -0.0053,0.0015 -0.0074,0.0027 -0.0021,0.0013 -0.0045,0.0023 -0.0052,0.0022 -7.25e-4,-4e-5 -0.003,6.6e-4 -0.0052,0.0018 -0.0021,0.0011 -0.0055,0.0019 -0.0077,0.0017 -0.0027,-1.88e-4 -0.0051,5.1e-4 -0.0077,0.0022 -0.0023,0.0017 -0.0054,0.0026 -0.0087,0.0028 -0.0031,1.05e-4 -0.0087,-8.2e-4 -0.0104,3.8e-4 -0.0038,0.0031 -0.01118,0.0042 -0.01596,4.2e-4 -0.0015,-0.0014 -0.005,-0.002 -0.0067,-0.0025 -0.0017,-5e-4 -0.0077,-0.0014 -0.0086,-0.0026 -0.004,-3.4e-4 -0.0177897,-0.008755 -0.0205897,-0.009475 -0.0093,-0.0027 -0.0243401,-0.0222607 -0.0332001,-0.0269007 0.0048,5e-4 0.035025,0.0241535 0.041835,0.0252535 0.0047,7.06e-4 0.0182048,0.004982 0.0250548,0.007582 0.0048,0.0021 0.0086,0.0033 0.01974,-0.0014 0.005,-0.0014 0.01354,-0.0079 0.01771,-0.0085 0.0039,-8.57e-4 0.0075,-0.0019 0.0085,-0.0026 7.14e-4,-6.4e-4 0.0022,-0.0011 0.0031,-0.001 0.0011,8e-5 0.0043,-0.0019 0.0075,-0.0045 0.0033,-0.0025 0.0077,-0.0054 0.01041,-0.0062 0.0025,-0.001 0.0051,-0.0021 0.0054,-0.0028 4.52e-4,-6.16e-4 0.01068,-0.0069 0.0165,-0.0098 0.006,-0.0036 0.0207767,-0.0189814 0.0293767,-0.0220414 0.0084,0.0014 0.007372,-0.006896 0.005972,-0.008396 -0.0014,-0.0014 -0.0035,-0.0034 -0.0045,-0.0045 -8.36e-4,-0.0013 -0.004897,2.9177e-4 -0.007097,-4.0823e-4 -0.0023,-5.97e-4 -0.005399,-0.002199 -0.006599,-0.003499 -0.0013,-0.0013 -0.003801,-0.002201 -0.005601,-0.002701 -0.0019,-5.5e-4 -0.006892,-0.003195 -0.007792,-0.004095 -0.001,-8.31e-4 -0.0124729,-0.003795 -0.0147729,-0.004695 -0.0023,-9.37e-4 -0.0049,-0.0022 -0.0057,-0.003 -0.0014,-0.0013 -0.005205,-0.003205 -0.0124748,-0.007705 -0.004593,-0.002397 -0.0101849,-0.004499 -0.0113849,-0.006499 0.001495,-0.0157653 0.026823,-0.011509 0.0401468,-0.0119075 0.01262,0.0042 0.0184649,0.007591 0.0277746,0.010526 0.0114506,0.006227 0.002949,-0.00327 -0.004448,-0.008318 -0.00364,-0.001863 -0.005049,-0.0108688 3.529e-4,-0.013318 0.006576,-0.001447 0.0107169,0.008423 0.0156173,0.0121233 0.0131015,0.0108794 0.0283375,0.0131218 0.0410076,0.0204627 0.0031,0.0018 0.0064,0.0033 0.0071,0.0034 7.22e-4,5.1e-5 0.003,0.0013 0.0052,0.0025 0.003543,0.002073 0.007841,0.00307 0.011,0.0051 0.002,0.0013 0.0058,0.003 0.0082,0.004 0.0098,0.0035 0.02584,0.01963 0.02603,0.0256 -3.7e-4,0.0048 -0.004,0.0057 -0.01604,0.004 l -0.01138,-0.0016 -0.008689,-0.005799 c -0.008671,-0.0107007 -0.0177168,-0.0164256 -0.0259409,-0.009131 -5.38e-4,0.0075 8.62e-4,0.01009 0.0064,0.01181 0.0027,9.58e-4 0.0057,0.0025 0.0065,0.0033 0.001,9.15e-4 0.0046,0.0024 0.0081,0.0031 0.0036,8.43e-4 0.0079,2.8e-4 0.0092,8.8e-4 0.0017,8.31e-4 0.0045,0.0014 0.0066,0.001 0.0041,-5.66e-4 0.0071,4.54e-4 0.01175,-8e-5 0.0131,-8.71e-4 0.01635,0.0012 0.02069,0.01315 0.0031,0.0076 0.0047,0.01002 0.0081,0.01235 0.0155665,3.928e-5 0.0257979,-0.00526 0.036554,-0.004298 0.009903,7.4753e-4 0.0195173,0.004695 0.0288339,0.008501 0.0100236,0.002713 0.0239854,0.004232 0.0163184,-0.0105439 -0.0013,-0.0025 -0.00509,-0.0127819 -0.00539,-0.0148819 -4.99e-4,-0.0052 -0.003903,-0.008302 -0.011563,-0.0155524 -0.0036,-0.0033 -0.008993,-0.006901 -0.0100934,-0.009201 -7.75e-4,-0.0021 -0.0023,-0.0051 -0.0037,-0.0063 -0.0024,-0.0027 -0.0026,-0.0039 -0.0043,-0.02507 -6.66e-4,-0.0085 -0.0032,-0.01284 -0.0093,-0.01862 C 0.461794,0.6226667 0.4685235,0.6196163 0.4644726,0.6230931 c -0.0084,-0.0012 -0.0115936,-5.0906e-4 -0.0190736,-0.008759 -0.0056,-0.0057 -0.01103,-0.0094 -0.02321,-0.01517 -0.0055,-0.0026 -0.01037,-0.0051 -0.01119,-0.0057 L 0.3967298,0.5825871 C 0.3933298,0.5799871 0.3739911,0.5631797 0.3725372,0.5605521 0.3685802,0.5577221 0.3571996,0.546643 0.3558996,0.545643 0.3498096,0.539355 0.3505866,0.5342533 0.3528366,0.5327294 c 0,0 -5.0242e-4,-0.007704 0.0103976,-0.0120642 0.007592,0.001191 0.01286,1.188e-4 0.01946,0.003199 0.005,0.006 0.008252,0.009201 0.017462,0.0175705 0.01012,0.006 0.0149227,0.00521 0.0204528,0.00991 0.0016,0.0015 0.0035,0.0043 0.0051,0.0049 0.0015,5.78e-4 0.0037,0.0019 0.0049,0.0031 0.0013,0.0013 0.0038,0.0024 0.0054,0.0031 0.0017,4.98e-4 0.0041,0.0022 0.0054,0.0037 0.0013,0.0017 0.0028,0.0029 0.0033,0.0029 5.7e-4,4.3e-5 0.0044,0.0037 0.0084,0.0082 0.008553,0.0113172 0.0142228,0.0148258 0.0186348,0.0149506 0.0049,8.01e-4 0.0130534,0.003192 0.0145534,0.004692 0.0015,0.0013 0.006399,0.003104 0.006399,0.003104 7.24e-4,5e-5 0.008887,0.003394 0.0109873,0.004894 0.004615,0.003213 0.0116051,0.00631 0.0135051,0.00651 7.25e-4,4e-5 0.003,0.0014 0.0052,0.0031 0.0021,0.0016 0.005,0.003 0.0065,0.0032 0.0015,1.04e-4 0.0038,0.0013 0.0052,0.0025 0.0013,0.0013 0.0034,0.0023 0.0043,0.0024 0.0097,0.0057 0.0096,0.01074 0.0084,0.01949 1.67e-4,0.0022 4e-6,0.006 6e-4,0.0086 6.83e-4,0.0028 0.0035,0.0071 0.0038,0.0094 2.55e-4,0.0034 0.0019,0.0059 0.0081,0.01234 0.0041,0.0047 0.0099,0.01005 0.01229,0.01187 0.0024,0.0019 0.0089,0.0039 0.012,0.0063 0.0026,0.0023 0.0039,0.0067 0.0056,0.0079 0.002,0.0013 0.0057,0.0041 0.008,0.006 0.0112,0.0073 0.0154552,0.0152943 0.0285152,0.0189243 0.0011,7.9e-5 0.0047,0.0019 0.0082,0.0039 0.0034,0.002 0.0057,0.0011 0.0064,0.0012 6.59e-4,4.7e-5 0.0019,0.0012 0.0029,0.0023 8.36e-4,0.0013 0.0034,0.0026 0.0056,0.0033 0.0021,5.47e-4 0.0064,0.0025 0.0087,0.0042 0.0064,0.0039 0.0102303,0.008387 0.0180739,0.00592 0.0033,-0.0013 0.0071,-0.0023 0.0083,-0.0022 0.0011,6.5e-5 0.0037,-5.77e-4 0.0061,-0.0017 0.005,-0.0021 0.0137842,-0.007687 0.0245242,-0.006987 0.0093,5.49e-4 0.0269622,0.002811 0.0294922,0.007531 0.0016,0.0027 0.005,0.004101 0.0115854,0.008304 0.01888,0.0064 0.0228109,0.003111 0.0290779,0.002509 0.0027,-5.54e-4 0.017865,0.004379 0.019765,0.004499 0.0057,3.92e-4 0.010446,1.9864e-4 0.018506,0.009709 0.0072,0.0087 0.0079,0.0097 0.01057,0.02099 0.002,0.008 0.0057,0.01101 0.0074,0.01246 0.0026,0.002 0.00501,0.004373 0.00651,0.0139734 9.55e-4,0.0055 -0.00538,0.0114394 -2.8007e-4,0.0170294 0.013,0.01038 0.0297796,0.0246462 0.0433191,0.0275462 0.0157242,-0.003257 0.0271128,-0.008676 0.0360013,0.006635 0.001398,0.003896 0.00227,0.0112438 0.00968,0.0110438 0.0063,-2.79e-4 0.0118849,-0.003389 0.0131849,-9.8974e-4 0.007318,0.003976 0.0128752,0.002103 0.0173121,0.006029 l 0.0113927,0.002729 c 0.01242,0.0016 0.0230613,0.008892 0.0230113,0.0140115 -0.002085,0.009385 0.00408,0.018071 0.011072,0.012494 0.013679,-0.002395 0.022643,-0.003928 0.035422,0.007131 0.002,0.0018 0.013678,0.0139771 0.017078,0.0174771 0.0071,0.0067 0.010096,0.0180143 0.0071,0.0308243 -0.0061,0.01078 -0.017978,0.003739 -0.027458,0.003219 -0.0052,-8.29e-4 -0.024699,-0.004483 -0.029167,-0.00121 -0.00242,0.006465 -0.0093,0.00579 -0.0190045,0.0118849 5.958e-5,0.005665 -0.0171704,0.0100316 -0.0235408,0.0123722 -0.006,0.0047 0.0100151,0.019071 -0.0248883,0.003419 C 0.945256,0.9914923 0.94051,0.9844197 0.9349752,0.9861553 0.921878,1.0004713 0.8996976,0.9941223 0.884337,0.9874853 c -0.006,-0.0025 -0.008,-0.0039 -0.0097,-0.0073 -0.0023,-0.004 -0.0062,-0.0059 -0.0081,-0.0036 -3.88e-4,5.37e-4 -0.0023,5.97e-4 -0.0045,6.9e-5 -0.0035,-8.17e-4 -0.0038,-6.17e-4 -0.0047,0.0021 -5.59e-4,0.0018 -0.002,0.0043 -0.003,0.0057 -0.0013,0.0013 -0.0029,0.0044 -0.0037,0.0065 -0.0022,0.0055 -0.0069,0.0062 -0.0142,0.007 -0.0031,4.36e-4 -0.0097,0.0021 -0.01566,0.0021 -0.0057,1.39e-4 -0.01102,5.02e-4 -0.01209,7.35e-4 -9.1e-4,3.04e-4 -0.0042,-5.48e-4 -0.0073,-0.0019 z"
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

sub nodes{
    my $name;
    if ($script_location eq "internet"){
        my $json_text = get( $url );   # Download the nodes.json
    }
    if ($script_location eq "vpn"){
        open(DATEI, "/var/www/nodes.json") or die "Datei wurde nicht gefunden\n";
            my $daten;
            while(<DATEI>){
                $daten = $daten.$_;
            }
        close (DATEI);
#	print $daten;
        $json_text = $daten;
#	print $json_text;
    }
    my $json        = JSON->new->utf8; #force UTF8 Encoding
    $ffnodes_json = $json->decode( $json_text ); #decode nodes.json
	$anzahl = 0; #Resette Anzahl auf 0
#	print Dumper $ffnodes_json;
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
#	print @node_name;
}




# Ab hier werden die Freifunk Nodes gesucht:
sub svg_nodes{
    if (!defined $anzahl) { nodes(); }
    my $geo_anzahl_nodes = 0;
    my $geo_anzahl_nodes2 = 0;
    while($geo_anzahl_nodes < $anzahl - 1){
        my $geo_nodes_y = $ffnodes_json->{"nodes"}->[$geo_anzahl_nodes]->{"geo"}->[0];
        my $geo_nodes_x = $ffnodes_json->{"nodes"}->[$geo_anzahl_nodes]->{"geo"}->[1];
        if ((defined $geo_nodes_x) and (defined $geo_nodes_y)){
            $svg_ebene_03 .= "\n     <circle\n       style=\"$svg_circle_style\"\n       id=\"svgCircle$geo_anzahl_nodes\"\n";
    #GEO Location:
            $geo_nodes_y = $geo_nodes_y * $geo_nodes_percent_y;
#           $geo_nodes_y = $geo_nodes_y + 6;

            $geo_nodes_y = $geo_nodes_y * -1;
            $geo_nodes_y = $geo_nodes_y + $geo_nodes_mv_y;
            $geo_nodes_y = $geo_nodes_y * 1.00;
            $geo_nodes_x = $geo_nodes_x * 1.00;
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
            if ($geo_anzahl_nodes eq $anzahl - 1){   
 
            my $geo_anzahl_nodes_animation_xtratimelocal = $geo_anzahl_nodes_animation_xtratime + $geo_anzahl_nodes2 - 0.5;
 
                $svg_ebene_03 .= '
                              values="0.15"
                              begin="'.$geo_anzahl_nodes_animation_xtratimelocal.'s" 
                              dur="'.$svg_animation_node_startanimationtime.'s"
                              repeatCount="'.$svg_animation_node_repeatCount.'"
                              fill="freeze"
                          />
                     
                     
                </text>
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


#
#  Ab hier wird die eigendliche Webseite mit den vorher generierten Variabeln erstellt:
#
print "Content-type: $content_type\n";
if ( $generate_html == "true" ){
    print "\n<!DOCTYPE html>\n";
    print "<html lang=\"de\">\n<head>\n\t\n\t<title>$title</title>\n";
    print "<meta charset=\"UTF-8\">\n<meta name=\"description\" content=\"A ffbsee logo - written in perl\">\n<meta name=\"author\" content=\"$author\">\n\n";
    print "<style>$style</style>\n</head>\n\n<body>\n\n";
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

# Ende der SVG:
print "\n</svg>\n";
	
	
if ( $generate_html eq "true" ){
    print  "</body>\n</html>";
}


