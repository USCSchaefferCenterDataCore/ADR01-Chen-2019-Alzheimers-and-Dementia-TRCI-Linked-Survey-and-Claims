/* dementia_bene.sas
   Make a bene_level file that summarizes dementia dates (un-&verified), regardless of enrollent
   
   input: dementia_dxdate_1991_2008
   output: dementia_bene

*/

options compress=yes mprint nocenter ls=150 ps=58;

%include "../../setup.inc";
%let minyr=1991;
%let maxyr=2008;

***** libname bene "&datalib.&clean_data./BeneStatus";

libname bsf "&hrsbsf";
libname proj "&projdir.Data";
  
  
   proc sql;
     /* compare ad and nonad earliest dx dates from bene_cond to 
        diagnosis dates after those dates from dementia_dxdate */
    create table dementia_dts as
       select hhidpn,dementia,dementia_add,demdx_dt,
              AD,max(FTD,Vascular) as FTDVas,oth_dementia as othdem,
              Lewy, oth_demadd as othdem_add,
              elsewhere,elsewhere_add,
              max(FTD,Vascular,oth_dementia,Lewy,oth_demadd) as nonAD_dem_add,
              max(FTD,Vascular,oth_dementia) as nonAD_dem,
              case AD when 0 then . when 1 then demdx_dt else .X end as AD_dt,
              case calculated FTDVas when 0 then . when 1 then demdx_dt else .X end as FTDVas_dt,
              case Lewy when 0 then . when 1 then demdx_dt else .X end as Lewy_dt,
              case othdem when 0 then . when 1 then demdx_dt else .X end as othdem_dt,
              case elsewhere when 0 then . when 1 then demdx_dt else .X end as elsewhere_dt,
              case othdem_add when 0 then . when 1 then demdx_dt else .X end as othdem_add_dt,
              case elsewhere_add when 0 then . when 1 then demdx_dt else .X end as elsewhere_add_dt,
              case calculated nonAD_dem when 0 then . when 1 then demdx_dt else .X end as nonAD_dem_dt,
              case calculated nonAD_dem_add when 0 then . when 1 then demdx_dt else .X end as nonAD_dem_add_dt
       from proj.dementia_dxdate_&minyr._&maxyr (where=(dementia_add ne 0))
       order hhidpn,demdx_dt;

     create table dementia_dt_bsf as 
        select hhidpn,min(alzhe) as alzhe,min(alzhdmte) as alzhdmte
            from (select hhidpn,input(alzhe,yymmdd8.) as alzhe,input(alzhdmte,yymmdd8.) as alzhdmte 
                from bsf.basf_1991_2008 (keep=hhidpn alzhe alzhdmte) )
            group by hhidpn
            order hhidpn;
                
data proj.dementia_bene;
   merge dementia_dt_bsf (in=_inbsf)
         dementia_dts (in=_indts);
   by hhidpn;
   
   length ndx_AD ndx_else_AD ndx_else_add_AD ndx_AD2othdem 
          ndx_AD2othdem_add ndx_AD2FTDVasLewy 
          ndx_othdem2AD ndx_othdem_add2AD 
          ndx_othdem ndx_else_othdem 
          ndx_othdem_add ndx_else_othdem_add 
          ndx_othdem_add2nonAD
          more_AD_dx more_othdem_dx else_AD_dx else_othdem_dx
          more_AD2othdem_dx more_othdem2AD_dx
          more_othdem_add_dx else_add_AD_dx else_othdem_add_dx
          more_AD2othdem_add_dx more_othdem_add2AD_dx
          3;
   label ndx_AD="# of AD dx after first"
         ndx_else_AD="# of specified elsewhere dx after first AD dx"
         ndx_else_add_AD="# of specified elsewhere (incl new) dx after first AD dx"
         ndx_othdem="# of other dementia dx after first nonAD dem dx"
         ndx_else_othdem="# of specified elsewhere dx after first nonAD dementia dx"
         ndx_othdem_add="# of other dementia (incl new) dx after first nonAD demdx"
         ndx_else_othdem_add="# of specified elsewhere dx after first other dementia dx (incl new)"

         ndx_AD2FTDVasLewy="# of FTD/Vascular/Lewy dem after first AD dx"
         ndx_AD2othdem="# of oth dementia dx after first AD"
         ndx_AD2othdem_add="# of oth dementia (incl new) dx after first AD"
         /* ndx_FTDVasLewy2AD="# of FTD/Vascular/Lewy dem before first AD dx" */
         /* ndx_othdem2AD="# first other dementia before first AD dx" */
         ndx_othdem_add2AD="# first other dementia (incl new) bwfore first AD dx"

         ndx_othdem_add2nonAD="# of other dementia dx (incl new) before first nonAD dx"
         
         more_AD_dx="Flags benes with at least 1 AD dx after first"
         more_othdem_dx="Flags benes with at least 1 other dementia dx after first"
         more_AD2othdem_dx = "Flags benes with at least 1 oth dem dx after first AD"
         more_othdem2AD_dx = "Flags benes with at least 1 other dementia before an AD dx"
         else_AD_dx="Flags benes with at least 1 specified elsewhere dx after first AD"
         else_othdem_dx="Flags benes with at least 1 specified elsewhere dx after first other dementia"
         
         more_othdem_add_dx="Flags benes with at least 1 other dementia (incl new) dx after first"
         more_AD2othdem_add_dx = "Flags benes with at least 1 oth dem (incl new) dx after first AD"
         more_othdem_add2AD_dx = "Flags benes with at least 1 oth dem (incl new) before an AD dx"
         else_add_AD_dx="Flags benes with at least 1 specified elsewhere (incl new) dx after first AD"
         else_othdem_add_dx="Flags benes with at least 1 specified elsewhere dx after first other dementia (incl new)"
         
         AD_dtmin="Min date of additional AD dx"
         AD_dtmax="Max date of additional AD dx"
         othdem_dtmin="Min date of additional other dementia dx"
         othdem_dtmax="Max date of additional other dementia dx"
         elsewhere_dtmin = "Min date of elsewhere specified dementia dx"
         othdem_add_dtmin="Min date of additional other dementia (incl new) dx"
         othdem_add_dtmax="Max date of additional other dementia (incl new) dx"
         demdx_date="Earliest date of any dementia diagnosis from claims (incl new dx)"
         AD_date="Earliest date of AD diagnosis from claims"
         nonAD_date="Earliest date of nonAD dementia diagnosis from claims (CCW def)"
         nonAD_add_date="Earliest date of nonAD dementia diagnosis from claims (incl new dx)"
         Lewy_date="Earliest date of Lewy body dementia"
         FTDVas_date="Earliest date of FTD or vascular dementia"
         dx2_add_date="Date of 2nd dementia dx (incl new)"
         dx2_date="Date of 2nd dementia dx"
         ;
        retain ndx_AD ndx_else_AD ndx_else_add_AD ndx_AD2othdem 
               ndx_AD2othdem_add ndx_AD2FTDVasLewy 
               ndx_othdem2AD ndx_othdem_add2AD 
               ndx_othdem ndx_else_othdem 
               ndx_othdem_add ndx_else_othdem_add 
               ndx_othdem_add2nonAD
               AD_dtmin AD_dtmax othdem_dtmin othdem_dtmax
               othdem_add_dtmin othdem_add_dtmax
               demdx_date AD_date nonAD_date nonAD_add_date
               Lewy_date FTDVas_date dx2_date dx2_add_date
               elsewhere_dtmin 
               ;
        array init0_[*] ndx_AD ndx_else_AD ndx_else_add_AD ndx_AD2othdem 
                        ndx_AD2othdem_add ndx_AD2FTDVasLewy 
                        ndx_othdem2AD ndx_othdem_add2AD 
                        ndx_othdem ndx_else_othdem 
                        ndx_othdem_add ndx_else_othdem_add 
                        ndx_othdem_add2nonAD
                        ;
        array initmiss_[*] AD_dtmin AD_dtmax othdem_dtmin othdem_dtmax
                       othdem_add_dtmin othdem_add_dtmax
                       demdx_date AD_date nonAD_date nonAD_add_date
                       Lewy_date FTDVas_date  
                       dx2_date dx2_add_date elsewhere_dtmin
                       ;
        

        if first.hhidpn then do;
           do i=1 to dim(init0_);
              init0_[i]=0;
           end;
           do i=1 to dim(initmiss_);
              initmiss_[i]=.;
           end;
        end;
        
        /* flag file contributions */
        in_basf=_inbsf;
        in_demdt=_indts;
        
        /* Earliest date for all dementia dx */
        demdx_date = min(demdx_date,demdx_dt);
        
        if dx2_add_date=. and demdx_dt > demdx_date > .Z then dx2_add_date=demdx_dt;
        if dx2_date=. and max(AD,nonAD,elsewhere)=1 and demdx_dt > min(Ad_dtmin,othdem_dtmin,elsewhere_dtmin) > .Z
           then dx2_date=demdx_dt;
        
        if elsewhere=1 then elsewhere_dtmin = min(elsewhere_dtmin,demdx_dt);
        
        if AD=1 then AD_date = min(AD_date,AD_dt);
        else if AD=0 and max(FTDVas,othdem,elsewhere)=1 then nonAD_date=min(nonAD_date,demdx_dt);
        if AD=0 and max(FTDVas,othdem,elsewhere,Lewy,othdem_add,elsewhere_add) then nonAD_add_date=min(nonAD_add_date,demdx_dt);
        if FTDVas=1 then FTDVas_date=min(FTDVas_date,demdx_dt);
        if Lewy=1 then Lewy_date=min(Lewy_date,demdx_dt);

        /* set nonAD date from alzhdmte if not same as alzhe */
        if missing(alzhe) or (alzhe ne alzhdmte) then nonalzhe=alzhdmte;
        else nonalzhe=.;
        
        /* set flags for first alzhe and alzhdmte */
        any_alzh=not missing(alzhe);
        any_nonalzh=not missing(nonalzhe);
        
        /* if AD dx, then count AD and other dementia diagnosis types */
        if not missing(AD_date) and demdx_dt > AD_date then do;  /* alzhe before cur dx date */
           if AD=1 then do;  /* initial dx verified by another AD dx */
              ndx_AD=ndx_AD+1;
              AD_dtmin = min(AD_dtmin,AD_dt);
              AD_dtmax = max(AD_dtmax,AD_dt);
           end;
           
           if elsewhere=1 then ndx_else_AD=ndx_else_AD+1;
           if elsewhere_add=1 then ndx_else_add_AD = ndx_else_add_AD+1;
           if othdem=1 then ndx_AD2othdem = ndx_AD2othdem+1;
           if othdem_add=1 then ndx_AD2othdem_add = ndx_AD2othdem_add+1;
           if max(FTDVas,Lewy)=1 then ndx_AD2FTDVasLewy = ndx_AD2FTDVasLewy+1;
           
        end;
        
        else if . < demdx_dt < AD_date then do;  /* alzhe after current dx date */
           if max(othdem,FTDVas)=1 then ndx_othdem2AD = ndx_othdem2AD+1; 
           if max(othdem_add,FTDVas,Lewy)=1 then ndx_othdem_add2AD = ndx_othdem_add2AD+1;
        end;

        /* if nonAD dementia then count other dementia dx types */
        if not missing(nonAD_date) and demdx_dt > nonAD_date then do;  /* nonalzhe before cur dx date */
           if max(FTDVas,othdem)=1 then do;  /* initial dx verified by another other dem dx */
              ndx_othdem=ndx_othdem+1;
              othdem_dtmin = min(othdem_dtmin,demdx_dt);
              othdem_dtmax = max(othdem_dtmax,demdx_dt);
           end;
           
           if max(FTDVas,othdem_add,Lewy)=1 then do;  /* initial dx verified by another other dem dx */
              ndx_othdem_add=ndx_othdem_add+1;
              othdem_add_dtmin = min(othdem_add_dtmin,demdx_dt);
              othdem_add_dtmax = max(othdem_add_dtmax,demdx_dt);
           end;
           
           if elsewhere=1 then ndx_else_othdem=ndx_else_othdem+1;
           if elsewhere_add=1 then ndx_else_othdem_add = ndx_else_othdem_add+1;
        end;
        
        else if . < demdx_dt < nonAD_date then do;  /* nonalzhe after cur dem dx */
           if max(othdem_add,Lewy)=1 then ndx_othdem_add2nonAD = ndx_othdem_add2nonAD+1;
        end;
        
        if last.hhidpn=1 then do;  /* summarize for hhidpn */

           any_AD=not missing(AD_date);
           any_nonAD=not missing(nonAD_date);
           any_nonAD_add=not missing(nonAD_add_date);
           
           /* AD and related dementias earliest dx date */
           ADR_date = min(AD_date,nonAD_date);
           ADR_add_date = min(AD_date,nonAD_date,nonAD_add_date);
           any_ADR = not missing(ADR_date);
           any_ADR_add = not missing(ADR_add_date);
           
           /* check dx-based dates with CCW dates 
              without new dx is before, same, after CCW */
           AD_dt_flag=sign(AD_date - alzhe);
           nonAD_dt_flag=sign(nonAD_date - nonalzhe);
           ADR_dt_flag=sign(ADR_date - alzhdmte);
           ADR_add_dt_flag = sign(min(ADR_date,ADR_add_date) - alzhdmte); 

           more_AD_dx=(ndx_AD>0);
           more_AD2othdem_dx = (ndx_AD2othdem>0);
           more_AD2othdem_add_dx = (ndx_AD2othdem_add>0);
           else_AD_dx= (ndx_else_AD>0);
           else_add_AD_dx = (ndx_else_add_AD>0);
           more_othdem2AD_dx = (ndx_othdem2AD>0);
           more_othdem_add2AD_dx = (ndx_othdem_add2AD>0);
         
           more_othdem_dx=(ndx_othdem>0);
           else_othdem_dx=(ndx_else_othdem>0);
           more_othdem_add_dx=(ndx_othdem_add>0);
           else_othdem_add_dx=(ndx_else_othdem_add>0);
           more_othdem_add2nonAD=(ndx_othdem_add2nonAD>0);
           
           new_dem_first=(. < demdx_date < min(alzhe,nonalzhe));
           
           /* make a verify dx flag to quantify whether there is any
              additional dx after first */
           if not missing(AD_date) and not missing(nonAD_date) then do;  /* AD dx found */
              if AD_date < nonAD_date then dementia_order=3;  /* AD before CCW dementia def */
              else if nonAD_date < AD_date then dementia_order=5;  /* CCW dementia before AD */
              else dementia_order=4;  /* same dates */
           end;
           else if not missing(AD_date) then dementia_order=1;  /* only AD */
           else if not missing(nonAD_date) then dementia_order=2;  /* only nonAD */
           else if not missing(nonAD_add_date) then dementia_order=6;
           else dementia_order=0;  /* no dementia */
           
           if not missing(AD_date) then do;
              if more_AD_dx=1 then AD_verify=1;
              else if else_AD_dx=1 then AD_verify=2;
              else if othdem2AD_dx=1 then AD_verify=3;
              else if more_AD2othdem_dx=1 then AD_verify=4;
              else if else_add_AD_dx=1 then AD_verify=5;
              else if more_othdem_add2AD_dx=1 then AD_verify=6;
              else if more_AD2othdem_add_dx=1 then AD_verify=7;
              else AD_verify=0;
          end;
   
          if not missing(nonAD_date) then do;
             if more_othdem_dx=1 then nonAD_verify=1;
             else if else_othdem_dx=1 then nonAD_verify=2;
             else if more_AD2othdem_dx=1 then nonAD_verify=3;
             else if othdem2AD_dx=1 then nonAD_verify=4;
             else if else_othdem_add_dx=1 then nonAD_verify=5;
             else if more_AD2othdem_add_dx=1 then nonAD_verify=6;
             else if more_othdem_add2AD_dx=1 then nonAD_verify=7;
             else if more_othdem_add_dx=1 then nonAD_verify=7;
             else nonAD_verify=0;
          end;

          if not missing(nonAD_add_date) then do;
             if more_othdem_add_dx=1 then nonAD_add_verify=1;
             else if else_othdem_add_dx=1 then nonAD_verify=2;
             else if more_AD2othdem_add_dx=1 then nonAD_add_verify=3;
             else if more_othdem_add2AD_dx=1 then nonAD_add_verify=4;
             else nonAD_add_verify=0;
          end;
          
          dx2_add_diff = intck("MONTH",demdx_date,dx2_add_date)+1; /* Date of 2nd dementia dx (incl new) */
          dx2_diff = intck("MONTH",min(AD_date,nonAD_date,elsewhere_dtmin),dx2_date)+1; /* Date of 2nd dementia dx */
          
          output;
        end;
        
        drop demdx_dt FTDVas AD MCI Lewy othdem othdem_add elsewhere elsewhere_add nonAD_dem
             AD_dt FTDVas_dt Lewy_dt othdem_dt othdem_add_dt elsewhere_dt elsewhere_add_dt
             nonAD_dem_dt nonAD_dem_add_dt dementia dementia_add;
        format demdx_date nonAD_date nonAD_add_date AD_date FTDVas_date Lewy_date 
               alzhe nonalzhe dx2_date dx2_add_date 
               date10.;
run;

%let AD_flags=more_AD_dx           more_AD2othdem_dx    more_AD2othdem_add_dx
              else_AD_dx           else_add_AD_dx       more_othdem2AD_dx
              more_othdem_add2AD_dx
               ;         
%let nonAD_flags=more_othdem_dx       
           else_othdem_dx       
           more_othdem_add_dx   
  dementia_order AD_verify         else_othdem_add_dx   
           more_othdem_add2nonAD
        ;

proc freq data=proj.dementia_bene;
   table in_basf in_demdt new_dem_first any_alzh any_nonalzh any_AD any_nonAD any_nonAD_add any_ADR any_ADR_add
         any_ADR*any_ADR_add any_nonAD*any_nonAD_add
         any_ADR*any_AD*any_nonAD*any_nonAD_add
         any_ADR_add*any_AD*any_nonAD*any_nonAD_add
         any_alzh*any_AD any_nonalzh*any_nonAD*any_nonAD_add any_alzh*any_nonalzh*any_ADR*any_ADR_add
         any_alzh*any_nonalzh*new_dem_first
         AD_dt_flag nonAD_dt_flag ADR_dt_flag ADR_add_dt_flag
         dementia_order AD_verify nonAD_verify nonAD_add_verify
         any_AD*(dementia_order AD_verify)
         any_nonAD*(dementia_order AD_verify nonAD_verify nonAD_add_verify)
         AD_date nonAD_date nonAD_add_date ADR_date ADR_add_date
         more_: else_: 
         any_alzh*more_AD_dx*else_AD_dx*else_add_AD_dx*more_AD2othdem_dx*more_AD2othdem_add_dx
         any_nonalzh*more_othdem_dx*else_othdem_dx*else_othdem_add_dx*more_othdem_add_dx
         any_alzh*(&AD_flags)
         any_nonalzh*(&nonAD_flags)
         /missing list;
  table dx2_diff dx2_add_diff /missprint;
  format AD_date nonAD_date nonAD_add_date ADR_date ADR_add_date year4.;
run;

proc means data=proj.dementia_bene;
   class any_alzh any_nonalzh;
   var ndx_: AD_date nonAD_date ADR_date nonAD_add_date ADR_add_date ;
   run;
proc univariate data=proj.dementia_bene;
   var  dx2_add_diff dx2_diff;
   run;

endsas;
/*
         more_incident_dx="Flags benes with at least 1 addl dx after incident dx"
         else_incident_dx="Flags benes with at least 1 specified elsewhere dx after incident dx"
         more_incident_chgdx="Flags benes with at least 1 different dx after incident dx"
        
        select (incident_status);
            when (1) more_incident_dx = more_AD_dx;
            when (2) more_incident_dx = more_AD_date nonAD_date ADR_date nonAD_add_date ADR_add_dateothdem_dx;
            when (3) more_incident_dx = more_AD_dx;
            otherwise more_incident_dx = .X;
         end;
        select (incident_status);
            when (1) more_incident_chgdx = more_AD2othdem_dx;
            when (2) more_incident_chgdx = more_othdem2AD_dx;
            when (3) more_incident_chgdx = more_AD2othdem_dx;
            otherwise more_incident_chgdx = .X;
         end;
         select (incident_status);
            when (1) else_incident_dx = else_AD_dx;
            when (2) else_incident_dx = else_othdem_dx;
            when (3) else_incident_dx = else_AD_dx;
            otherwise else_incident_dx = .X;
         end;

         /* use flags to also verify AD status */
         select (AD_status);
            when (1,2)  /* AD is first dementia dx (in AD_yr from alzhe) */
            when (3)    /* AD after nonAD dementia */
            when (4)    /* only nonAD dementia */
            otherwise ;
         end; 

         more_incident_dx="Flags benes with at least 1 addl dx after incident dx"
         else_incident_dx="Flags benes with at least 1 specified elsewhere dx after incident dx"
         more_incident_chgdx="Flags benes with at least 1 different dx after incident dx"
*/
        