
## Set these options before running 
TEST=0  ## 0= all 1= only run one signal sample
SUBMIT=1 ## 0 : only print command, 1 : condor submission, 2 : run in interactive/local machine
EOSOUTPUTDIR=/store/user/benitezj/ggHbb/limits/2017  # where the histograms will be saved from condor job

# which samples to submit
NOMINAL=1
MUONCR=1
LOOSEBTAG=1


## 
LUMI=35.9
echo 'lumi=' $LUMI

## MC
INPUTDIR=root://cmseos.fnal.gov//eos/uscms/store/user/lpchbb/zprimebits-v12.04/cvernier
echo 'MC input dir= ' $INPUTDIR

## hqq125 and data
INPUTDIRDATA=root://cmseos.fnal.gov//eos/uscms/store/user/lpchbb/zprimebits-v12.05
echo 'data input dir= ' $INPUTDIRDATA

## script to run
HBBSCRIPT=./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py

## output dir
echo 'local output dir = ' $PWD 
echo 'eos output dir = ' $EOSOUTPUTDIR

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
    
    local outfile=$PWD/ggHbb_${sample}
    
    /bin/rm -f ${outfile}.log


    ## no run, just print the command 
    if [ "$SUBMIT" == "0" ]; then
	echo $command	
    fi

    ## condor submission
    if [ "$SUBMIT" == "1" ]; then

	############
	## clean out the output
	#########
	/bin/rm -f /eos/uscms/${EOSOUTPUTDIR}/hist_${sample}.root

	######################
	### create the execution script
	#######################
	/bin/rm -f ${outfile}.sh
	touch ${outfile}.sh
	echo "pwd"  >> ${outfile}.sh
	echo "mount"  >> ${outfile}.sh
        echo "/bin/tar -xf ${CMSSW_VERSION}.tar"  >> ${outfile}.sh
	echo "ls ."  >> ${outfile}.sh
	echo "source /cvmfs/cms.cern.ch/cmsset_default.sh"  >> ${outfile}.sh
        echo "export SCRAM_ARCH=slc6_amd64_gcc530"  >> ${outfile}.sh 
	echo "cd ./${CMSSW_VERSION}/src"  >> ${outfile}.sh
	echo "scramv1 b ProjectRename "  >> ${outfile}.sh
	echo "eval \`scramv1 runtime -sh\` "  >> ${outfile}.sh
        echo "cd DAZSLE/ZPrimePlusJet/"  >> ${outfile}.sh
	echo "source setup.sh"  >> ${outfile}.sh
	echo "cd ../../"  >> ${outfile}.sh
	echo "env"  >> ${outfile}.sh
	echo "${command}" >> ${outfile}.sh 
	echo "xrdcp hist.root root://cmseos.fnal.gov/${EOSOUTPUTDIR}/hist_${sample}.root" >> ${outfile}.sh 
	


	################
	### create condor jdl
	################
	/bin/rm -f ${outfile}.sub
	touch ${outfile}.sub
	echo "Universe   = vanilla" >> ${outfile}.sub 
	echo "Executable = /bin/bash" >> ${outfile}.sub 
	echo "Log        = ${outfile}.log" >> ${outfile}.sub
	echo "Output     = ${outfile}.log" >> ${outfile}.sub
	echo "Error      = ${outfile}.log" >> ${outfile}.sub
	echo "Arguments  = ggHbb_${sample}.sh" >> ${outfile}.sub
	echo "Should_Transfer_Files = YES" >> ${outfile}.sub
	echo "WhenToTransferOutput = ON_EXIT" >> ${outfile}.sub
	echo "Transfer_Input_Files = ggHbb_${sample}.sh, ${CMSSW_BASE}.tar" >> ${outfile}.sub


	echo "Queue" >> ${outfile}.sub
    
	local condorsub="/usr/bin/condor_submit ${outfile}.sub"
	echo $condorsub
	`${condorsub}`
    fi

     ##process in the local machine (testing)
    if [ "$SUBMIT" == "2" ]; then
	echo $command
	`${command} >> ${outfile}.log 2>&1 &`
    fi
}
  

submitMany()
{
    eval sample="$1"
    eval command="$2"
    eval files="$3"
    
    ## condor submission
    local COUNTER=0
    for f in `echo $files | sed s/,/' '/g ` ; do 
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
GGHBBFILES=GluGluHToBB_M125_13TeV_powheg_pythia8_CKKW_1000pb_weighted.root
VBFHBBFILES=VBFHToBB_M_125_13TeV_powheg_pythia8_weightfix_all_1000pb_weighted.root
ZHFILES=ZH_HToBB_ZToQQ_M125_13TeV_powheg_pythia8_1000pb_weighted.root,ggZH_HToBB_ZToNuNu_M125_13TeV_powheg_pythia8_1000pb_weighted.root,ZH_HToBB_ZToNuNu_M125_13TeV_powheg_pythia8_ext_1000pb_weighted.root,ggZH_HToBB_ZToQQ_M125_13TeV_powheg_pythia8_1000pb_weighted.root
WHFILES=WminusH_HToBB_WToQQ_M125_13TeV_powheg_pythia8_1000pb_weighted.root,WplusH_HToBB_WToQQ_M125_13TeV_powheg_pythia8_1000pb_weighted.root
TTHBBFILES=ttHTobb_M125_13TeV_powheg_pythia8_1000pb_weighted.root

DYLLFILES=DYJetsToLL_M_50_13TeV_ext_1000pb_weighted.root
DYQQFILES=DYJetsToQQ_HT180_13TeV_1000pb_weighted_v1204.root

WFILES=WJetsToLNu_HT_100To200_13TeV_1000pb_weighted.root,WJetsToLNu_HT_200To400_13TeV_1000pb_weighted.root,WJetsToLNu_HT_400To600_13TeV_1000pb_weighted.root,WJetsToLNu_HT_600To800_13TeV_1000pb_weighted.root,WJetsToLNu_HT_800To1200_13TeV_1000pb_weighted.root,WJetsToLNu_HT_1200To2500_13TeV_1000pb_weighted.root
WQQFILES=WJetsToQQ_HT180_13TeV_1000pb_weighted_v1204.root

TTFILES=TT_powheg_1000pb_weighted_v1204.root

VVFILES=WWTo4Q_13TeV_powheg_1000pb_weighted.root,ZZ_13TeV_pythia8_1000pb_weighted.root,WZ_13TeV_pythia8_1000pb_weighted.root

STFILES=ST_t_channel_antitop_4f_inclusiveDecays_TuneCUETP8M2T4_13TeV_powhegV2_madspin_1000pb_weighted.root,ST_t_channel_top_4f_inclusiveDecays_TuneCUETP8M2T4_13TeV_powhegV2_madspin_1000pb_weighted.root,ST_tW_antitop_5f_inclusiveDecays_13TeV_powheg_pythia8_TuneCUETP8M2T4_1000pb_weighted.root,ST_tW_top_5f_inclusiveDecays_13TeV_powheg_pythia8_TuneCUETP8M2T4_1000pb_weighted.root

QCDFILES=QCD_HT100to200_13TeV_1000pb_weighted.root,QCD_HT200to300_13TeV_all_1000pb_weighted.root,QCD_HT300to500_13TeV_all_1000pb_weighted.root,QCD_HT500to700_13TeV_ext_1000pb_weighted.root,QCD_HT700to1000_13TeV_ext_1000pb_weighted.root,QCD_HT1000to1500_13TeV_all_1000pb_weighted.root,QCD_HT1500to2000_13TeV_all_1000pb_weighted.root,QCD_HT2000toInf_13TeV_1000pb_weighted.root

DATAFILES=JetHTRun2016B_03Feb2017_ver2_v2_v3.root,JetHTRun2016B_03Feb2017_ver1_v1_v3.root,JetHTRun2016C_03Feb2017_v1_v3_0.root,JetHTRun2016C_03Feb2017_v1_v3_1.root,JetHTRun2016C_03Feb2017_v1_v3_2.root,JetHTRun2016C_03Feb2017_v1_v3_3.root,JetHTRun2016C_03Feb2017_v1_v3_4.root,JetHTRun2016C_03Feb2017_v1_v3_5.root,JetHTRun2016C_03Feb2017_v1_v3_6.root,JetHTRun2016C_03Feb2017_v1_v3_7.root,JetHTRun2016C_03Feb2017_v1_v3_8.root,JetHTRun2016C_03Feb2017_v1_v3_9.root,JetHTRun2016D_03Feb2017_v1_v3_0.root,JetHTRun2016D_03Feb2017_v1_v3_1.root,JetHTRun2016D_03Feb2017_v1_v3_10.root,JetHTRun2016D_03Feb2017_v1_v3_11.root,JetHTRun2016D_03Feb2017_v1_v3_12.root,JetHTRun2016D_03Feb2017_v1_v3_13.root,JetHTRun2016D_03Feb2017_v1_v3_14.root,JetHTRun2016D_03Feb2017_v1_v3_2.root,JetHTRun2016D_03Feb2017_v1_v3_3.root,JetHTRun2016D_03Feb2017_v1_v3_4.root,JetHTRun2016D_03Feb2017_v1_v3_5.root,JetHTRun2016D_03Feb2017_v1_v3_6.root,JetHTRun2016D_03Feb2017_v1_v3_7.root,JetHTRun2016D_03Feb2017_v1_v3_8.root,JetHTRun2016D_03Feb2017_v1_v3_9.root,JetHTRun2016E_03Feb2017_v1_v3_0.root,JetHTRun2016E_03Feb2017_v1_v3_1.root,JetHTRun2016E_03Feb2017_v1_v3_2.root,JetHTRun2016E_03Feb2017_v1_v3_3.root,JetHTRun2016E_03Feb2017_v1_v3_4.root,JetHTRun2016E_03Feb2017_v1_v3_5.root,JetHTRun2016E_03Feb2017_v1_v3_6.root,JetHTRun2016E_03Feb2017_v1_v3_7.rootJetHTRun2016E_03Feb2017_v1_v3_8.root,JetHTRun2016E_03Feb2017_v1_v3_9.root,JetHTRun2016E_03Feb2017_v1_v3_10.root,JetHTRun2016E_03Feb2017_v1_v3_11.root,JetHTRun2016E_03Feb2017_v1_v3_12.root,JetHTRun2016E_03Feb2017_v1_v3_13.root,JetHTRun2016E_03Feb2017_v1_v3_14.root,JetHTRun2016F_03Feb2017_v1_v3_0.root,JetHTRun2016F_03Feb2017_v1_v3_1.root,JetHTRun2016F_03Feb2017_v1_v3_2.root,JetHTRun2016F_03Feb2017_v1_v3_3.root,JetHTRun2016F_03Feb2017_v1_v3_4.root,JetHTRun2016F_03Feb2017_v1_v3_5.root,JetHTRun2016F_03Feb2017_v1_v3_6.root,JetHTRun2016F_03Feb2017_v1_v3_7.root,JetHTRun2016F_03Feb2017_v1_v3_8.root,JetHTRun2016F_03Feb2017_v1_v3_9.root,JetHTRun2016F_03Feb2017_v1_v3_10.root,JetHTRun2016G_03Feb2017_v1_v3_0.root,JetHTRun2016G_03Feb2017_v1_v3_1.root,JetHTRun2016G_03Feb2017_v1_v3_2.root,JetHTRun2016G_03Feb2017_v1_v3_3.root,JetHTRun2016G_03Feb2017_v1_v3_4.root,JetHTRun2016G_03Feb2017_v1_v3_5.root,JetHTRun2016G_03Feb2017_v1_v3_6.root,JetHTRun2016G_03Feb2017_v1_v3_7.root,JetHTRun2016G_03Feb2017_v1_v3_8.root,JetHTRun2016G_03Feb2017_v1_v3_9.root,JetHTRun2016G_03Feb2017_v1_v3_10.root,JetHTRun2016G_03Feb2017_v1_v3_11.root,JetHTRun2016G_03Feb2017_v1_v3_12.root,JetHTRun2016G_03Feb2017_v1_v3_13.root,JetHTRun2016G_03Feb2017_v1_v3_14.root,JetHTRun2016G_03Feb2017_v1_v3_15.root,JetHTRun2016G_03Feb2017_v1_v3_16.root,JetHTRun2016G_03Feb2017_v1_v3_17.root,JetHTRun2016G_03Feb2017_v1_v3_18.root,JetHTRun2016G_03Feb2017_v1_v3_19.root,JetHTRun2016G_03Feb2017_v1_v3_20.root,JetHTRun2016G_03Feb2017_v1_v3_21.root,JetHTRun2016G_03Feb2017_v1_v3_22.root,JetHTRun2016G_03Feb2017_v1_v3_23.root,JetHTRun2016G_03Feb2017_v1_v3_24.root,JetHTRun2016G_03Feb2017_v1_v3_25.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_0.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_1.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_2.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_3.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_4.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_5.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_6.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_7.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_8.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_9.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_10.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_11.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_12.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_13.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_14.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_15.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_16.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_17.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_18.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_19.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_20.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_21.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_22.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_23.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_24.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_25.root,JetHTRun2016H_03Feb2017_ver3_v1_v3.root


MUONCRFILES=SingleMuonRun2016B_03Feb2017_ver1_v1_fixtrig.root,SingleMuonRun2016B_03Feb2017_ver2_v2_fixtrig.root,SingleMuonRun2016C_03Feb2017_v1_fixtrig.root,SingleMuonRun2016D_03Feb2017_v1_fixtrig.root,SingleMuonRun2016E_03Feb2017_v1_fixtrig.root,SingleMuonRun2016F_03Feb2017_v1_fixtrig.root,SingleMuonRun2016G_03Feb2017_v1_fixtrig.root,SingleMuonRun2016H_03Feb2017_ver2_v1_fixtrig.root,SingleMuonRun2016H_03Feb2017_ver3_v1_fixtrig.root


####################################
### submit the jobs

if [ "$NOMINAL" == "1" ]; then 

 command="python $HBBSCRIPT -p hqq125  --lumi $LUMI -o ./ -i $INPUTDIRDATA -f "
 submitMany "hqq125" "\${command}" $GGHBBFILES

 if [ "$TEST" == "1" ]; then return 1 ; fi

 
 command="python $HBBSCRIPT -p vbfhqq125  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "vbfhqq125" "\${command}" $VBFHBBFILES
 
 command="python $HBBSCRIPT -p zhqq125  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "zhqq125" "\${command}" $ZHFILES
 
 command="python $HBBSCRIPT -p whqq125  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "whqq125" "\${command}" $WHFILES
 
 command="python $HBBSCRIPT -p tthqq125  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "tthqq125" "\${command}" $TTHBBFILES
 
 command="python $HBBSCRIPT -p vvqq  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "vvqq" "\${command}" $VVFILES
 
 command="python $HBBSCRIPT -p zqq  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "zqq" "\${command}" $DYQQFILES
 
 command="python $HBBSCRIPT -p stqq  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "stqq" "\${command}" $STFILES
 
 command="python $HBBSCRIPT -p wqq  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "wqq" "\${command}" $WQQFILES
 
 command="python $HBBSCRIPT -p wlnu  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "wlnu" "\${command}" $WFILES
 
 command="python $HBBSCRIPT -p zll  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "zll" "\${command}" $DYLLFILES
 
 command="python $HBBSCRIPT -p tqq  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "tqq" "\${command}" $TTFILES
 
 command="python $HBBSCRIPT -p qcd  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "qcd" "\${command}" $QCDFILES
 
 command="python $HBBSCRIPT -p data_obs --data --lumi $LUMI -o ./ -i $INPUTDIRDATA -f "
 submitMany "data_obs" "\${command}" $DATAFILES
 
fi

###############################################
###  MuonCR 
##############################################
### (WARNING: muonCR and nominal cannot run in the same directory because they will write to same output file name)
if [ "$MUONCR" == "1" ]; then 

 command="python $HBBSCRIPT -p hqq125  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIRDATA -f "
 submitMany "hqq125_muonCR" "\${command}" $GGHBBFILES
 
 command="python $HBBSCRIPT -p vbfhqq125  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "vbfhqq125_muonCR" "\${command}" $VBFHBBFILES
 
 command="python $HBBSCRIPT -p zhqq125  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "zhqq125_muonCR" "\${command}" $ZHFILES
 
 command="python $HBBSCRIPT -p whqq125  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "whqq125_muonCR" "\${command}" $WHFILES
 
 command="python $HBBSCRIPT -p tthqq125  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "tthqq125_muonCR" "\${command}" $TTHBBFILES
 
 command="python $HBBSCRIPT -p vvqq  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "vvqq_muonCR" "\${command}" $VVFILES
 
 command="python $HBBSCRIPT -p zqq  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "zqq_muonCR" "\${command}" $DYQQFILES
 
 command="python $HBBSCRIPT -p stqq  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "stqq_muonCR" "\${command}" $STFILES
 
 command="python $HBBSCRIPT -p wqq  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "wqq_muonCR" "\${command}" $WQQFILES
 
 command="python $HBBSCRIPT -p wlnu  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "wlnu_muonCR" "\${command}" $WFILES
 
 command="python $HBBSCRIPT -p zll  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "zll_muonCR" "\${command}" $DYLLFILES
 
 command="python $HBBSCRIPT -p tqq  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "tqq_muonCR" "\${command}" $TTFILES
 
 command="python $HBBSCRIPT -p qcd  --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "qcd_muonCR" "\${command}" $QCDFILES
 
 command="python $HBBSCRIPT -p data_obs --data --muonCR  --lumi $LUMI -o ./ -i $INPUTDIR -f "
 submitMany "data_obs_muonCR" "\${command}" $MUONCRFILES

fi

#############################################
### Templates with Loose BB cut (0.8)
############################################
if [ "$LOOSEBTAG" == "1" ]; then
 
command="python $HBBSCRIPT -p hqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIRDATA -f "
submitMany "hqq125_looserWZ" "\${command}" $GGHBBFILES

command="python $HBBSCRIPT -p vbfhqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "vbfhqq125_looserWZ" "\${command}" $VBFHBBFILES

command="python $HBBSCRIPT -p zhqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "zhqq125_looserWZ" "\${command}" $ZHFILES

command="python $HBBSCRIPT -p whqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "whqq125_looserWZ" "\${command}" $WHFILES

command="python $HBBSCRIPT -p tthqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "tthqq125_looserWZ" "\${command}" $TTHBBFILES

command="python $HBBSCRIPT -p vvqq   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "vvqq_looserWZ" "\${command}" $VVFILES

command="python $HBBSCRIPT -p zqq   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "zqq_looserWZ" "\${command}" $DYQQFILES

command="python $HBBSCRIPT -p stqq   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "stqq_looserWZ" "\${command}" $STFILES

command="python $HBBSCRIPT -p wqq   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "wqq_looserWZ" "\${command}" $WQQFILES

command="python $HBBSCRIPT -p wlnu   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "wlnu_looserWZ" "\${command}" $WFILES

command="python $HBBSCRIPT -p zll   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "zll_looserWZ" "\${command}" $DYLLFILES

command="python $HBBSCRIPT -p tqq   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f "
submitMany "tqq_looserWZ" "\${command}" $TTFILES

fi


#### show the jobs in the queue
if [ "${SUBMIT}" == "1" ]; then
    /usr/bin/condor_q
fi
