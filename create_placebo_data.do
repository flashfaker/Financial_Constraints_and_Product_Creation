* Prediction Model for Water Quality Measurement Before and After 
local fname create_placebo_data

/*******************************************************************************

Synapse: Create the pseudo data for the three working data sets for the project 
Product Innovation and Credit Market Disruptions (forthcoming RFS)
(by Joao Granja and Sara Moreira)

Author: Zirui Song
Date Created: May 25th, 2022

********************************************************************************/

/**************
	Basic Set-up
	***************/
	clear all
	set more off, permanently
	capture log close
	
	* Set local directory
	* notice that dropbox path for Mac/Windows might differ
	global dropdir = "/Users/zsong98/Dropbox/Financial Constraints and Product Creation"
	global logdir = "$dropdir/code/create_placebo_data/LogFiles"
	* data from 1. data folder in Dropbox share
	global outdir = "$dropdir/Data/placebo data"
	global rawdir = "$dropdir/Data/work files"
	
	* Start plain text log file with same name
	log using "$logdir/`fname'.txt", replace text
	
/**************
	Main Full Sample 
	***************/
*** set obs number and seed
	set obs 213015 
	set seed 60637
	
*** import the original data for year and firm variable (panel ID)
	use "$rawdir/sample_bartik", clear
	keep firm year
	
	* generate pseudo state and cuonty code for variables such as bartik3 (i.e. stcntybr)
	* suppose there are 3,000 counties in sample
	gen st = runiformint(1, 50)
	bysort firm: replace st = st[_N]
	
	* issue: a same county might be mapped to different states (but should be fine for 
	* pseudo data)
	gen stcntybr = runiformint(1, 3000)
	bysort firm: replace stcntybr = stcntybr[_N]
	
*** generate fixed effects and control variables related vars
	* generate bartik 
	gen bartik3 = runiform(-0.33, 0.30)
	bysort stcntybr: replace bartik3 = bartik3[_N]
	* generate rev_it (very skewed to the right, huge density close to zero)
	* need fix later possibly... histograms not matching exactly
	// let 10% of values to be 0 and the other 9% follow beta(1.5, 10000) distribution
	gen rev_it = rbinomial(1,0.9)
	replace rev_it = -1 if rev_it == 0 // so that the zero values are kept
	replace rev_it = rbinomial(1, 0.5) if rev_it == 1 
	replace rev_it = runiform(10, 20000) if rev_it == 0
	replace rev_it = rbeta(1, 10000) * 10000000000 if rev_it == 1
	replace rev_it = 0 if rev_it == -1 // so that the zero values are kept
	
	* first uniform distribution for the bottom 10% obs, then beta distribution scaled 
	* for the top 90% (later might need to change)
	gen rev_mean_it = rbinomial(1, 0.9)
	replace rev_mean_it = -1 if rev_mean_it == 0 // so that the zero values are kept
	replace rev_mean_it = rbinomial(1, 0.5) if rev_mean_it == 1 
	replace rev_mean_it = runiform(40, 6000) if rev_mean_it == 0
	replace rev_mean_it = rbeta(1, 10000) * 1000000000 if rev_mean_it == 1
	replace rev_mean_it = 0 if rev_mean_it == -1 // so that the zero values are kept
	
	* T2_it (number of products) stepwise uniform distributions
	gen T2_it = rbinomial(1, 0.95)
	replace T2_it = -1 if T2_it == 0 // so that the zero values are kept
	replace T2_it = rbinomial(1, 0.5) if T2_it == 1
	replace T2_it = runiformint(1, 4) if T2_it == 0
	replace T2_it = round(rbeta(1, 1000) * 500000) if T2_it == 1
	replace T2_it = 0 if T2_it == -1 // so that the zero values are kept
	
*** generate main variables in the sample
	* generate number of products variables 
	// first genereate new and old products, then sum together for total 
	gen Na_it = rbinomial(1, 0.5) 
	replace Na_it = -1 if Na_it == 0 // so that the zero values are kept
	replace Na_it = rbinomial(1, 0.1) if Na_it == 1
	replace Na_it = runiformint(1, 4) if Na_it == 0 
	replace Na_it = round(rbeta(1, 1000) * 100000) if Na_it == 1
	replace Na_it = 0 if Na_it == -1 // so that the zero values are kept
		
	gen Nf_it = rbinomial(1, 0.6) 
	replace Nf_it = -1 if Nf_it == 0 // so that the zero values are kept
	replace Nf_it = rbinomial(1, 0.01) if Nf_it == 1
	replace Nf_it = runiformint(1, 6) if Nf_it == 0 
	replace Nf_it = round(rbeta(1, 1000) * 10000) if Nf_it == 1
	replace Nf_it = 0 if Nf_it == -1 // so that the zero values are kept
	
	gen N_it = Nf_it + Na_it 
	
	* generate product introduction variables
	// first generate product_intro_a and product_intro_b 
	gen product_intro_a = rbinomial(1, 0.3)
	gen product_intro_b = rbinomial(1, 0.1)
	egen product_intro = rowmax(product_intro_a product_intro_b)
	
	* generate total number of products related variables
	gen modules_it = rbinomial(1, 0.53)
	replace modules_it = round(rbeta(1,10000)*300000) if modules_it == 0
	
	gen groups_it = rbinomial(1, 0.66) 
	replace groups_it = round(rbeta(1, 10000)*80000) if groups_it == 0
	
	* generate revenues and other variables
	gen rev_r_it = rev_it 
	
	* generate HHI index (values of 0 and 1 and then uniform in between)
	gen hhi_product_it = rbinomial(1, 0.95) // generate zero values
	replace hhi_product_it = -1 if hhi_product_it == 0 // keep the zero values 
	replace hhi_product_it = rbinomial(1, 0.15) if hhi_product_it == 1 // generate 1s 
	replace hhi_product_it = runiform(0,1) if hhi_product_it == 0
	replace hhi_product_it = 0 if hhi_product_it == -1 // keep the zero values 
	
*** create entry rate variables
	// note that entryrate = entryrate_a + entryrate_b 
	gen entryrate_a = rbinomial(1, 0.25) 
	replace entryrate_a = rbeta(1, 10000)*90000 if entryrate_a == 1
	gen entryrate_b = rbinomial(1, 0.15) 
	replace entryrate_b = rbeta(1, 10000)*80000 if entryrate_b == 1
	egen entryrate = rowtotal(entryrate_a entryrate_b)
	egen entryrate_c = rowmin(entryrate_a entryrate_b)
	
*** generate variables appearing in the regression tables
	// large values at 0, uniform distribution from 0.05 to 0.9, and then 
	// beta distribution afterwards
	gen outsharerev = rbinomial(1, 0.95) 
	replace outsharerev = -1 if outsharerev == 0 // keep the zero values 
	replace outsharerev = rbinomial(1, 0.3) if outsharerev == 1
	replace outsharerev = runiform(0, 1) if outsharerev == 0
	replace outsharerev = rbeta(5, 0.15) if outsharerev == 1
	replace outsharerev = 0 if outsharerev == -1 // keep the zero values 
	*gen outsharerevenue = outsharerev
	
	// generate nstates (count of fips states total) use sum of two beta distributions
	gen nstates = rbinomial(1, 0.7)
	replace nstates = floor(rbeta(2, 0.3)*50) if nstates == 0
	replace nstates = floor(rbeta(1, 100)*500) if nstates == 1
		* make sure that nstates stay constant within a firm
		bysort firm: replace nstates = nstates[_N]
	
	// generate HHIrev, 15% of 1s, otherwise beta distribution and then uniform
	gen HHIrev = rbinomial(1, 0.15) 
	replace HHIrev = 2 if HHIrev == 1 // keep the 1 values 
	replace HHIrev = rbinomial(1, 0.8) if HHIrev == 0 
	replace HHIrev = rbeta(2, 50) if HHIrev == 0
	replace HHIrev = runiform(0, 1) if HHIrev == 1
	replace HHIrev = 1 if HHIrev == 2 // keep the 1 values 
		* make sure that HHIrev stays constant within a firm
		bysort firm: replace HHIrev = HHIrev[_N]
********************************* END ******************************************

capture log close
exit