
## Set this options before running 
TEST=0  ## only run a signal sample
SUBMIT=1 ## 0 : only print command, 1 : condor submission, 2 : run in interactive/local machine
EOSOUTPUTDIR=/store/user/benitezj/ggHbb/limits/2016  # where the histograms will be saved from condor job

## 
LUMI=35.9
echo 'lumi=' $LUMI

## MC
INPUTDIR=root://cmseos.fnal.gov//eos/uscms/store/user/lpchbb/zprimebits-v12.04/cvernier
echo 'MC input dir= ' $INPUTDIR

## hqq125 and data
INPUTDIRDATA=root://cmseos.fnal.gov//eos/uscms/store/user/lpchbb/zprimebits-v12.05
echo 'data input dir= ' $INPUTDIRDATA

## local output dir
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


## MC file lists
ZHFILES=ZH_HToBB_ZToQQ_M125_13TeV_powheg_pythia8_1000pb_weighted.root,ggZH_HToBB_ZToNuNu_M125_13TeV_powheg_pythia8_1000pb_weighted.root,ZH_HToBB_ZToNuNu_M125_13TeV_powheg_pythia8_ext_1000pb_weighted.root,ggZH_HToBB_ZToQQ_M125_13TeV_powheg_pythia8_1000pb_weighted.root
WHFILES=WminusH_HToBB_WToQQ_M125_13TeV_powheg_pythia8_1000pb_weighted.root,WplusH_HToBB_WToQQ_M125_13TeV_powheg_pythia8_1000pb_weighted.root
VVFILES=WWTo4Q_13TeV_powheg_1000pb_weighted.root,ZZ_13TeV_pythia8_1000pb_weighted.root,WZ_13TeV_pythia8_1000pb_weighted.root
STFILES=ST_t_channel_antitop_4f_inclusiveDecays_TuneCUETP8M2T4_13TeV_powhegV2_madspin_1000pb_weighted.root,ST_t_channel_top_4f_inclusiveDecays_TuneCUETP8M2T4_13TeV_powhegV2_madspin_1000pb_weighted.root,ST_tW_antitop_5f_inclusiveDecays_13TeV_powheg_pythia8_TuneCUETP8M2T4_1000pb_weighted.root,ST_tW_top_5f_inclusiveDecays_13TeV_powheg_pythia8_TuneCUETP8M2T4_1000pb_weighted.root
WFILES=WJetsToLNu_HT_100To200_13TeV_1000pb_weighted.root,WJetsToLNu_HT_200To400_13TeV_1000pb_weighted.root,WJetsToLNu_HT_400To600_13TeV_1000pb_weighted.root,WJetsToLNu_HT_600To800_13TeV_1000pb_weighted.root,WJetsToLNu_HT_800To1200_13TeV_1000pb_weighted.root,WJetsToLNu_HT_1200To2500_13TeV_1000pb_weighted.root
QCDFILES=QCD_HT100to200_13TeV_1000pb_weighted.root,QCD_HT200to300_13TeV_all_1000pb_weighted.root,QCD_HT300to500_13TeV_all_1000pb_weighted.root,QCD_HT500to700_13TeV_ext_1000pb_weighted.root,QCD_HT700to1000_13TeV_ext_1000pb_weighted.root,QCD_HT1000to1500_13TeV_all_1000pb_weighted.root,QCD_HT1500to2000_13TeV_all_1000pb_weighted.root,QCD_HT2000toInf_13TeV_1000pb_weighted.root


### submit the jobs
command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p hqq125  --lumi $LUMI -o ./ -i $INPUTDIRDATA -f GluGluHToBB_M125_13TeV_powheg_pythia8_CKKW_1000pb_weighted.root"
submit "hqq125" "\${command}"
if [ "$TEST" == "1" ]; then return 1 ; fi

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p vbfhqq125  --lumi $LUMI -o ./ -i $INPUTDIR -f VBFHToBB_M_125_13TeV_powheg_pythia8_weightfix_all_1000pb_weighted.root"
submit "vbfhqq125" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p zhqq125  --lumi $LUMI -o ./ -i $INPUTDIR -f $ZHFILES"
submit "zhqq125" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p whqq125  --lumi $LUMI -o ./ -i $INPUTDIR -f $WHFILES"
submit "whqq125" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p tthqq125  --lumi $LUMI -o ./ -i $INPUTDIR -f ttHTobb_M125_13TeV_powheg_pythia8_1000pb_weighted.root"
submit "tthqq125" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p vvqq  --lumi $LUMI -o ./ -i $INPUTDIR -f $VVFILES"
submit "vvqq" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p zqq  --lumi $LUMI -o ./ -i $INPUTDIR -f DYJetsToQQ_HT180_13TeV_1000pb_weighted_v1204.root"
submit "zqq" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p stqq  --lumi $LUMI -o ./ -i $INPUTDIR -f $STFILES"
submit "stqq" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p wqq  --lumi $LUMI -o ./ -i $INPUTDIR -f WJetsToQQ_HT180_13TeV_1000pb_weighted_v1204.root"
submit "wqq" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p wlnu  --lumi $LUMI -o ./ -i $INPUTDIR -f $WFILES"
submit "wlnu" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p zll  --lumi $LUMI -o ./ -i $INPUTDIR -f DYJetsToLL_M_50_13TeV_ext_1000pb_weighted.root"
submit "zll" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p tqq  --lumi $LUMI -o ./ -i $INPUTDIR -f TT_powheg_1000pb_weighted_v1204.root"
submit "tqq" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p qcd  --lumi $LUMI -o ./ -i $INPUTDIR -f $QCDFILES"
submit "qcd" "\${command}"

### Phibb samples
#python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p Phibb50  --lumi $LUMI -o ./ -i $INPUTDIR -f Spin0_ggPhi12j_g1_50_Scalar_13TeV_madgraph_1000pb_weighted.root
#python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p Phibb75  --lumi $LUMI -o ./ -i $INPUTDIR -f Spin0_ggPhi12j_g1_75_Scalar_13TeV_madgraph_1000pb_weighted.root
#python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p Phibb150  --lumi $LUMI -o ./ -i $INPUTDIR -f Spin0_ggPhi12j_g1_150_Scalar_13TeV_madgraph_1000pb_weighted.root
#python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p Phibb250  --lumi $LUMI -o ./ -i $INPUTDIR -f Spin0_ggPhi12j_g1_250_Scalar_13TeV_madgraph_1000pb_weighted.root


##input data files as one string 
DATAFILES=JetHTRun2016B_03Feb2017_ver2_v2_v3.root,JetHTRun2016B_03Feb2017_ver1_v1_v3.root,JetHTRun2016C_03Feb2017_v1_v3_0.root,JetHTRun2016C_03Feb2017_v1_v3_1.root,JetHTRun2016C_03Feb2017_v1_v3_2.root,JetHTRun2016C_03Feb2017_v1_v3_3.root,JetHTRun2016C_03Feb2017_v1_v3_4.root,JetHTRun2016C_03Feb2017_v1_v3_5.root,JetHTRun2016C_03Feb2017_v1_v3_6.root,JetHTRun2016C_03Feb2017_v1_v3_7.root,JetHTRun2016C_03Feb2017_v1_v3_8.root,JetHTRun2016C_03Feb2017_v1_v3_9.root,JetHTRun2016D_03Feb2017_v1_v3_0.root,JetHTRun2016D_03Feb2017_v1_v3_1.root,JetHTRun2016D_03Feb2017_v1_v3_10.root,JetHTRun2016D_03Feb2017_v1_v3_11.root,JetHTRun2016D_03Feb2017_v1_v3_12.root,JetHTRun2016D_03Feb2017_v1_v3_13.root,JetHTRun2016D_03Feb2017_v1_v3_14.root,JetHTRun2016D_03Feb2017_v1_v3_2.root,JetHTRun2016D_03Feb2017_v1_v3_3.root,JetHTRun2016D_03Feb2017_v1_v3_4.root,JetHTRun2016D_03Feb2017_v1_v3_5.root,JetHTRun2016D_03Feb2017_v1_v3_6.root,JetHTRun2016D_03Feb2017_v1_v3_7.root,JetHTRun2016D_03Feb2017_v1_v3_8.root,JetHTRun2016D_03Feb2017_v1_v3_9.root,JetHTRun2016E_03Feb2017_v1_v3_0.root,JetHTRun2016E_03Feb2017_v1_v3_1.root,JetHTRun2016E_03Feb2017_v1_v3_2.root,JetHTRun2016E_03Feb2017_v1_v3_3.root,JetHTRun2016E_03Feb2017_v1_v3_4.root,JetHTRun2016E_03Feb2017_v1_v3_5.root,JetHTRun2016E_03Feb2017_v1_v3_6.root,JetHTRun2016E_03Feb2017_v1_v3_7.root,JetHTRun2016E_03Feb2017_v1_v3_8.root,JetHTRun2016E_03Feb2017_v1_v3_9.root,JetHTRun2016E_03Feb2017_v1_v3_10.root,JetHTRun2016E_03Feb2017_v1_v3_11.root,JetHTRun2016E_03Feb2017_v1_v3_12.root,JetHTRun2016E_03Feb2017_v1_v3_13.root,JetHTRun2016E_03Feb2017_v1_v3_14.root,JetHTRun2016F_03Feb2017_v1_v3_0.root,JetHTRun2016F_03Feb2017_v1_v3_1.root,JetHTRun2016F_03Feb2017_v1_v3_2.root,JetHTRun2016F_03Feb2017_v1_v3_3.root,JetHTRun2016F_03Feb2017_v1_v3_4.root,JetHTRun2016F_03Feb2017_v1_v3_5.root,JetHTRun2016F_03Feb2017_v1_v3_6.root,JetHTRun2016F_03Feb2017_v1_v3_7.root,JetHTRun2016F_03Feb2017_v1_v3_8.root,JetHTRun2016F_03Feb2017_v1_v3_9.root,JetHTRun2016F_03Feb2017_v1_v3_10.root,JetHTRun2016G_03Feb2017_v1_v3_0.root,JetHTRun2016G_03Feb2017_v1_v3_1.root,JetHTRun2016G_03Feb2017_v1_v3_2.root,JetHTRun2016G_03Feb2017_v1_v3_3.root,JetHTRun2016G_03Feb2017_v1_v3_4.root,JetHTRun2016G_03Feb2017_v1_v3_5.root,JetHTRun2016G_03Feb2017_v1_v3_6.root,JetHTRun2016G_03Feb2017_v1_v3_7.root,JetHTRun2016G_03Feb2017_v1_v3_8.root,JetHTRun2016G_03Feb2017_v1_v3_9.root,JetHTRun2016G_03Feb2017_v1_v3_10.root,JetHTRun2016G_03Feb2017_v1_v3_11.root,JetHTRun2016G_03Feb2017_v1_v3_12.root,JetHTRun2016G_03Feb2017_v1_v3_13.root,JetHTRun2016G_03Feb2017_v1_v3_14.root,JetHTRun2016G_03Feb2017_v1_v3_15.root,JetHTRun2016G_03Feb2017_v1_v3_16.root,JetHTRun2016G_03Feb2017_v1_v3_17.root,JetHTRun2016G_03Feb2017_v1_v3_18.root,JetHTRun2016G_03Feb2017_v1_v3_19.root,JetHTRun2016G_03Feb2017_v1_v3_20.root,JetHTRun2016G_03Feb2017_v1_v3_21.root,JetHTRun2016G_03Feb2017_v1_v3_22.root,JetHTRun2016G_03Feb2017_v1_v3_23.root,JetHTRun2016G_03Feb2017_v1_v3_24.root,JetHTRun2016G_03Feb2017_v1_v3_25.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_0.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_1.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_2.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_3.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_4.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_5.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_6.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_7.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_8.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_9.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_10.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_11.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_12.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_13.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_14.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_15.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_16.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_17.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_18.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_19.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_20.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_21.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_22.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_23.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_24.root,JetHTRun2016H_03Feb2017_ver2_v1_v3_25.root,JetHTRun2016H_03Feb2017_ver3_v1_v3.root

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p data_obs --data --lumi $LUMI -o ./ -i $INPUTDIRDATA -f $DATAFILES"
submit "data_obs" "\${command}"



###  MuonCR DATA files 
### (WARNING: muonCR and nominal data cannot run in the same directory because they will write to same output file name)
MUONCRFILES=SingleMuonRun2016B_03Feb2017_ver1_v1_fixtrig.root,SingleMuonRun2016B_03Feb2017_ver2_v2_fixtrig.root,SingleMuonRun2016C_03Feb2017_v1_fixtrig.root,SingleMuonRun2016D_03Feb2017_v1_fixtrig.root,SingleMuonRun2016E_03Feb2017_v1_fixtrig.root,SingleMuonRun2016F_03Feb2017_v1_fixtrig.root,SingleMuonRun2016G_03Feb2017_v1_fixtrig.root,SingleMuonRun2016H_03Feb2017_ver2_v1_fixtrig.root,SingleMuonRun2016H_03Feb2017_ver3_v1_fixtrig.root

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p data_obs --data --muonCR  --lumi $LUMI -o ./ -i $INPUTDIRDATA -f $MUONCRFILES"
submit "data_obs_muonCR" "\${command}"



### Loose BB cut (0.8)
command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p hqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIRDATA -f GluGluHToBB_M125_13TeV_powheg_pythia8_CKKW_1000pb_weighted.root"
submit "hqq125_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p vbfhqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f VBFHToBB_M_125_13TeV_powheg_pythia8_weightfix_all_1000pb_weighted.root"
submit "vbfhqq125_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p zhqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f $ZHFILES"
submit "zhqq125_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p whqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f $WHFILES"
submit "whqq125_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p tthqq125   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f ttHTobb_M125_13TeV_powheg_pythia8_1000pb_weighted.root"
submit "tthqq125_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p vvqq   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f $VVFILES"
submit "vvqq_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p zqq   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f DYJetsToQQ_HT180_13TeV_1000pb_weighted_v1204.root"
submit "zqq_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p stqq   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f $STFILES"
submit "stqq_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p wqq   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f WJetsToQQ_HT180_13TeV_1000pb_weighted_v1204.root"
submit "wqq_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p wlnu   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f $WFILES"
submit "wlnu_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p zll   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f DYJetsToLL_M_50_13TeV_ext_1000pb_weighted.root"
submit "zll_looserWZ" "\${command}"

command="python ./DAZSLE/ZPrimePlusJet/fitting/PbbJet/Hbb_create_new.py -p tqq   --dbtag 0.8  --lumi $LUMI -o ./ -i $INPUTDIR -f TT_powheg_1000pb_weighted_v1204.root"
submit "tqq_looserWZ" "\${command}"





#### show the jobs in the queue
if [ "${SUBMIT}" == "1" ]; then
    /usr/bin/condor_q
fi