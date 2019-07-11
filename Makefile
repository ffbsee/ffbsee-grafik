all:
	# Create png from svg
	inkscape --without-gui --export-png="export/Logo_FFBSee.svg.png" Logo_FFBSee.svg
	inkscape --without-gui --export-png="export/webseite.svg.png" webseite.svg
	inkscape --without-gui --export-png="export/technikcamp2019-black.svg.png" events/technikcamp2019-black.svg
	inkscape --without-gui --export-png="export/ffbsee-backbone.svg.png" ffbsee-backbone.svg
