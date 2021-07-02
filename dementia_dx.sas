/* dementia_dx.sas
   pull all dementia dx's and look at the order of
   change in diagnosis code (AD->other dementia and vice versa)

   Input: [ctyp]_fix_yyyy
   Output: dementia_dx_[ctyp]_1991_2008
*/

options ls=150 ps=1000 nocenter replace compress=yes mprint;
**** options obs=1000;

%let hrsclaims=/sch-projects/dua-data-projects/HRS/Datalib/Data/Revsplit/;
%let minyr=1991;
%let maxyr=2008;
%let ccw_dx="3310"  "33111" "33119" "3312"  "3317"  "2900"  "29010"
            "29011" "29012" "29013" "29020" "29021" "2903"  "29040" 
            "29041" "29042" "29043" "2940"  "29410" "29411" "29420" 
            "29421" "2948"  "797";
%let oth_dx="33182" "33189" "3319" "2908" "2909" "2949";
%let symp_dx="78093" "7843" "78469" "33183";

/* ccw dementia codes by type */
%let AD_dx="3310";
%let ftd_dx="33111", "33119";
%let vasc_dx="29040", "29041", "29042", "29043";
%let presen_dx="29010", "29011", "29012", "29013";
%let senile_dx="3312", "2900",  "29020", "29021", "2903", "797";
%let unspec_dx="29420", "29421";
%let class_else_dx="3317", "2940", "29410", "29411", "2948" ;
 
/* other dementia dx codes, not on ccw list */
%let lewy_dx="33182";
%let degen_dx="33189", "3319";
%let oth_sen_dx="2908", "2909";
%let oth_clelse_dx="2949";

/* dementia symptom dx codes, from Imfeld paper */
%let amnesia_dx="78093";
%let aphasia_dx="7843";
%let mci_dx="33183";
%let oth_symp_dx="78469";

%let clmtypes=ip snf hh op car;

%let max_demdx=9;

libname dx "&hrsclaims";
libname proj "Data";
   
%macro getdx(ctyp,byear,eyear,dxv=,dropv=,keepv=,diag=dgnscd);
   
   data proj.dementia_dx_&ctyp._&byear._&eyear;
     
      set 
      %do year = &byear %to &eyear;
          dx.&ctyp._fix_&year (in=_in&year keep=hhidpn thru_dt &diag.: &dxv &keepv drop=&dropv)
      %end;
          ; /* end set */
      
      length demdx1-demdx&max_demdx $ 5 dxtypes $ 13;
      length n_ccwdem n_othdem n_demdx n_sympdx dxsub 3;
      
      array _iny_[&byear.:&eyear] _in&byear - _in&eyear;
      array diag_[*] &diag.: &dxv ;
      array demdx_[*] demdx1-demdx&max_demdx; /* max_demdx=9 */
      
      /* first set claim year */
      do y=&byear to &eyear;
         if _iny_[y]=1 then year=y;
      end;
      
      /* count how many dementia-related dx are found,
         separately by ccw list, other list, and symptom list.
         Keep thru_dt as dx date.
         Keep first 5 dx codes found.
      */
      n_ccwdem=0;
      n_othdem=0;
      n_sympdx=0;
      dxsub=0; /* # of unique dementia dx */
      do i=1 to dim(diag_);
         if diag_[i] in (&ccw_dx) then n_ccwdem=n_ccwdem+1;
         if diag_[i] in (&oth_dx) then n_othdem=n_othdem+1;
         if diag_[i] in (&symp_dx) then n_sympdx= n_sympdx+1;
         if diag_[i] in (&ccw_dx &oth_dx) then do;
            found=0;
            do j=1 to dxsub;
               if diag_[i]=demdx_[j] then found=j;
            end;
            if found=0 then do;
               dxsub=dxsub+1;
               if dxsub<=&max_demdx then demdx_[dxsub]=diag_[i]; /* dementia dx 1-10, by the order of dementia dx */
            end;
         end;
      end;
      
      if n_ccwdem=0 and n_othdem=0 and n_sympdx=0 then delete;  /* just keep claims w/ dementia diagnoses */
      else demdx_dt=input(thru_dt,yymmdd8.);
      
      n_demdx=sum(n_ccwdem,n_othdem);
      
      /* summarize the types of dementia dx into a string var dxtypes: AFVPSUEldse
         uppercase are CCW dx codes, lowercase are others */
      
      do j=1 to dxsub;
         select (demdx_[j]);
            when (&AD_dx)  substr(dxtypes,1,1)="A";
            when (&ftd_dx) substr(dxtypes,2,1)="F";
            when (&vasc_dx) substr(dxtypes,3,1)="V";
            when (&presen_dx) substr(dxtypes,4,1)="P";
            when (&senile_dx) substr(dxtypes,5,1)="S";
            when (&unspec_dx) substr(dxtypes,6,1)="U";
            when (&class_else) substr(dxtypes,7,1)="E";
            when (&lewy_dx) substr(dxtypes,8,1)="l";
            when (&degen) substr(dxtypes,9,1)="d";
            when (&oth_sen) substr(dxtypes,10,1)="s";
            when (&oth_clelse) substr(dxtypes,11,1)="e";
            otherwise substr(dxtypes,12,1)="X";
         end;
      end;
      
      drop &diag.: &dxv thru_dt found i j y;
      rename dxsub=dx_max;
      
      label n_ccwdem="# of CCW dementia dx"
            n_othdem="# of other dementia dx"
	    n_sympdx="# of dementia symptom dx"
            n_demdx="Total # of dementia dx"
            dx_max="# of unique dementia dx"
            demdx1="Dementia diagnosis 1"
            demdx2="Dementia diagnosis 2"
            demdx3="Dementia diagnosis 3"
            demdx4="Dementia diagnosis 4"
            demdx5="Dementia diagnosis 5"
            demdx6="Dementia diagnosis 6"
            demdx7="Dementia diagnosis 7"
            demdx8="Dementia diagnosis 8"
            demdx9="Dementia diagnosis 9"
            demdx10="Dementia diagnosis 10"
            demdx_dt="Date of dementia diagnosis"
            dxtypes="String summarizing types of dementia dx"
            ;
run;


%getdx(ip,1991,2008,dxv=ad_dgns pdgns_cd)
%getdx(sn,1991,2008,dxv=ad_dgns pdgns_cd)
%getdx(hh,1991,2008,dxv=pdgns_cd)
%getdx(op,1991,2008,dxv=pdgns_cd)
%getdx(pb,1991,2008,dxv=pdgns_cd,keepv=claim_id,diag=dgns_cd)

/* car line diagnoses */
data proj.dementia_dx_carline_1991_2008;
   set dx.pb_line_1991 (in=_in1991 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_1992 (in=_in1992 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_1993 (in=_in1993 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_1994 (in=_in1994 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_1995 (in=_in1995 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_1996 (in=_in1996 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_1997 (in=_in1997 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_1998 (in=_in1998 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_1999 (in=_in1999 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_2000 (in=_in2000 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_2001 (in=_in2001 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_2002 (in=_in2002 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_2003 (in=_in2003 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_2004 (in=_in2004 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_2005 (in=_in2005 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_2006 (in=_in2006 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_2007 (in=_in2007 keep=hhidpn expdt1 lndgns claim_id)
       dx.pb_line_2008 (in=_in2008 keep=hhidpn expdt1 lndgns claim_id)
       ;
    length line_ccwdem line_othdem line_symp 3;
    length clm_typ $ 1 line_dxtype $ 1;
    
    line_ccwdem=lndgns in (&ccw_dx);
    line_othdem=lndgns in (&oth_dx);
    line_symp=lndgns in (&symp_dx);
    
    if line_ccwdem=0 and line_othdem=0 and line_symp=0 then delete;
    demdx_dt=input(expdt1,yymmdd8.);
    clm_typ="6"; /* carrier-line */

    select (lndgns);
       when (&AD_dx)  line_dxtype="A";
       when (&ftd_dx) line_dxtype="F";
       when (&vasc_dx) line_dxtype="V";
       when (&presen_dx) line_dxtype="P";
       when (&senile_dx) line_dxtype="S";
       when (&unspec_dx) line_dxtype="U";
       when (&class_else) line_dxtype="E";
       when (&lewy_dx) line_dxtype="l";
       when (&degen) line_dxtype="d";
       when (&oth_sen) line_dxtype="s";
       when (&oth_clelse) line_dxtype="e";
       otherwise line_dxtype="X";
    end;
    drop expdt1;
    label line_ccwdem="Whether carrier line dx =CCW dementia dx"
          line_othdem="Whether carrier line dx =other dementia dx"
          line_symp="Whether carrier line dx =dementia symptom dx"
          line_dxtype="Type of dementia dx"
          clm_typ="Type of claim"
          demdx_dt="Date of dementia dx"
          ;
run;



