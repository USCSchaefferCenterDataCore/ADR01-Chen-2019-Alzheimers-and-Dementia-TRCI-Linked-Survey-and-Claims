/* dementia_dxdt_typ.sas
   read files with all dementia diagnoses for a claim by 
   type of claim.  Combine those with the same date of dx.
   
   Input: dementia_dx_[typ]_1991_2008
   Output: dementia_dxdt_[typ]_1991_2008
   where [typ] is ip, op, snf, hha, carmrg (car + car-linedx)
   
*/
options ls=150 ps=1000 nocenter replace compress=yes mprint;

%let hrsclaims=/sch-projects/dua-data-projects/HRS/Datalib/Data/Revsplit/;
%let minyr=1991;
%let maxyr=2008;
%let max_demdx=9;

%let ccw_dx="3310"  "33111" "33119" "3312"  "3317"  "2900"  "29010"
            "29011" "29012" "29013" "29020" "29021" "2903"  "29040" 
            "29041" "29042" "29043" "2940"  "29410" "29411" "29420" 
            "29421" "2948"  "797";
%let oth_dx="33182","33189","3319","2908","2909","2949" ;
%let symp_dx="78093" "7843" "78469" "33183";

/* ccw dementia codes by type */
%let AD_dx="3310 " ;
%let ftd_dx="33111", "33119" ;
%let vasc_dx="29040", "29041", "29042", "29043" ;
%let presen_dx="29010", "29011", "29012", "29013" ;
%let senile_dx="3312", "2900", "29020", "29021", "2903", "797" ;
%let unspec_dx="29420", "29421" ;
%let class_else="3317", "2940", "29410", "29411", "2948 " ;
 
/* other dementia dx codes, not on ccw list */
%let lewy_dx="33182";
%let degen="33189", "3319 ";
%let oth_sen="2908", "2909";
%let oth_clelse="2949";

/* dementia symptom dx codes, from Imfeld paper */
%let amnesia_dx="78093";
%let aphasia_dx="7843";
%let mci_dx="33183";
%let oth_symp_dx="78469";

%let clmtypes=ip sn hh op pb;

libname proj "Data";

/* combine diagnosis codes found from same service type on the same date */

%macro combine_dts(typ);

   title2 dementia_dx_&typ._1991_2008 to dementia_dxdt_&typ._1991_2008;
   proc sort data=proj.dementia_dx_&typ._1991_2008;
      by hhidpn year demdx_dt;

   data proj.dementia_dxdt_&typ._1991_2008;
      set proj.dementia_dx_&typ._1991_2008 (where=(not missing(hhidpn)));
      by hhidpn year demdx_dt;
   
      length _dxtypes $ 13 _demdx1-_demdx&max_demdx $ 5;
      length n_claim_typ n_add_typ _dxmax _dxmax1 3;
      retain n_claim_typ _dxmax _dxmax1 _dxtypes _demdx1-_demdx&max_demdx;
      
      array demdx_[*] demdx1-demdx&max_demdx; /* final/original vars */
      array _demdx_[*] _demdx1-_demdx&max_demdx; /* updated vars */
   
      /* set clm_typ---was originally done in a dropped append step in dementia_dx.sas */
      length  clm_typ $ 1;

      if "%substr(&typ,1,1)" = "i" then clm_typ="1"; /* inpatient */
      else if "%substr(&typ,1,1)" = "s" then clm_typ="2"; /* SNF */
      else if "%substr(&typ,1,1)" = "o" then clm_typ="3"; /* outpatient */
      else if "%substr(&typ,1,1)" = "h" then clm_typ="4"; /* home health */
      else if "%substr(&typ,1,1)" = "p" then clm_typ="5"; /* carrier */
      else clm_typ="X";  

      label clm_typ="Type of claim";

      /* first claim on this date.  Save dementia dx-s into master list */
      if first.demdx_dt=1 then do;
         do i=1 to dim(demdx_);
            _demdx_[i]=demdx_[i];
         end;
         _dxtypes=dxtypes;
         _dxmax=dx_max;
         _dxmax1=dx_max;
         n_claim_typ=1;
      end; 
      
      /* subsequent claim on same date.  Add any dementia dx that
         is not found in the first claim on this date */
      else do; /* not found dx in the first claim on this date */ 
         n_claim_typ=n_claim_typ+1;
         do i=1 to dx_max;
            dxfound=0;
            do j=1 to _dxmax;
               if demdx_[i]=_demdx_[j] then dxfound=1;
            end;
            if dxfound=0 then do;  /* new dx, update list */
               _dxmax=_dxmax+1;
               if _dxmax<&max_demdx then _demdx_[_dxmax]=demdx_[i];
               
		select (demdx_[i]); /* update dxtypes string */
                  when (&AD_dx)  substr(_dxtypes,1,1)="A";
                  when (&ftd_dx) substr(_dxtypes,2,1)="F";
                  when (&vasc_dx) substr(_dxtypes,3,1)="V";
                  when (&presen_dx) substr(_dxtypes,4,1)="P";
                  when (&senile_dx) substr(_dxtypes,5,1)="S";
                  when (&unspec_dx) substr(_dxtypes,6,1)="U";
                  when (&class_else) substr(_dxtypes,7,1)="E";
                  when (&lewy_dx) substr(_dxtypes,8,1)="l";
                  when (&degen) substr(_dxtypes,9,1)="d";
                  when (&oth_sen) substr(_dxtypes,10,1)="s";
                  when (&oth_clelse) substr(_dxtypes,11,1)="e";
                  otherwise substr(_dxtypes,12,1)="X";
               end; /* select */

            end;  /* dxfound = 0 */
         end; /* do i=1 to _dxmax */
      end;  /* multiple claims on same date */

      /* output one obs per service-type and date */
      if last.demdx_dt=1 then do;
         /* restore original variables with updated ones */
         dxtypes=_dxtypes;
         do i=1 to dim(demdx_);
            demdx_[i]=_demdx_[i];
         end;
         n_add_typ=_dxmax - _dxmax1;
         dx_max=_dxmax;
         output;
      end;
      
      label n_add_typ="# of dementia dx codes added from mult claims"
            n_claim_typ="# of claims with same date of same service type"
            ;
      drop _demdx: _dxmax _dxtypes i j dxfound _dxmax1;
   run;
   proc freq data=proj.dementia_dxdt_&typ._1991_2008;
      table n_claim_typ n_add_typ /missing ;
      run;
%mend combine_dts;

%combine_dts(ip);
%combine_dts(op);
%combine_dts(sn);
%combine_dts(hh);
%combine_dts(pb);

endsas;



