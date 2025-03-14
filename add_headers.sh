echo "Adding headers to source spectrum file for XSPEC to automatically grep them"

fparkey PNbkg_spectrum.ds PNsource_spectrum.ds+1 BACKFILE
fparkey PN.rmf PNsource_spectrum.ds+1 RESPFILE
fparkey PN.arf PNsource_spectrum.ds+1 ANCRFILE

echo " Now do you want to bin the data using min counts of grppha ? (y/n) "
read ans
if [[ "$ans" == "y" ]]; then
echo "Good. Proceeding further...!"
fi

echo "using grppha....."

grppha
