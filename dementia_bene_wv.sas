/* dementia_bene_wv.sas
   Merges together dementia diagnosis, cogstate, and bene enrollment, 
    along with some RAND HRS variables.
    
   Input: bene_enroll 
          rndhrs  
          cogstate_wide 
          dementia_bene
   
   Output: dementia_bene_wv
           dementia_bene_long

*/

options compress=yes mprint nocenter ls=150 ps=58;

%let hrsclaims=/sch-projects/dua-data-projects/HRS/Datalib/Data/Revsplit/;
%let minyr=1991;
%let maxyr=2008;
%let hrsbsf=/sch-data-library/dua-data/HRS/Restricted/Claims/Sas/DenomBsf/;
%let hrsmac=/sch-data-library/public-data/HRS/Unrestricted/Programs/rndpgmN/Mac/;
%let maclib=/sch-data-library/datapgm/SAS_MACROS/;
%include "&maclib.sascontents.mac";
%include "&maclib.renvars.mac";
%include "&hrsmac.wvlist.mac";
%include "&hrsmac.wvlabel.mac";

%let contentsdir=./;

***** libname bene "&datalib.&clean_data./BeneStatus";

libname bsf "&hrsbsf";
libname proj "../../../Data";
libname library "/sch-data-library/public-data/HRS/Unrestricted/Sas";
%let rndv=p;
%let maxwv=9;

proc format;
   value ADstat
   0="0.No AD or nonAD dementia"
   1="1.AD before nonAD dementia"
   2="2.AD first dementia DX"
   3="3.AD after nonAD dementia"
   4="4.only nonAD dementia"
   ;
   value demadst
   0="0.no AD or nonAD dementia"
   1="1.incident AD"
   2="2.incident nonAD dementia"
   3="3.incident AD and nonAD dementia"
   4="4.incident AD-nonAD dementia before yr"
   5="5.incident nonAD dementia-AD before yr"   
   7="7.already AD-dementia later"
   8="8.already nonAD dementia-AD later"
   9="9.already AD and nonAD dementia"
   ;

   value in_samp
   0="0.Not in samp"
   1="1.FFS all year"
   2="2.FFS cur and 2 lag years"
   ;
   value race
   1="1.NH white"
   2="2.NH non-white"
   3="3.Hispanic"
   other="missing"
   ;

/* incorporate bene_enroll */
data proj.dementia_bene_wv
     proj.dementia_bene_long (keep=hhidpn wv proxy ragender race raeduc inw agey everdem demver sampwv lsampwv 
                                   bwc20 ser7 tr20 totcog totcogA totcog_imp
                                   cogstate lcogstate cogstateA cog_dif cog_dif_type cogdem_wvs memrye: enrmo_long);
    merge proj.bene_enroll (in=_inMC drop=buyin_: hmoind_:)
          library.rndhrs_&rndv (in=_inrnd keep=hhidpn hacohort rabdate raddate raidate ragender raracem rahispan raeduc inw: 
                                 %wvlist(r,iwstat iwend wtcrnh proxy agey_e,endwv=&maxwv.)
                                 %wvlist(r,memrye,begwv=5,endwv=9)
                                 %wvlist(r,nhmliv,begwv=3,endwv=&maxwv.)
                                 %wvlist(h,cpl hhresp hhid,endwv=&maxwv.)
                                 %wvlist(s,hhidpn proxy iwstat iwend, endwv=&maxwv.)
                                 %wvlist(s,nhmliv,begwv=3,endwv=&maxwv.))
          proj.cogstate_wide (in=_incog keep=hhidpn %wvlist(r,cogstate cogstateA cogstateB cogstateAB proxy bwc20 ser7 tr20 totcog totcogA totcog_imp,begwv=4))
          proj.dementia_bene (in=_inclms keep=hhidpn AD_date nonAD_date nonAD_add_date any_ADR dx2_add_date dx2_add_diff
                                              more_: else_:)
          ;
    by hhidpn;
    
    dupidall=first.hhidpn=0 or last.hhidpn=0;
    pickone=last.hhidpn;
    
    /* set in flags */

    in_enr=_inMC;  /* in any year of denominator */
    in_clms=_inclms;
    in_cog = _incog;
    
    /* arrays for wave variables */
    length sampwv1-sampwv&maxwv. 3 ;
    
    array inw_[*] inw1-inw&maxwv.;
    array agey_[*] %wvlist(r,agey_e,endwv=&maxwv);
    array iwend_[*] %wvlist(r,iwend,endwv=&maxwv.);
    array iwstat_[*] %wvlist(r,iwstat,endwv=&maxwv.);
    array wtcrnh_[*] %wvlist(r,wtcrnh,endwv=&maxwv.);
    array proxy_[*] %wvlist(r,proxy,endwv=&maxwv.);
    array rnhmliv_[*] %wvlist(r,nhmliv,endwv=&maxwv.);
    array hcpl_[*] %wvlist(h,cpl,endwv=&maxwv.);
    array hhresp_[*] %wvlist(h,hhresp,endwv=&maxwv.);
    array cogstate_[*] %wvlist(r,cogstate,endwv=&maxwv.);
    array cogstateA_[*] %wvlist(r,cogstateA,endwv=&maxwv.);
    array memrye_[*] %wvlist(r,memrye,endwv=&maxwv);
    
    array siwstat_[*] %wvlist(s,iwstat,endwv=&maxwv.);
    array sproxy_[*] %wvlist(s,proxy,endwv=&maxwv.);
    array snhmliv_[*] %wvlist(s,nhmliv,endwv=&maxwv.);
    array shhidpn_[*] %wvlist(s,hhidpn,endwv=&maxwv.);
    
    array sampwv_[*] sampwv1 - sampwv&maxwv.;
    array enrmo_[*] enrmo1 - enrmo&maxwv.;
    array enrmo_long_[*] enrmo_long1 - enrmo_long&maxwv.;
    array betwmo_[*] betwmo1 - betwmo&maxwv.;
    array iwdate_[*] iwdate1-iwdate&maxwv.;
    array everAD_[*] everAD1-everAD&maxwv.;
    array evernonAD_[*] evernonAD1-evernonAD&maxwv.;
    array evernonADc_[*] evernonADc1-evernonADc&maxwv.;
    array everdem_[*] everdem1-everdem&maxwv.;
    array newdem_[*] newdem1-newdem&maxwv.;
    array newAD_[*] newAD1-newAD&maxwv.;
    array demver_[*] demver1-demver&maxwv.;

    /* beg / end enrollment dates */
    array ABffs_bdt_[*] ABffs_bdt1-ABffs_bdt11;
    array ABffs_edt_[*] ABffs_edt1-ABffs_edt11;

    /* cogstate non-proxy scores */
   array bwc20_[*] %wvlist(r,bwc20, endwv=&maxwv);
   array ser7_[*] %wvlist(r,ser7, endwv=&maxwv);
   array tr20_[*] %wvlist(r,tr20, endwv=&maxwv);
   array totcog_[*] %wvlist(r,totcog, endwv=&maxwv);
   array totcogA_[*] %wvlist(r,totcogA, endwv=&maxwv);
   array totcog_imp_[*] %wvlist(r,totcog_imp, endwv=&maxwv);

    /* make some dummy vars */
    if rahispan=1 then race = 3;
    else if raracem = 1 then race = 1;
    else if raracem in (2,3) then race = 2;
    
    dem_date=min(AD_date,nonAD_add_date,nonAD_date);
    n_waves = sum(of inw_[*]);
    
    firstwv=.;
    prior_wv=.;
    nenr=1;
    sp_aftdem=0;
    sp_befdem=0;
    n_spidR=0;
    firstdem_wv=0;
    firstAD_wv=0;
    _diedwv=0;
    cogdem_wvs = 0;    

    /* loop through waves, setting MC enrollment status and
       AD/dementia flags */

    do wv=1 to dim(sampwv_) while (_diedwv=0);
       
       /* figure the right interview date to use if R is nonresp 
          Note that wave 1 is all HRS/ahead overlap cohort and all iws were in 1992
          Wave 2 has 1994 interviews for HRS cohort but 1993 for Ahead/ovrlap cases
          Wave 3 has 1996 interviews for the HRS cohort but 1995 for Ahead/ovrlap */
          
       if wv>=4 then _iwyr = 1998 + 2*(wv-4); /* from 1998 forward no mixed iw years */
       else if wv=1 then _iwyr = 1992;
       else if hacohort=3 then _iwyr = 1992 + 2*(wv-1); /* waves 2-3 for HRS cohort */
       else _iwyr = 1993 + 2*(wv-2);  /* waves 2-3 for AHEAD / overlap cohort */
       
       /* if responded then calculate months enrolled since last interview
          or if first interview, enrolled before first (since 1991) 
          This will be based on R iw date if responded but the end of iw year if not */
       if inw_[wv]=1 then iwdate=iwend_[wv];
       else do;
          iwdate=mdy(12,31,_iwyr);
          if not missing(raddate) and (_iwyr-2)<=year(raddate)<=_iwyr+1 then do;
             iwdate=raddate;
             _diedwv=wv;
          end;
          else if iwstat_[wv] in (5,6) then do;  /* died this wave or prior */
             if not missing(raddate) then do;
                if .Z<prior_wv<raddate and raddate<=iwdate then do;  /* adjust for death */
                   iwdate = raddate;
                   _diedwv=100+wv;
                end;
                else if .Z<prior_wv<raidate and raidate<=iwdate then do;  /* adjust for death */
                   iwdate = raidate;
                   _diedwv=700+wv;
                end;
                else do;
                   if missing(prior_wv) and mdy(1,1,1992)<=raddate<=iwdate then iwdate=raddate;  /* died bef first wave */
                   else if missing(prior_wv) and mdy(1,1,1992)<=raidate<=iwdate then iwdate=raidate;  /* died bef first wave */
                   else if raddate>iwdate and raidate>iwdate then do;
                      _diedwv=200+wv;  
                      put "*** POSSIBLE ERROR: death date " _diedwv= hhidpn= wv= iwstat_[wv]= inw_[wv]= iwend_[wv]=date10. prior_wv=date10. raddate=date10.  raidate=date10. iwdate=date10. ;
                   end;
                   else do;
                      _diedwv=300+wv;
                      put "*** POSSIBLE ERROR: death date " _diedwv= hhidpn= wv= iwstat_[wv]= inw_[wv]= iwend_[wv]=date10. prior_wv=date10. raddate=date10. raidate=date10. iwdate=date10. ;
                      if year(raddate)>=year(prior_wv) then iwdate=raddate;
                   end;
                end;
             end;  /* not missing raddate */
             else do;  /* died but missing date */
                if iwstat_[wv]=6 then do;
                   _diedwv=600+wv;
                   put "*** POSSIBLE ERROR: death date missing " _diedwv= hhidpn= wv= iwstat_[wv]= inw_[wv]= iwend_[wv]=date10. prior_wv=date10. raddate=date10. raidate=date10. iwdate=date10. ;
                end;
                else _diedwv=500+wv;  /* died this wave, set flag */
                /* use mid-prior year as iw date */
                iwdate = mdy(7,1,year(iwdate)-1);                
             end; /* missing death date */
          end;  /* died this wave or prior */
       end;  /* else do - nonresponse wave */

       if firstwv=. and inw_[wv]=1 then firstwv=wv;  /* save first iw wave where R responded */
       if inw_[wv]=1 then lastwv=wv; /* and last wave where R responded */
       
          /******************** AB - FFS enrollment dates and flags *********************/
          
          /* calculate the number of months between interviews */
          if not missing(prior_wv) then betwmo_[wv] = intck("MONTH",prior_wv,iwdate)+1;
          else betwmo_[wv] = .F;  /* first interview */
          

          if in_enr = 1 then do;  /* if in MC denominator */
             /* if after last enrollment or enrollment begins after interview, 
                set to not enrolled for any months */
             if nenr > n_ABffs then do;
                enrmo_[wv] = 0; 
                enrmo_long_[wv]=0;
             end;
             else if ABffs_bdt_[nenr] > iwdate then do;
                enrmo_[wv]=0;
                enrmo_long_[wv]=0;
             end;
              
             /* if enrolled entire period from last wv or first enrollment to this one
                count all months as enrolled */
             else if ABffs_bdt_[nenr] le min(prior_wv,iwdate) and ABffs_edt_[nenr] ge iwdate  /* enrolled from bdt to iw */
                   then do;
                enrmo_[wv] = intck("MONTH",max(prior_wv,ABffs_bdt_[nenr]),iwdate)+1;
                enrmo_long_[wv] = intck("MONTH",ABffs_bdt_[nenr],iwdate)+1;
             end;
             
             /* enrollment doesn‘t cover the entire period or multiple enrollments during period
                where period is since beginning of enrollment if first interview and
                prior iw date if re-interview */
             else if ABffs_bdt_[nenr] le iwdate then do;   
                enrmo_[wv]=0;
                enrmo_long_[wv]=0;
                exit=(nenr > n_ABFFS);
                if exit=0 and ABffs_edt_[nenr] >= iwdate then 
                   enrmo_long_[wv] = intck("MONTH",ABffs_bdt_[nenr],iwdate)+1;   /* count all continuous months enrolled before iw */
                /* loop through all enrollments that occur completely before the current interview */
                do while (exit=0);
                   if (.Z < ABffs_edt_[nenr] < iwdate) then do;
                      enrmo_[wv] = enrmo_[wv] + intck("MONTH",max(prior_wv,ABffs_bdt_[nenr]),ABffs_edt_[nenr])+1;   /* count all months in enrollment */
                      if enrmo_long_[wv]=0 and (ABffs_bdt_[nenr] <= iwdate <= ABffs_edt_[nenr]) then 
                         enrmo_long_[wv] = intck("MONTH",ABffs_bdt_[nenr],iwdate)+1;   /* count all months in enrollment */
                      nenr=nenr+1;
                   end;
                   
                   /* check if done with relevant enrollments (completely between interviews) */
                   if nenr > n_ABffs then exit=1;
                   else if ABffs_edt_[nenr] ge iwdate then exit=1;
                   
                end;   /* do while (exit=0) */
                
                /* get last AB ffs enr months before iw */
                if nenr <=n_ABffs then do;
                   if ABffs_bdt_[nenr] le iwdate and ABffs_edt_[nenr] ge iwdate
                      then do;
                      enrmo_[wv] = enrmo_[wv] + intck("MONTH",ABffs_bdt_[nenr],iwdate)+1;
                      enrmo_long_[wv] = intck("MONTH",ABffs_bdt_[nenr],iwdate)+1;
                   end;   
                end;
             
             end; /* else if ABffs_dt le iwend */
             
             /* sampwv flag = 1 if enrolled some of time since last iw, 3 if all the time, 0 if none */
             sampwv_[wv] = (enrmo_[wv] > 0) + 2*(enrmo_[wv] => betwmo_[wv]) ;  
             
             
             /******************** AD dementia dates and flags ************************/
             
             newdem_[wv]=0;
             newAD_[wv]=0;

             if not missing(dem_date) then do;
                everdem_[wv] = (dem_date <= iwdate);
                if everdem_[wv]=1 then do;  /* check if verified by another dx */
                   more_ndx=sum(more_AD_dx,more_othdem_dx,more_AD2othdem_dx,more_othdem2AD_dx,
                          else_AD_dx,else_othdem_dx);
                   more_add_ndx=sum(more_AD_dx,more_othdem_add_dx,more_AD2othdem_add_dx,more_othdem_add2AD_dx,
                          else_add_AD_dx,else_othdem_add_dx);
                   if more_add_ndx>0 then demver_[wv]=1;
                   else demver_[wv]=0;
                end;
                else demver_[wv]=0;
             end;

             /* no dementia date but in mc pop */
             else do;
                everdem_[wv]=0;
                demver_[wv]=0;
             end;

             if not missing(AD_date) then everAD_[wv] = (AD_date <= iwdate);
             else everAD_[wv]=0;

             if not missing(nonAD_add_date) then evernonAD_[wv] = (nonAD_add_date <= iwdate);
             else evernonAD_[wv]=0;

             if not missing(nonAD_date) then evernonADc_[wv] = (nonAD_date <= iwdate);
             else evernonADc_[wv]=0;
             
             if firstdem_wv=0 and everdem_[wv]=1 then do;
                firstdem_wv=wv;
                newdem_[wv]=1;
                sp_befdem=n_spidR;
                sp_aftdem=0;
             end;
             if firstAD_wv=0 and everAD_[wv]=1 then do;
                firstAD_wv=wv;
                newAD_[wv]=1;
             end;
             if everdem_[wv]=1 and siwstat_[wv]=1 then sp_aftdem=sp_aftdem+1;
             n_spidR = n_spidR + (siwstat_[wv]=1);
          end; /* in MC denominator */
          
          else do;  /* not in MC claims */
             sampwv_[wv] = .E;
             everdem_[wv] = .E;
             everAD_[wv] = .E;
             evernonAD_[wv] = .E;
             evernonADc_[wv] = .E;
             demver_[wv] = .E;
          end;
          
          /* save current iw date as prior iw date */
          prior_wv = iwdate;  
          iwdate_[wv]=iwdate;
       * no longer processing only if inw end; /* if inw */
       

       /******************** count waves cogstate is demented *******************/
       if cogstate_[wv] = 1 then cogdem_wvs = cogdem_wvs +1;

       /* output a long file */
       inw=inw_[wv];
       agey = agey_[wv];
       cogstate = cogstate_[wv];
       cogstateA = cogstateA_[wv];
       proxy = proxy_[wv];
       demver = demver_[wv];
       everdem = everdem_[wv];
       sampwv = sampwv_[wv];
       wtcrnh=wtcrnh_[wv];
       
       /* lag of sampwv */
       if wv>1 then lsampwv = sampwv_[wv-1];
       enrmo_long = enrmo_long_[wv];
       memrye = memrye_[wv];
       if wv<&maxwv then memrye_nxt = memrye_[wv+1];
       /* lag of cogstate */
       if wv>1 then lcogstate = cogstate_[wv-1];
       else lcogstate = .F;
       
       /* cogstate non-proxy scores */
       bwc20 = bwc20_[wv];
       tr20 = tr20_[wv];
       ser7 = ser7_[wv];
       totcog = totcog_[wv];
       totcogA = totcogA_[wv];
       totcog_imp = totcog_imp_[wv];
       
       if not missing(cogstate) and not missing(demver) then 
          cog_dif = (cogstate > 1 and demver=1)+2*(cogstate=1 and demver=0);
       else if missing(demver) then cog_dif = .D;
       else if missing(cogstate) then cog_dif = .C;
       cog_dif_type = "C";  /* status using current cogstate and demver */
       
       /* check if matches prior wave cogstate - allow these as matches */
       if wv>1 and not missing(lcogstate) and not missing(demver) then do;
          if missing(cog_dif) then do;
             cog_dif = (lcogstate > 1 and demver=1)+2*(lcogstate=1 and demver=0);
             cog_dif_type = "L";
          end;
          else if cog_dif>0 then do;
             if (lcogstate>1 and demver=0) then cog_dif=-2;
             else if (lcogstate=1 and demver=1) then cog_dif=-1;
             if cog_dif < 0 then cog_dif_type = "P";
          end;
       end;
       output proj.dementia_bene_long;
       
    end;  /* do wv = 1 to dim(sampwv_) while not deceased */
    

    AD_wvs=sum(of everAD_[*]);
    dem_wvs=sum(of everdem_[*]);
    nonAD_wvs=sum(of evernonAD_[*]);
    nonADc_wvs=sum(of evernonADc_[*]);
    output proj.dementia_bene_wv;
 run;

proc freq data=proj.dementia_bene_wv;
 title2 dementia_bene_wv;
    table dupidall pickone dupidall*pickone in_enr 
          sp_befdem sp_aftdem n_spidR firstdem_wv firstAD_wv
          _diedwv firstwv lastwv _diedwv*(firstwv lastwv)
          sp_befdem*sp_aftdem
          AD_wvs dem_wvs nonAD_wvs nonADc_wvs in_enr*dem_wvs
         sampwv: everAD: everdem: newAD: newdem:
          /missing list;
run;

proc format;
  value spwvs
  2-10="2+";
  value agey
  low-64 = "under 65"
  65-69 = "65-69"
  70-75 = "70-74"
  75-79 = "75-79"
  80-84 = "80-84"
  85-high = "85+"
  ;
   value diff
   1-12="1-12: 1 yr"
   13-24="13-24: 2 yr"
   25-36="25-36: 3 yr"
   37-high="37+: >3 yr"
   ;

run;
