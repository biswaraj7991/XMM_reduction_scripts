
echo "Enter path of ODF and PPS" 

pathname=$(pwd)
echo $pathname
echo $pathname/ODF

gunzip $pathname/ODF/*.*
gunzip $pathname/PPS/*.*

export SAS_ODF=$pathname/ODF

echo "unzipping done. next cifbuild"

cifbuild

export SAS_CCF=$pathname/ccf.cif


echo " Running odfingest"

odfingest
echo "enter name of SAS file created."
#read sasfilename
for file in "$pathname"/*.SAS; do
        sasfilename=$(basename "$file")
        echo "found---> " $sasfilename

done


export SAS_ODF=$pathname/$sasfilename
#: <<'END'
mkdir spectra_XMM

cd spectra_XMM

epproc

for file in *ImagingEvts.ds; do
	mv "$file" "EPIC.ds"
done
figlet "EPIC.ds"

evselect table=EPIC.ds withrateset=Y rateset=rateEPIC.ds maketimecolumn=Y timebinsize=25 makeratecolumn=Y expression='#XMMEA_EP && (PI>10000 && PI<12000) && (PATTERN==0)'

echo "check with dsplot..."

dsplot table=rateEPIC.ds x=TIME y=RATE.ERROR


echo "Apply rate cut value"
read RATE

tabgtigen table=rateEPIC.ds expression='(RATE<='"$RATE"')' gtiset=EPICgti.ds

evselect table=EPIC.ds withfilteredset=Y filteredset=EPICclean.ds destruct=Y keepfilteroutput=T expression='#XMMEA_EP && gti(EPICgti.ds,TIME) && (PI >150)'

evselect table=EPICclean.ds imagebinning=binSize imageset=PNimage.ds withimageset=yes xcolumn=X ycolumn=Y ximagebinsize=80 yimagebinsize=80
figlet "Finished pre-processing"


figlet "pileup"
mv $pathname/pileup_checker.sh $pathname/spectra_XMM
bash pileup_checker.sh

echo "starting final spectrum extraction for ep pn with annulur region for source. Enter the physical cooridnates plz!"

echo "choose whether you want circular region (1) or annulur region (2)"
read choice
if [[ $choice -eq 1 ]]
then
 echo "you chose 1-cirular region, proceed to enter values. a,b,outer radius"
 read asource
 read bsource
 read outer
 
 evselect table=EPICclean.ds withspectrumset=yes spectrumset=PNsource_spectrum.ds energycolumn=PI spectralbinsize=5    withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0)   && (PATTERN<=4) && ((X,Y) IN circle('"$asource"','"$bsource"','"$outer"'))'
else
 echo "you chose 2-annulur region; enter corrdinates; a,b,inner,outer"
 read asource
 read bsource
 read inner
 read outer
 
 evselect table=EPICclean.ds withspectrumset=yes spectrumset=PNsource_spectrum.ds energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0) &&  (PATTERN<=4) && ((X,Y) IN annulus('"$asource"','"$bsource"','"$inner"','"$outer"'))'

fi




echo "starting final spectrum extraction for ep pn with outer circular region for backgrnd. Enter the physical cooridnates plz!"
read abkg
read bbkg
evselect table=EPICclean.ds withspectrumset=yes spectrumset=PNbkg_spectrum.ds  energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle('"$abkg"','"$bbkg"','"$outer"'))'




backscale spectrumset=PNsource_spectrum.ds badpixlocation=EPICclean.ds

backscale spectrumset=PNbkg_spectrum.ds badpixlocation=EPICclean.ds

rmfgen spectrumset=PNsource_spectrum.ds rmfset=PN.rmf

arfgen spectrumset=PNsource_spectrum.ds arfset=PN.arf withrmfset=yes rmfset=PN.rmf badpixlocation=EPICclean.ds detmaptype=psf

echo "This is the end. Move on to grouping.!"


specgroup spectrumset=PNsource_spectrum.ds mincounts=30 oversample=3 rmfset=PN.rmf arfset=PN.arf backgndset=PNbkg_spectrum.ds groupedset=PN_spectrum_grp.ds

cd ..
#END
mkdir photometry_OM
cd photometry_OM

mkdir om_fast
mkdir om_image
mkdir om_grism

cd om_image
omichain

cd ..

cd om_fast
omfchain
cd ..

cd om_grism
omgchain
cd ..
cd ..
cd spectra_XMM
figlet "GRPPHA"

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


figlet "Done !"
