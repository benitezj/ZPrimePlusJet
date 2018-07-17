
## Set these options before running 
TEST=1  ## 0= all samples,  1= only run one signal sample
SUBMIT=0 ## 0 : only print command, 1 : condor submission, 2 : run in interactive/local machine
EOSOUTPUTDIR=/store/user/benitezj/ggHbb/limits/2017_b13_TrigMuIdIso  # where the histograms will be saved from condor job

# which samples to submit
NOMINAL=1
MUONCR=1
LOOSEBTAG=1


## 
LUMI=41.0
echo 'lumi=' $LUMI

## MC
INPUTDIR=/eos/uscms/store/user/lpcbacon/dazsle/zprimebits-v12.07/norm
echo 'MC input dir= ' $INPUTDIR

## data
INPUTDIRDATA=/eos/uscms/store/user/lpcbacon/dazsle/zprimebits-v12.07/sklim
echo 'data input dir= ' $INPUTDIRDATA

## use some 2016 samples from here
INPUTDIR2016=/eos/uscms/store/user/lpchbb/zprimebits-v12.04/cvernier
echo 'temp 2016 samples dir= ' $INPUTDIR2016


## script to run
HBBSCRIPT=./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_2017.py

## output dir
echo 'local output dir = ' $PWD 
echo 'eos output dir = ' $EOSOUTPUTDIR



##############################################
### need to tar the CMSSW to submit condor job
if [ "${SUBMIT}" == "1" ]; then
    /bin/rm -f ${CMSSW_BASE}.tar
    /bin/tar -cvf ${CMSSW_BASE}.tar -C $CMSSW_BASE/../ $CMSSW_VERSION
    if [ ! -f ${CMSSW_BASE}.tar ]; then
	echo "CMSSW tar not created"
	return 0
    fi
fi

### job submision function needed below
submit()
{
    eval sample="$1"
    eval command="$2"
    eval files="$3"
    #echo $files

    ## condor submission
    local COUNTER=0
#    for f in `echo $files | sed s/,/' '/g ` ; do 
    for f in $files; do 
	echo $COUNTER $f 

	############
	## clean out the output
	#########
	local outfile=hist_${sample}_${COUNTER}
	/bin/rm -f $PWD/${outfile}.log

	######################
	### create the execution script
	#######################
	/bin/rm -f $PWD/${outfile}.sh
	touch $PWD/${outfile}.sh
	echo "pwd"  >> $PWD/${outfile}.sh
	echo "mount"  >> $PWD/${outfile}.sh
        echo "/bin/tar -xf ${CMSSW_VERSION}.tar"  >> $PWD/${outfile}.sh
	echo "ls ."  >> $PWD/${outfile}.sh
	echo "source /cvmfs/cms.cern.ch/cmsset_default.sh"  >> $PWD/${outfile}.sh
        echo "export SCRAM_ARCH=slc6_amd64_gcc530"  >> $PWD/${outfile}.sh 
	echo "cd ./${CMSSW_VERSION}/src"  >> $PWD/${outfile}.sh
	echo "scramv1 b ProjectRename "  >> $PWD/${outfile}.sh
	echo "eval \`scramv1 runtime -sh\` "  >> $PWD/${outfile}.sh
        echo "cd DAZSLE/ZPrimePlusJet/"  >> $PWD/${outfile}.sh
	echo "source setup.sh"  >> $PWD/${outfile}.sh
	echo "cd ../../"  >> $PWD/${outfile}.sh
	echo "env"  >> $PWD/${outfile}.sh
	echo "${command} ${f}" >> $PWD/${outfile}.sh 
	echo "xrdcp hist.root root://cmseos.fnal.gov/${EOSOUTPUTDIR}/${outfile}.root" >> $PWD/${outfile}.sh 
	
	################
	### create condor jdl
	################
	/bin/rm -f $PWD/${outfile}.sub
	touch $PWD/${outfile}.sub
	echo "Universe   = vanilla" >> $PWD/${outfile}.sub 
	echo "Executable = /bin/bash" >> $PWD/${outfile}.sub 
	echo "Log        = $PWD/${outfile}.log" >> $PWD/${outfile}.sub
	echo "Output     = $PWD/${outfile}.log" >> $PWD/${outfile}.sub
	echo "Error      = $PWD/${outfile}.log" >> $PWD/${outfile}.sub
	echo "Arguments  = ${outfile}.sh" >> $PWD/${outfile}.sub
	echo "Should_Transfer_Files = YES" >> $PWD/${outfile}.sub
	echo "WhenToTransferOutput = ON_EXIT" >> $PWD/${outfile}.sub
	echo "Transfer_Input_Files = ${PWD}/${outfile}.sh, ${CMSSW_BASE}.tar" >> $PWD/${outfile}.sub
	echo "Queue" >> $PWD/${outfile}.sub
    

	local condorsub="/usr/bin/condor_submit $PWD/${outfile}.sub"
	echo $condorsub
	if [ "$SUBMIT" == "1" ]; then
	    /bin/rm -f /eos/uscms/${EOSOUTPUTDIR}/hist_${sample}.root
	    `${condorsub}`
	else 
	    echo $command $f
	fi

	COUNTER=`echo $COUNTER | awk '{print $1+1}'`
     done


}


#################################
## Define input files
GGHBBFILES=GluGluHToBB_M125_13TeV_powheg_pythia8_1000pb_weighted.root

VBFHBBFILES=VBFHToBB_M_125_13TeV_powheg_pythia8_weightfix_all_1000pb_weighted.root

ZHFILES=`/bin/ls $INPUTDIR2016 | grep ZH_HToBB | grep 1000pb_weighted | tr '\n' ' '`

WHFILES="WminusH_HToBB_WToQQ_M125_13TeV_powheg_pythia8_1000pb_weighted.root WplusH_HToBB_WToQQ_M125_13TeV_powheg_pythia8_1000pb_weighted.root"

TTHBBFILES=ttHTobb_M125_13TeV_powheg_pythia8_1000pb_weighted.root

DYLLFILES=DYJetsToLL_M_50_13TeV_ext_1000pb_weighted.root

DYQQFILES=DYJetsToQQ_HT180_13TeV_1000pb_weighted_v1204.root

WFILES=`/bin/ls $INPUTDIR2016 | grep WJetsToLNu_HT_ | grep 1000pb_weighted | tr '\n' ' '`

WQQFILES=WJetsToQQ_HT180_13TeV_1000pb_weighted_v1204.root

TTFILES="TTToHadronic_TuneCP5_13TeV_powheg_pythia8_byLumi_1000pb_weighted.root TTToSemiLeptonic_TuneCP5_13TeV_powheg_pythia8_byLumi_1000pb_weighted.root"

VVFILES="WW_TuneCP5_13TeV_pythia8_1000pb_weighted.root WZ_TuneCP5_13TeV_pythia8_1000pb_weighted.root ZZ_TuneCP5_13TeV_pythia8_1000pb_weighted.root"

STFILES=`/bin/ls $INPUTDIR | grep ST_ | grep TuneCP5 | grep 1000pb_weighted | tr '\n' ' '`

QCDFILES=`/bin/ls $INPUTDIR | grep QCD_HT | grep TuneCP5 | grep 1000pb_weighted | tr '\n' ' '`

DATAFILES=`/bin/ls $INPUTDIRDATA | grep JetHTRun2017 | tr '\n' ' '`

MUONCRFILES=`/bin/ls $INPUTDIRDATA | grep SingleMuonRun2017 | tr '\n' ' '`


####################################
### submit the jobs

if [ "$NOMINAL" == "1" ]; then 

 command="python $HBBSCRIPT -p hqq125  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
 submit "hqq125" "\${command}" "\${GGHBBFILES}"

 if [ "$TEST" == "1" ]; then return 1 ; fi

 
 command="python $HBBSCRIPT -p vbfhqq125  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "vbfhqq125" "\${command}" "\${VBFHBBFILES}"
 
 command="python $HBBSCRIPT -p zhqq125  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "zhqq125" "\${command}" "\${ZHFILES}"
 
 command="python $HBBSCRIPT -p whqq125  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "whqq125" "\${command}" "\${WHFILES}"
 
 command="python $HBBSCRIPT -p tthqq125  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "tthqq125" "\${command}" "\${TTHBBFILES}"
 
 command="python $HBBSCRIPT -p vvqq  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
 submit "vvqq" "\${command}" "\${VVFILES}"
 
 command="python $HBBSCRIPT -p zqq  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "zqq" "\${command}" "\${DYQQFILES}"
 
 command="python $HBBSCRIPT -p stqq  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
 submit "stqq" "\${command}" "\${STFILES}"
 
 command="python $HBBSCRIPT -p wqq  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "wqq" "\${command}" "\${WQQFILES}"
 
 command="python $HBBSCRIPT -p wlnu  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "wlnu" "\${command}" "\${WFILES}"
 
 command="python $HBBSCRIPT -p zll  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "zll" "\${command}" "\${DYLLFILES}"
 
 command="python $HBBSCRIPT -p tqq  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
 submit "tqq" "\${command}" "\${TTFILES}"
 
 command="python $HBBSCRIPT -p qcd  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
 submit "qcd" "\${command}" "\${QCDFILES}"
 
 command="python $HBBSCRIPT -p data_obs --data --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIRDATA} -f "
 submit "data_obs" "\${command}" "\${DATAFILES}"
 
fi

###############################################
###  MuonCR 
##############################################
### (WARNING: muonCR and nominal cannot run in the same directory because they will write to same output file name)
if [ "$MUONCR" == "1" ]; then 

 command="python $HBBSCRIPT -p hqq125  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "hqq125_muonCR" "\${command}" "\${GGHBBFILES}"
 
 command="python $HBBSCRIPT -p vbfhqq125  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "vbfhqq125_muonCR" "\${command}" "\${VBFHBBFILES}"
 
 command="python $HBBSCRIPT -p zhqq125  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "zhqq125_muonCR" "\${command}" "\${ZHFILES}"
 
 command="python $HBBSCRIPT -p whqq125  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "whqq125_muonCR" "\${command}" "\${WHFILES}"
 
 command="python $HBBSCRIPT -p tthqq125  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "tthqq125_muonCR" "\${command}" "\${TTHBBFILES}"
 
 command="python $HBBSCRIPT -p vvqq  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
 submit "vvqq_muonCR" "\${command}" "\${VVFILES}"
 
 command="python $HBBSCRIPT -p zqq  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "zqq_muonCR" "\${command}" "\${DYQQFILES}"
 
 command="python $HBBSCRIPT -p stqq  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
 submit "stqq_muonCR" "\${command}" "\${STFILES}"
 
 command="python $HBBSCRIPT -p wqq  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "wqq_muonCR" "\${command}" "\${WQQFILES}"
 
 command="python $HBBSCRIPT -p wlnu  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "wlnu_muonCR" "\${command}" "\${WFILES}"
 
 command="python $HBBSCRIPT -p zll  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
 submit "zll_muonCR" "\${command}" "\${DYLLFILES}"
 
 command="python $HBBSCRIPT -p tqq  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
 submit "tqq_muonCR" "\${command}" "\${TTFILES}"
 
 command="python $HBBSCRIPT -p qcd  --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
 submit "qcd_muonCR" "\${command}" "\${QCDFILES}"
 
 command="python $HBBSCRIPT -p data_obs --data --muonCR  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIRDATA} -f "
 submit "data_obs_muonCR" "\${command}" "\${MUONCRFILES}"

fi

#############################################
### Templates with Loose BB cut (0.8)
############################################
if [ "$LOOSEBTAG" == "1" ]; then
 
command="python $HBBSCRIPT -p hqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
submit "hqq125_looserWZ" "\${command}" "\${GGHBBFILES}"

command="python $HBBSCRIPT -p vbfhqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
submit "vbfhqq125_looserWZ" "\${command}" "\${VBFHBBFILES}"

command="python $HBBSCRIPT -p zhqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
submit "zhqq125_looserWZ" "\${command}" "\${ZHFILES}"

command="python $HBBSCRIPT -p whqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
submit "whqq125_looserWZ" "\${command}" "\${WHFILES}"

command="python $HBBSCRIPT -p tthqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
submit "tthqq125_looserWZ" "\${command}" "\${TTHBBFILES}"

command="python $HBBSCRIPT -p vvqq   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
submit "vvqq_looserWZ" "\${command}" "\${VVFILES}"

command="python $HBBSCRIPT -p zqq   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
submit "zqq_looserWZ" "\${command}" "\${DYQQFILES}"

command="python $HBBSCRIPT -p stqq   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
submit "stqq_looserWZ" "\${command}" "\${STFILES}"

command="python $HBBSCRIPT -p wqq   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
submit "wqq_looserWZ" "\${command}" "\${WQQFILES}"

command="python $HBBSCRIPT -p wlnu   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
submit "wlnu_looserWZ" "\${command}" "\${WFILES}"

command="python $HBBSCRIPT -p zll   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR2016} -f "
submit "zll_looserWZ" "\${command}" "\${DYLLFILES}"

command="python $HBBSCRIPT -p tqq   --dbtag 0.8  --lumi $LUMI -o ./ -i root://cmseos.fnal.gov/${INPUTDIR} -f "
submit "tqq_looserWZ" "\${command}" "\${TTFILES}"

fi


#### show the jobs in the queue
if [ "${SUBMIT}" == "1" ]; then
    /usr/bin/condor_q
fi
