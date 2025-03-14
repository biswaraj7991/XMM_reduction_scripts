cd ..
pathname=$(pwd)
export SAS_CCF=$pathname/ccf.cif

echo "enter name of SAS file created."

for file in "$pathname"/*.SAS; do
        sasfilename=$(basename "$file")
        echo "found---> " $sasfilename

done

export SAS_ODF=$pathname/$sasfilename

cd spectra_XMM
echo "choose whether you want circular region (1) or annulur region (2)"
read choice
if [[ $choice -eq 1 ]]
then
 echo "you chose 1-cirular region, proceed to enter values. a,b,rad"
 read asource
 read bsource
 read rad
 
 evselect table=EPICclean.ds withfilteredset=yes filteredset=pn_filtered.evt  keepfilteroutput=yes expression='((X,Y) in CIRCLE('"$asource"','"$bsource"','"$rad"') && gti(EPICgti.ds,TIME))'
 echo "epatplot file name..."
 read patname
 epatplot set=pn_filtered.evt plotfile=$patname
else
 echo "you chose 2-annulur region; enter corrdinates; a,b,inner,outer"
 read asource
 read bsource
 read inner
 read outer
 
 evselect table=EPICclean.ds withfilteredset=yes filteredset=pn_filtered.evt  keepfilteroutput=yes expression='((X,Y) in annulus('"$asource"','"$bsource"','"$inner"','"$outer"') && gti(EPICgti.ds,TIME))'
 echo "epatplot file name..."
 read patname
 epatplot set=pn_filtered.evt plotfile=$patname
 
 
fi

