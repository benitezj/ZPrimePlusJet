import os
import math
from array import array
from optparse import OptionParser
import ROOT
import sys
sys.path.append(os.path.expandvars("$CMSSW_BASE/src/DAZSLE/ZPrimePlusJet/analysis"))

from sampleContainer import *


##----##----##----##----##----##----##
def main(options, args):
    
    fileName = 'hist.root'
    
    outfile = ROOT.TFile(options.odir + "/" + fileName, "recreate")



    ##--## define the input files
    #print options.files
    files = []
    inputfiles = (options.files).split(',')
    for i in range(0,len(inputfiles)):
        files.append(options.idir + '/' + inputfiles[i])
        print files[i]
         
    if len(files) == 0 :
        print "no files found"
        exit

    ##--## process the samples
    if options.data:
        if options.muonCR:
            container = sampleContainer('data_obs', files, 1, options.dbtagmin, options.dbtag, options.lumi, True, False,
                                        '((triggerBits&4)&&passJson)', True)
        else:
            container = sampleContainer('data_obs', files, 1, options.dbtagmin, options.dbtag, options.lumi, True, False,
                                         '((triggerBits&2)&&passJson)', True)
    else:
        container = sampleContainer(options.process,files, 1, options.dbtagmin, options.dbtag, options.lumi, False, False, '1', True)



    ##--## define the histograms
    if options.muonCR:
         plots = ['h_msd_ak8_muCR4_N2_pass', 'h_msd_ak8_muCR4_N2_fail',
                  'h_msd_ak8_muCR4_N2_pass_JESUp', 'h_msd_ak8_muCR4_N2_pass_JESDown',
                  'h_msd_ak8_muCR4_N2_fail_JESUp', 'h_msd_ak8_muCR4_N2_fail_JESDown',
                  'h_msd_ak8_muCR4_N2_pass_JERUp', 'h_msd_ak8_muCR4_N2_pass_JERDown',
                  'h_msd_ak8_muCR4_N2_fail_JERUp', 'h_msd_ak8_muCR4_N2_fail_JERDown',
                  'h_msd_ak8_muCR4_N2_pass_mutriggerUp', 'h_msd_ak8_muCR4_N2_pass_mutriggerDown',
                  'h_msd_ak8_muCR4_N2_fail_mutriggerUp', 'h_msd_ak8_muCR4_N2_fail_mutriggerDown',
                  'h_msd_ak8_muCR4_N2_pass_muidUp', 'h_msd_ak8_muCR4_N2_pass_muidDown',
                  'h_msd_ak8_muCR4_N2_fail_muidUp', 'h_msd_ak8_muCR4_N2_fail_muidDown',
                  'h_msd_ak8_muCR4_N2_pass_muisoUp', 'h_msd_ak8_muCR4_N2_pass_muisoDown',
                  'h_msd_ak8_muCR4_N2_fail_muisoUp', 'h_msd_ak8_muCR4_N2_fail_muisoDown',
                  'h_msd_ak8_muCR4_N2_pass_PuUp', 'h_msd_ak8_muCR4_N2_pass_PuDown',
                  'h_msd_ak8_muCR4_N2_fail_PuUp', 'h_msd_ak8_muCR4_N2_fail_PuDown',
                  ]
    else:
        plots = ['h_msd_v_pt_ak8_topR6_N2_pass', 'h_msd_v_pt_ak8_topR6_N2_fail',
                 # SR with N2DDT @ 26% && db > 0.9, msd corrected
                 'h_msd_v_pt_ak8_topR6_N2_pass_matched', 'h_msd_v_pt_ak8_topR6_N2_pass_unmatched',
                 # matched and unmatached for mass up/down
                 'h_msd_v_pt_ak8_topR6_N2_fail_matched', 'h_msd_v_pt_ak8_topR6_N2_fail_unmatched',
                 # matched and unmatached for mass up/down
                 'h_msd_v_pt_ak8_topR6_N2_pass_JESUp', 'h_msd_v_pt_ak8_topR6_N2_pass_JESDown',  # JES up/down
                 'h_msd_v_pt_ak8_topR6_N2_fail_JESUp', 'h_msd_v_pt_ak8_topR6_N2_fail_JESDown',  # JES up/down
                 'h_msd_v_pt_ak8_topR6_N2_pass_JERUp', 'h_msd_v_pt_ak8_topR6_N2_pass_JERDown',  # JER up/down
                 'h_msd_v_pt_ak8_topR6_N2_fail_JERUp', 'h_msd_v_pt_ak8_topR6_N2_fail_JERDown',  # JER up/down
                 'h_msd_v_pt_ak8_topR6_N2_pass_triggerUp', 'h_msd_v_pt_ak8_topR6_N2_pass_triggerDown',  # trigger up/down
                 'h_msd_v_pt_ak8_topR6_N2_fail_triggerUp', 'h_msd_v_pt_ak8_topR6_N2_fail_triggerDown',  # trigger up/down
                 'h_msd_v_pt_ak8_topR6_N2_pass_PuUp', 'h_msd_v_pt_ak8_topR6_N2_pass_PuDown',  # Pu up/downxf
                 'h_msd_v_pt_ak8_topR6_N2_fail_PuUp', 'h_msd_v_pt_ak8_topR6_N2_fail_PuDown',  # trigger up/down
                 ]



    ##--## get the histograms
    hall = {}        
    for plot in plots:
        tag = plot.split('_')[-1]  # 'pass' or 'fail' or systematicName
        if tag not in ['pass', 'fail']:
            tag = plot.split('_')[-2] + '_' + plot.split('_')[-1]  # 'pass_systematicName', 'pass_systmaticName', etc.
            
        name = '%s_%s' % (options.process, tag)
        hall[name] = getattr(container, plot)
        hall[name].SetName(name)
        #print hall[name].GetName()



    ##---## save the histograms
    outfile.cd()
    for key, h in hall.iteritems():
        h.Write()
    outfile.Write()
    outfile.Close()


##----##----##----##----##----##----##
if __name__ == '__main__':
    parser = OptionParser()
    parser.add_option('-b', action='store_true', dest='noX', default=False, help='no X11 windows')
    parser.add_option("--lumi", dest="lumi", default=35.9, type="float", help="luminosity", metavar="lumi")
    parser.add_option('-i', '--idir', dest='idir', default='data/', help='directory with data', metavar='idir')
    parser.add_option('-o', '--odir', dest='odir', default='./', help='directory to write histograms', metavar='odir')
    parser.add_option('-m', '--muonCR', action='store_true', dest='muonCR', default=False, help='for muon CR', metavar='muonCR')
    parser.add_option('-d', '--dbtagmin', dest='dbtagmin', default=-99., type="float",help='left bound to btag selection', metavar='dbtagmin')
    parser.add_option('-p', '--process', dest='process', default='none', help='process name', metavar='process')
    parser.add_option('-f', '--files', dest='files', default='none', help='input root files comma separated', metavar='files')
    parser.add_option('--data', action='store_true', dest='data', default=False, help='data samples flag', metavar='data')
    parser.add_option('--dbtag', dest='dbtag', default=0.9, type="float",help='left bound to btag selection', metavar='dbtag')

    (options, args) = parser.parse_args()

    main(options, args)

    print "All done."
