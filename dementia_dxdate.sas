/* dementia_dxdate.sas
   look at all dementia dx's and look at the order of
   change in diagnosis code (AD->other dementia and vice versa)

   Input: dementia_dxdt_[typ]_ 1991_2008
   Output: dementia_dxdate_1991_2008
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


data proj.dementia_dxdate_1991_2008;
 
  merge proj.dementia_dxdt_ip_1991_2008     
        proj.dementia_dxdt_op_1991_2008     
        proj.dementia_dxdt_sn_1991_2008    
        proj.dementia_dxdt_hh_1991_2008    
        proj.dementia_dxdt_pb_1991_2008 
        ;
   by hhidpn year demdx_dt clm_typ;
   
   mult_clmtyp=(first.clm_typ=0 or last.clm_typ=0); /* more than one type on same date */
   if clm_typ="6" then clm_typ="5";  /* treat linedx source as car */
   
   /* output summarized events, across claim types on same date? */
   /* Which dementias take precedence?
      Count # of types, flag mult dementias on one date
      Then attempt to look at order...e.g., types by year?
       */

   length claim_types $ 5 _dxtypes $ 13 _demdx1-_demdx&max_demdx $ 5;
   length n_claims n_add_dxdate _dxmax _dxmax1 dxfound 3;
   length AD FTD Vascular oth_dementia elsewhere mixed
          oth_demadd elsewhere_add mixed_add
          Lewy dementia dementia_add
          mult_clmtyp
         3;
   retain claim_types n_claims _dxmax _dxmax1 _dxtypes _demdx1-_demdx&max_demdx;
   
   array demdx_[*] demdx1-demdx&max_demdx;
   array _demdx_[*] _demdx1-_demdx&max_demdx;

   if first.demdx_dt=1 then do;
      do i=1 to dim(demdx_);
         _demdx_[i]=demdx_[i];
      end;
      _dxtypes=dxtypes;
      _dxmax=dx_max;
      _dxmax1=dx_max;
      claim_types=clm_typ;
      n_claims=n_claim_typ;
   end;
   else do;  /* if multiple claims on same date, merge dx lists */
      n_claims=n_claims+n_claim_typ;
      if first.clm_typ=1 then claim_types = trim(left(claim_types)) || clm_typ;
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

   if last.demdx_dt=1 then do;
      /* restore original variables with updated ones */
      dxtypes=_dxtypes;
      do i=1 to dim(demdx_);
         demdx_[i]=_demdx_[i];
      end;
      dx_max=_dxmax;
      n_add_dxdate=_dxmax - _dxmax1;
      
      /* categorize the type of dementia diagnosis */
      AD = (substr(dxtypes,1,1)="A");
      FTD = (substr(dxtypes,2,1)="F");
      Vascular = (substr(dxtypes,3,1)="V");
      oth_dementia = (substr(dxtypes,4,1)="P" or 
                      substr(dxtypes,5,1)="S" or
                      substr(dxtypes,6,1)="U");
      oth_demadd = (oth_dementia=1 or
                    substr(dxtypes,9,1)="d" or
                    substr(dxtypes,10,1)="s");
      Lewy = (substr(dxtypes,8,1)="l");
      elsewhere = (substr(dxtypes,7,1)="E");
      elsewhere_add = (elsewhere = 1 or substr(dxtypes,11,1)="e");
      
      if sum(AD, FTD, Vascular)>1 then mixed = 1;
      else mixed = 0;
      
      /* categorize the diagnoses on this claim */
      dementia=0;
      if AD=1 then dementia=1;
      else if FTD=1 then dementia=2;
      else if vascular=1 then dementia=3;
      else if oth_dementia = 1 then dementia=7;
      else if elsewhere = 1 then dementia=8;
      
      /* alternate using additional DX */
      if sum(AD, FTD, Vascular, Lewy) > 1 then mixed_add=1;
      else mixed_add=0;
      
      dementia_add = dementia;
      if Lewy=1 and (dementia=0 or dementia>3) then dementia_add=4;
      else if dementia in (0,8) and oth_demadd = 1 then dementia_add=7;
      else if dementia=0 and elsewhere_add=1 then dementia_add=8;
      
      output;
   end;
   
   label dementia="Category of dementia (AD-FTD-Vascular preferred)"
         dementia_add="Category of dementia-extended (AD-FTD-Vascular-Lewy preferred)"
         n_add_dxdate="# of dementia dx added from additional claim types"
         n_claims="# of claims with dem dx on same date"
         ;
   drop _demdx: _dxmax _dxmax1 _dxtypes i j dxfound clm_typ n_claim_typ n_add_typ;

run;

endsas;

/*
%macro runtab(ctyp);
   title2 for &ctyp claims;
   proc freq data=proj.dementia_dx_&ctyp._1991_2008 order=freq;
      table dxtypes /missing;
   run;
%mend;

%runtab(ip)
%runtab(snf)
%runtab(hha)
%runtab(op)
%runtab(carmrg)
     
endsas;
*/

  