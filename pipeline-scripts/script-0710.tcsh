#!/bin/tcsh

# ---------------------------------------------------------------------------
# top level definitions (constant across demo)
# ---------------------------------------------------------------------------
 
# labels
set subj           = FMRI-ANALYSIS		# Subject ID
set ses            = sess0710		# Session ID

# upper directories
set dir_inroot     = ${PWD:h}                        # one dir above scripts/
set dir_log        = ${dir_inroot}/logs

# subject directories
set sdir_basic     = ${dir_inroot}/${subj}/${ses}
set sdir_anat      = ${sdir_basic}/anat
set sdir_epi       = ${sdir_basic}/func/step-10
set sdir_time	   = ${sdir_basic}/func/timing
set sdir_ap		   = ${sdir_basic}/output-script-step-10-FH

# --------------------------------------------------------------------------
# data and control variables
# --------------------------------------------------------------------------

# AP files       
# set dsets_epi    = ( ${sdir_epi}/moco_doco_1_nulled-ss.nii.gz \
#					 ${sdir_epi}/moco_doco_2_nulled-ss.nii.gz \
#					 ${sdir_epi}/moco_doco_3_nulled-ss.nii.gz )
set dsets_epi    = ( ${sdir_epi}/run_01_Pip_fmri-bold_1.5mm_TE25.8_TR1250_FH_FA45_FOV84_1_1_15_mc_topupDC-ss.nii.gz \
					 ${sdir_epi}/run_03_Pip_fmri-bold_1.5mm_TE25.8_TR1250_FH_FA45_FOV84_1_1_25_mc_topupDC-ss.nii.gz \
					 ${sdir_epi}/run_05_Pip_fmri-bold_1.5mm_TE25.8_TR1250_FH_FA45_FOV84_1_1_35_mc_topupDC-ss.nii.gz )

set anat_orig	 = ${sdir_anat}/sess-0710-anat.nii.gz  
set anat_ss      = ${sdir_anat}/PreviousT1Session2CurrentSessionT2Warped-ss-unet.nii.gz


# set stim_files   = ( ${sdir_epi}/ringcheckers4_5deg_allruns_valid.1D )
set stim_files   = ( ${sdir_time}/ringcheckers4_5deg_FHruns.1D )


set stim_labs    = ( FACE  OBJ  SFACE  SOBJ )

# control variables
set blur_size    = 2.0
set final_dxyz   = 1.5      # can test against inputs
set cen_motion   = 0.2
set cen_outliers = 0.02

# check available N_threads and report what is being used
# + consider using up to 16 threads (alignment programs are parallelized)
# + N_threads may be set elsewhere; to set here, uncomment the following line:
### setenv OMP_NUM_THREADS 16

set nthr_avail = `afni_system_check.py -disp_num_cpu`
set nthr_using = `afni_check_omp`

echo "++ INFO: Using ${nthr_avail} of available ${nthr_using} threads"

setenv AFNI_COMPRESSOR GZIP

# ---------------------------------------------------------------------------
# run programs
# ---------------------------------------------------------------------------

set ap_cmd = ${sdir_ap}/script.cmd.${subj}

\mkdir -p ${sdir_ap}

# write AP command to file
# regress_censor to input custom 1D file. Remove "regress_censor_motion" and "regress_censor_outliers". 
#    -regress_censor_motion    ${cen_motion}                               \
#    -regress_censor_outliers  ${cen_outliers}                             \
#	-regress_censor_extern my_censor.1D		


# Do 3dSkullStrip before afni command
# 3dSkullStrip -input ${anat_orig} -prefix ${anat_cp} -orig_vol -monkey
# 3dSkullStrip -input sess0409-anat.nii.gz -prefix sess0409-anat-update-8.nii.gz -orig_vol -monkey -shrink_fac 0.63 -touchup -niter 600

# afni_proc.py                                                              \
#     -subj_id                  ${subj}                                     \
#     -blocks tshift align volreg regress             							  \
#     -dsets                   ${dsets_epi}                                 \
#     -copy_anat               ${anat_cp}                                   \
# 	-anat_has_skull          no                                           \
#     -volreg_align_to         MIN_OUTLIER                                  \
# 	-volreg_align_e2a													\
# 	-align_opts_aea -cost lpc+ZZ -giant_move							\
#     -regress_stim_times      ${stim_files}                                \
# 	-regress_censor_extern   ${custom_censor}							\
#     -regress_basis            'SPMG1'                                 \
# 	-regress_stim_types 	  AM2  										\
#     -html_review_style 		 pythonic 
	
	
# 		-align_opts_aea -cost lpc+ZZ -giant_move							\
# 	-blip_reverse_dset 		${dc_reverse} 					\
# 	-blip_forward_dset 		${dc_forward} 					\
# 	-blip_opts_qw           -useweight	
#	-regress_censor_motion 0.3 								\
#	-regress_censor_outliers 0.02							\

#afni_proc.py                                                 \
#    -subj_id                 ${subj}                         \
#    -blocks tshift volreg                                    \
#    -dsets                   ${dsets_epi}                    \
#    -copy_anat               ${anat_cp}                      \
#    -anat_has_skull          no                              \
#    -volreg_align_to         MIN_OUTLIER					
	# mask    -mask_apply anat 
	# -blur_size 1											\
cat <<EOF >! ${ap_cmd}
afni_proc.py                                                 \
    -subj_id                 ${subj}                         \
    -blocks tshift volreg blur mask regress                  \
    -dsets                   ${dsets_epi}                    \
	-copy_anat               ${anat_ss}                      \
	-anat_has_skull          no                              \
	-volreg_align_to         MIN_OUTLIER						\
	-volreg_interp           -cubic 						\
	
	-mask_apply epi 				\
	-regress_stim_times      ${stim_files}                   \
	-regress_basis 'dmBLOCK' 								\
 	-regress_stim_types 	  AM1  							\
    -html_review_style 		 pythonic 						
	
EOF

cd ${sdir_ap}

# execute AP command to make processing script
tcsh -xef ${ap_cmd} |& tee output.script.cmd.${subj}

# execute the proc script, saving text info
time tcsh -xef proc.${subj} |& tee output.proc.${subj}

echo "++ FINISHED!"

echo -e "\a"

exit 0
