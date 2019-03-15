addprocs(5)
LOAD_PATH
LOAD_PATH=LOAD_PATH[1:2]
basedir=homedir();
netdir=pwd()
cd(netdir);
push!(LOAD_PATH,netdir)

using StatsBase
using MultivariateStats
using Distributions

using CYCLOPS_2a_AutoEncoderModule
using CYCLOPS_2a_PreNPostprocessModule
using CYCLOPS_2a_MCA
using CYCLOPS_2a_MultiCoreModule_Smooth
using CYCLOPS_2a_Seed
using CYCLOPS_2a_CircularStats

using PyPlot

indir=string(basedir,"/Google Drive/PNAS_BRAIN_2016/CompileData");
homologuedir=string(basedir,"/Google Drive/PNAS_BRAIN_2016/SeedFiles");
outdir=string(basedir,"/Google Drive/CYCLOPS_OUTPUT_FINALL/BA11");


############################################################
Frac_Var=0.85 # Set Number of Dimensions of SVD to maintain this fraction of variance
DFrac_Var=0.03 # Set Number of Dimensions of SVD to so that incremetal fraction of variance of var is at least this much
N_best =40 # Number of random initial conditions to try for each optimization

total_background_num=40; # Number of background runs for global background ref
n_cores=5; # Number of machine cores
############################################################

cd(homologuedir)
seed_homologues1=readcsv("Human_UbiquityCyclers.csv");
homologue_symbol_list1=seed_homologues1[2:end,2];
###########################################################
Seed_MinCV 				= 0.14
Seed_MaxCV 				= .7
Seed_Blunt				=.975
MaxSeeds                =10000
###########################################################


srand(12345);

cd(indir);
fullnonseed_data=readcsv("Annotated_Unlogged_BA11Data.csv");


alldata_probes=fullnonseed_data[4:end ,1];
alldata_symbols=fullnonseed_data[4:end ,2];

alldata_times=fullnonseed_data[3,4:end];
alldata_subjects=fullnonseed_data[2,4:end];

alldata_data=fullnonseed_data[4:end , 4:end];
alldata_data=float64(alldata_data);

n_samples=length(alldata_times)
n_probes=length(alldata_probes)
timestamped_samples=setdiff(1:n_samples,findin(alldata_times,["NA"]))
cutrank=n_probes-MaxSeeds

Seed_MinMean										= (sort(vec(mean(alldata_data,2))))[cutrank]

seed_symbols1, seed_data1 							= getseed_homologuesymbol_brain(fullnonseed_data,homologue_symbol_list1,Seed_MaxCV,Seed_MinCV,Seed_MinMean,Seed_Blunt);
seed_data1 											= dispersion!(seed_data1)

outs1, norm_seed_data1								=	GetEigenGenes(seed_data1,Frac_Var,DFrac_Var,30)
estimated_phaselist1,bestnet1,global_var_metrics1 	=	CYCLOPS_Order(outs1,norm_seed_data1,N_best)
estimated_phaselist1a								=	mod(estimated_phaselist1 + 2*pi,2*pi)

global_smooth_metrics1								=	smoothness_measures(seed_data1,norm_seed_data1,estimated_phaselist1a)
global_smooth_metrics1[1]

global_metrics1										=	global_var_metrics1

#pvals=multicore_backgroundstatistics_global_eigen(seed_data1,outs1,N_best,total_background_num,global_metrics1)

truetimes=mod(float64(alldata_times[timestamped_samples]),24)
estimated_phaselist1a=estimated_phaselist1[timestamped_samples]

shiftephaselist1=best_shift_cos(estimated_phaselist1a,truetimes,"hours")






scatter(truetimes,shiftephaselist1,alpha=.75,s=14)
suptitle("CYCLOPS Phase Prediction: Human Frontal Cortex", fontsize=18)
ylabp=[0,pi/2,pi,3*pi/2,2*pi]
ylabs=[0, "","π","","2π"]
xlabp=[0,6,12,18,24]
xlabs=["0", "6","12","18","24"]
ylabel("CYCLOPS Phase (radians)", fontsize=14)
xlabel("Hour of Death", fontsize=14)
xticks(xlabp, xlabs)
yticks(ylabp, ylabs)

###################
#Asses Error
#####################

errors=Circular_Error_List(2*pi*truetimes/24,shiftephaselist1)
hrerrors=(12/pi)*abs(errors)
mean(hrerrors)
median(hrerrors)
sqrt(var(hrerrors))
sort(hrerrors)[.75*length(hrerrors)]

correlations=Circular_Correlations(2*pi*truetimes/24,shiftephaselist1)

###################################################
clockgenes=["C1orf51","ARNTL","NR1D1","CLOCK","PER3"]
clockrows=findin(alldata_symbols,clockgenes);
clockrows=clockrows[[2,4,1,3,5]] # reorder for plotting

clockdata=alldata_data[clockrows,:];
clockannotations=alldata_symbols[clockrows,:];
clockannotations[1]="CHRONO"  # C1orf51 renamed CHRONO
for n in 1:4
	m1=2*n-1
	m2=2n
	subplot(5,2,m1)
		scatter(truetimes,clockdata[n,[timestamped_samples]],alpha=.75,s=7,color="DarkRed")
		title(clockannotations[n])
		xlabp=[0,24]
		xlabs=["0","24"]
		ylabp=[]
		ylabs=[]
		xticks(xlabp, xlabs)
		yticks(ylabp, ylabs)


	subplot(5,2,m2)
        scatter(shiftephaselist1,clockdata[n,[timestamped_samples]],alpha=.75,s=7)
        title(clockannotations[n])
		xlabp=[0,2*pi]
		xlabs=[0,"2π"]
		ylabp=[]
		ylabs=[]
		xticks(xlabp, xlabs)
		yticks(ylabp, ylabs)
	end
n=5
m1=2*n-1
m2=2n
subplot(5,2,m1)
	scatter(truetimes,clockdata[n,[timestamped_samples]],alpha=.75,s=7,color="DarkRed")
	title(clockannotations[n])
	xlabp=[0,24]
	xlabs=["0","24"]
	ylabp=[]
	ylabs=[]
	xticks(xlabp, xlabs)
	yticks(ylabp, ylabs)
	xlabel("Hour of Death", fontsize=18,color="DarkRed")

subplot(5,2,m2)
    scatter(shiftephaselist1,clockdata[n,[timestamped_samples]],alpha=.75,s=7)
    title(clockannotations[n])
	xlabp=[0,2*pi]
	xlabs=[0,"2π"]
	ylabp=[]
	ylabs=[]
	xticks(xlabp, xlabs)
	yticks(ylabp, ylabs)
	xlabel("CYCLOPS Phase", fontsize=18,color="DarkBlue")

text(-4*pi,600,"Relative Expression",rotation="vertical",fontsize=19)

#suptitle("Gene Expression As A Function of TOD and CYCLOPS Phase ", fontsize=14, fontweight="bold")

############################

for n in 1:20
	m1=2*n-1
	m2=2n
	subplot(5,8,m1)
		scatter(truetimes,seed_data1[n,[timestamped_samples]],alpha=.75,s=7,color="DarKRed")
		title(seed_symbols1[n])
		xlabp=[0,24]
		xlabs=["0","24"]
		xticks(xlabp, xlabs)


	subplot(5,8,m2)
        scatter(shiftephaselist1,seed_data1[n,[timestamped_samples]],alpha=.75,s=7)
        title(seed_symbols1[n])
		xlabp=[0,2*pi]
		xlabs=[0,"2π"]
		yticks=[]
		ylabs=[]
		xticks(xlabp, xlabs)


	end
####################

title("Selected Clock Genes")
