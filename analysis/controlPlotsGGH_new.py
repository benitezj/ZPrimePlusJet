import ROOT
from ROOT import TFile, TTree, TChain, gPad, gDirectory
from multiprocessing import Process
from optparse import OptionParser
from operator import add
import math
import sys
import time
import array
import glob
import os
from plotHelpers_new import *
DBTMIN=-99


##############################################################################
def main(options,args):

    print 'Input file: ', options.ifile
    print 'Output dir: ', options.odir
    lumi = 41.0
    print 'Lumi: ', lumi
    isData = True
    print 'isData = ', isData
    muonCR = False
    print 'muonCR = ', muonCR


    ########################
    ## open the input file
    ifile = ROOT.TFile.Open(options.ifile,'read')
    if ifile.IsZombie():
        print "could not open input file\n"
        return

    ########################
    ## create the output file
    ofile = ROOT.TFile.Open(options.odir+'/plots.root','recreate')
    if ofile.IsZombie():
        print "could not open output file\n"
        return

    
    
    sigsamples ={'hqq125' , 
                 'vbfhqq125' ,
#                 'zhqq125' ,
#                 'whqq125' ,
                 'tthqq125' 
                 }
    
    bkgsamples ={'vvqq' ,
                 'zqq' ,
                 'stqq' ,
                 'wqq' , 
                 'wlnu' ,
                 'zll' ,
                 'tqq' ,
                 'qcd'  
                 }


    legname ={'hqq125': 'ggH(b#bar{b})', 
    'vbfhqq125': 'VBF H(b#bar{b})',
 #   'zhqq125': 'ZH(b#bar{b})',
 #   'whqq125': 'WH(b#bar{b})',
    'vhqq125': 'VH(b#bar{b})',
    'tthqq125': 't#bar{t}H(b#bar{b})',
    'vvqq': 'VV(4q)',
    'zqq': 'Z(qq)+jets',
    'stqq': 'single-t',
    'wqq': 'W(qq)+jets', 
    'wlnu': 'W(l#nu)+jets',
    'zll': 'Z(ll)+jets',
    'tqq': 't#bar{t}+jets',
    'qcd': 'QCD',
    'data_obs': 'Data'
    }


    color ={'hqq125':  ROOT.kAzure+1, 
    'vbfhqq125':  ROOT.kBlue-10,
#    'zhqq125': ROOT.kTeal+1,
#    'whqq125': ROOT.kTeal+1,
    'vhqq125': ROOT.kTeal+1,
    'tthqq125': ROOT.kBlue-1,
    'vvqq': ROOT.kOrange,
    'zqq':  ROOT.kRed,
    'stqq':  ROOT.kRed-2,
    'wqq': ROOT.kGreen+3, 
    'wlnu': ROOT.kGreen+2,
    'zll': ROOT.kRed-3,
    'tqq': ROOT.kGray,
    'qcd':  ROOT.kBlue+2,
    'data_obs': ROOT.kBlack
    }


    style ={'hqq125': 2, 
    'vbfhqq125': 3,
#    'zhqq125': 4,
#    'whqq125': 4,
    'vhqq125': 4,
    'tthqq125': 5,
    'vvqq': 1,
    'zqq': 1,
    'stqq': 1,
    'wqq': 1, 
    'wlnu': 1,
    'zll': 1,
    'tqq': 1,
    'qcd': 1,
    'data_obs': 1 
    }

    #={'hqq125': , 
    #'vbfhqq125': ,
    #'zhqq125': ,
    #'whqq125': ,
    #'tthq125': ,
    #'vvqq': ,
    #'zqq': ,
    #'stqq': ,
    #'wqq': , 
    #'wlnu': ,
    #'zll': ,
    #'tqq': ,
    #'qcd': ,
    #'data_obs': 
    #}




    #################
    ## define plots and samples
    #plots = ['h_pt_ak8','h_msd_ak8','h_dbtag_ak8','h_n_ak4','h_n_ak4_dR0p8','h_t21_ak8','h_t32_ak8','h_n2b1sdddt_ak8','h_t21ddt_ak8','h_met','h_npv','h_eta_ak8','h_ht','h_dbtag_ak8_aftercut','h_n2b1sdddt_ak8_aftercut','h_rho_ak8']
    plots = ['pt_ak8','msd_ak8','dbtag_ak8','n_ak4','t21_ak8','t32_ak8','n2b1sdddt_ak8','t21ddt_ak8','eta_ak8','rho_ak8']#,'n_ak4_dR0p8','met','npv','ht','dbtag_ak8_aftercut','n2b1sdddt_ak8_aftercut'
    #plots = ['pt_ak8','msd_ak8',']



    for plot in plots:
        hd = ifile.Get('data_obs_'+plot);
        if hd==0: 
            print 'no data_obs'
        print plot, 'data_obs', hd, hd.Integral()
    
        hs = {}
        for s in sigsamples:
            hs[s] = ifile.Get(s+'_'+plot);
            if hs[s]==0: 
                print 'no ', plot, s
            print plot, s, hs[s], hs[s].Integral()

        ## here combine WH+ZH
        wh = ifile.Get('whqq125_'+plot);
        zh = ifile.Get('zhqq125_'+plot);
        hs['vhqq125']= wh.Clone("vhqq125");
        hs['vhqq125'].Add(zh)
        print plot, hs['vhqq125'], hs['vhqq125'].Integral()

        hb = {}
        for s in bkgsamples:
            hb[s] = ifile.Get(s+'_'+plot);
            if hb[s]==0: 
                print 'no ', plot, s
            print plot, s, hb[s], hb[s].Integral()
    
        makeCanvasComparisonStackWData(hd,hs,hb,legname,color,style,plot,options.odir,lumi,ofile)


    ofile.Close()


##----##----##----##----##----##----##
if __name__ == '__main__':

    parser = OptionParser()
    parser.add_option('-b', action='store_true', dest='noX', default=False, help='no X11 windows')
    parser.add_option('-f', '--ifile', dest='ifile', default='./hist_nominal.root', help='input file', metavar='ifile')
    parser.add_option('-o', '--odir', dest='odir', default='./', help='output dir', metavar='odir')

    (options, args) = parser.parse_args()

     
    import tdrstyle
    tdrstyle.setTDRStyle()
    ROOT.gStyle.SetPadTopMargin(0.10)
    ROOT.gStyle.SetPadLeftMargin(0.16)
    ROOT.gStyle.SetPadRightMargin(0.10)
    #ROOT.gStyle.SetPalette(1)
    ROOT.gStyle.SetPaintTextFormat("1.1f")
    ROOT.gStyle.SetOptFit(0000)
    ROOT.gStyle.SetOptStat(0)
    ROOT.gROOT.SetBatch()

    main(options,args)
##----##----##----##----##----##----##

