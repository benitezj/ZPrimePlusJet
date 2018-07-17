
## Set these options before running 
TEST=1  ## 0= all samples,  1= only run one signal sample
SUBMIT=0 ## 0 : only print command, 1 : condor submission, 2 : run in interactive/local machine
EOSOUTPUTDIR=/store/user/benitezj/ggHbb/limits/2017_b14_16july  # where the histograms will be saved from condor job

# which samples to submit
NOMINAL=1
MUONCR=0
LOOSEBTAG=0


## 
LUMI=41.0
echo 'lumi=' $LUMI

## MC
INPUTDIR=/eos/uscms/store/user/benitezj/ggHbb/bits/ggHbits-b14-01
echo 'MC input dir= ' $INPUTDIR

## script to run
HBBSCRIPT=./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_2017.py

## output dir
echo 'local output dir = ' $PWD 
echo 'eos output dir = ' $EOSOUTPUTDIR
if [ ! -d /eos/uscms$EOSOUTPUTDIR ]; then
    mkdir /eos/uscms$EOSOUTPUTDIR
fi


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
    #eval files="$3"
    
    
    local files=`/bin/ls $INPUTDIR/*.root | grep $sample`
    #echo $files


    ## here get the crossection for the sample
    local XS=2.
    echo $XS
 
    ## here get the total initial sum of weights for the sample
    local NEV=`root -q -b DAZSLE/ZPrimePlusJet/fitting/PbbJet/getEvents.C\(\"${INPUTDIR}\",\"${sample}\"\) | grep Total | awk -F" " '{print \$2}'`
    echo $NEV

    ## scale the LUMI by XS/SumWeights
    local SCALE=`echo "$LUMI $XS $NEV" |  awk -F" " '{print $1*$2/$3}'`
    


    ## condor submission
    local COUNTER=0
#    for f in `echo $files | sed s/,/' '/g ` ; do 
    for f in $files; do 
	echo $COUNTER $f 

	local fullcommand="${command} -p '' --lumi $SCALE -f ${f}"

	local outfile=${sample}_${COUNTER}
	local condorsub="/usr/bin/condor_submit $PWD/${outfile}.sub"


	######Only print the command
	if [ "$SUBMIT" == "0" ]; then
	    echo $fullcommand
	fi

	######################
	### create the execution script
	#######################	
	if [ "$SUBMIT" == "1" ]; then
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
	    echo "${fullcommand}" >> $PWD/${outfile}.sh 
	    echo "xrdcp hist.root root://cmseos.fnal.gov/${EOSOUTPUTDIR}/${outfile}.root" >> $PWD/${outfile}.sh 
	    
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
	    
	    
	    echo $fullcommand
	    echo $condorsub
	fi


	####actual condor submission
	if [ "$SUBMIT" == "2" ]; then
	    /bin/rm -f /eos/uscms/${EOSOUTPUTDIR}/${sample}.root
	    /bin/rm -f $PWD/${outfile}.log
	    `${condorsub}`
	fi

	COUNTER=`echo $COUNTER | awk '{print $1+1}'`
     done


}



####################################
### submit the jobs

if [ "$NOMINAL" == "1" ]; then 

 command="python $HBBSCRIPT -o ./ -i root://cmseos.fnal.gov/${INPUTDIR}"
 submit GluGluHToBB_M125_13TeV_powheg_pythia8 "\${command}" 

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



#GluGluHToBB_M125_13TeV_powheg_pythia8
#
#VBFHToBB_M_125_13TeV_powheg_pythia8_weightfix
#WminusH_HToBB_WToQQ_M125_13TeV_powheg_pythia8
#WplusH_HToBB_WToQQ_M125_13TeV_powheg_pythia8
#ZH_HToBB_ZToNuNu_M125_13TeV_powheg_pythia8
#ZH_HToBB_ZToQQ_M125_13TeV_powheg_pythia8
#ggZH_HToBB_ZToNuNu_M125_13TeV_powheg_herwigpp
#ggZH_HToBB_ZToQQ_M125_13TeV_powheg_pythia8
#ttHTobb_M125_TuneCP5_13TeV_powheg_pythia8
#
#DYJetsToLL_M_50_HT_100to200_TuneCP5_13TeV
#DYJetsToLL_M_50_HT_200to400_TuneCP5_13TeV
#DYJetsToLL_M_50_HT_400to600_TuneCP5_13TeV
#DYJetsToLL_M_50_HT_600to800_TuneCP5_13TeV
#DYJetsToLL_M_50_HT_800to1200_TuneCP5_13TeV
#
#WJetsToLNu_HT_100To200_TuneCP5_13TeV
#WJetsToLNu_HT_1200To2500_TuneCP5_13TeV
#WJetsToLNu_HT_200To400_TuneCP5_13TeV
#WJetsToLNu_HT_400To600_TuneCP5_13TeV
#WJetsToLNu_HT_600To800_TuneCP5_13TeV
#WJetsToLNu_HT_800To1200_TuneCP5_13TeV
#
#WW_TuneCP5_13TeV_pythia8
#WZ_TuneCP5_13TeV_pythia8
#ZZ_TuneCP5_13TeV_pythia8
#
#ST_tW_antitop_5f_inclusiveDecays_TuneCP5_13TeV_powheg_pythia8
#ST_tW_top_5f_inclusiveDecays_TuneCP5_13TeV_powheg_pythia8
#ST_t_channel_antitop_4f_inclusiveDecays_TuneCP5_13TeV_powhegV2_madspin_pythia8
#ST_t_channel_top_4f_inclusiveDecays_TuneCP5_13TeV_powhegV2_madspin_pythia8
#
#TTJets_TuneCP5_13TeV_amcatnloFXFX_pythia8
#TTTo2L2Nu_TuneCP5_13TeV_powheg_pythia8
#TTToSemiLeptonic_WspTgt150_TuneCUETP8M2T4_13TeV_powheg_pythia8
#
#CD_HT1000to1500_TuneCP5_13TeV_madgraph_pythia8
#CD_HT100to200_TuneCP5_13TeV_madgraph_pythia8
#CD_HT1500to2000_TuneCP5_13TeV_madgraph_pythia8
#CD_HT2000toInf_TuneCP5_13TeV_madgraph_pythia8
#CD_HT200to300_TuneCP5_13TeV_madgraph_pythia8
#CD_HT300to500_TuneCP5_13TeV_madgraph_pythia8
#CD_HT500to700_TuneCP5_13TeV_madgraph_pythia8
#CD_HT700to1000_TuneCP5_13TeV_madgraph_pythia8
#
#JetHTRun2017B_17Nov2017_v1
#JetHTRun2017C_17Nov2017_v1
#JetHTRun2017D_17Nov2017_v1
#JetHTRun2017E_17Nov2017_v1
#JetHTRun2017F_17Nov2017_v1
#
#SingleMuonRun2017B_17Nov2017_v1
#SingleMuonRun2017C_17Nov2017_v1
#SingleMuonRun2017D_17Nov2017_v1
#SingleMuonRun2017E_17Nov2017_v1
#SingleMuonRun2017F_17Nov2017_v1
