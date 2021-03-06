C  NOTE: The present subroutine package uses I/O units 97, 98 and 99.
C        Do not use these unit numbers in your main program.
C
C  *********************************************************************
C                       SUBROUTINE ELSEPA
C  *********************************************************************
      SUBROUTINE ELSEPA(IELEC,EV,IZ,NELEC,MNUCL,MODF,MELEC,MUFIN,RMUF,MWEAK,
     1                  MEXCH,MCPOL,VPOLA,VPOLB,MABS,VABSA,VABSD,IHEF,
     2                                         IW,PV,WKSK,ISOT,EVLAB,TARGMASS,SINV)
C
C
C                              F. Salvat, A. Jablonski and C.J. Powell
C                              September 27, 2004
C
C
C     This subroutine computes scattering amplitudes, differential cross
C  sections and total (integrated) cross sections for ELastic Scattering
C  of Electrons and Positrons by neutral Atoms and positive ions.
C
C     The interaction is described through a static (central) field,
C  which consists of the electrostatic potential and, for projectile
C  electrons, an approximate local exchange potential. For slow
C  projectiles, a correlation-polarization potential and an absorptive
C  imaginary potential can optionally be included. The differential
C  cross section is evaluated by means of relativistic (Dirac) partial-
C  wave analysis, or from approximate high-energy factorizations.
C
C  Input arguments:
C    IELEC ..... electron-positron flag;
C                =-1 for electrons,
C                =+1 for positrons.
C    EV ........ projectile's kinetic energy (in eV).
C    IZ ........ atomic number of the target atom or ion.
C    NELEC ..... number of bound atomic electrons.
C    MNUCL ..... nuclear charge density model.
C                  1 --> point nucleus (P),
C                  2 --> uniform distribution (U),
C                  3 --> Fermi distribution (F),
C                  4 --> Helm's uniform-uniform distribution (Uu).
C    MELEC ..... electron density model.
C                  1 --> TFM analytical density,
C                  2 --> TFD analytical density,
C                  3 --> DHFS analytical density,
C                  4 --> DF numerical density, read from 'Z_zzz.DEN',
C                  5 --> density read from file 'density.usr'.
C    MUFIN ..... Aggregation effects...
C                  0 --> free atom,
C                  1 --> muffin-tin model.
C    RMUF ....   Muffin-tin radius (in cm).
C    MWEAK ..... PV axial-vector potential flag !O.K.
C                  0 --> no PV effects
C                  1 --> PV potential is on
C    MEXCH ..... exchange correction for electrons.
C                  0 --> no exchange correction,
C                  1 --> Furness-McCarthy (FM),
C                  2 --> Thomas-Fermi (TF),
C                  3 --> Riley-Truhlar (RT).
C    MCPOL ..... correlation-polarization correction.
C                  0 --> no correlation-polarization correction,
C                  1 --> Buckingham potential (B),
C                  2 --> Local density approximation (LDA).
C      VPOLA ... atomic polarizability (in cm**3).
C      VPOLB ... cutoff radius parameter b_pol
C                    (used only when MCPOL>0).
C    MABS ...... absorption correction (imaginary potential).
C                  0 --> no absorption correction,
C                  1 --> LDA (electron-hole excitations only).
C      VABSA ... strength of the absorption potential.
C      VABSD ... energy gap, DELTA (eV).
C                    (used only when MABS is different from 0).
C    IHEF ...... =0: phase shifts are computed for the electrostatic
C                    field of the whole atom (nucleus+electron cloud)
C                    with optional exchange, polarization and absorption
C                    corrections.
C                =1: the differential cross section is obtained from a
C                    high-energy factorization. The phase shifts are
C                    evaluated for the bare nucleus. The screening of
C                    the nuclear charge by the atomic electrons is
C                    accounted for by means of a pre-evaluated high-
C                    energy correction factor, which is read from file
C                    'Z_zzz.DFS'.
C                =2: when the energy is larger than 100 MeV, the DCS is
C                    obtained as the product of the Mott DCS for a point
C                    nucleus, the Helm Uu nuclear form factor (with an
C                    empirical Coulomb correction) and the electron
C                    screening factor.
C    IW ........ output unit (to be defined in the main program).
C    PV ........ parity related helicity constant (to be defined in the main program). !O.K.
C    WKSK ...... weak skin as a fraction of the charge radius !O.K.
C
C  The electrostatic potential and electron density of the target atom
C  or ion are calculated by subroutine EFIELD and delivered through the
C  the named common block /CFIELD/.
C
C  Output (through the common block /DCSTAB/):
C     ECS ........ total cross section (cm**2).
C     TCS1 ....... 1st transport cross section (cm**2).
C     TCS2 ....... 2nd transport cross section (cm**2).
C     TH(I) ...... scattering angles (in deg)
C     XT(I) ...... values of (1-COS(TH(I)))/2.
C     DCST(I) .... differential cross section per unit solid
C                  angle at TH(I) (in cm**2/sr).
C     SPOL(I) .... Sherman spin-polarization function at TH(I).
C     ERROR(I) ... relative uncertainty of the computed DCS
C                  values. Estimated from the convergence of the
C                  series.
C     NTAB ....... number of angles in the table.
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1   INTEGER*4 (I-N)
C
C  ****  The parameter IWR defines the amount of information printed on
C  output files:
C  IWR>0 => the scattering potential is printed on file 'scfield.dat'.
C  IWR>1 => the scattering amplitudes are printed on file 'scatamp.dat'.
      PARAMETER (IWR=0)
C
C
      PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
      PARAMETER (HREV=27.21138602D0)  ! Hartree energy (eV)
      PARAMETER (GEV2HART=1.0D9/HREV) ! Conversion to Hartree
      PARAMETER (REV=5.109989461D5)  ! Electron rest energy (eV)
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (ALPHAFS=1.D0/SL)    ! Fine-structure constant 
      PARAMETER (A0B2=A0B*A0B)
      PARAMETER (TREV=REV+REV)
      PARAMETER (PI=3.1415926535897932D0,FOURPI=4.0D0*PI)
      PARAMETER (F2BOHR=1.0D-13/A0B)
      PARAMETER (GF=1.1663787D-5/GEV2HART**2*SL**3)!Fermi Constant

C
      CHARACTER*30 SCFILE,NULL,FILENAME
      CHARACTER*1 LIT10(10),LIT1,LIT2,LIT3
      DATA LIT10/'0','1','2','3','4','5','6','7','8','9'/
C
      PARAMETER (NGT=650)
      COMMON/DCSTAB/ECS,TCS1,TCS2,TH(NGT),XT(NGT),DCST(NGT),DCSTLAB(NGT),
     1              SPOL(NGT),ERROR(NGT),NTAB,THLAB(NGT)
      COMMON/CTOTCS/TOTCS,ABCS
      DIMENSION Q2T(NGT),FQ(NGT)
C
      PARAMETER (NDIM=1000,NDIN=NDIM-4)
      COMMON/CFIELD/R(NDIM),RVN(NDIM),DEN(NDIM),RVST(NDIM),NPOT,
     1                      RVNW(NDIM)
      COMMON/FIELD/RAD(NDIM),RV(NDIM),NP
      COMMON/FIELDI/RADI(NDIM),RVI(NDIM),RW(NDIM),IAB,NPI
      DIMENSION RVEX(NDIM),RVPOL(NDIM),GAUSSDENS(NDIM),
     1          GAUSS(NDIM),DE(NDIM),DIFRWEAK(NDIM),
     2          DEPR1(NDIM),DEPR2(NDIM),RWEAK(NDIM),
     3          DENN(NDIM),POT1(NDIM),POT2(NDIM)
C
      PARAMETER (NPC=1500,NDM=25000)
      COMMON/WORK/XL(NDM),SA(NDM),SB(NDM),SC(NDM),SD(NDM),PL(NDM)
      COMMON/CRMORU/CFM(NPC),CGM(NPC),DPC(NPC),DMC(NPC),
     1              CF,CG,RUTHC,WATSC,RK2,ERRFC,ERRGC,NPC1
      DIMENSION DENA(NPC),DENB(NPC),DENC(NPC),DEND(NPC)
C
C   Below one can choose which scattering angles to write to
C   files nuclmodel_001+.dat, nuclmodel_001-.dat, etc. when
C   the input parameter MODF is set to be nonzero.
C
      INTEGER :: INDX(18) = (/305,317,327,387,467,527,537,547,295,297,299,301,303,307,309,311,313,315/) 
      CHARACTER(3) :: FMTX
      CHARACTER(6) :: FMT
C
C  ----  Mott DCS and spin polarization (point unscreened nucleus)
      IF(NELEC.EQ.0.AND.MNUCL.EQ.1) THEN
        CALL MOTTSC(IELEC,IZ,EV,IW)
        RETURN
      ENDIF
C  ----  High-energy Mott-Born approximation.
      IF(EV.GT.100.0D6.AND.IHEF.EQ.2.AND.IZ.EQ.NELEC) THEN
        CALL HEBORN(IELEC,IZ,MNUCL,EV,IW)
        RETURN
      ENDIF
C
      WRITE(IW,1000)
 1000 FORMAT(1X,'#',/1X,'# Subroutine ELSEPA. Elastic scattering of ',
     1  'electrons and positrons',/1X,'#',20X,
     2  'by neutral atoms and positive ions')
      IF(IELEC.EQ.-1) THEN
        WRITE(IW,1100)
 1100   FORMAT(1X,'#',/1X,'# Projectile: electron')
      ELSE
        WRITE(IW,1200)
 1200   FORMAT(1X,'#',/1X,'# Projectile: positron')
      ENDIF
      E=EV/HREV
      WRITE(IW,1300) EV,E
 1300 FORMAT(1X,'# Kinetic energy =',1P,E12.5,' eV =',
     1       E12.5,' a.u.')

C
C  ****  You may wish to comment off the next condition to run the
C  program for kinetic energies less that 10 eV. However, the results
C  for these energies may be highly inaccurate.
C
      IF(EV.LT.10.0D0) THEN
        WRITE(IW,'(''  STOP. The kinetic energy is too small.'')')
        STOP 'The kinetic energy is too small.'
      ENDIF
      IF(EV.LT.100.0D0) THEN
        WRITE(IW,'(1X,''#'',/1X,''#  ***  WARNING: Energy is '',
     1   ''too low.'',/1X,''#'',16X,''The reliability of the '',
     2   ''results is questionable.'')')
      ENDIF
C
      IHEF0=0
      IF(EV.GT.20.1D3*IZ.AND.IHEF.GT.0.AND.IZ.EQ.NELEC) THEN
        IF(EV.GT.1.0D6.OR.MABS.EQ.0) THEN
          IHEF0=1
          GO TO 100
        ENDIF
      ENDIF
C
C  ****  Electrostatic field.
C
      IF(MNUCL.LT.1.OR.MNUCL.GT.4) THEN
        WRITE(IW,*) 'ELSEPA: incorrect MNUCL value.'
        STOP 'ELSEPA: incorrect MNUCL value.'
      ENDIF
      IF(MELEC.LT.1.OR.MELEC.GT.5) THEN
        WRITE(IW,*) 'ELSEPA: incorrect MELEC value.'
        STOP 'ELSEPA: incorrect MELEC value.'
      ENDIF
      CALL EFIELD(DENN,IZ,NELEC,NELEC,MNUCL,MODF,MELEC,IW,WKSK,ISOT)      
      ZINF=IELEC*DBLE(IZ-NELEC)
      DO I=1,NPOT
        RV(I)=DBLE(IELEC)*RVST(I)
      ENDDO
      RV(NPOT)=ZINF
C
C   Weak potential implementation by Oleksandr Koshchii
C
      IF(MWEAK.NE.0) THEN              
        CALL WEAKCHARGE(QW,DBLE(IZ),ISOT)
        CALL GRIDCOEF(RMI,RMA)
C 
C   Calculation of moments that sum of Gaussians (SG) predicts
C
        CALL GAUSSCALC(GAUSS,GAUSSDENS,GAUSSRAD,GAUSSRADT,DBLE(IZ),ISOT,RMI,RMA,NDIN)
C        
C   IF MODF equals to 0, sensitivity plots (Fig. 3 of Phys. Rev. C 102, 022501 (2020))
C   cannot be generated, as the caculation is performed using one specific nuclear
C   model for the weak skin (or no skin at all when MWEAK=1). Otherwise, sensitivity 
C   plots can be generated using various nuclear models as an input. In this version
C   of the code, five nuclear models of C-12 are implemented.
C
        IF (MODF.EQ.0) THEN !no nuclear model test
            IF (MWEAK.EQ.1) THEN !no weak skin
                RCN=0.0D0 !weak skin normalization factor
            ELSE IF (MWEAK.EQ.2) THEN !symmetrized Fermi skin
                A2=0.49445D0*F2BOHR !parameter "a" of model2
                RC2=2.06849D0*F2BOHR !parameter "c" of model2                
                CALL GAUSSCALC(POT1,DEPR1,RCH,RCHT,DBLE(IZ),ISOT,RMI,RMA,NDIN)
                CALL FERMICALC(POT2,DEPR2,RWK,RWKT,DBLE(IZ),RC2,A2,RMI,RMA,NDIN)
                RCN=1.0D0 !weak skin normalization factor
            ELSE IF (MWEAK.EQ.3) THEN  
                !never tested in this form
                A2=0.49445D0*F2BOHR
                RC2=2.06849D0*F2BOHR
                CALL GAUSSCALC(POT1,DEPR1,RCH,RCHT,DBLE(IZ),ISOT,RMI,RMA,NDIN)
                CALL HELMCALC(POT2,DEPR2,RWK,RWKT,DBLE(IZ),RC2,A2,RMI,RMA,NDIN)
                RCN=1.0D0 !weak skin normalization factor        
            ELSE
                WRITE(6,*) 'Change the value for MWEAK --> 0...3'
                STOP
            ENDIF
            WRITE(*,*), 'WKSK=', WKSK, 'RCH'
            CALL SGRID(RWEAK,DIFRWEAK,RMI,RMA,0.5D0*DBLE(NDIN),NDIN)
        ELSE
            CALL FERMI2PCOEFNUCL(RCCH2,ACH2,RCWK2,AWK2,DBLE(IZ),ISOT,MODF)
            CALL GAUSSCALC(POT1,DEPR1,RCH,RCHT,DBLE(IZ),ISOT,RMI,RMA,NDIN)
            CALL FERMICALC(POT2,DEPR2,RWK,RWKT,DBLE(IZ),RCWK2,AWK2,RMI,RMA,NDIN)
            !weak skin normalization factor changes depending on WKSK
            RCN=WKSK*GAUSSRAD**2*(2.0D0+WKSK)/(RWK**2-RCH**2) 
            CALL SGRID(RWEAK,DIFRWEAK,RMI,RMA,0.5D0*DBLE(NDIN),NDIN)
            WRITE(*,*), 'WKSK=', WKSK, 'RCH'
            WRITE(*,*), 'NORM=', RCN
        END IF   

        DO I=1,NDIM
            X=RWEAK(I)
            RVN(I)=RV(I)
            DE(I)=QW/DBLE(IZ)*DENN(I)+QW/DBLE(IZ)*RCN*(DEPR2(I)-DEPR1(I)) !DENN is passed from EFIELD
            RVNW(I)=GF/(2.0D0**1.5D0)*X*DE(I)
            IF (RVN(I).EQ.0.0D0) RVNW(I)=0.0D0 
            RV(I)=RVN(I)+PV*RVNW(I)
        ENDDO
      END IF
**************************************************************************************
      
C
C  ************  Muffin-tin model for scattering in solids.
C
      NMT=0
      IF(MUFIN.EQ.1) THEN
        WRITE(IW,1600) RMUF
 1600   FORMAT(1X,'#',/1X,'# Muffin-tin model: Rmt =',1P,E12.5,' cm')
        CALL SPLINE(R,RV,SA,SB,SC,SD,0.0D0,0.0D0,NPOT)
        CALL SPLINE(R,DEN,DENA,DENB,DENC,DEND,0.0D0,0.0D0,NPOT)
        RMT=RMUF/A0B
        IF(RMT.LT.R(NPOT)) THEN
          CALL FINDI(R,RMT,NPOT,J)
          IF(J.LT.5) STOP 'The muffin-tin radius is too small.'
          DENRMT=DENA(J)+RMT*(DENB(J)+RMT*(DENC(J)+RMT*DEND(J)))
        ELSE
          RMT=R(NPOT)
          DENRMT=DEN(NPOT)
        ENDIF
        RHORMT=2.0D0*DENRMT/(FOURPI*RMT**2)
        DO I=1,NPOT
          IF(R(I).GT.RMT) THEN
            IF(RAD(I-1).LT.RMT*0.9999999D0) THEN
              NP=I
              RAD(NP)=RMT
            ELSE
              NP=I-1
              RAD(NP)=RMT
            ENDIF
            RC1=RMT
            CALL FINDI(R,RC1,NPOT,J)
            V1=SA(J)+RC1*(SB(J)+RC1*(SC(J)+RC1*SD(J)))
            DEN1=DENA(J)+RC1*(DENB(J)+RC1*(DENC(J)+RC1*DEND(J)))
            RV(NP)=2.0D0*V1
            DEN(NP)=2.0D0*DEN1
            RVST(NP)=RV(NP)/DBLE(IELEC)
            GO TO 1
          ELSE
            RAD(I)=R(I)
C
            RC1=R(I)
            FD1=FOURPI*RC1**2
            V1=RV(I)
            DEN1=DEN(I)
C
            RC2=2.0D0*RMT-R(I)
            FD2=FOURPI*RC2**2
            CALL FINDI(R,RC2,NPOT,J)
            V2=SA(J)+RC2*(SB(J)+RC2*(SC(J)+RC2*SD(J)))
            DEN2=DENA(J)+RC2*(DENB(J)+RC2*(DENC(J)+RC2*DEND(J)))
C
            IF(I.GT.1) THEN
              RV(I)=V1+RC1*(V2/RC2)
              DEN(I)=DEN1+FD1*(DEN2/FD2)
            ELSE
              RV(I)=V1
              DEN(I)=DEN1
            ENDIF
          ENDIF
          RVST(I)=RV(I)/DBLE(IELEC)
        ENDDO
        NP=NPOT
    1   CONTINUE
C
C  ****  Ensure proper normalization of the muffin-tin electron density.
C
        SUM=RMOM(RAD,DEN,NP,0)
        RHOU=(NELEC-SUM)/(FOURPI*RMT**3/3.0D0)
        DO I=1,NP
          DEN(I)=DEN(I)+RHOU*FOURPI*RAD(I)**2
        ENDDO
        RHORMT=RHORMT+RHOU
        SUM=RMOM(RAD,DEN,NP,0)
        WRITE(6,*) 'Electron density normalization =',SUM
C
        NMT=NP
        E=E-RV(NMT)/RAD(NMT)
        DO I=2,NMT
          RV(I)=RV(I)-RV(NMT)*RAD(I)/RAD(NMT)
          RVST(I)=RVST(I)-RVST(NMT)*RAD(I)/RAD(NMT)
        ENDDO
        IF(NP.LT.NPOT) THEN
          NP=NP+1
          DO I=NP,NPOT
            IF(I.EQ.NP) RAD(I)=RAD(I-1)
            RV(I)=0.0D0
            RVST(I)=0.0D0
            DEN(I)=0.0D0
          ENDDO
        ENDIF
      ELSE
        NP=NPOT
        DO I=1,NPOT
          RAD(I)=R(I)
        ENDDO
      ENDIF
C
C  ************  Exchange correction for electrons.
C
      IF(IELEC.EQ.-1.AND.MEXCH.NE.0) THEN
        IF(MEXCH.EQ.1) THEN
C  ****  Furness-McCarthy exchange potential.
          WRITE(IW,1500)
 1500     FORMAT(1X,'#',/1X,'# Furness-McCarthy exchange',
     1      ' potential')
          DO I=2,NP
            AUX=RAD(I)*E*(1.0D0+EV/TREV)+RVST(I)
            AUX2=AUX*AUX
            IF(DEN(I).GT.1.0D-5*AUX2) THEN
              RVEX(I)=0.5D0*(AUX-SQRT(AUX2+DEN(I)))
            ELSE
              T=DEN(I)/AUX2
              RVEX(I)=-0.5D0*AUX*T*(0.5D0-T*(0.125D0-T*0.065D0))
            ENDIF
            RV(I)=RV(I)+RVEX(I)
          ENDDO
        ELSE IF(MEXCH.EQ.2) THEN
C  ****  Thomas-Fermi exchange potential.
          WRITE(IW,1400)
 1400     FORMAT(1X,'#',/1X,'# Thomas-Fermi exchange potential')
          DO I=1,NP
            RHO=DEN(MAX(2,I))/(FOURPI*RAD(MAX(2,I))**2)
            SKF=(3.0D0*PI*PI*RHO)**3.333333333333333D-1
            EF=0.5D0*SKF*SKF
            SKL=SQRT(2.0D0*(E*(1.0D0+EV/TREV)+EF))
            X=SKF/SKL
            IF(X.LT.0.001D0) THEN
              FX=(2.0D0/3.0D0)*X**3
            ELSE
              FX=X-0.5D0*(1.0D0-X*X)*LOG(ABS((1.0D0+X)/(1.0D0-X)))
            ENDIF
            RVEX(I)=-(SKL/PI)*FX*RAD(I)
            RV(I)=RV(I)+RVEX(I)
          ENDDO
        ELSE IF(MEXCH.EQ.3) THEN
C  ****  Riley-Truhlar exchange potential.
          WRITE(IW,1501)
 1501     FORMAT(1X,'#',/1X,'# Riley-Truhlar exchange potential')
          DO I=1,NP
            AUX=4.0D0*(RAD(I)*E*(1.0D0+EV/TREV)+RVST(I))
            IF(AUX.GT.1.0D-16*DEN(I)) THEN
              RVEX(I)=-DEN(I)/AUX
              RV(I)=RV(I)+RVEX(I)
            ENDIF
          ENDDO
        ELSE
          WRITE(IW,*) 'ELSEPA: incorrect MEXCH value.'
          STOP 'ELSEPA: incorrect MEXCH value.'
        ENDIF
        IF(NMT.GT.1) THEN
          E=E-RV(NMT)/RAD(NMT)
          DO I=2,NMT
            RV(I)=RV(I)-RAD(I)*(RV(NMT)/RAD(NMT))
            RVEX(I)=RVEX(I)-RAD(I)*(RVEX(NMT)/RAD(NMT))
          ENDDO
        ENDIF
      ELSE
        DO I=1,NP
          RVEX(I)=0.0D0
        ENDDO
      ENDIF
C
C  ********  Absorption potential (local density approximation).
C
      IF(MABS.EQ.1.AND.VABSA.GT.1.0D-12.AND.EV.LE.1.0D6) THEN
        IAB=1
        WRITE(IW,1502) VABSD,VABSA
 1502   FORMAT(1X,'#',/1X,'# LDA absorption potential (only electr',
     1    'on-hole excitations):',/1X,'#',
     2    27X,'Delta =',1P,E12.5,' eV',/1X,'#',28X,'Aabs =',E12.5)
        DELTA=VABSD/HREV
        AABS=VABSA
C
        RADI(1)=RAD(1)
        RVI(1)=RV(1)
        RW(1)=0.0D0
        RVPOL(1)=0.0D0
        DO I=2,NP
          RADI(I)=RAD(I)
          RVI(I)=RV(I)
          RHO=DEN(I)/(FOURPI*RAD(I)**2)
          EKIN=E-RV(I)/RAD(I)
          IF(RHO.GT.1.0D-16.AND.EKIN.GT.DELTA) THEN
            VEL=SQRT(2.0D0*EKIN)
            EKEV=EKIN*HREV
            FREL=SQRT(2.0D0*(EKEV+REV)**2/(REV*(EKEV+2.0D0*REV)))
            CALL XSFEG(RHO,DELTA,IELEC,EKIN,0,XSEC,2)
            RW(I)=-0.5D0*VEL*RHO*XSEC*RAD(I)*AABS*FREL
          ELSE
            RW(I)=0.0D0
          ENDIF
          RVPOL(I)=0.0D0
          WRITE(6,1503) I,RADI(I),RW(I)
 1503     FORMAT(1X,'i=',I4,',   r=',1P,E12.5,',   r*Wabs= ',E12.5)
        ENDDO
        NPI=NP
      ELSE
        IAB=0
        DO I=1,NP
          RADI(I)=RAD(I)
          RVI(I)=RV(I)
          RW(I)=0.0D0
          RVPOL(I)=0.0D0
        ENDDO
        NPI=NP
      ENDIF
C
C  ****  We add a 'constant' tail to the potential to extend the grid
C  up to a point where irregular Coulomb functions can be be calculated.
C
      IF((MCPOL.NE.1.AND.MCPOL.NE.2).OR.EV.GT.1.0D4) THEN
        IF(NP.LT.NDIM-4) THEN
          IF(RAD(NP)-RAD(NP-1).LT.1.0D-16) THEN
            I=NP
            RAD(I)=RAD(I-1)
            RADI(I)=RADI(I-1)
          ELSE
            I=NP+1
            RAD(I)=RAD(I-1)
            RADI(I)=RADI(I-1)
            RV(I)=RV(I-1)
          ENDIF
          RV(I)=ZINF
          RVI(I)=RV(I)
          DEN(I)=0.0D0
          RVEX(I)=0.0D0
          RVPOL(I)=0.0D0
          RW(I)=0.0D0
          IST=I+1
          NADD=1
          DO I=IST,NDIM
            NADD=NADD+1
            RAD(I)=2.0D0*RAD(I-1)
            RADI(I)=2.0D0*RADI(I-1)
            RV(I)=ZINF
            RVI(I)=RV(I)
            DEN(I)=0.0D0
            RVEX(I)=0.0D0
            RVPOL(I)=0.0D0
            RW(I)=0.0D0
            NP=I
            NPI=I
            IF(RAD(I).GT.1.0D4.AND.NADD.GT.4) GO TO 2
          ENDDO
        ELSE
          WRITE (*,*) 'NP=',NP
          STOP 'Not enough memory space 1.'
        ENDIF
    2   CONTINUE
      ELSE IF(MCPOL.EQ.1) THEN
C
C  ************  Atomic polarizability correction.
C
C  ****  Buckingham empirical potential.
        WRITE(IW,1700) VPOLA,VPOLB
 1700   FORMAT(1X,'#',/1X,'# Correlation-polarization potential (Buc',
     1    'kingham):',/1X,'#',27X,'Alpha =',1P,E12.5,' cm**3',
     2     /1X,'#',28X,'Bpol =',E12.5)
        IF(VPOLB.LT.0.01D0) THEN
          WRITE(IW,*) 'ELSEPA: VPOLB cannot be less than 0.01.'
          STOP 'ELSEPA: VPOLB cannot be less than 0.01.'
        ENDIF
        ALPHA=VPOLA/A0B**3
        D2=SQRT(0.5D0*ALPHA*VPOLB**2/DBLE(IZ)**3.333333333333333D-1)
        NPOL=NP
        DO I=1,NPOL
          VPOL=-0.5D0*ALPHA/(RAD(I)**2+D2)**2
          RVPOL(I)=VPOL*RAD(I)
          RV(I)=RV(I)+RVPOL(I)
          RVI(I)=RV(I)
        ENDDO
        IF(NPOL.LT.NDIM-5) THEN
          DO I=NPOL+1,NDIM-5
            RAD(I)=1.25D0*RAD(I-1)
            RADI(I)=RAD(I)
            VPOL=-0.5D0*ALPHA/(RAD(I)**2+D2)**2
            RVPOL(I)=VPOL*RAD(I)
            RV(I)=ZINF+RVPOL(I)
            RVI(I)=RV(I)
            DEN(I)=0.0D0
            RVEX(I)=0.0D0
            RW(I)=0.0D0
            NP=I
            NPI=I
            IF(ABS(VPOL).LT.1.0D-6*MAX(E,1.0D1*ABS(ZINF)/RAD(I))
     1        .AND.RAD(I).GT.50.0D0) GO TO 3
          ENDDO
        ENDIF
        STOP 'Not enough memory space 2.'
    3   CONTINUE
        IF(NP.LT.NDIM-4) THEN
          I=NP+1
          RAD(I)=RAD(I-1)
          RADI(I)=RADI(I-1)
          RV(I)=ZINF
          RVI(I)=RV(I)
          DEN(I)=0.0D0
          RVEX(I)=0.0D0
          RW(I)=0.0D0
          RVPOL(I)=0.0D0
          DO I=NP+2,NDIM
            RAD(I)=2.0D0*RAD(I-1)
            RADI(I)=2.0D0*RADI(I-1)
            RV(I)=RV(I-1)
            RVI(I)=RV(I)
            DEN(I)=0.0D0
            RVEX(I)=0.0D0
            RW(I)=0.0D0
            RVPOL(I)=0.0D0
            NP=I
            NPI=I
            IF(RAD(I).GT.1.0D4) GO TO 33
          ENDDO
        ELSE
          STOP 'Not enough memory space 3.'
        ENDIF
   33   CONTINUE
C
      ELSE IF(MCPOL.EQ.2) THEN
C  ****  LDA correlation-polarization potential.
        WRITE(IW,1701) VPOLA,VPOLB
 1701   FORMAT(1X,'#',/1X,'# Correlation-polarization potential (LDA',
     1    '):',/1X,'#',27X,'Alpha =',1P,E12.5,' cm**3',
     2     /1X,'#',28X,'Bpol =',E12.5)
        IF(VPOLB.LT.0.01D0) THEN
          WRITE(IW,*) 'ELSEPA: VPOLB cannot be less than 0.01.'
          STOP 'ELSEPA: VPOLB cannot be less than 0.01.'
        ENDIF
        ALPHA=VPOLA/A0B**3
        D2=SQRT(0.5D0*ALPHA*VPOLB**2/DBLE(IZ)**3.333333333333333D-1)
        NPOL=NP
        IMODE=0
        IF(MUFIN.NE.1) THEN
          DO I=NPOL,1,-1
            RIP=RAD(MAX(2,I))
            RHO=DEN(MAX(2,I))/(FOURPI*RIP**2)
            VCO=VCPOL(IELEC,RHO)
            VPAS=-0.5D0*ALPHA/(RIP**2+D2)**2
            IF(IMODE.EQ.0) THEN
              VPOL=VPAS
              IF(VCO.LT.VPAS) IMODE=1
            ELSE
              VPOL=MAX(VCO,VPAS)
            ENDIF
            RVPOL(I)=VPOL*RAD(I)
            RV(I)=RV(I)+RVPOL(I)
            RVI(I)=RV(I)
          ENDDO
          IF(IMODE.EQ.0) THEN
            WRITE(IW,1702)
            WRITE(6,1702)
 1702       FORMAT(1X,'#',/1X,'# ERROR: The correlation and pol',
     1        'arization potentials do not cross.')
            STOP
          ENDIF
          VCOUT=-1.0D16
        ELSE
          DO I=1,NPOL
            RIP=RAD(MAX(2,I))
            RHO=DEN(MAX(2,I))/(FOURPI*RIP**2)
            IF(RHO.LT.1.0D-35) RHO=RHORMT
            VCO=VCPOL(IELEC,RHO)
            VPAS=-0.5D0*ALPHA/(RIP**2+D2)**2
            VPOL=MAX(VCO,VPAS)
            RVPOL(I)=VPOL*RAD(I)
            RV(I)=RV(I)+RVPOL(I)
            RVI(I)=RV(I)
          ENDDO
          VCOUT=MAX(VCPOL(IELEC,RHORMT),-0.5D0*ALPHA/(RMT**2+D2)**2)
        ENDIF
C
        IF(NPOL.LT.NDIM-5) THEN
          DO I=NPOL+1,NDIM-5
            IF(MUFIN.EQ.1.AND.IMODE.EQ.0) THEN
              RAD(I)=RAD(I-1)+0.05D0
            ELSE
              RAD(I)=1.25D0*RAD(I-1)
            ENDIF
            RADI(I)=RAD(I)
            VPOL=-0.5D0*ALPHA/(RAD(I)**2+D2)**2
            IF(IMODE.EQ.0) THEN
              IF(VPOL.GT.VCOUT) IMODE=1
              VPOL=MAX(VCOUT,VPOL)
            ENDIF
            RVPOL(I)=VPOL*RAD(I)
            RV(I)=ZINF+RVPOL(I)
            RVI(I)=RV(I)
            DEN(I)=0.0D0
            RVEX(I)=0.0D0
            RW(I)=0.0D0
            NP=I
            NPI=I
            IF(ABS(VPOL).LT.1.0D-6*MAX(E,1.0D1*ABS(ZINF)/RAD(I))
     1        .AND.RAD(I).GT.50.0D0) GO TO 34
          ENDDO
        ENDIF
        STOP 'Not enough memory space 4.'
   34   CONTINUE
        IF(NP.LT.NDIM-4) THEN
          I=NP+1
          RAD(I)=RAD(I-1)
          RADI(I)=RADI(I-1)
          RV(I)=ZINF
          DEN(I)=0.0D0
          RVI(I)=RV(I)
          RVEX(I)=0.0D0
          RW(I)=0.0D0
          RVPOL(I)=0.0D0
          DO I=NP+2,NDIM
            RAD(I)=2.0D0*RAD(I-1)
            RADI(I)=2.0D0*RADI(I-1)
            RV(I)=RV(I-1)
            RVI(I)=RV(I)
            DEN(I)=0.0D0
            RVEX(I)=0.0D0
            RW(I)=0.0D0
            RVPOL(I)=0.0D0
            NP=I
            NPI=I
            IF(RAD(I).GT.1.0D4) GO TO 35
          ENDDO
        ELSE
          STOP 'Not enough memory space 5.'
        ENDIF
   35   CONTINUE
      ENDIF
C
C  ****  At high energies, we compute the DCS for scattering by the bare
C  (finite) nucleus and multiply it by a pre-evaluated screening factor.
C  R1/10.0D0
  100 CONTINUE
      IF(IHEF0.EQ.1) THEN
        IAB=0
        WRITE(IW,1800)
 1800   FORMAT(1X,'#',/1X,'# WARNING: High-energy factorization',
     1    ' with free-atom DF screening.',/1X,'#',
     2    10X,'Absorption, polarization and exchange corrections are',
     3    /1X,'#',10X,'switched off.',/1X,'#',10X,
     4    'Phase shifts are calculated for the bare nucleus.'/1X,'#',
     5    10X,'Scattering amplitudes are not evaluated.')
C  ****  Read screening function from data files.
        JT=IZ
        J1=JT-10*(JT/10)
        JT=(JT-J1)/10
        J2=JT-10*(JT/10)
        JT=(JT-J2)/10
        J3=JT-10*(JT/10)
        LIT1=LIT10(J1+1)
        LIT2=LIT10(J2+1)
        LIT3=LIT10(J3+1)
        SCFILE='z_'//LIT3//LIT2//LIT1//'.dfs'
        OPEN(UNIT=99,FILE=SCFILE,STATUS='OLD',ERR=4)
        READ(99,'(1X,A1)') NULL
        READ(99,'(1X,A1)') NULL
        READ(99,'(1X,A1)') NULL
        NQS=0
        DO I=1,NGT
          READ(99,*,END=4) Q2T(I),FQ(I)
          NQS=I
        ENDDO
    4   CONTINUE
        CLOSE(UNIT=99)
        IF(NQS.EQ.0) THEN
          WRITE(6,*) 'ELSEPA: I/O error. SCFILE does not exist.'
          GO TO 5
        ENDIF
C        (The number of atomic electrons is set to zero)
        CALL EFIELD(DENN,IZ,NELEC,0,MNUCL,MODF,MELEC,IW,WKSK,ISOT)        
        DO I=1,NPOT
          RAD(I)=R(I)
          RV(I)=DFLOAT(IELEC)*RVN(I)
        ENDDO
        RV(NPOT)=DFLOAT(IELEC)*DFLOAT(IZ)
        NP=NPOT
C  ****  A constant tail is appended to the potential table...
        IF(NP.LT.NDIM-4) THEN
          I=NP+1
          RAD(I)=RAD(I-1)
          RV(I)=RV(I-1)
          DO I=NP+2,NDIM
            RAD(I)=2.0D0*RAD(I-1)
            RV(I)=RV(I-1)
            NP=I
            IF(RAD(I).GT.1.0D4) GO TO 5
          ENDDO
        ELSE
          STOP 'Not enough memory space 6'
        ENDIF
      ENDIF
    5 CONTINUE
C
      IF(IWR.GT.0) THEN
        OPEN(99,FILE='scfield.dat')
        WRITE(99,3001)
 3001   FORMAT(1X,'#  Scattering field.',/1X,'#  All quantities in',
     1    ' atomic units (a.u.), unless otherwise indicated.')
        IF(IELEC.EQ.-1) THEN
          WRITE(99,3002) IZ,NELEC
 3002     FORMAT(1X,'#  Z =',I4,', NELEC =',I4,
     1      ',   projectile: electron')
        ELSE
          WRITE(99,3003) IZ,NELEC
 3003     FORMAT(1X,'#  Z =',I4,', NELEC =',I4,
     1      ',   projectile: positron')
        ENDIF
        WRITE(99,3004) EV/HREV,EV
 3004   FORMAT(1X,'#  Kinetic energy =',1P,E12.5,' a.u. =',
     1      E12.5,' eV',/1X,'#')
        IF(NMT.GT.0) THEN
          WRITE(99,3005) NMT,RAD(NMT)
 3005     FORMAT(1X,'#  Muffin-tin radius = RAD(',I3,') =',
     1       1P,E12.5,' a.u.')
          WRITE(99,3006) EV/HREV-E,(EV/HREV-E)*HREV
 3006     FORMAT(1X,'#  Zero-energy shift = ',1P,E12.5,
     1       ' a.u. = ',E12.5,' eV')
          WRITE(99,3007) E,E*HREV
 3007     FORMAT(1X,'#  Effective kinetic energy =',1P,E12.5,
     1       ' a.u. =',E12.5,' eV',/1X,'#')
        ENDIF
        WRITE(99,3008)
 3008   FORMAT(1X,'#',3X,'i',7X,'r',11X,'r*V',9X,'r*Vst',8X,'r*Vex',7X,
     1        'r*Vpol',7X,'r*Wabs',8X,'rho_e',/1X,'#',96('-'))
        DO I=1,NP
          RHO=DEN(MAX(2,I))/(FOURPI*RAD(MAX(2,I))**2)
          WRITE(99,'(2X,I4,1P,7E13.5)') I,RAD(I),RV(I),
     1      IELEC*RVST(I),RVEX(I),RVPOL(I),RW(I),RHO
        ENDDO
        CLOSE(99)
      ENDIF
C
C  ************  Partial-wave analysis.
C
      NDELTA=25000
      IF(IAB.EQ.0) THEN
        IF(IHEF0.EQ.1) THEN
          CALL DPWA0(EV,NDELTA,1)
        ELSE
          IF(EV.LT.1.001D3) THEN
            ISCH=1
          ELSE
            ISCH=2
          ENDIF
          IF(MCPOL.GT.0) ISCH=1
          CALL DPWA0(EV,NDELTA,ISCH)
        ENDIF
        TOTCS=ECS
        ABCS=0.0D0
      ELSE
        IF(EV.LT.1.001D3) THEN
          ISCH=1
        ELSE
          ISCH=2
        ENDIF
        IF(MCPOL.GT.0.OR.MUFIN.EQ.1) ISCH=1
        CALL DPWAI0(EV,TOTCS,ABCS,NDELTA,ISCH)
      ENDIF

C
C  ************  DCS table.
C
      IF(IHEF0.EQ.1) THEN
        NTABT=NTAB
        DO I=1,NTAB
C  ****  Screening correction and check for numerical artifacts.
          Q2=4.0D0*RK2*XT(I)
          IF(Q2.LE.Q2T(NQS)) THEN
            CALL FINDI(Q2T,Q2,NQS,J)
            F=FQ(J)+(FQ(J+1)-FQ(J))*(Q2-Q2T(J))/(Q2T(J+1)-Q2T(J))
          ELSE
            F=1.0D0
          ENDIF
          IF(TH(I).GT.1.0D0.AND.ERROR(I).LT.1.0D-2) THEN
            DCST(I)=DCST(I)*(Q2*F/(1.0D0+Q2))**2
          ELSE IF(TH(I).LE.10.0D0) THEN
            THRAD=TH(I)*PI/180.0D0
            RMR=DPWAC(THRAD)
            DCST(I)=RUTHC*F*F*RMR/(1.0D0+Q2)**2
            ERROR(I)=1.0D-5
          ELSE
            IF(ERROR(I).GT.1.0D-2) THEN
              NTABT=I-1
              GO TO 6
            ENDIF
          ENDIF
          SPOL(I)=0.0D0
        ENDDO
    6   CONTINUE
        IF(NTABT.LT.NTAB) THEN
          DO I=NTABT,NTAB
            DCST(I)=1.0D-45
            ERROR(I)=1.0D0
          ENDDO
        ENDIF
      ENDIF
C
C  ****  Small-angle DCS for ions.
C
      IMATCH=1
      IF(IZ.NE.NELEC) THEN
        DO I=126,NTAB
          IF(ERROR(I).LT.5.0D-4) THEN
            IMATCH=I
            GO TO 7
          ENDIF
        ENDDO
    7   CONTINUE
        WRITE(IW,2112) TH(IMATCH)
 2112   FORMAT(1X,'#',/1X,'# WARNING: Partial-wave scattering amplit',
     1    'udes and DCSs are calculated',/1X,'#',10X,
     2    'only for THETA .gt.',1P,E10.3,' deg')
      ENDIF
C
C  ****  Integrated cross sections.
C
      IF(DCST(1).LT.1.0D-35) WRITE(IW,2012) DMAX1(0.5D0,TH(IMATCH))
 2012 FORMAT(1X,'#',/1X,'# WARNING: DCSs are integrated only for',
     1  ' THETA .gt.',1P,E10.3,' deg')
      ECS0=FOURPI*RMOM(XT,DCST,NTAB,0)
      ECS1=FOURPI*RMOM(XT,DCST,NTAB,1)
      ECS2=FOURPI*RMOM(XT,DCST,NTAB,2)
      ECS=ECS0
      TCS1=2.0D0*ECS1
      TCS2=6.0D0*(ECS1-ECS2)
      WRITE(IW,2013) ECS,ECS/A0B2
 2013 FORMAT(1X,'#',/1X,'# Total elastic cross section =',1P,
     1     E12.5,' cm**2 =',E12.5,' a0**2')
      WRITE(IW,2014) TCS1,TCS1/A0B2
 2014 FORMAT(1X,'# 1st transport cross section =',1P,
     1     E12.5,' cm**2 =',E12.5,' a0**2')
      WRITE(IW,2015) TCS2,TCS2/A0B2
 2015 FORMAT(1X,'# 2nd transport cross section =',1P,
     1     E12.5,' cm**2 =',E12.5,' a0**2',/1X,'#')
      IF(IAB.EQ.1.AND.IZ.EQ.NELEC) THEN
        WRITE(IW,2016) ABCS,ABCS/A0B2
 2016   FORMAT(1X,'#    Absorption cross section =',1P,
     1     E12.5,' cm**2 =',E12.5,' a0**2')
        WRITE(IW,2017) TOTCS,TOTCS/A0B2
 2017   FORMAT(1X,'#   Grand total cross section =',1P,
     1     E12.5,' cm**2 =',E12.5,' a0**2',/1X,'#')
      ENDIF
C
      ECUT=MAX(20.0D3*IZ,2.0D6)
      WRITE(IW,'(1X,''#'')')
      WRITE(IW,'(1X,''# Differential cross section:'',23X,
     1  ''MU=(1-COS(THETA))/2'')')
      WRITE(IW,'(1X,''#'',/1X,''#  THETACM'',8X,''THETALAB'',16X,''DCSCM'',
     1  16X,''DCSLAB'',16X,''Sherman'',16X,''error''/1X,''#  (deg)'',
     2  10X,''(deg)'',16X,''(cm**2/sr)'',12X,''(cm**2/sr)'',12X,''function'',
     3  /1X,''#'',70(''-''))')
C     
C   Convert centre of mass angles and cross sections to lab frame
C        
      DO I=1,NTAB
        THRAD=TH(I)*PI/180.0D0
        QSQ=1.0D0/(2.0D0*SINV)*(SINV-TARGMASS**2)**2*(1.0D0-COS(THRAD))
        THETALABRAD=2.0D0*ASIN(1.0D0/SQRT(4.0D0*EVLAB**2/QSQ-2.0D0*EVLAB/TARGMASS))
        THLAB(I)=THETALABRAD/PI*180.0D0
        
        GAMMACL=(TARGMASS+EVLAB)/SQRT(SINV)
        ALPHAJC=EVLAB/(TARGMASS+EVLAB)
        DCSTLAB(I)=((GAMMACL**2*(ALPHAJC+COS(THRAD))**2+SIN(THRAD)**2)**(1.5D0))/(GAMMACL*ABS(1.0D0+ALPHAJC*COS(THRAD)))*DCST(I)
      ENDDO
C
      DO I=1,NTAB
        WRITE(IW,2018) TH(I),THLAB(I),DCST(I),DCSTLAB(I),SPOL(I),ERROR(I)
      ENDDO
 2018 FORMAT(1X,1P,E16.8,E16.8,E22.14,E22.14,3E22.14,E9.1)
C
C   Sensitivity plots output
C
      FMT = '(I3.3)'
      !Nuclear models test
      IF (MODF.NE.0) THEN
        WRITE (FMTX,FMT) MODF !FMTX is first digits of model number            
        IF (PV.EQ.1) THEN
            FILENAME='nuclmodel_'//TRIM(FMTX)//'+.dat'
        ELSE IF (PV.EQ.-1) THEN
            FILENAME='nuclmodel_'//TRIM(FMTX)//'-.dat'
        ELSE
            GO TO 4018
        END IF            
        OPEN(61,FILE=FILENAME,ACTION='WRITE',POSITION='APPEND')
      ELSE
        GO TO 4018
      ENDIF

      DO I=1, SIZE(INDX)
        J=INDX(I)
        !IF (MODF.EQ.0) THEN
        !    WRITE(61,3018) PV,THLAB(J),DCSTLAB(J),RC2/RC1,WKSKF,WKSK        
        !ELSE
            WRITE(61,3018) PV,THLAB(J),DCSTLAB(J),WKSK
        !ENDIF    
      END DO
 3018 FORMAT(1X,1P,E16.8,E16.8,4E22.14,E9.1)
      CLOSE (61)
 4018 CONTINUE
C     
C  ****  Scattering amplitudes.
C
      IF(IWR.GT.1) THEN
        OPEN(99,FILE='scatamp.dat')
        WRITE(99,'(1X,''#  Scattering amplitudes (in cm)'',
     1    6X,''MU=(1-cos(TH))/2'')')
        IF(IELEC.EQ.-1) THEN
          WRITE(99,3010) IZ
 3010     FORMAT(1X,'#  Z =',I4,',   projectile: electron')
        ELSE
          WRITE(99,3011) IZ
 3011     FORMAT(1X,'#  Z =',I4,',   projectile: positron')
        ENDIF
        WRITE(99,3012) EV
 3012   FORMAT(1X,'#  Kinetic energy =',1P,E12.5,' eV',/1X,'#')
        WRITE(99,'(1X,''# TH (deg)'',6X,''MU'',10X,''Re(F)'',8X,
     1    ''Im(F)'',8X,''Re(G)'',8X,''Im(G)'',/1X,''#'',
     2    74(''-''))')
        IF(IHEF0.NE.0) RETURN
        DO I=1,NTAB
          THRAD=TH(I)*PI/180.0D0
          IF(EV.LT.ECUT.OR.IHEF0.EQ.0) THEN
            CALL DPWA(THRAD,CF,CG,DCS,SPL,ERRF,ERRG)
          ELSE
            CF=0.0D0
            CG=0.0D0
          ENDIF
          WRITE(99,3013) THLAB(I),XT(I),CF,CG
        ENDDO
 3013   FORMAT(1X,1P,E16.8,E16.8,4E13.5)
        CLOSE(99)
      ENDIF
C
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE EFIELD
C  *********************************************************************
      SUBROUTINE EFIELD(DENN,IZ,NELEC,N,MNUCL,MODF,MELEC,IW,WKSK,ISOT)
C
C     Electrostatic field of atoms and ions.
C
C  Input parameters:
C     IZ ....... atomic number (INTEGER).
C     NELEC .... number of electrons (INTEGER, .LE.IZ).
C     N ........ number of electrons used to determine the scattering
C                amplitudes (when the high energy factorization is used,
C                N is set equal to zero).
C     MNUCL .... nuclear density model (INTEGER).
C                 1 --> point nucleus,
C                 2 --> uniform distribution,
C                 3 --> Fermi distribution,
C                 4 --> Helm's uniform-uniform distribution.
C     MELEC .... electron density model (INTEGER).
C                 1 --> TFM analytical density,
C                 2 --> TFD analytical density,
C                 3 --> DHFS analytical density,
C                 4 --> DF density from pre-evaluated files,
C                 5 --> density read from file 'density.usr'.
C     IW ........ output unit (to be defined in the main program).
C     PV ........ parity related helicity constant (to be defined in the main program). !O.K.
C
C  Output (through common block /CFIELD/):
C     R(I) ..... radial grid points. R(1)=0.0D0.
C     RVN(I) ... nuclear potential times R.
C     DEN(I) ... radial electron density, i.e. the electron density
C                multiplied by 4*PI*R**2.
C     RVST(I) ... atomic electrostatic potential (nuclear+electronic)
C                times R.
C     NPOT ..... number of grid points where the potential function is
C                tabulated. For I.GT.NPOT, RVST(I) is set equal to
C                RVST(NPOT).
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      CHARACTER*1 LIT10(10),LIT1,LIT2,LIT3
      CHARACTER*12 ELFILE,NULL
      CHARACTER*2 LSYMBL(103)
C  ****  Set IWR=1 to print the electrostatic potential on a file.
      PARAMETER (IWR=0)
C
      PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
      PARAMETER (HREV=27.21138602D0)  ! Hartree energy (eV)
      PARAMETER (GEV2HART=1.0D9/HREV) ! Hartree energy (eV)
      PARAMETER (F2BOHR=1.0D-13/A0B) !1.889726D-5
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (ALPHAFS=1.D0/SL)    ! Fine-structure constant 
      PARAMETER (GF=1.1663787D-5/GEV2HART**2*SL**3)!Fermi Constant
      PARAMETER (A0B2=A0B*A0B)
      PARAMETER (PI=3.1415926535897932D0, FOURPI=4.0D0*PI)
      PARAMETER (SIN2THETA=0.23868D0)
C
      PARAMETER (NDIM=1000,NDIN=NDIM-4)
      DIMENSION DIFR(NDIM),DENN(NDIM),RVE(NDIM),ELAW(103),
     1          GAUSS(NDIM),GAUSSDENS(NDIM),
     2          FERMI(NDIM),FERMIDENS(NDIM),
     3          HELM(NDIM),HELMDENS(NDIM)
      COMMON/CFIELD/R(NDIM),RVN(NDIM),DEN(NDIM),RVST(NDIM),NPOT,
     1                      RVNW(NDIM)
      PARAMETER (NPPG=NDIM+1,NPTG=NDIM+NPPG)
      COMMON/STORE1/AUX(NPTG),A(NPTG),B(NPTG),C(NPTG),D(NPTG),
     1             AUXW(NPTG)
C
      DATA LIT10/'0','1','2','3','4','5','6','7','8','9'/
C
      DATA LSYMBL       /' H','He','Li','Be',' B',' C',' N',' O',
     1    ' F','Ne','Na','Mg','Al','Si',' P',' S','Cl','Ar',' K',
     2    'Ca','Sc','Ti',' V','Cr','Mn','Fe','Co','Ni','Cu','Zn',
     3    'Ga','Ge','As','Se','Br','Kr','Rb','Sr',' Y','Zr','Nb',
     4    'Mo','Tc','Ru','Rh','Pd','Ag','Cd','In','Sn','Sb','Te',
     5    ' I','Xe','Cs','Ba','La','Ce','Pr','Nd','Pm','Sm','Eu',
     6    'Gd','Tb','Dy','Ho','Er','Tm','Yb','Lu','Hf','Ta',' W',
     7    'Re','Os','Ir','Pt','Au','Hg','Tl','Pb','Bi','Po','At',
     8    'Rn','Fr','Ra','Ac','Th','Pa',' U','Np','Pu','Am','Cm',
     9    'Bk','Cf','Es','Fm','Md','No','Lr'/
      DATA ELAW     /1.007900D0,4.002600D0,6.941000D0,9.012200D0,
     1    1.081100D1,1.200000D1,1.400670D1,1.599940D1,1.899840D1,
     2    2.017970D1,2.298980D1,2.430500D1,2.698150D1,2.808550D1,
     3    3.097380D1,3.206600D1,3.545270D1,3.994800D1,3.909830D1,
     4    3.996259D1,4.495590D1,4.786700D1,5.094150D1,5.199610D1,
     5    5.493800D1,5.584500D1,5.893320D1,5.869340D1,6.354600D1,
     6    6.539000D1,6.972300D1,7.261000D1,7.492160D1,7.896000D1,
     7    7.990400D1,8.380000D1,8.546780D1,8.762000D1,8.890590D1,
     8    9.122400D1,9.290640D1,9.594000D1,9.890630D1,1.010700D2,
     9    1.029055D2,1.064200D2,1.078682D2,1.124110D2,1.148180D2,
     1    1.187100D2,1.217600D2,1.276000D2,1.269045D2,1.312900D2,
     1    1.329054D2,1.373270D2,1.389055D2,1.401160D2,1.409076D2,
     2    1.442400D2,1.449127D2,1.503600D2,1.519640D2,1.572500D2,
     3    1.589253D2,1.625000D2,1.649303D2,1.672600D2,1.689342D2,
     4    1.730400D2,1.749670D2,1.784900D2,1.809479D2,1.838400D2,
     5    1.862070D2,1.902300D2,1.922170D2,1.950780D2,1.969666D2,
     6    2.005900D2,2.043833D2,2.079767D2,2.089804D2,2.089824D2,
     7    2.099871D2,2.220176D2,2.230197D2,2.260254D2,2.270277D2,
     8    2.320381D2,2.310359D2,2.380289D2,2.370482D2,2.440642D2,
     9    2.430614D2,2.470000D2,2.470000D2,2.510000D2,2.520000D2,
     1    2.570000D2,2.580000D2,2.590000D2,2.620000D2/
C
      EXTERNAL BESJN
      
      IF(IZ.LE.0) STOP 'Negative atomic number'
      IF(IZ.GT.103) STOP 'Atomic number larger than 103'
      IF(IZ.EQ.20.AND.ISOT.EQ.1) THEN
        Z=DBLE(IZ)
        AW=4.79525229D1
      ELSE
        Z=DBLE(IZ)
        AW=ELAW(IZ)
      END IF
      IF(IZ.GT.0) THEN
        WRITE(IW,1001) LSYMBL(IZ),IZ,AW
 1001   FORMAT(1X,'# Element: ',A2,',  Z = ',I3,
     1    '  atomic weight =',1P,E12.5,' g/mol')
      ELSE
        WRITE(IW,'(1X,''#'',/1X,
     1    ''# Only polarization potential'')')
      ENDIF
C
C  ************  Nuclear electrostatic potential (times R).
C
      CALL GRIDCOEF(RMI,RMA)
      CALL SGRID(R,DIFR,RMI,RMA,0.5D0*DBLE(NDIN),NDIN)

      IF(MNUCL.EQ.1.OR.IZ.EQ.0) THEN
        WRITE(IW,1002)
 1002   FORMAT(1X,'#',/1X,'# Nuclear model: point charge')
        CALL SGRID(R,DIFR,1.0D-6,100.0D0,0.5D0*DBLE(NDIN),NDIN)
        DO I=1,NDIN
          RVN(I)=Z
          DENN(I)=0.0D0
        ENDDO
      ELSE IF (MNUCL.EQ.2) THEN
        !IF (MODF.NE.0) THEN !To test nuclear models
        !    CALL FERMI2PCOEFNUCL(C0,A0,RCWK1,AWK1,Z,ISOT,MODF)
        !    CALL FERMICALC(FERMI,FERMIDENS,RAD,RADT,Z,C0,A0,RMI,RMA,NDIN)
        !ELSE
            CALL FERMI2PCOEF(C0,A0,Z,ISOT)            
            CALL FERMICALC(FERMI,FERMIDENS,RAD,RADT,Z,C0,A0,RMI,RMA,NDIN)
        !ENDIF
        DO I=1,NDIN
            X=R(I)
            RVN(I)=FERMI(I)
            DENN(I)=FERMIDENS(I)
        ENDDO
      ELSE IF (MNUCL.EQ.3) THEN
        !IF (MODF.NE.0) THEN !To test nuclear models
        !    CALL FERMI2PCOEFNUCL(C0,A0,RCWK1,AWK1,Z,ISOT,MODF)
        !    CALL FERMICALC(FERMI,FERMIDENS,RAD,RADT,Z,C0,A0,RMI,RMA,NDIN)
        !ELSE
        !NEVER TESTED IT IN THIS FORM
        CALL HELMCOEF(C0,A0,DBLE(IZ),ISOT)            
        CALL HELMCALC(FERMI,FERMIDENS,RAD,RADT,Z,C0,A0,RMI,RMA,NDIN)
        !ENDIF        
        DO I=1,NDIN
            X=R(I)
            RVN(I)=HELM(I)
            DENN(I)=HELMDENS(I)
        ENDDO
      ELSE IF (MNUCL.EQ.4) THEN
        CALL GAUSSCALC(GAUSS,GAUSSDENS,RAD,RADT,Z,ISOT,RMI,RMA,NDIN)
        DO I=1,NDIN
            X=R(I)
            RVN(I)=GAUSS(I)
            DENN(I)=GAUSSDENS(I)
        ENDDO
      ENDIF
      
C
C  ************  Electronic potential (times R).
C
      WRITE(IW,1006) NELEC
 1006 FORMAT(1X,'#',/1X,'# Number of electrons =',I3)
      IF(N.LT.0) STOP 'Negative number of electrons'
      IF(N.GT.IZ) STOP 'Negative ion'
      IF(N.EQ.0) THEN
        DO I=1,NDIN
          DEN(I)=0.0D0
          RVE(I)=0.0D0
        ENDDO
        GO TO 2
      ENDIF
C
      IF(MELEC.LT.4.OR.MELEC.GT.5) THEN
C  ****  Analytical electron density models.
        IF(MELEC.EQ.1) THEN
          CALL TFM(IZ,A1,A2,A3,AL1,AL2,AL3)
          WRITE(IW,1007)
 1007     FORMAT(1X,'#',/1X,
     1      '# Electron density: analytical TFM model')
        ELSE IF(MELEC.EQ.2) THEN
          CALL TFD(IZ,A1,A2,A3,AL1,AL2,AL3)
          WRITE(IW,1008)
 1008     FORMAT(1X,'#',/1X,
     1      '# Electron density: analytical TFD model')
        ELSE
          CALL DHFS(IZ,A1,A2,A3,AL1,AL2,AL3)
          WRITE(IW,1009)
 1009     FORMAT(1X,'#',/1X,
     1      '# Electron density: analytical DHFS model')
        ENDIF
        WRITE(IW,1010) A1,AL1,A2,AL2,A3,AL3
 1010   FORMAT(1X,'#',19X,'A1 = ',1P,D12.5,' ,   ALPHA1 =',D12.5,
     1      /1X,'#',19X,'A2 = ',D12.5,' ,   ALPHA2 =',D12.5,
     2      /1X,'#',19X,'A3 = ',D12.5,' ,   ALPHA3 =',D12.5)
        XN=DBLE(N)
        DO I=1,NDIN
          DEN(I)=(A1*AL1*AL1*EXP(-AL1*R(I))
     1           +A2*AL2*AL2*EXP(-AL2*R(I))
     2           +A3*AL3*AL3*EXP(-AL3*R(I)))*XN
        ENDDO
      ELSE
C  ****  Electron density read from a file.
        NE=0
        IF(MELEC.EQ.4) THEN
          JT=IZ
          J1=JT-10*(JT/10)
          JT=(JT-J1)/10
          J2=JT-10*(JT/10)
          JT=(JT-J2)/10
          J3=JT-10*(JT/10)
          LIT1=LIT10(J1+1)
          LIT2=LIT10(J2+1)
          LIT3=LIT10(J3+1)
          ELFILE='z_'//LIT3//LIT2//LIT1//'.den'
        ELSE
          ELFILE='density.usr '
        ENDIF
C
        WRITE(IW,1011) ELFILE
 1011   FORMAT(1X,'#',/1X,'# Electron density: Read from file ',A12)
        OPEN(99,FILE=ELFILE,STATUS='OLD',ERR=1)
        READ(99,'(A12)') NULL
        READ(99,'(A12)') NULL
        READ(99,'(A12)') NULL
        DO I=1,NDIN
          READ(99,*,END=1) AUX(I),RVE(I)
          NE=I
          RVE(I)=LOG(RVE(I))
        ENDDO
        STOP 'EFIELD: File is too large.'
    1   CONTINUE
        IF(NE.EQ.0) STOP 'I/O error in EFIELD'
        CLOSE(99)
        WRITE(IW,1012) NE
 1012   FORMAT(1X,'#',19X,'Number of data points = ',I4)
        IF(NE.LT.4) STOP 'SPLINE needs more than 4 points'
C  ****  ... and interpolated (lin-log cubic spline).
        CALL SPLINE(AUX,RVE,A,B,C,D,0.0D0,0.0D0,NE)
        B(NE)=(RVE(NE)-RVE(NE-1))/(AUX(NE)-AUX(NE-1))
        A(NE)=RVE(NE-1)-B(NE)*AUX(NE-1)
        C(NE)=0.0D0
        D(NE)=0.0D0
        DO I=1,NDIN
          X=R(I)
          IF(X.GT.AUX(NE)) THEN
            DEN(I)=0.0D0
          ELSE
            CALL FINDI(AUX,X,NE,J)
            DEN(I)=EXP(A(J)+X*(B(J)+X*(C(J)+X*D(J))))*X*FOURPI
          ENDIF
        ENDDO
      ENDIF
C  ****  Calculation of the electrostatic potential.
      DO I=1,NDIN
        RVE(I)=DEN(I)*R(I)*DIFR(I)
      ENDDO
      CALL SLAG6(1.0D0,RVE,RVE,NDIN)
      NDIN1=NDIN+1
      DO I=1,NDIN
        K=NDIN1-I
        AUX(I)=DEN(K)*DIFR(K)
      ENDDO
      CALL SLAG6(1.0D0,AUX,AUX,NDIN)
      WRITE(IW,1013) RVE(NDIN)
 1013 FORMAT(1X,'#',19X,'Volume integral =',1P,E12.5)
      FNORM=DBLE(N)/RVE(NDIN)
      DO I=1,NDIN
        RVE(I)=FNORM*(RVE(I)+AUX(NDIN1-I)*R(I))
        DEN(I)=FNORM*DEN(I)*R(I)
      ENDDO
C
    2 CONTINUE
      ZINF=DBLE(IZ-N)
      DO I=1,NDIN
        RVST(I)=RVN(I)-RVE(I)
      ENDDO
      NPOT=NDIN
      DO I=NDIN,6,-1
        IF((ABS(RVST(I)-ZINF).LT.5.0D-12).
     1       AND.(ABS(DEN(I)).LT.5.0D-12)) THEN
          RVST(I)=ZINF
          NPOT=I
        ELSE
          GO TO 3
        ENDIF
      ENDDO
    3 CONTINUE
C
      IF(IWR.GT.0) THEN
        OPEN(99,FILE='esfield.dat')
        WRITE(99,'(1X,''#  Electrostatic field (a.u.)'')')
        WRITE(99,2001) LSYMBL(IZ),IZ,AW
 2001   FORMAT(1X,'#  Element: ',A2,',  Z = ',I3,
     1      '  atomic weight =',1P,E14.7,' g/mol')
        WRITE(99,2002) N
 2002 FORMAT(1X,'#  Number of electrons =',I3)
        WRITE(99,2003) MNUCL,MELEC
 2003 FORMAT(1X,'#  MNUCL =',I3,',   MELEC =',I3,/1X,'#')
        WRITE(99,2004)
 2004 FORMAT(1X,'#',3X,'I',7X,'R(I)',11X,'RHON(I)',9X,'RVN(I)',10X,
     1         'DEN(I)',10X,'RVST(I)',/1X,'#',84('-'))
        DO I=1,NPOT
         WRITE(99,'(2X,I4,1P,5E16.8)')
     1     I,R(I),DENN(I),RVN(I),DEN(I),RVST(I)
        ENDDO
        CLOSE(99)
      ENDIF
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE TFM
C  *********************************************************************
      SUBROUTINE TFM(IZ,A1,A2,A3,AL1,AL2,AL3)
C
C     Parameters in Moliere's analytical approximation (three Yukawa
C  terms) to the Thomas-Fermi field.
C     Ref.: G. Moliere, Z. Naturforsch. 2a (1947) 133.
C
      IMPLICIT REAL*8 (A-H,O-Z), INTEGER*4 (I-N)
      Z=DBLE(IZ)
      RTF=0.88534D0/Z**0.33333333333D0
      AL1=6.0D0/RTF
      AL2=1.2D0/RTF
      AL3=0.3D0/RTF
      A1=0.10D0
      A2=0.55D0
      A3=0.35D0
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE TFD
C  *********************************************************************
      SUBROUTINE TFD(IZ,A1,A2,A3,AL1,AL2,AL3)
C
C     Parameters in the analytical approximation (three Yukawa terms)
C  for the Thomas-Fermi-Dirac field.
C     Ref.: R.A. Bonham and T.G. Strand, J. Chem. Phys. 39 (1963) 2200.
C
      IMPLICIT REAL*8 (A-H,O-Z), INTEGER*4 (I-N)
      DIMENSION AA1(5),AA2(5),AA3(5),AAL1(5),AAL2(5),AAL3(5)
      DATA AA1/1.26671D-2,-2.61047D-2,2.14184D-2,-2.35686D-3,
     12.10672D-5/
      DATA AA2/5.80612D-2,2.93077D-2,8.57135D-2,-2.23342D-2,
     11.64675D-3/
      DATA AA3/9.27968D-1,-1.64643D-3,-1.07685D-1,2.47998D-2,
     1-1.67822D-3/
      DATA AAL1/1.64564D2,-1.52192D2,6.23879D1,-1.15005D1,
     18.08424D-1/
      DATA AAL2/1.13060D1,-6.31902D0,2.26025D0,-3.70738D-1,
     12.61151D-2/
      DATA AAL3/1.48219D0,-5.57601D-2,1.64387D-2,-4.39703D-3,
     19.97225D-4/
C
      IF(IZ.LE.0) THEN
        WRITE(6,100)
  100   FORMAT(5X,'*** TFD: Negative atomic number. STOP.')
        STOP 'TFD: Negative atomic number.'
      ENDIF
C
      X=LOG(DBLE(IZ))
      A1=AA1(1)+X*(AA1(2)+X*(AA1(3)+X*(AA1(4)+X*AA1(5))))
      A2=AA2(1)+X*(AA2(2)+X*(AA2(3)+X*(AA2(4)+X*AA2(5))))
      A3=AA3(1)+X*(AA3(2)+X*(AA3(3)+X*(AA3(4)+X*AA3(5))))
      AL1=AAL1(1)+X*(AAL1(2)+X*(AAL1(3)+X*(AAL1(4)+X*AAL1(5))))
      AL2=AAL2(1)+X*(AAL2(2)+X*(AAL2(3)+X*(AAL2(4)+X*AAL2(5))))
      AL3=AAL3(1)+X*(AAL3(2)+X*(AAL3(3)+X*(AAL3(4)+X*AAL3(5))))
      A3=1.0D0-A1-A2
C
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE DHFS
C  *********************************************************************
      SUBROUTINE DHFS(IZ,A1,A2,A3,AL1,AL2,AL3)
C
C     DHFS analytical screening function parameters for free neutral
C  atoms. The input argument is the atomic number.
C
C     Ref.: F. Salvat et al., Phys. Rev. A36 (1987) 467-474.
C     Elements from Z=93 to 103 added in march 1992.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      DIMENSION B1(103),B2(103),BL1(103),BL2(103),BL3(103)
      DATA B1/-7.05665D-6,-2.25920D-1,6.04537D-1,3.27766D-1,
     1   2.32684D-1,1.53676D-1,9.95750D-2,6.25130D-2,3.68040D-2,
     2   1.88410D-2,7.44440D-1,6.42349D-1,6.00152D-1,5.15971D-1,
     3   4.38675D-1,5.45871D-1,7.24889D-1,2.19124D+0,4.85607D-2,
     4   5.80017D-1,5.54340D-1,1.11950D-2,3.18350D-2,1.07503D-1,
     5   4.97556D-2,5.11841D-2,5.00039D-2,4.73509D-2,7.70967D-2,
     6   4.00041D-2,1.08344D-1,6.09767D-2,2.11561D-2,4.83575D-1,
     7   4.50364D-1,4.19036D-1,1.73438D-1,3.35694D-2,6.88939D-2,
     8   1.17552D-1,2.55689D-1,2.69313D-1,2.20138D-1,2.75057D-1,
     9   2.71053D-1,2.78363D-1,2.56210D-1,2.27100D-1,2.49215D-1,
     A   2.15313D-1,1.80560D-1,1.30772D-1,5.88293D-2,4.45145D-1,
     B   2.70796D-1,1.72814D-1,1.94726D-1,1.91338D-1,1.86776D-1,
     C   1.66461D-1,1.62350D-1,1.58016D-1,1.53759D-1,1.58729D-1,
     D   1.45327D-1,1.41260D-1,1.37360D-1,1.33614D-1,1.29853D-1,
     E   1.26659D-1,1.28806D-1,1.30256D-1,1.38420D-1,1.50030D-1,
     F   1.60803D-1,1.72164D-1,1.83411D-1,2.23043D-1,2.28909D-1,
     G   2.09753D-1,2.70821D-1,2.37958D-1,2.28771D-1,1.94059D-1,
     H   1.49995D-1,9.55262D-2,3.19155D-1,2.40406D-1,2.26579D-1,
     I   2.17619D-1,2.41294D-1,2.44758D-1,2.46231D-1,2.55572D-1,
     J   2.53567D-1,2.43832D-1,2.41898D-1,2.44050D-1,2.40237D-1,
     K   2.34997D-1,2.32114D-1,2.27937D-1,2.29571D-1/
      DATA B2/-1.84386D+2,1.22592D+0,3.95463D-1,6.72234D-1,
     1   7.67316D-1,8.46324D-1,9.00425D-1,9.37487D-1,9.63196D-1,
     2   9.81159D-1,2.55560D-1,3.57651D-1,3.99848D-1,4.84029D-1,
     3  5.61325D-1,-5.33329D-1,-7.54809D-1,-2.2852D0,7.75935D-1,
     4   4.19983D-1,4.45660D-1,6.83176D-1,6.75303D-1,7.16172D-1,
     5   6.86632D-1,6.99533D-1,7.14201D-1,7.29404D-1,7.95083D-1,
     6   7.59034D-1,7.48941D-1,7.15671D-1,6.70932D-1,5.16425D-1,
     7   5.49636D-1,5.80964D-1,7.25336D-1,7.81581D-1,7.20203D-1,
     8   6.58088D-1,5.82051D-1,5.75262D-1,5.61797D-1,5.94338D-1,
     9   6.11921D-1,6.06653D-1,6.50520D-1,6.15496D-1,6.43990D-1,
     A   6.11497D-1,5.76688D-1,5.50366D-1,5.48174D-1,5.54855D-1,
     B   6.52415D-1,6.84485D-1,6.38429D-1,6.46684D-1,6.55810D-1,
     C   7.05677D-1,7.13311D-1,7.20978D-1,7.28385D-1,7.02414D-1,
     D   7.42619D-1,7.49352D-1,7.55797D-1,7.61947D-1,7.68005D-1,
     E   7.73365D-1,7.52781D-1,7.32428D-1,7.09596D-1,6.87141D-1,
     F   6.65932D-1,6.46849D-1,6.30598D-1,6.17575D-1,6.11402D-1,
     G   6.00426D-1,6.42829D-1,6.30789D-1,6.21959D-1,6.10455D-1,
     H   6.03147D-1,6.05994D-1,6.23324D-1,6.56665D-1,6.42246D-1,
     I   6.24013D-1,6.30394D-1,6.29816D-1,6.31596D-1,6.49005D-1,
     J   6.53604D-1,6.43738D-1,6.48850D-1,6.70318D-1,6.76319D-1,
     K   6.65571D-1,6.88406D-1,6.94394D-1,6.82014D-1/
      DATA BL1/ 4.92969D+0,5.52725D+0,2.81741D+0,4.54302D+0,
     1   5.99006D+0,8.04043D+0,1.08122D+1,1.48233D+1,2.14001D+1,
     2   3.49994D+1,4.12050D+0,4.72663D+0,5.14051D+0,5.84918D+0,
     3   6.67070D+0,6.37029D+0,6.21183D+0,5.54701D+0,3.02597D+1,
     4   6.32184D+0,6.63280D+0,9.97569D+1,4.25330D+1,1.89587D+1,
     5   3.18642D+1,3.18251D+1,3.29153D+1,3.47580D+1,2.53264D+1,
     6   4.03429D+1,2.01922D+1,2.91996D+1,6.24873D+1,8.78242D+0,
     7   9.33480D+0,9.91420D+0,1.71659D+1,5.52077D+1,3.13659D+1,
     8   2.20537D+1,1.42403D+1,1.40442D+1,1.59176D+1,1.43137D+1,
     9   1.46537D+1,1.46455D+1,1.55878D+1,1.69141D+1,1.61552D+1,
     A   1.77931D+1,1.98751D+1,2.41540D+1,3.99955D+1,1.18053D+1,
     B   1.65915D+1,2.23966D+1,2.07637D+1,2.12350D+1,2.18033D+1,
     C   2.39492D+1,2.45984D+1,2.52966D+1,2.60169D+1,2.54973D+1,
     D   2.75466D+1,2.83460D+1,2.91604D+1,2.99904D+1,3.08345D+1,
     E   3.16806D+1,3.13526D+1,3.12166D+1,3.00767D+1,2.86302D+1,
     F   2.75684D+1,2.65861D+1,2.57339D+1,2.29939D+1,2.28644D+1,
     G   2.44080D+1,2.09409D+1,2.29872D+1,2.37917D+1,2.66951D+1,
     H   3.18397D+1,4.34890D+1,2.00150D+1,2.45012D+1,2.56843D+1,
     I   2.65542D+1,2.51930D+1,2.52522D+1,2.54271D+1,2.51526D+1,
     J   2.55959D+1,2.65567D+1,2.70360D+1,2.72673D+1,2.79152D+1,
     K   2.86446D+1,2.93353D+1,3.01040D+1,3.02650D+1/
      DATA BL2/ 2.00272D+0,2.39924D+0,6.62463D-1,9.85154D-1,
     1   1.21347D+0,1.49129D+0,1.76868D+0,2.04035D+0,2.30601D+0,
     2   2.56621D+0,8.71798D-1,1.00247D+0,1.01529D+0,1.17314D+0,
     3   1.34102D+0,2.55169D+0,3.38827D+0,4.56873D+0,3.12426D+0,
     4   1.00935D+0,1.10227D+0,4.12865D+0,3.94043D+0,3.06375D+0,
     5   3.78110D+0,3.77161D+0,3.79085D+0,3.82989D+0,3.39276D+0,
     6   3.94645D+0,3.47325D+0,4.12525D+0,4.95015D+0,1.69671D+0,
     7   1.79002D+0,1.88354D+0,3.11025D+0,4.28418D+0,4.24121D+0,
     8   4.03254D+0,2.97020D+0,2.86107D+0,3.36719D+0,2.73701D+0,
     9   2.71828D+0,2.61549D+0,2.74124D+0,3.08408D+0,2.88189D+0,
     A   3.29372D+0,3.80921D+0,4.61191D+0,5.91318D+0,1.79673D+0,
     B   2.69645D+0,3.45951D+0,3.46574D+0,3.48193D+0,3.50982D+0,
     C   3.51987D+0,3.55603D+0,3.59628D+0,3.63834D+0,3.73639D+0,
     D   3.72882D+0,3.77625D+0,3.82444D+0,3.87344D+0,3.92327D+0,
     E   3.97271D+0,4.09040D+0,4.20492D+0,4.24918D+0,4.24261D+0,
     F   4.23412D+0,4.19992D+0,4.14615D+0,3.73461D+0,3.69138D+0,
     G   3.96429D+0,3.24563D+0,3.62172D+0,3.77959D+0,4.25824D+0,
     H   4.92848D+0,5.85205D+0,2.90906D+0,3.55241D+0,3.79223D+0,
     I   4.00437D+0,3.67795D+0,3.63966D+0,3.61328D+0,3.43021D+0,
     J   3.43474D+0,3.59089D+0,3.59411D+0,3.48061D+0,3.50331D+0,
     K   3.61870D+0,3.55697D+0,3.58685D+0,3.64085D+0/
      DATA BL3/ 1.99732D+0,1.00000D+0,1.00000D+0,1.00000D+0,
     1   1.00000D+0,1.00000D+0,1.00000D+0,1.00000D+0,1.00000D+0,
     2   1.00000D+0,1.00000D+0,1.00000D+0,1.00000D+0,1.00000D+0,
     3   1.00000D+0,1.67534D+0,1.85964D+0,2.04455D+0,7.32637D-1,
     4   1.00000D+0,1.00000D+0,1.00896D+0,1.05333D+0,1.00137D+0,
     5   1.12787D+0,1.16064D+0,1.19152D+0,1.22089D+0,1.14261D+0,
     6   1.27594D+0,1.00643D+0,1.18447D+0,1.35819D+0,1.00000D+0,
     7   1.00000D+0,1.00000D+0,7.17673D-1,8.57842D-1,9.47152D-1,
     8   1.01806D+0,1.01699D+0,1.05906D+0,1.15477D+0,1.10923D+0,
     9   1.12336D+0,1.43183D+0,1.14079D+0,1.26189D+0,9.94156D-1,
     A   1.14781D+0,1.28288D+0,1.41954D+0,1.54707D+0,1.00000D+0,
     B   6.81361D-1,8.07311D-1,8.91057D-1,9.01112D-1,9.10636D-1,
     C   8.48620D-1,8.56929D-1,8.65025D-1,8.73083D-1,9.54998D-1,
     D   8.88981D-1,8.96917D-1,9.04803D-1,9.12768D-1,9.20306D-1,
     E   9.28838D-1,1.00717D+0,1.09456D+0,1.16966D+0,1.23403D+0,
     F   1.29699D+0,1.35350D+0,1.40374D+0,1.44284D+0,1.48856D+0,
     G   1.53432D+0,1.11214D+0,1.23735D+0,1.25338D+0,1.35772D+0,
     H   1.46828D+0,1.57359D+0,7.20714D-1,8.37599D-1,9.33468D-1,
     I   1.02385D+0,9.69895D-1,9.82474D-1,9.92527D-1,9.32751D-1,
     J   9.41671D-1,1.01827D+0,1.02554D+0,9.66447D-1,9.74347D-1,
     K   1.04137D+0,9.90568D-1,9.98878D-1,1.04473D+0/
C
      IIZ=IABS(IZ)
      IF(IIZ.GT.103) IIZ=103
      IF(IIZ.EQ.0) IIZ=1
      A1=B1(IIZ)
      A2=B2(IIZ)
      A3=1.0D0-(A1+A2)
      IF(ABS(A3).LT.1.0D-15) A3=0.0D0
      AL1=BL1(IIZ)
      AL2=BL2(IIZ)
      AL3=BL3(IIZ)
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE MOTTCS
C  *********************************************************************
      SUBROUTINE MOTTSC(IELEC,IZ,EV,IW)
C
C     Mott cross section for elastic scattering of high-energy electrons
C  and positrons by unscreened point nuclei.
C
C  Input parameters:
C    IELEC ..... electron-positron flag;
C                =-1 for electrons,
C                =+1 for positrons.
C    IZ ........ atomic number of the target atom.
C    EV ........ projectile's kinetic energy (in eV).
C    IW ........ output unit (to be defined in the main program).
C
C  The Mott DCS and spin polarization function are printed on unit IW.
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1   INTEGER*4 (I-N)
C
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
      PARAMETER (HREV=27.21138602D0)  ! Hartree energy (eV)
      PARAMETER (A0B2=A0B*A0B)
      PARAMETER (F2BOHR=1.0D-13/A0B)
      PARAMETER (PI=3.1415926535897932D0,FOURPI=4.0D0*PI)
C
      PARAMETER (NGT=650)
      COMMON/DCSTAB/ECS,TCS1,TCS2,TH(NGT),XT(NGT),DCST(NGT),DCSTLAB(NGT),SPOL(NGT),
     1              ERROR(NGT),NTAB,THLAB(NGT)
C
      PARAMETER (NPC=1500)
      COMMON/CRMORU/CFM(NPC),CGM(NPC),DPC(NPC),DMC(NPC),
     1              CF,CG,RUTHC,WATSC,RK2,ERRF,ERRG,NPC1
C
      WRITE(IW,1000)
 1000 FORMAT(1X,'#',/1X,'# Subroutine MOTTSC. Elastic scattering of ',
     1  'electrons and positrons',/1X,'#',20X,
     2  'by unscreened Coulomb fields')
      IF(IELEC.EQ.-1) THEN
        WRITE(IW,1100)
 1100   FORMAT(1X,'#',/1X,'# Projectile: electron')
      ELSE
        WRITE(IW,1200)
 1200   FORMAT(1X,'#',/1X,'# Projectile: positron')
      ENDIF
      E=EV/HREV
      WRITE(IW,1300) EV,E
 1300 FORMAT(1X,'# Kinetic energy =',1P,E12.5,' eV =',
     1       E12.5,' a.u.')
C
      WRITE(IW,'(1X,''#'',/1X,''#  ***  WARNING: Mott '',
     1  ''scattering (point unscreend nucleus).'')')
C
      IF(IZ.LE.0) STOP 'Negative atomic number.'
      WRITE(IW,1001) IZ
 1001 FORMAT(1X,'#',/1X,'# Z = ',I3)
C
      Z=DFLOAT(IZ*IELEC)
      CALL DPWAC0(Z,EV)
C
      TH(1)=0.0D0
      TH(2)=1.0D-4
      I=2
   10 CONTINUE
      I=I+1
      IF(TH(I-1).LT.0.9999D-3) THEN
        TH(I)=TH(I-1)+2.5D-5
      ELSE IF(TH(I-1).LT.0.9999D-2) THEN
        TH(I)=TH(I-1)+2.5D-4
      ELSE IF(TH(I-1).LT.0.9999D-1) THEN
        TH(I)=TH(I-1)+2.5D-3
      ELSE IF(TH(I-1).LT.0.9999D+0) THEN
        TH(I)=TH(I-1)+2.5D-2
      ELSE IF(TH(I-1).LT.0.9999D+1) THEN
        TH(I)=TH(I-1)+1.0D-1
      ELSE IF(TH(I-1).LT.2.4999D+1) THEN
        TH(I)=TH(I-1)+2.5D-1
      ELSE
        TH(I)=TH(I-1)+5.0D-1
      ENDIF
      IF(TH(I).LT.180.0D0) GO TO 10
      NTAB=I
C
      NTABT=NTAB
      DO I=1,NTAB
        THR=TH(I)*PI/180.0D0
        XT(I)=(1.0D0-COS(THR))/2.0D0
        IF(TH(I).GT.1.0D-5) THEN
          Q2=4.0D0*RK2*XT(I)
          RMR=DPWAC(THR)
          DCST(I)=RUTHC*RMR/Q2**2
C  ****  Spin polarization (Sherman) function.
          CF=CF*A0B
          CG=CG*A0B
          ACF=CDABS(CF)**2
          ACG=CDABS(CG)**2
          DCS=ACF+ACG
          IF(DCS.GT.1.0D-45) THEN
            ERR=2.0D0*(ACF*ERRF+ACG*ERRG)/DCS
          ELSE
            ERR=1.0D0
          ENDIF
          ERROR(I)=ERR
C
          CSPL1=DCMPLX(0.0D0,1.0D0)*CF*DCONJG(CG)
          CSPL2=DCMPLX(0.0D0,1.0D0)*CG*DCONJG(CF)
          TST=CDABS(CSPL1-CSPL2)/(CDABS(CSPL1)+1.0D-30)
          IF(TST.GT.1.0D-3.AND.ERROR(I).LT.1.0D-5) THEN
            SPOL(I)=(CSPL1-CSPL2)/DCS
          ELSE
            SPOL(I)=0.0D0
          ENDIF
        ELSE
          DCST(I)=1.0D-45
          SPOL(I)=0.0D0
          ERROR(I)=1.0D0
        ENDIF
      ENDDO
C
      WRITE(IW,'(1X,''#'')')
      WRITE(IW,'(1X,''# Differential cross section'',6X,
     1  ''MU=(1-COS(THETA))/2'')')
      WRITE(IW,'(1X,''#'',/1X,''#  THETA'',8X,''MU'',10X,''DCS'',
     1  10X,''DCS'',8X,''Sherman'',7X,''error''/1X,''#  (deg)'',
     2  17X,''(cm**2/sr)'',3X,''(a0**2/sr)'',4X,''function'',
     3  /1X,''#'',71(''-''))')
      DO I=1,NTAB
        WRITE(IW,2018) TH(I),XT(I),DCST(I),DCST(I)/A0B2,SPOL(I),ERROR(I)
      ENDDO
 2018 FORMAT(1X,1P,E10.3,E13.5,3E13.5,2X,E8.1)
C
      ECS=1.0D35
      TCS1=1.0D35
      TCS2=1.0D35
C
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE HEBORN
C  *********************************************************************
      SUBROUTINE HEBORN(IELEC,IZ,MNUCL,EV,IW)
C
C     Mott-Born cross section for elastic scattering of high-energy
C  electrons and positrons by neutral atoms.
C
C    The DCS is obtained as the product of the Mott DCS for a point
C  nucleus, the Helm uniform-uniform nuclear form factor (with an
C  empirical Coulomb correction) and the high-energy DF screening
C  factor.
C
C  Input parameters:
C    IELEC ..... electron-positron flag;
C                =-1 for electrons,
C                =+1 for positrons.
C    IZ ........ atomic number of the target atom.
C    MNUCL ..... nuclear charge density model.
C                  1 --> point nucleus (P),
C                  2 --> uniform distribution (U),
C                3,4 --> Helm's uniform-uniform distribution (Uu).
C    EV ........ projectile's kinetic energy (in eV).
C    IW ........ output unit (to be defined in the main program).
C
C  Output (through the common block /DCSTAB/):
C     ECS ........ total cross section (cm**2).
C     TCS1 ....... 1st transport cross section (cm**2).
C     TCS2 ....... 2nd transport cross section (cm**2).
C     TH(I) ...... scattering angles (in deg)
C     XT(I) ...... values of (1-COS(TH(I)))/2.
C     DCST(I) .... differential cross section per unit solid angle at
C                  TH(I) (in cm**2/sr).
C     ERROR(I) ... relative uncertainty of the computed DCS values.
C                  Estimated from the convergence of the series.
C     NTAB ....... number of angles in the table.
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1   INTEGER*4 (I-N)
C
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
      PARAMETER (HREV=27.21138602D0)  ! Hartree energy (eV)
      PARAMETER (A0B2=A0B*A0B)
      PARAMETER (F2BOHR=1.0D-13/A0B)
      PARAMETER (PI=3.1415926535897932D0,FOURPI=4.0D0*PI)
C
      PARAMETER (NGT=650)
      COMMON/DCSTAB/ECS,TCS1,TCS2,TH(NGT),XT(NGT),DCST(NGT),DCSTLAB(NGT),SPOL(NGT),
     1              ERROR(NGT),NTAB,THLAB(NGT)
      COMMON/CTOTCS/TOTCS,ABCS
      COMMON/CDCSHE/Q2T(NGT),FQ(NGT),U1,U2,NQS,MOM
C
      DIMENSION ELAW(103)
C
      PARAMETER (NPC=1500)
      COMMON/CRMORU/CFM(NPC),CGM(NPC),DPC(NPC),DMC(NPC),
     1              CF,CG,RUTHC,WATSC,RK2,ERRF,ERRG,NPC1
C
      CHARACTER*12 SCFILE,NULL
      CHARACTER*1 LIT10(10),LIT1,LIT2,LIT3
      CHARACTER*2 LSYMBL(103)
      DATA LIT10/'0','1','2','3','4','5','6','7','8','9'/
C
      DATA LSYMBL       /' H','He','Li','Be',' B',' C',' N',' O',
     1    ' F','Ne','Na','Mg','Al','Si',' P',' S','Cl','Ar',' K',
     2    'Ca','Sc','Ti',' V','Cr','Mn','Fe','Co','Ni','Cu','Zn',
     3    'Ga','Ge','As','Se','Br','Kr','Rb','Sr',' Y','Zr','Nb',
     4    'Mo','Tc','Ru','Rh','Pd','Ag','Cd','In','Sn','Sb','Te',
     5    ' I','Xe','Cs','Ba','La','Ce','Pr','Nd','Pm','Sm','Eu',
     6    'Gd','Tb','Dy','Ho','Er','Tm','Yb','Lu','Hf','Ta',' W',
     7    'Re','Os','Ir','Pt','Au','Hg','Tl','Pb','Bi','Po','At',
     8    'Rn','Fr','Ra','Ac','Th','Pa',' U','Np','Pu','Am','Cm',
     9    'Bk','Cf','Es','Fm','Md','No','Lr'/
C
      DATA ELAW     /1.007900D0,4.002600D0,6.941000D0,9.012200D0,
     1    1.081100D1,1.201070D1,1.400670D1,1.599940D1,1.899840D1,
     2    2.017970D1,2.298980D1,2.430500D1,2.698150D1,2.808550D1,
     3    3.097380D1,3.206600D1,3.545270D1,3.994800D1,3.909830D1,
     4    4.007800D1,4.495590D1,4.786700D1,5.094150D1,5.199610D1,
     5    5.493800D1,5.584500D1,5.893320D1,5.869340D1,6.354600D1,
     6    6.539000D1,6.972300D1,7.261000D1,7.492160D1,7.896000D1,
     7    7.990400D1,8.380000D1,8.546780D1,8.762000D1,8.890590D1,
     8    9.122400D1,9.290640D1,9.594000D1,9.890630D1,1.010700D2,
     9    1.029055D2,1.064200D2,1.078682D2,1.124110D2,1.148180D2,
     1    1.187100D2,1.217600D2,1.276000D2,1.269045D2,1.312900D2,
     1    1.329054D2,1.373270D2,1.389055D2,1.401160D2,1.409076D2,
     2    1.442400D2,1.449127D2,1.503600D2,1.519640D2,1.572500D2,
     3    1.589253D2,1.625000D2,1.649303D2,1.672600D2,1.689342D2,
     4    1.730400D2,1.749670D2,1.784900D2,1.809479D2,1.838400D2,
     5    1.862070D2,1.902300D2,1.922170D2,1.950780D2,1.969666D2,
     6    2.005900D2,2.043833D2,2.072000D2,2.089804D2,2.089824D2,
     7    2.099871D2,2.220176D2,2.230197D2,2.260254D2,2.270277D2,
     8    2.320381D2,2.310359D2,2.380289D2,2.370482D2,2.440642D2,
     9    2.430614D2,2.470000D2,2.470000D2,2.510000D2,2.520000D2,
     1    2.570000D2,2.580000D2,2.590000D2,2.620000D2/
C
      EXTERNAL DCSHB
C
      WRITE(IW,1000)
 1000 FORMAT(1X,'#',/1X,'# Subroutine HEBORN. Elastic scattering of ',
     1  'electrons and positrons',/1X,'#',20X,
     2  'by neutral atoms')
      IF(IELEC.EQ.-1) THEN
        WRITE(IW,1100)
 1100   FORMAT(1X,'#',/1X,'# Projectile: electron')
      ELSE
        WRITE(IW,1200)
 1200   FORMAT(1X,'#',/1X,'# Projectile: positron')
      ENDIF
      E=EV/HREV
      WRITE(IW,1300) EV,E
 1300 FORMAT(1X,'# Kinetic energy =',1P,E12.5,' eV =',
     1       E12.5,' a.u.')
C
      WRITE(IW,'(1X,''#'',/1X,''#  ***  WARNING: High-energy '',
     1  ''Mott-Born approximation. Neutral atom.'')')
C
      IF(IZ.LE.0) STOP 'Negative atomic number.'
      IF(IZ.GT.103) STOP 'Atomic number larger than 103.'
      AW=ELAW(IZ)
      WRITE(IW,1001) LSYMBL(IZ),IZ,AW
 1001 FORMAT(1X,'#',/1X,'# Element: ',A2,',  Z = ',I3,
     1  '  atomic weight =',1P,E12.5,' g/mol')
C
      Z=DFLOAT(IZ*IELEC)
      CALL DPWAC0(Z,EV)
C
C  ****  Read screening function from data files.
      JT=IZ
      J1=JT-10*(JT/10)
      JT=(JT-J1)/10
      J2=JT-10*(JT/10)
      JT=(JT-J2)/10
      J3=JT-10*(JT/10)
      LIT1=LIT10(J1+1)
      LIT2=LIT10(J2+1)
      LIT3=LIT10(J3+1)
      SCFILE='z_'//LIT3//LIT2//LIT1//'.dfs'
      OPEN(UNIT=99,FILE=SCFILE,STATUS='OLD',ERR=4)
      READ(99,'(1X,A1)') NULL
      READ(99,'(1X,A1)') NULL
      READ(99,'(1X,A1)') NULL
      NQS=0
      DO I=1,NGT
        READ(99,*,END=4) Q2T(I),FQ(I)
        NQS=I
      ENDDO
    4 CONTINUE
      CLOSE(UNIT=99)
      IF(NQS.EQ.0) THEN
        WRITE(6,*) 'ELSEPA: I/O error. SCFILE does not exist.'
        WRITE(IW,*) 'ELSEPA: I/O error. SCFILE does not exist.'
        RETURN
      ENDIF
C
C  ****  Nuclear charge density parameters.
C
      IF(MNUCL.EQ.1) THEN
C  ****  Point nucleus.
        WRITE(IW,1002)
 1002   FORMAT(1X,'#',/1X,'# Nuclear model: point charge')
        U1=0.0D0
        U2=0.0D0
      ELSE IF (MNUCL.EQ.2) THEN
C  ****  Uniform distribution..
        R1=1.07D0*F2BOHR*AW**0.3333333333333333D0
        R2=2.00D0*F2BOHR
        R1=R1*DSQRT((1.0D0+2.5D0*(R2/R1)**2)
     1             /(1.0D0+0.75D0*(R2/R1)**2))
        WRITE(IW,1004) R1*A0B
 1004   FORMAT(1X,'#',/1X,'# Nuclear model: uniform spherical d',
     1    'istribution',/1X,'#',16X,'Nuclear radius =',1P,E12.5,
     2    ' cm')
        U1=R1**2
        U2=0.0D0
      ELSE IF(MNUCL.EQ.4.OR.MNUCL.EQ.3) THEN
C  ****  Helm's Uu distribution.
        RNUC=1.070D0*F2BOHR*AW**0.3333333333333333D0
        R1=0.962D0*RNUC+0.435D0*F2BOHR
        R2=2.0D0*F2BOHR
        IF(R2.GT.R1) THEN
          STORE=R1
          R1=R2
          R2=STORE
        ENDIF
        WRITE(IW,1105) R1*A0B,R2*A0B
 1105   FORMAT(1X,'#',/1X,'# Nuclear model: Helm''s Uu distribu',
     1    'tion',/1X,'#',16X,'  Inner radius =',1P,E12.5, ' cm',
     2    /1X,'#',16X,'Skin thickness =',E12.5,' cm')
        U1=R1**2
        U2=R2**2
      ELSE
        WRITE(IW,1003)
 1003   FORMAT(1X,'#',/1X,'# Undefined nuclear charge density model.',
     1    /1X,'# The calculation was aborted by subroutine HEBRON.')
      ENDIF
C
      TH(1)=0.0D0
      TH(2)=1.0D-4
      I=2
   10 CONTINUE
      I=I+1
      IF(TH(I-1).LT.0.9999D-3) THEN
        TH(I)=TH(I-1)+2.5D-5
      ELSE IF(TH(I-1).LT.0.9999D-2) THEN
        TH(I)=TH(I-1)+2.5D-4
      ELSE IF(TH(I-1).LT.0.9999D-1) THEN
        TH(I)=TH(I-1)+2.5D-3
      ELSE IF(TH(I-1).LT.0.9999D+0) THEN
        TH(I)=TH(I-1)+2.5D-2
      ELSE IF(TH(I-1).LT.0.9999D+1) THEN
        TH(I)=TH(I-1)+1.0D-1
      ELSE IF(TH(I-1).LT.2.4999D+1) THEN
        TH(I)=TH(I-1)+2.5D-1
      ELSE
        TH(I)=TH(I-1)+5.0D-1
      ENDIF
      IF(TH(I).LT.180.0D0) GO TO 10
      NTAB=I
C
      NTABT=NTAB
      DO I=1,NTAB
        THR=TH(I)*PI/180.0D0
        XT(I)=(1.0D0-COS(THR))/2.0D0
C  ****  Screening correction.
        Q2=4.0D0*RK2*XT(I)
        IF(Q2.LE.Q2T(NQS)) THEN
          CALL FINDI(Q2T,Q2,NQS,J)
          F=FQ(J)+(FQ(J+1)-FQ(J))*(Q2-Q2T(J))/(Q2T(J+1)-Q2T(J))
        ELSE
          F=1.0D0
        ENDIF
C  ****  Nuclear form factor.
        QR2=Q2*U1
        QR=DSQRT(QR2)
        IF(QR2.LT.1.0D-8) THEN
          FR=1.0D0+QR2*(-0.1D0+QR2*3.5714285714285714D-3)
        ELSE
          FR=3.0D0*(DSIN(QR)-QR*DCOS(QR))/(QR*QR2)
        ENDIF
        QU2=Q2*U2
        QU=DSQRT(QU2)
        IF(QU2.LT.1.0D-8) THEN
          FU=1.0D0+QU2*(-0.1D0+QU2*3.5714285714285714D-3)
        ELSE
          FU=3.0D0*(DSIN(QU)-QU*DCOS(QU))/(QU*QU2)
        ENDIF
        FN=FR*FU
C
        RMR=DPWAC(THR)
        DCST(I)=RUTHC*(F*FN)**2*RMR/(1.0D0+Q2)**2
      ENDDO
C
C  ****  Integrated cross sections.
C
      SUM0=0.0D0
      SUM1=0.0D0
      SUM2=0.0D0
      RMUL=0.0D0
      RMUU=1.0D-16
   20 CONTINUE
      MOM=0
      CALL GABQ(DCSHB,RMUL,RMUU,SUMP0,1.0D-9,IER)
      MOM=1
      CALL GABQ(DCSHB,RMUL,RMUU,SUMP1,1.0D-9,IER)
      MOM=2
      CALL GABQ(DCSHB,RMUL,RMUU,SUMP2,1.0D-9,IER)
      SUM0=SUM0+SUMP0
      SUM1=SUM1+SUMP1
      SUM2=SUM2+SUMP2
      RMUL=RMUU
      RMUU=MIN(2.0D0*RMUL,1.0D0)
      IF(RMUL.LT.0.9999999D0) GO TO 20
      ECS0=FOURPI*SUM0
      ECS1=FOURPI*SUM1
      ECS2=FOURPI*SUM2
C
      ECS=ECS0
      TCS1=2.0D0*ECS1
      TCS2=6.0D0*(ECS1-ECS2)
      WRITE(IW,2013) ECS,ECS/A0B2
 2013 FORMAT(1X,'#',/1X,'# Total elastic cross section =',1P,
     1     E12.5,' cm**2 =',E12.5,' a0**2')
      WRITE(IW,2014) TCS1,TCS1/A0B2
 2014 FORMAT(1X,'# 1st transport cross section =',1P,
     1     E12.5,' cm**2 =',E12.5,' a0**2')
      WRITE(IW,2015) TCS2,TCS2/A0B2
 2015 FORMAT(1X,'# 2nd transport cross section =',1P,
     1     E12.5,' cm**2 =',E12.5,' a0**2',/1X,'#')
C
      WRITE(IW,'(1X,''#'')')
      WRITE(IW,'(1X,''# Differential cross section'',6X,
     1  ''MU=(1-COS(THETA))/2'')')
      WRITE(IW,'(1X,''#'',/1X,''#  THETA'',8X,''MU'',10X,''DCS'',
     1  10X,''DCS'',8X,''Sherman'',7X,''error''/1X,''#  (deg)'',
     2  17X,''(cm**2/sr)'',3X,''(a0**2/sr)'',4X,''function'',
     3  /1X,''#'',71(''-''))')
      DO I=1,NTAB
        SPOL(I)=0.0D0
        ERROR(I)=1.0D-5
        WRITE(IW,2018) TH(I),XT(I),DCST(I),DCST(I)/A0B2,SPOL(I),ERROR(I)
      ENDDO
 2018 FORMAT(1X,1P,E10.3,E13.5,3E13.5,2X,E8.1)
C
      RETURN
      END
C  *********************************************************************
      FUNCTION DCSHB(RMU)
C     Mott-Born DCS for elastic scattering of high-energy electrons and
C  positrons by neutral atoms.
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1   INTEGER*4 (I-N)
      PARAMETER (NPC=1500)
      COMMON/CRMORU/CFM(NPC),CGM(NPC),DPC(NPC),DMC(NPC),
     1              CF,CG,RUTHC,WATSC,RK2,ERRF,ERRG,NPC1
      PARAMETER (NGT=650)
      COMMON/CDCSHE/Q2T(NGT),FQ(NGT),U1,U2,NQS,MOM
C  ****  Screening correction.
      Q2=4.0D0*RK2*RMU
      IF(Q2.LE.Q2T(NQS)) THEN
        CALL FINDI(Q2T,Q2,NQS,J)
        F=FQ(J)+(FQ(J+1)-FQ(J))*(Q2-Q2T(J))/(Q2T(J+1)-Q2T(J))
      ELSE
        F=1.0D0
      ENDIF
C  ****  (nuclear form factor)**2.
      QR2=Q2*U1
      QR=DSQRT(QR2)
      IF(QR2.LT.1.0D-8) THEN
        FR=1.0D0+QR2*(-0.1D0+QR2*3.5714285714285714D-3)
      ELSE
        FR=3.0D0*(SIN(QR)-QR*COS(QR))/(QR*QR2)
      ENDIF
      QU2=Q2*U2
      QU=DSQRT(QU2)
      IF(QU2.LT.1.0D-8) THEN
        FU=1.0D0+QU2*(-0.1D0+QU2*3.5714285714285714D-3)
      ELSE
        FU=3.0D0*(SIN(QU)-QU*COS(QU))/(QU*QU2)
      ENDIF
      FN=FR*FU
C
      RMR=DPWAC(ACOS(1.0D0-2.0D0*RMU))
      DCSHB=(RUTHC*(F*FN)**2*RMR/(1.0D0+Q2)**2)*RMU**MOM
      RETURN
      END
C  *********************************************************************
C                        SUBROUTINE SGRID
C  *********************************************************************
      SUBROUTINE SGRID(R,DIFR,R0,RN,C,N)
C
C  This subroutine sets up a radial grid R(I) (I=1:N) such that
C     1) A*(R(I)+R0)+B*LOG(R(I)+R0)+C=I.
C     2) The grid spacing, R(I+1)-R(I), increases monotonously with I.
C     3) The parameters A and B are determined by requiring that R(1)=0
C        and R(N)=RN. They are required to be positive.
C
C     To describe the wave functions of an electron in the field of an
C  atom, the following parameter values should be adequate: R0 about
C  1.0D-5 or smaller, RN of the order of 10, N=400 or larger, C=N/2 or
C  so. Then, C is approximately equal to the number of grid points
C  between 0 and 1, R(2) is smaller than R0 in a factor of about 10, and
C  R(N)-R(N-1)=RN/(N-C), approximately.
C
C     The output arrays contain the grid points R(1:N) and the relative
C  increments DIFR(1:N), i.e. the values of the derivative of R(I) with
C  respect to I.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
C  ****  Set IWR=1 to print the grid on a file.
      PARAMETER (IWR=0)
      DIMENSION R(N),DIFR(N)
C
 1000 FORMAT(4X,'R0=',1P,E18.11,'  RN=',E18.11,
     1      /4X,' C=',E18.11,'   N=',I5,/)
C  ****  R0 must be positive (gt. 1.0d-35).
      IF(R0.LT.1.0D-35) THEN
        WRITE(6,1001)
 1001 FORMAT(1X,'** Error in SGRID: R0 is too small.')
        WRITE(6,1000) R0,RN,C,N
        STOP 'SGRID: R0 is too small.'
      ENDIF
C  ****  RN has to be larger than R0.
      IF(RN.LE.R0) THEN
        WRITE(6,1002)
 1002 FORMAT(1X,'** Error in SGRID: RN is less than or ',
     1  'equal to R0.')
        WRITE(6,1000) R0,RN,C,N
        STOP 'SGRID: RN is less than or equal to R0.'
      ENDIF
C  ****  N should be larger than 10.
      IF(N.LT.10) THEN
        WRITE(6,1003)
 1003 FORMAT(1X,'** WARNING in SGRID: N is too small.')
        WRITE(6,1000) R0,RN,C,N
      ENDIF
C  ****  Risk of round off errors if RN/R0 is too large.
      RN0=RN/R0
      IF(RN0.GT.1.0D12) THEN
        WRITE(6,1004)
 1004 FORMAT(1X,'** WARNING in SGRID: RN/R0 is too large.')
        WRITE(6,1000) R0,RN,C,N
      ENDIF
C
      CC=C
      B=(1.0D0-CC)/LOG(R0)
      RPR0=RN+R0
      A=(DBLE(N)-CC-B*LOG(RPR0))/RPR0
      IF(B.LT.1.0D-15.OR.A.LT.1.0D-15) THEN
        A=0.0D0
        B=(DBLE(N)-1.0D0)/LOG(RN0+1.0D0)
        CC=1.0D0-B*LOG(R0)
      ENDIF
C
      R(1)=0.0D0
      RPR0=R(1)+R0
      DIFR(1)=RPR0/(A*RPR0+B)
      RR=1.0D-35
      DO I=2,N
        RL=RR
        RU=RL
    1   RU=2.0D0*RU
        RPR0=RU+R0
        FU=A*RPR0+B*LOG(RPR0)+CC-DBLE(I)
        IF(FU.LT.0.0D0) GO TO 1
    2   RR=0.5D0*(RU+RL)
        RPR0=RR+R0
        FR=A*RPR0+B*LOG(RPR0)+CC-DBLE(I)
        IF(FR.GT.0.0D0) THEN
          RU=RR
        ELSE
          RL=RR
        ENDIF
        IF(RU-RL.GT.1.0D-15*RR) GO TO 2
        R(I)=RR
        RPR0=RR+R0
        DIFR(I)=RPR0/(A*RPR0+B)
      ENDDO
C
C  ****  Print the grid on a file.
C
      IF(IWR.EQ.1) THEN
        OPEN(99,FILE='grid.dat')
        WRITE(99,2001)
 2001   FORMAT(4X,'Radial grid:',
     1         '  A*(R(I)+R0)+B*LOG(R(I)+R0)+C=I',/)
        WRITE(99,1000) R0,RN,C,N
        WRITE(99,2002) A,B,CC
 2002   FORMAT(4X,1P,' A=',E18.11,'   B=',E18.11,'  C=',E18.11,/)
        WRITE(99,2003)
 2003   FORMAT(4X,'I',8X,'R(I)',9X,'DIFR(I)',/3X,34('-'))
        DO I=1,N
          WRITE(99,'(1X,I5,1P,5E15.7)') I,R(I),DIFR(I)
        ENDDO
        CLOSE(99)
      ENDIF
C
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE SLAG6
C  *********************************************************************
      SUBROUTINE SLAG6(H,Y,S,N)
C
C     Piecewise six-point Lagrange integration of a uniformly tabulated
C  function.
C
C     H ...... step length,
C     Y ...... array of function values (ordered abscissas),
C     S ...... array of integral values defined as
C              S(I)=INTEGRAL(Y) from X(1) to X(I)=X(1)+(I-1)*H,
C     N ...... number of data points.
C
      IMPLICIT REAL*8 (A-H,O-Z), INTEGER*4 (I-N)
      DIMENSION Y(N),S(N)
      IF(N.LT.6) STOP
      HR=H/1440.0D0
      Y1=0.0D0
      Y2=Y(1)
      Y3=Y(2)
      Y4=Y(3)
      S(1)=0.0D0
      S(2)=HR*(475*Y2+1427*Y3-798*Y4+482*Y(4)-173*Y(5)+27*Y(6))
      S(3)=S(2)
     1    +HR*(-27*Y2+637*Y3+1022*Y4-258*Y(4)+77*Y(5)-11*Y(6))
      DO I=4,N-2
        Y1=Y2
        Y2=Y3
        Y3=Y4
        Y4=Y(I)
        S(I)=S(I-1)
     1      +HR*(11*(Y1+Y(I+2))-93*(Y2+Y(I+1))+802*(Y3+Y4))
      ENDDO
      Y5=Y(N-1)
      Y6=Y(N)
      S(N-1)=S(N-2)
     1      +HR*(-27*Y6+637*Y5+1022*Y4-258*Y3+77*Y2-11*Y1)
      S(N)=S(N-1)
     1    +HR*(475*Y6+1427*Y5-798*Y4+482*Y3-173*Y2+27*Y1)
      RETURN
      END
C  *********************************************************************
C                       FUNCTION VCPOL
C  *********************************************************************
      FUNCTION VCPOL(IELEC,DEN)
C
C     This function gives the correlation potential of an electron
C  (IELEC=-1) or positron (IELEC=+1) in an homogeneous electron gas of
C  density DEN (electrons per unit volume).
C
C  ****  All quantities are in atomic units.
C
      IMPLICIT REAL*8 (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER (PI=3.1415926535897932D0,FOURPI=4.0D0*PI)
C
      IF(DEN.LT.1.0D-12) THEN
        VCPOL=0.0D0
        RETURN
      ENDIF
      RS=(3.0D0/(FOURPI*MAX(DEN,1.0D-12)))**3.333333333333D-1
      RSL=LOG(RS)
C
      IF(IELEC.EQ.-1) THEN
C  ****  Electron exchange-correlation potential.
C        Ref:  Padial and Norcross, Phys. Rev. A 29(1984)1742.
C              Perdew and Zunger, Phys. Rev. B 23(1981)5048.
        IF(RS.LT.1.0D0) THEN
          VCPOL=0.0311D0*RSL-0.0584D0+0.00133D0*RS*RSL-0.0084D0*RS
        ELSE
          GAM=-0.1423D0
          BET1=1.0529D0
          BET2=0.3334D0
          RSS=SQRT(RS)
          VCPOL=GAM*(1.0D0+(7.0D0/6.0D0)*BET1*RSS
     1         +(4.0D0/3.0D0)*BET2*RS)/(1.0D0+BET1*RSS+BET2*RS)**2
        ENDIF
      ELSE
C  ****  Positron correlation potential.
C        Ref:  Jain, Phys. Rev. A 41(1990)2437.
        IF(RS.LT.0.302D0) THEN
          VCPOL=(-1.82D0/SQRT(RS))+(0.051D0*RSL-0.115D0)*RSL+1.167D0
        ELSE IF(RS.LT.0.56D0) THEN
          VCPOL=-0.92305D0-0.09098D0/RS**2
        ELSE IF(RS.LT.8.0D0) THEN
          RSD=1.0D0/(RS+2.5D0)
          VCPOL=(-8.7674D0*RS*RSD**3)+(-13.151D0+0.9552D0*RS)*RSD**2
     1         +2.8655D0*RSD-0.6298D0
        ELSE
          VCPOL=-179856.2768D0*3.0D0*DEN**2+186.4207D0*2.0D0*DEN
     1         -0.524D0
        ENDIF
        VCPOL=0.5D0*VCPOL
      ENDIF
      RETURN
      END
C  *********************************************************************
C                        SUBROUTINE XSFEG
C  *********************************************************************
      SUBROUTINE XSFEG(DEN,DELTA,IELEC,EK,MORD,XSEC,IMODE)
C
C     This subroutine computes restricted (W>DELTA) total cross sections
C  for interactions of electrons (IELEC=-1) or positrons (IELEC=+1) with
C  a degenerate free electron gas (per electron in the gas). The DCS
C  is obtained from Lindhard's dielectric function (i.e. within the
C  first Born approximation), with the Ochkur exchange correction for
C  electrons.
C
C  Ref.: F. Salvat, Phys. Rev. A 68 (2003) 012708.
C
C
C  Input arguments:
C     DEN ...... density of the electron gas (electrons per unit
C                volume).
C     DELTA .... energy gap (or minimum energy loss).
C     IELEC .... kind of projectile.
C                =-1, electron; =+1, positron.
C     EK ....... kinetic energy of the projectile.
C     MORD ..... order of the calculated cross section;
C                =0, total cross section,
C                =1, stopping cross section,
C                =2, energy straggling cross section.
C     XSEC ..... total integrated cross section.
C     IMODE .... =1, the complete DCS (for electron-hole and plasmon
C                    excitations) is calculated.
C                =2, the output value XSEC corresponds to electron-hole
C                    excitations (binary collisions) only.
C
C                                  (All quantities in atomic units).
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER(F2O3=2.0D0/3.0D0,F3O16=3.0D0/16.0D0)
      PARAMETER(PI=3.1415926535897932D0, FOURPI=4.0D0*PI)
      COMMON/CXSFEG/EF,EP,CHI2,XP,ZC,XC,XE,SXE,IELPO
      PARAMETER(NPM=50)
      COMMON/CXSPL0/Z
      COMMON/CXSPL1/ZPT(NPM),XPT(NPM),FPL(NPM),ZANAL,XANAL,
     1              AX(NPM),BX(NPM),CX(NPM),DX(NPM),
     2              AF(NPM),BF(NPM),CF(NPM),DF(NPM),MOM
C  ****  Contributions from electron-hole and plasmon excitations.
      COMMON/XSFEGO/XSEH,XSPL
C
      EXTERNAL PLSTR
C  ****  Plasmon excitation functions are printed if IWR=1.
      IWR=0
C
      IF(MORD.LT.0.OR.MORD.GT.2) THEN
          STOP 'Wrong MORD value.'
      ENDIF
C
C  ****  Constants and energy-independent parameters.
C
      DENM=MAX(DEN,1.0D-5)
      IELPO=IELEC
      EP2=FOURPI*DENM
      EP=SQRT(EP2)
      EF=0.5D0*(3.0D0*PI**2*DENM)**F2O3
      XE=EK/EF
      IF(XE.LT.1.0D-3) THEN
        XSEC=0.0D0
        RETURN
      ENDIF
      SXE=SQRT(XE)
      XP=EP/EF
      CHI2=F3O16*XP*XP
C  ****  Plasmon cutoff momentum.
        ZL=XP-1.0D-3
    1   CONTINUE
        FL=ZL*ZL+CHI2*F1(ZL,4.0D0*ZL*(ZL+1.0D0))
        IF(FL.GT.0.0D0) THEN
          ZL=0.5D0*ZL
          GO TO 1
        ENDIF
        ZU=XP+1.0D-2
    2   CONTINUE
        FU=ZU*ZU+CHI2*F1(ZU,4.0D0*ZU*(ZU+1.0D0))
        IF(FU.LT.0.0D0) THEN
          ZU=ZU+ZU
          GO TO 2
        ENDIF
    3   ZC=0.5D0*(ZL+ZU)
        FT=ZC*ZC+CHI2*F1(ZC,4.0D0*ZC*(ZC+1.0D0))
        IF(FT.LT.0.0D0) THEN
          ZL=ZC
        ELSE
          ZU=ZC
        ENDIF
        IF(ABS(ZL-ZU).GT.1.0D-15*ZC) GO TO 3
        XC=4.0D0*ZC*(ZC+1.0D0)
C
C  ************  Electron-hole contribution.
C
      CALL SEH0(XSEH,DELTA,MORD,IWR)
C
      IF(IMODE.EQ.2) THEN
        XSEC=XSEH
        RETURN
      ENDIF
C
C  ************  Plasmon contribution.
C
      IF(XE.LT.XP) THEN
        XSPL=0.0D0
      ELSE
C  ****  Plasmon line.
        ZPT(1)=0.0D0
        XPT(1)=XP
        FPL(1)=1.0D0
        ZANAL=0.0D0
        XANAL=0.0D0
C  ****  Varying step: 2*DZ for I<NPH.
        NPH=2*NPM/3
        DFZ=0.999999999D0*ZC/DBLE(NPM+NPH-3)
        DO I=2,NPM
          IF(I.LT.NPH) THEN
            Z=ZPT(I-1)+DFZ*2.0D0
          ELSE
            Z=ZPT(I-1)+DFZ
          ENDIF
          IF(Z.GT.0.02D0*ZC) THEN
C  The starting endpoints must be outside the Lindhard continuum.
            XL=MAX(4.0D0*Z*(Z+1.0D0)+1.0D-9,0.9D0*XP)
            XU=1.1D0*XC
    4       X=0.5D0*(XL+XU)
            FT=Z*Z+CHI2*F1(Z,X)
            IF(FT.GT.0.0D0) THEN
              XU=X
            ELSE
              XL=X
            ENDIF
C           WRITE(6,'('' X,FT ='',1P,3E18.11)') X,FT
            IF(FT.GT.1.0D-6) GO TO 4
            IF(ABS(XL-XU).GT.1.0D-13*X) GO TO 4
          ELSE
            X=SQRT(XP**2+(48.0D0/5.0D0)*Z**2+16.0D0*Z**4)
          ENDIF
          XPT(I)=X
          ZPT(I)=Z
        ENDDO
        DO I=2,NPM-1
          Z=ZPT(I)
          XUP=4.0D0*Z*(Z+1.0D0)-1.0D-9
          CALL GABQ(PLSTR,1.0D-10,XUP,SUM,1.0D-6,IER)
          IF(IER.EQ.1) THEN
            WRITE(6,*) 'GABQ error in XSFEG.'
            STOP
          ENDIF
          FPL(I)=1.0D0-SUM*(6.0D0/(16.0D0*PI))
          XAP=XP+(24.0D0/5.0D0)*Z*Z/XP
          IF(ABS(XAP-XPT(I)).LT.1.0D-3*XPT(I).AND.
     1      FPL(I).GT.0.999D0) THEN
            ZANAL=ZPT(I)
            XANAL=XPT(I)
          ENDIF
        ENDDO
        FPL(NPM)=FPL(NPM-1)+(FPL(NPM-1)-FPL(NPM-2))
     1      *(XPT(NPM)-XPT(NPM-1))/(XPT(NPM-1)-XPT(NPM-2))
C
        IF(IWR.EQ.1) THEN
          OPEN(9,FILE='plasma.dat')
          Z=1.1D0*ZC
          XLOW=MAX(0.0D0,4.0D0*Z*(Z-1.0D0))+1.0D-9
          XUP=4.0D0*Z*(Z+1.0D0)-1.0D-9
          CALL GABQ(PLSTR,XLOW,XUP,SUM,1.0D-6,IER)
          IF(IER.EQ.1) THEN
            WRITE(6,*) 'GABQ error in XSFEG.'
            STOP
          ENDIF
          BETHE=SUM*(6.0D0/(16.0D0*PI))
          WRITE(9,*) '#  BETHE SUM =',BETHE
          WRITE(9,*) '#  AN. APPROX. VALID FOR Z <',ZANAL
          WRITE(9,*) '#  AN. APPROX. VALID FOR X <',XANAL
          DO I=1,NPM
            Z=ZPT(I)
            XAP=XP+(24.0D0/5.0D0)*Z*Z/XP
            WRITE(9,'(I4,1P,5E14.6)') I,ZPT(I),XPT(I),FPL(I),XAP
          ENDDO
          CLOSE(9)
        ENDIF
C
        CALL SPLINE(ZPT,XPT,AX,BX,CX,DX,0.0D0,0.0D0,NPM)
        CALL SPLINE(ZPT,FPL,AF,BF,CF,DF,0.0D0,0.0D0,NPM)
        CALL SPL0(XSPL,DELTA,MORD)
      ENDIF
C
      XSEC=XSEH+XSPL
      RETURN
      END
C  *********************************************************************
C                       FUNCTION PLSTR
C  *********************************************************************
      FUNCTION PLSTR(X)
C
C     Integrand of the DDCS for a point (Z,X) within the Lindhard
C  continuum.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER(PI=3.1415926535897932D0)
      COMMON/CXSFEG/EF,EP,CHI2,XP,ZC,XC,XE,SXE,IELPO
      COMMON/CXSPL0/Z
C
      PLSTR=0.0D0
      IF(Z.LT.1.0D-8) RETURN
C  ****  F2 function.
      IF(X.LT.1.0D0) THEN
        IF(X.LT.4.0D0*Z*(1.0D0-Z)) THEN
          F2=PI*X*0.125D0/Z  ! Region a.
        ELSE
          ZIN=1.0D0/Z
          ZM=Z-X*ZIN*0.25D0
          F2=PI*0.125D0*ZIN*(1.0D0-ZM*ZM)  ! Region b.
        ENDIF
      ELSE
        ZIN=1.0D0/Z
        ZM=Z-X*ZIN*0.25D0
        F2=PI*0.125D0*ZIN*(1.0D0-ZM*ZM)  ! Region b.
      ENDIF
C
      PLSTR=X*Z*Z*F2/((Z*Z+CHI2*F1(Z,X))**2+(CHI2*F2)**2)
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE SPL0
C  *********************************************************************
      SUBROUTINE SPL0(XSPL,DELTA,MORD)
C
C     Restricted total cross sections for plasmon excitation.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER(PI=3.1415926535897932D0)
      PARAMETER(NPM=50)
      COMMON/CXSFEG/EF,EP,CHI2,XP,ZC,XC,XE,SXE,IELPO
      COMMON/CXSPL1/ZPT(NPM),XPT(NPM),FPL(NPM),ZANAL,XANAL,
     1              AX(NPM),BX(NPM),CX(NPM),DX(NPM),
     2              AF(NPM),BF(NPM),CF(NPM),DF(NPM),MOM
      EXTERNAL SPL1
C
      XSPL=0.0D0
      IF(XE.LT.XP+1.0D-8) THEN
        WRITE(6,*) 'WARNING: X is less than XP (SPL0).'
        RETURN
      ENDIF
C  ****  Minimum and maximum allowed Z-values.
      I1=0
      IN=NPM
      DO I=2,NPM
        IF(IELPO.EQ.-1) THEN
          XUP=MIN(4.0D0*ZPT(I)*(SXE-ZPT(I)),XE-1.0D0)
        ELSE
          XUP=4.0D0*ZPT(I)*(SXE-ZPT(I))
        ENDIF
        IF(XUP.GT.XPT(I)) THEN
          IF(I1.EQ.0) I1=I
        ENDIF
        IF(XUP.LT.XPT(I).AND.I1.GT.0) THEN
          IN=I
          GO TO 1
        ENDIF
      ENDDO
    1 CONTINUE
      IF(I1.EQ.0) RETURN
C
      I=I1-1
      ZL=ZPT(I)
      ZU=ZPT(I+1)
    2 Z=0.5D0*(ZL+ZU)
      X=AX(I)+Z*(BX(I)+Z*(CX(I)+Z*DX(I)))
      IF(IELPO.EQ.-1) THEN
        XMIN=MIN(4.0D0*Z*(SXE-Z),XE-1.0D0)
      ELSE
        XMIN=4.0D0*Z*(SXE-Z)
      ENDIF
      IF(XMIN.GT.X) THEN
        ZU=Z
      ELSE
        ZL=Z
      ENDIF
C       WRITE(6,'('' Z1,X-XCON ='',1P,3E18.11)') Z,X-XMIN
      IF(ABS(ZU-ZL).GT.1.0D-14*Z) GO TO 2
      ZMIN=Z
C
      IF(IN.LT.NPM) THEN
        I=IN-1
        ZL=ZPT(I)
        ZU=ZPT(I+1)
    3   Z=0.5D0*(ZL+ZU)
        X=AX(I)+Z*(BX(I)+Z*(CX(I)+Z*DX(I)))
        IF(IELPO.EQ.-1) THEN
          XMAX=MIN(4.0D0*Z*(SXE-Z),XE-1.0D0)
        ELSE
          XMAX=4.0D0*Z*(SXE-Z)
        ENDIF
        IF(XMAX.LT.X) THEN
          ZU=Z
        ELSE
          ZL=Z
        ENDIF
C         WRITE(6,'('' Z2,X-XCON ='',1P,3E18.11)') Z,X-XMAX
        IF(ABS(ZU-ZL).GT.1.0D-14*Z) GO TO 3
        ZMAX=Z
      ELSE
        XMAX=XC
        ZMAX=ZC
      ENDIF
C
      XDEL=DELTA/EF
      IF(XDEL.GE.XMAX) RETURN
      IF(XDEL.GT.XMIN) THEN
        CALL FINDI(XPT,XDEL,NPM,I)
        ZL=ZPT(I)
        ZU=ZPT(I+1)
    4   Z=0.5D0*(ZL+ZU)
        X=AX(I)+Z*(BX(I)+Z*(CX(I)+Z*DX(I)))
        IF(XDEL.LT.X) THEN
          ZU=Z
        ELSE
          ZL=Z
        ENDIF
C         WRITE(6,'('' Z1,X-XCON ='',1P,3E18.11)') Z,X-XDEL
        IF(ABS(ZU-ZL).GT.1.0D-14*Z) GO TO 4
        ZMIN=Z
        XMIN=XDEL
      ENDIF
C
      IF(XMIN.GT.XMAX) RETURN
C
C  ****  Soft plasmon excitation.
C
      FACT= 3.0D0/(16.0D0*CHI2)
      IF(XMIN.LT.XANAL.AND.XMAX.GT.XANAL) THEN
        IF(MORD.EQ.0) THEN
          X=XANAL
          S0U=X+(XP/2.0D0)*LOG((X-XP)/(X+XP))
          X=XMIN
          S0L=X+(XP/2.0D0)*LOG((X-XP)/(X+XP))
          SUMP=FACT*(S0U-S0L)
          ZMIN=ZANAL
        ELSE IF(MORD.EQ.1) THEN
          X=XANAL
          S1U=(X**2/2.0D0)+(XP**2/2.0D0)*LOG(X*X-XP*XP)
          X=XMIN
          S1L=(X**2/2.0D0)+(XP**2/2.0D0)*LOG(X*X-XP*XP)
          SUMP=FACT*(S1U-S1L)
          ZMIN=ZANAL
        ELSE IF(MORD.EQ.2) THEN
          X=XANAL
          S2U=(X**3/3.0D0)+XP**2*X+(XP**3/2.0D0)
     1       *LOG((X-XP)/(X+XP))
          X=XMIN
          S2L=(X**3/3.0D0)+XP**2*X+(XP**3/2.0D0)
     1       *LOG((X-XP)/(X+XP))
          SUMP=FACT*(S2U-S2L)
          ZMIN=ZANAL
        ELSE
          STOP 'Wrong MORD value.'
        ENDIF
      ELSE
        SUMP=0.0D0
      ENDIF
C
      IF(ZMIN.LT.ZMAX) THEN
        MOM=MORD
        CALL GABQ(SPL1,ZMIN,ZMAX,SUM,1.0D-6,IER)
        IF(IER.NE.0) THEN
          OPEN(9,FILE='plasma.dat')
          DO I=1,NPM
            WRITE(9,'(I4,1P,5E14.6)') I,XPT(I),ZPT(I),FPL(I)
          ENDDO
          CLOSE(9)
          WRITE(6,*) 'Accumulated numerical errors...'
          WRITE(6,*) 'GABQ error in SPL0.'
          STOP
        ENDIF
      ELSE
        SUMP=0.0D0
      ENDIF
      XSPL=(2.0D0*PI/(XE*EF*EF))*(SUM+SUMP)*EF**MORD
      RETURN
      END
C  *********************************************************************
C                       FUNCTION SPL1
C  *********************************************************************
      FUNCTION SPL1(Z)
C
C     DCS for plasmon excitations.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER(R96O5=96.0D0/5.0D0,R3O4=3.0D0/4.0D0)
      COMMON/CXSFEG/EF,EP,CHI2,XP,ZC,XC,XE,SXE,IELPO
      PARAMETER(NPM=50)
      COMMON/CXSPL1/ZPT(NPM),XPT(NPM),FPL(NPM),ZANAL,XANAL,
     1              AX(NPM),BX(NPM),CX(NPM),DX(NPM),
     2              AF(NPM),BF(NPM),CF(NPM),DF(NPM),MOM
C
      CALL FINDI(ZPT,Z,NPM,I)
      X=AX(I)+Z*(BX(I)+Z*(CX(I)+Z*DX(I)))
      FP=AF(I)+Z*(BF(I)+Z*(CF(I)+Z*DF(I)))
      SPL1=FP*X**MOM/(Z*X)
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE SEH0
C  *********************************************************************
      SUBROUTINE SEH0(XSEH,DELTA,MORD,IWR)
C
C  Restricted total cross sections for electron-hole excitations.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER(PI=3.1415926535897932D0)
      PARAMETER(NHM=150)
      DIMENSION XT(NHM),DW(NHM)
      COMMON/CXSFEG/EF,EP,CHI2,XP,ZC,XC,XE,SXE,IELPO
C
      IF(IELPO.EQ.-1) THEN
        XMAX=0.5D0*(XE-1.0D0)
C       XMAX=XE-1.0D-8  !!!! NO EXCHANGE !!!!
      ELSE
        XMAX=XE-1.0D-8
      ENDIF
      XMIN=MAX(DELTA/EF,1.0D-10)
      IF(XMIN.GE.XMAX) THEN
        XSEH=0.0D0
        RETURN
      ENDIF
C
      FACTL=6.0D0/(16.0D0*PI)
      FACTR=0.5D0
      NP=1
      XT(1)=XMIN
      DW(1)=SEH1(XT(1))
      IF(XMIN.LT.1.2D0*XC) THEN
        NS1=2*NHM/3
        DX=(MIN(1.2D0*XC,XMAX)-XMIN)/DBLE(NS1-1)
        DO I=2,NS1
          NP=I
          XT(I)=XT(I-1)+DX
          DW(I)=FACTL*SEH1(XT(I))
        ENDDO
      ENDIF
      IF(XT(NP).LT.XMAX-1.0D-10) THEN
        DFX=EXP(LOG((XMAX)/XT(NP))/DBLE(NHM-NP))
        NP1=NP+1
        ICALC=0
        DO I=NP1,NHM
          NP=I
          XT(I)=XT(I-1)*DFX
          IF(ICALC.EQ.0) THEN
            DW(I)=FACTL*SEH1(XT(I))
            DWA=FACTR/XT(I)**2
            IF(IELPO.EQ.-1) THEN  ! Exchange correction.
              FEXP=XT(I)/(XE-XT(I))
C             FEXP=1.0D0  !!!! NO EXCHANGE !!!!
              DWA=DWA*(1.0D0-FEXP*(1.0D0-FEXP))
            ENDIF
            IF(ABS(DW(I)-DWA).LT.1.0D-4*DWA) ICALC=1
          ELSE
C  ****  High-Z electron-hole excitations. Moller or Rutherford
C        differential cross section.
            DW(I)=FACTR/XT(I)**2
            IF(IELPO.EQ.-1) THEN  ! Exchange correction.
              FEXP=XT(I)/(XE-XT(I))
C             FEXP=1.0D0  !!!! NO EXCHANGE !!!!
              DW(I)=DW(I)*(1.0D0-FEXP*(1.0D0-FEXP))
            ENDIF
          ENDIF
        ENDDO
      ENDIF
      IF(NP.LT.3) THEN
        XSEH=0.0D0
        WRITE(6,*) 'WARNING: NP is too small (SEH0).'
        RETURN
      ENDIF
      DW(NP)=EXP(LOG(DW(NP-1))+LOG(DW(NP-1)/DW(NP-2))
     1      *(XT(NP)-XT(NP-1))/(XT(NP-1)-XT(NP-2)))
C
      IF(IWR.EQ.1) THEN
        OPEN(9,FILE='ehdcs.dat')
        DO I=1,NP
          WRITE(9,'(1X,1P,5E14.6)') XT(I)/XC,DW(I)
        ENDDO
        CLOSE(9)
      ENDIF
C
      FACT=2.0D0*PI/(XE*EF*EF)
      XSEH=FACT*RMOM(XT,DW,NP,MORD)*EF**MORD
      RETURN
      END
C  *********************************************************************
C                       FUNCTION SEH1
C  *********************************************************************
      FUNCTION SEH1(X)
C
C     Integral of the DDCS over Z within the Lindhard continuum.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      COMMON/CXSFEG/EF,EP,CHI2,XP,ZC,XC,XE,SXE,IELPO
      COMMON/CXSEH1/XX
      EXTERNAL SEH2
C
      SEH1=0.0D0
      SXP1=SQRT(X+1.0D0)
      SXEX=SQRT(XE-X)
      ZMIN=MAX(0.5D0*(SXE-SXEX),0.5D0*(SXP1-1.0D0))+1.0D-10
      ZMAX=MIN(0.5D0*(SXE+SXEX),0.5D0*(SXP1+1.0D0))-1.0D-10
      IF(ZMIN.GE.ZMAX) RETURN
C
      XX=X
      IF(ABS(X-XC).LT.2.0D-2*XC) THEN
        DZ=ZMAX-ZMIN
        ZMINM=ZMIN+1.0D-7*(ZMAX-ZMIN)
        CALL GABQ(SEH2,ZMINM,ZMAX,SUM,1.0D-6,IER)
        IF(IER.EQ.1) THEN
          WRITE(6,*) 'GABQ error in SEH1.'
          STOP
        ENDIF
        SEH1=SUM
      ELSE
        CALL GABQ(SEH2,ZMIN,ZMAX,SUM,1.0D-6,IER)
        IF(IER.EQ.1) THEN
          WRITE(6,*) 'GABQ error in SEH1.'
          STOP
        ENDIF
        SEH1=SUM
      ENDIF
      RETURN
      END
C  *********************************************************************
C                       FUNCTION SEH2
C  *********************************************************************
      FUNCTION SEH2(Z)
C
C     Integrand of the DDCS for a point (Z,X) within the Lindhard
C  continuum.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER(PI=3.1415926535897932D0)
      COMMON/CXSFEG/EF,EP,CHI2,XP,ZC,XC,XE,SXE,IELPO
      COMMON/CXSEH1/X
C
      SEH2=0.0D0
      IF(Z.LT.1.0D-8) RETURN
C  ****  F2 function.
      IF(X.LT.1.0D0) THEN
        IF(X.LT.4.0D0*Z*(1.0D0-Z)) THEN
          F2=PI*X*0.125D0/Z  ! Region a.
        ELSE
          ZIN=1.0D0/Z
          ZM=Z-X*ZIN*0.25D0
          F2=PI*0.125D0*ZIN*(1.0D0-ZM*ZM)  ! Region b.
        ENDIF
      ELSE
        ZIN=1.0D0/Z
        ZM=Z-X*ZIN*0.25D0
        F2=PI*0.125D0*ZIN*(1.0D0-ZM*ZM)  ! Region b.
      ENDIF
C
      SEH2=Z*F2/((Z*Z+CHI2*F1(Z,X))**2+(CHI2*F2)**2)
      IF(IELPO.EQ.-1) THEN  ! Exchange correction for electrons.
        FEXP=4.0D0*Z*Z/(XE-X)
C       FEXP=1.0D0  !!!! NO EXCHANGE !!!!
        SEH2=SEH2*(1.0D0-FEXP*(1.0D0-FEXP))
      ENDIF
      RETURN
      END
C  *********************************************************************
C                       FUNCTION F1
C  *********************************************************************
      FUNCTION F1(Z,X)
C
C     Lindhard's f_1(z,x) function.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
C
      IF(Z.LT.1.0D-5*X) THEN
        R=(Z/X)**2
        F1=-((16.0D0/3.0D0)+(256.0D0/5.0D0)*R)*R
        RETURN
      ENDIF
C
      ZIN=1.0D0/Z
      ZM=Z-X*ZIN*0.25D0
      IF(ABS(ZM).LT.1.0D-8) THEN
        AUX1=2.0D0*ZM-(4.0D0/3.0D0)*ZM**3-(4.0D0/15.0D0)*ZM**5
      ELSE
        ARGL=ABS((1.0D0+ZM)/(1.0D0-ZM))
        IF(ARGL.LT.1.0D-25.OR.ARGL.GT.1.0D25) THEN
          AUX1=0.0D0
        ELSE
          AUX1=(1.0D0-ZM**2)*LOG(ARGL)
        ENDIF
      ENDIF
C
      ZP=Z+X*ZIN*0.25D0
      IF(ABS(ZP).LT.1.0D-8) THEN
        AUX2=2.0D0*ZP-(4.0D0/3.0D0)*ZP**3-(4.0D0/15.0D0)*ZP**5
      ELSE
        ARGL=ABS((1.0D0+ZP)/(1.0D0-ZP))
        IF(ARGL.LT.1.0D-25.OR.ARGL.GT.1.0D25) THEN
          AUX2=0.0D0
        ELSE
          AUX2=(1.0D0-ZP**2)*LOG(ARGL)
        ENDIF
      ENDIF
C
      F1=0.5D0+0.125D0*(AUX1+AUX2)*ZIN
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE GABQ
C  *********************************************************************
      SUBROUTINE GABQ(FCT,XL,XU,SUM,TOL,IER)
C
C     This subroutine calculates the value SUM of the integral of the
C  (external) function FCT over the interval (XL,XU) using the 20-point
C  Gauss quadrature method with an adaptive bipartition scheme.
C
C     TOL is the tolerance, i.e. the maximum allowed relative error; it
C  should not exceed 1.0D-13. IER is an error flag; its output value is
C  0 when the required accuracy has been attained and 1 otherwise.
C
C                              Francesc Salvat. Barcelona, January 2002.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER(NP=10,NST=128,NCALLS=20000)
      DIMENSION X(NP),W(NP),S(NST),SN(NST),XR(NST),XRN(NST)
C  ****  Gauss 20-point integration formula.
C  Abscissas.
      DATA X/7.6526521133497334D-02,2.2778585114164508D-01,
     1       3.7370608871541956D-01,5.1086700195082710D-01,
     2       6.3605368072651503D-01,7.4633190646015079D-01,
     3       8.3911697182221882D-01,9.1223442825132591D-01,
     4       9.6397192727791379D-01,9.9312859918509492D-01/
C  Weights.
      DATA W/1.5275338713072585D-01,1.4917298647260375D-01,
     1       1.4209610931838205D-01,1.3168863844917663D-01,
     2       1.1819453196151842D-01,1.0193011981724044D-01,
     3       8.3276741576704749D-02,6.2672048334109064D-02,
     4       4.0601429800386941D-02,1.7614007139152118D-02/
C  ****  Error control.
      CTOL=MIN(MAX(TOL,1.0D-13),1.0D-2)
      PTOL=0.01D0*CTOL
      ERR=1.0D35
      IER=0
C  ****  Gauss integration from XL to XU.
      H=XU-XL
      SUM=0.0D0
      A=0.5D0*(XU-XL)
      B=0.5D0*(XL+XU)
      C=A*X(1)
      D=W(1)*(FCT(B+C)+FCT(B-C))
      DO I1=2,NP
        C=A*X(I1)
        D=D+W(I1)*(FCT(B+C)+FCT(B-C))
      ENDDO
      ICALL=NP+NP
      LH=1
      S(1)=D*A
      XR(1)=XL
C  ****  Adaptive bipartition scheme.
    1 CONTINUE
      HO=H
      H=0.5D0*H
      SUMR=0.0D0
      LHN=0
      DO I=1,LH
        SI=S(I)
        XA=XR(I)
        XB=XA+H
        XC=XA+HO
        A=0.5D0*(XB-XA)
        B=0.5D0*(XB+XA)
        C=A*X(1)
        D=W(1)*(FCT(B+C)+FCT(B-C))
        DO I2=2,NP
          C=A*X(I2)
          D=D+W(I2)*(FCT(B+C)+FCT(B-C))
        ENDDO
        S1=D*A
        A=0.5D0*(XC-XB)
        B=0.5D0*(XC+XB)
        C=A*X(1)
        D=W(1)*(FCT(B+C)+FCT(B-C))
        DO I3=2,NP
          C=A*X(I3)
          D=D+W(I3)*(FCT(B+C)+FCT(B-C))
        ENDDO
        S2=D*A
        ICALL=ICALL+4*NP
        S12=S1+S2
        IF(ABS(S12-SI).LE.MAX(PTOL*ABS(S12),1.0D-25)) THEN
          SUM=SUM+S12
        ELSE
          SUMR=SUMR+S12
          LHN=LHN+2
          IF(LHN.GT.NST) GO TO 2
          SN(LHN)=S2
          XRN(LHN)=XB
          SN(LHN-1)=S1
          XRN(LHN-1)=XA
        ENDIF
        IF(ICALL.GT.NCALLS) GO TO 2
      ENDDO
      ERR=ABS(SUMR)/MAX(ABS(SUMR+SUM),1.0D-25)
      IF(ERR.LT.CTOL.OR.LHN.EQ.0) RETURN
      LH=LHN
      DO I=1,LH
        S(I)=SN(I)
        XR(I)=XRN(I)
      ENDDO
      GO TO 1
C  ****  Warning (low accuracy) message.
    2 CONTINUE
      IER=1
      WRITE(6,11)
   11 FORMAT(/2X,'>>> GABQ. Gauss adaptive-bipartition quadrature.')
      WRITE(6,12) XL,XU,TOL
   12 FORMAT(2X,'XL =',1P,E19.12,',  XU =',E19.12,',  TOL =',E8.1)
      WRITE(6,13) ICALL,SUM,ERR,LHN
   13 FORMAT(2X,'NCALLS = ',I5,',  SUM =',1P,E20.13,',  ERR =',E8.1,
     1      /2X,'Number of open subintervals =',I3)
      WRITE(6,14)
   14 FORMAT(2X,'WARNING: the required accuracy has not been ',
     1  'attained.'/)
      RETURN
      END


CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C                  *****************************
C                  *  SUBROUTINE PACKAGE DPWA  *
C                  *****************************
C
C
C                                          Francesc Salvat.
C                                          Universitat de Barcelona.
C                                          July 19, 2003
C
C
C     Dirac Partial Wave Analysis for elastic scattering of electrons
C  and positrons by Coulomb fields with short-range central
C  modifications. The radial Dirac equation is solved by using
C  subroutines taken from the RADIAL FORTRAN package described in the
C  reference
C    F. Salvat, J. M. Fernandez-Varea and W. Williamson, Jr.
C       Comput. Phys. Commun. 90 (1995) 151.
C    with modifications by F. Salvat et al. (internal report,
C       University of Barcelona, 2001).
C
C     The calling sequence from the main program is:
C
C****   CALL DPWA0(EV,NDELTA,ISCH)
C
C    This subroutine determines the phase shifts. It acts as the
C  initialization routine for the evaluation of scattering amplitudes
C  and differential cross sections.
C
C****   CALL DPWA(TH,CF,CG,DCS,SPL,ERRF,ERRG)
C
C    Subroutine DPWA gives elastic scattering functions at the
C  scattering angle TH obtained from the phase shifts calculated
C  previously by subroutine DPWA0.
C
C
C            ****  All I/O energies and lengths in eV and cm, resp.
C
C  *********************************************************************
C                      SUBROUTINE DPWA0
C  *********************************************************************
      SUBROUTINE DPWA0(EV,NDELTA,ISCH)
C
C     This subroutine computes Dirac phase shifts, differential cross
C  sections and scattering amplitudes for elastic scattering of
C  electrons in central fields.
C
C  Input arguments:
C     EV ....... effective kinetic energy of the projectile (eV).
C     NDELTA ... number of required phase shifts (LT.25000).
C     ISCH ..... =1: all phase shifts are computed by solving the radial
C                    equation.
C                =2: only phase shifts of selected orders are computed
C                    from the solution of the radial equation, the
C                    others are obtained by lin-log natural cubic spline
C                    interpolation. For high energies, ISCH=2 leads to a
C                    considerable reduction of the calculation time.
C
C  Input (through the common block /FIELD/):
C     R(I) .... radial grid points (radii in increasing order). The
C               first point in the grid must be the origin, i.e. R(1)=0.
C               Repeated values are interpreted as discontinuities.
C     RV(I).... R(I) times the potential energy at R=R(I). The last
C               component, RV(NP), is assumed to be equal to the
C               asymptotic value.
C     NP ...... number of input grid points.
C
C *** NOTE: The radii and potential values, R(I) and RV(I), are in
C           atomic units.
C
C  Output (through the common block /DCSTAB/):
C     ECS ........ total cross section (cm**2)
C                    (only for finite range fields).
C     TCS1 ....... 1st transport cross section (cm**2)
C                    (only for finite range fields).
C     TCS2 ....... 2nd transport cross section (cm**2)
C                    (only for finite range fields).
C     TH(I) ...... scattering angles (in deg)
C     XT(I) ...... values of (1-COS(TH(I)))/2.0D0.
C     DCST(I) .... differential cross section per unit solid angle at
C                    TH(I) (cm**2/sr).
C     ERROR(I) ... estimated relative uncertainty of the computed DCS
C                    value.
C     NTAB ....... number of angles in the table.
C
C  NOTE: The values of ECS, TCS1 and TCS2 are computed from the DCS
C  table. This introduces a certain error (of the order of 0.01 per
C  cent) but ensures consistency of multiple scattering simulations
C  using the DCS table.
C
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1   INTEGER*4 (I-N)
      PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
      PARAMETER (HREV=27.21138602D0)  ! Hartree energy (eV)
      PARAMETER (A0B2=A0B*A0B)
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (PI=3.1415926535897932D0,FOURPI=4.0D0*PI)
C  ****  Input-output.
      PARAMETER (NDIM=1000)
      COMMON/FIELD/R(NDIM),RV(NDIM),NP
      PARAMETER (NGT=650)
      COMMON/DCSTAB/ECS,TCS1,TCS2,TH(NGT),XT(NGT),DCST(NGT),DCSTLAB(NGT),SPOL(NGT),
     1              ERROR(NGT),NTAB,THLAB(NGT)
C  ****  Link with the RADIAL package.
      PARAMETER (NPPG=NDIM+1,NPTG=NDIM+NPPG)
      COMMON/RGRID/RRR(NPTG),P(NPTG),Q(NPTG),INDD(NPTG),NRT
      COMMON/VGRID/RG(NPPG),RVG(NPPG),VA(NPPG),VB(NPPG),VC(NPPG),
     1             VD(NPPG),NVT
C  ****  Phase shifts and partial wave series coefficients.
      PARAMETER (NPC=1500,NDM=25000)
      DIMENSION DPI(NDM),DMI(NDM)
      COMMON/PHASES/DP(NDM),DM(NDM),NPH,ISUMP
      COMMON/WORK/XL(NDM),SA(NDM),SB(NDM),SC(NDM),SD(NDM),P1(NDM)
      COMMON/CSA/CFL(NDM),CGL(NDM),CFM(NDM),CGM(NDM),NPHM,IZINF
      COMMON/CRMORU/CFMC(NPC),CGMC(NPC),DPC(NPC),DMC(NPC),
     1              CFC,CGC,RUTHC,WATSC,RK2,ERRFC,ERRGC,NPC1
C
      CI=DCMPLX(0.0D0,1.0D0)
      ISUMP=0
C
      OPEN(UNIT=98,FILE='dpwa.dat')
      WRITE(98,2000)
 2000 FORMAT(//2X,'**** PARTIAL WAVE ANALYSIS (DPWA0) ',
     1  42('*')/)
C
      NDELT=NDELTA
      IF(NDELT.GT.NDM) THEN
        WRITE(98,2001)
 2001   FORMAT(/2X,'WARNING: NDELTA IS TOO LARGE')
        NDELT=NDM
      ENDIF
      IF(NDELT.LT.6) NDELT=6
      EPS=1.0D-14
      EPSCUT=1.0D-9
C
      E=EV/HREV
C
C  ****  Initialization of the RADIAL package.
C
      CALL VINT(R,RV,NP)
      ZINF=RVG(NVT)
      IF(DABS(ZINF).GT.1.0D-10) THEN
        IZINF=1
        CALL DPWAC0(ZINF,EV)
        IF(NDELT.GT.8000) NDELT=8000
      ELSE
        IZINF=0
      ENDIF
      DO I=1,NVT
        RRR(I)=RG(I)
        INDD(I)=I
      ENDDO
      NRT=NVT
C
      WRITE(98,2002) EV
 2002 FORMAT(/2X,'KINETIC ENERGY =',1P,E12.5,' eV')
      IF(E.LT.0.0D0) THEN
        WRITE(98,2003)
        WRITE(6,2003)
 2003   FORMAT(//2X,'NEGATIVE ENERGY. STOP.')
        STOP
      ENDIF
      RK=DSQRT(E*(E+2.0D0*SL*SL))/SL
C
      IF(IZINF.EQ.1) WRITE(98,2004)
 2004 FORMAT(/2X,'ONLY INNER PHASE SHIFTS ARE TABULATED')
      WRITE(98,2005)
 2005 FORMAT(/6X,'L',7X,'PHASE(SPIN UP)',5X,'PHASE(SPIN DOWN)',
     1       /2X,47('-'))
      ISCH0=ISCH
      IF(ISCH0.EQ.2.AND.EV.GT.1000.0D0) GO TO 1
C
C  ****  ISCH0=1, all phase shifts are computed by solving the radial
C        equation.
C
      L=0
      CALL DPHASE(E,EPS,PHP,-1,IER)
      IF(IER.NE.0) STOP
      PHM=0.0D0
      WRITE(98,2006) L,PHP,PHM
      WRITE(6,2006) L,PHP,PHM
 2006 FORMAT(3X,I5,4X,1P,E16.8,4X,E16.8)
      DP(1)=PHP
      DM(1)=0.0D0
C
      IFIRST=2
   33 CONTINUE
      ISUMP=1
      TST=0.0D0
      DO I=IFIRST,NDELT
        L=I-1
        CALL DPHASE(E,EPS,PHP,-L-1,IER)
        IF(IER.NE.0) STOP
        CALL DPHASE(E,EPS,PHM,L,IER)
        IF(IER.NE.0) STOP
        DP(I)=PHP
        DM(I)=PHM
        TST=DMAX1(DABS(PHP),DABS(PHM),DABS(DP(I-1)))
        NPH=I
        WRITE(98,2006) L,PHP,PHM
        WRITE(6,2006) L,PHP,PHM
        IF(TST.LT.EPSCUT.AND.L.GT.10) GO TO 6
C  ****  When the last phase shift (spin up) differs in more than 20 per
C  cent from the quadratic extrapolation, accumulated roundoff errors
C  may be important and the calculation of phase shifts is discontinued.
        IF(I.GT.500) THEN
          DPEXT=DP(I-3)+3.0D0*(DP(I-1)-DP(I-2))
          DPMAX=MAX(ABS(DP(I-3)),ABS(DP(I-2)),ABS(DP(I-1)),ABS(DP(I)))
          IF(ABS(DP(I)-DPEXT).GT.0.20D0*DPMAX) THEN
            NPH=I-1
            WRITE(98,2107)
            WRITE(6,2107)
 2107 FORMAT(/2X,'WARNING: Possible accumulation of round-off errors.')
            GO TO 6
          ENDIF
        ENDIF
      ENDDO
      WRITE(98,2007) TST
      WRITE(6,2007) TST
 2007 FORMAT(/2X,'WARNING: TST =',1P,E11.4,'. CHECK CONVERGENCE.')
      GO TO 6
C
C  ****  ISCH0=2, only inner phase shifts of orders L in a given grid
C        are computed from the solution of the radial equation. Phase
C        shifts of orders not included in this grid are obtained by
C        lin-log cubic spline interpolation.
C          The adopted grid is: 0(1)100(5)300(10) ...
C
C        This is a somewhat risky procedure, which is based on the
C        observed variation of the calculated phase shifts with L for
C        atomic scattering fields. When a change of sign is found, all
C        the phases are recalculated.
C
    1 L=0
      CALL DPHASE(E,EPS,PHP,-1,IER)
      IF(IER.NE.0) STOP
      PHM=0.0D0
      WRITE(98,2006) L,PHP,PHM
      WRITE(6,2006) L,PHP,PHM
      DP(1)=PHP
      DM(1)=0.0D0
C
      LMAX=NDELT-1
      IND=0
      IADD=1
      LPP=1
    2 L=LPP
      CALL DPHASE(E,EPS,PHP,-L-1,IER)
      IF(IER.NE.0) STOP
      CALL DPHASE(E,EPS,PHM,L,IER)
      IF(IER.NE.0) STOP
      WRITE(6,2006) L,PHP,PHM
C
      DP(L+1)=PHP
      DM(L+1)=PHM
C
      IF(L.LT.95) THEN
        WRITE(98,2006) L,PHP,PHM
      ELSE
        IF(DMAX1(DABS(PHP),DABS(PHM)).LT.EPSCUT) GO TO 3
        IND=IND+1
        XL(IND)=L
        DPI(IND)=PHP
        DMI(IND)=PHM
        IF(IND.GT.1) THEN
          S1=SIGN(PI,DPI(IND))
          S0=SIGN(PI,DPI(IND-1))
          IF(S1*S0.LT.0.0D0.AND.L.LT.500) THEN
            IF(DABS(DPI(IND-1)).LT.1.0D-6.AND.L.GT.300) THEN
              IND=IND-1
              L=XL(IND)+0.5D0
              GO TO 3
            ENDIF
            ISCH0=1
            IFIRST=MIN(L,94)
            GO TO 33
          ENDIF
          S1=SIGN(PI,DMI(IND))
          S0=SIGN(PI,DMI(IND-1))
          IF(S1*S0.LT.0.0D0.AND.L.LT.500) THEN
            IF(DABS(DMI(IND-1)).LT.1.0D-6.AND.L.GT.300) THEN
              IND=IND-1
              L=XL(IND)+0.5D0
              GO TO 3
            ENDIF
            ISCH0=1
            IFIRST=MIN(L,94)
            GO TO 33
          ENDIF
        ENDIF
        IF(L.GT.500.AND.DABS(DPI(IND-1)).LT.1.0D-5) THEN
          I=IND
          DPEXT=DPI(I-3)+3.0D0*(DPI(I-1)-DPI(I-2))
          DPMAX=MAX(ABS(DPI(I-3)),ABS(DPI(I-2)),ABS(DPI(I-1)),
     1          ABS(DPI(I)))
          IF(ABS(DPI(I)-DPEXT).GT.0.20D0*DPMAX) THEN
            IND=I-1
            WRITE(98,2107)
            WRITE(6,2107)
            GO TO 3
          ENDIF
          DMEXT=DMI(I-3)+3.0D0*(DMI(I-1)-DMI(I-2))
          DMMAX=MAX(ABS(DMI(I-3)),ABS(DMI(I-2)),ABS(DMI(I-1)),
     1          ABS(DMI(I)))
          IF(ABS(DMI(I)-DMEXT).GT.0.20D0*DMMAX) THEN
            IND=I-1
            WRITE(98,2107)
            WRITE(6,2107)
            GO TO 3
          ENDIF
        ENDIF
      ENDIF
      TST=DMAX1(DABS(PHP),DABS(PHM))
      IF(TST.LT.EPSCUT.AND.L.GT.3) GO TO 3
      IF(L.GE.LMAX) GO TO 3
C
      IF(L.GT.99) IADD=5
      IF(L.GT.299) IADD=10
      IF(L.GT.599) IADD=20
      IF(L.GT.1199) IADD=50
      IF(L.GT.2999) IADD=100
      IF(L.GT.9999) IADD=250
      LPP=L+IADD
      IF(LPP.GT.LMAX) LPP=LMAX
      GO TO 2
C
C  ****  Check consistency of sparsely tabulated phase shifts.
C        A discontinuity larger than 0.25*PI is considered as
C        a symptom of numerical inconsistencies.
C
    3 CONTINUE
      NPH=L+1
      TST=0.0D0
      DO I=1,IND
        WRITE(98,2008) INT(XL(I)+0.5D0),DPI(I),DMI(I)
 2008   FORMAT(3X,I5,4X,1P,E16.8,4X,E16.8,'  i')
        IF(I.GT.1) THEN
          TST=MAX(TST,DABS(DPI(I)-DPI(I-1)),DABS(DMI(I)-DMI(I-1)))
        ENDIF
      ENDDO
      IF(IND.LT.4) GO TO 6
      IF(TST.GT.0.25D0*PI) THEN
        WRITE(98,2009)
        WRITE(6,2009)
 2009   FORMAT(/2X,'ERROR: DIRECTLY COMPUTED PHASE SHIFTS SHOW',
     1    ' LARGE DISCONTINUITIES.')
        STOP
      ENDIF
C
C  ****  Interpolated phase shifts (lin-log cubic spline).
C
      IF(DPI(IND).GT.0.0D0) THEN
        ITRAN=+1.0D0
      ELSE
        ITRAN=-1.0D0
      ENDIF
      DO I=1,IND
        DPI(I)=DLOG(DABS(DPI(I)))
      ENDDO
      CALL SPLINE(XL,DPI,SA,SB,SC,SD,0.0D0,0.0D0,IND)
      DO 4 I=2,NPH
        L=I-1
        IF(L.LT.95) GO TO 4
        RL=L
        CALL FINDI(XL,RL,IND,J)
        DP(I)=SA(J)+RL*(SB(J)+RL*(SC(J)+RL*SD(J)))
        DP(I)=ITRAN*DEXP(DP(I))
    4 CONTINUE
C
      IF(DMI(IND).GT.0.0D0) THEN
        ITRAN=+1.0D0
      ELSE
        ITRAN=-1.0D0
      ENDIF
      DO I=1,IND
        DMI(I)=DLOG(DABS(DMI(I)))
      ENDDO
      CALL SPLINE(XL,DMI,SA,SB,SC,SD,0.0D0,0.0D0,IND)
      DO 5 I=2,NPH
        L=I-1
        IF(L.LT.95) GO TO 5
        RL=L
        CALL FINDI(XL,RL,IND,J)
        DM(I)=SA(J)+RL*(SB(J)+RL*(SC(J)+RL*SD(J)))
        IF(ITRAN.NE.0) DM(I)=ITRAN*DEXP(DM(I))
    5 CONTINUE
      TST=DMAX1(DABS(DP(NPH)),DABS(DM(NPH)))
      IF(TST.GT.10.0D0*EPSCUT) THEN
        WRITE(98,2007) TST
        WRITE(6,2007) TST
      ENDIF
C
C  ************  Coefficients in the partial-wave expansion.
C
    6 CONTINUE
      CFACT=1.0D0/(2.0D0*CI*RK)
      IF(IZINF.EQ.1) THEN
        CXP=CDEXP(2.0D0*CI*DP(1))
        CXPC=CDEXP(2.0D0*CI*DPC(1))
        CFL(1)=CXPC*(CXP-1)*CFACT
        CGL(1)=0.0D0
        DO I=2,NPH
          L=I-1
          CXP=CDEXP(2.0D0*CI*DP(I))
          CXM=CDEXP(2.0D0*CI*DM(I))
          CXPC=CDEXP(2.0D0*CI*DPC(I))
          CXMC=CDEXP(2.0D0*CI*DMC(I))
          CFL(I)=((L+1)*CXPC*(CXP-1)+L*CXMC*(CXM-1))*CFACT
          CGL(I)=(CXMC*(CXM-1)-CXPC*(CXP-1))*CFACT
        ENDDO
      ELSE
        CXP=CDEXP(2*CI*DP(1))
        CFL(1)=(CXP-1.0D0)*CFACT
        CGL(1)=0.0D0
        DO I=2,NPH
          L=I-1
          CXP=CDEXP(2.0D0*CI*DP(I))
          CXM=CDEXP(2.0D0*CI*DM(I))
          CFL(I)=((L+1)*(CXP-1)+L*(CXM-1))*CFACT
          CGL(I)=CXM*(1.0D0-CDEXP(2.0D0*CI*(DP(I)-DM(I))))*CFACT
        ENDDO
      ENDIF
C
C  ****  Reduced series (two iterations).
C
      IF(NPH.GE.250.AND.ISUMP.EQ.0) THEN
        DO I=1,NPH
          CFM(I)=CFL(I)
          CGM(I)=CGL(I)
        ENDDO
C
        NPHM=NPH
        DO 7 NTR=1,2
          NPHM=NPHM-1
          CFC=0.0D0
          CFP=CFM(1)
          CGC=0.0D0
          CGP=CGM(1)
          DO I=1,NPHM
            RL=I-1
            CFA=CFC
            CFC=CFP
            CFP=CFM(I+1)
            CFM(I)=CFC-CFP*(RL+1)/(RL+RL+3)-CFA*RL/(RL+RL-1)
            CGA=CGC
            CGC=CGP
            CGP=CGM(I+1)
            CGM(I)=CGC-CGP*(RL+2)/(RL+RL+3)-CGA*(RL-1)/(RL+RL-1)
          ENDDO
    7   CONTINUE
      ENDIF
C
C  ****  Scattering amplitudes and DCS.
C
      WRITE(98,2010)
 2010 FORMAT(//2X,'*** SCATTERING AMPLITUDES AND DIFFERENT',
     1  'IAL CROSS SECTION ***')
      WRITE(98,2011)
 2011 FORMAT(/4X,'ANGLE',6X,'DCS',7X,'ASYMMETRY',4X,'DIRECT AMPLITU',
     1  'DE',7X,'SPIN-FLIP AMPLITUDE',5X,'ERROR',/4X,'(deg)',3X,
     2  '(cm**2/sr)',22X,'(cm)',20X,'(cm)',/2X,91('-'))
C
C  ****  Angular grid (TH in deg).
C
      TH(1)=0.0D0
      TH(2)=1.0D-4
      I=2
   10 CONTINUE
      I=I+1
      IF(TH(I-1).LT.0.9999D-3) THEN
        TH(I)=TH(I-1)+2.5D-5
      ELSE IF(TH(I-1).LT.0.9999D-2) THEN
        TH(I)=TH(I-1)+2.5D-4
      ELSE IF(TH(I-1).LT.0.9999D-1) THEN
        TH(I)=TH(I-1)+2.5D-3
      ELSE IF(TH(I-1).LT.0.9999D+0) THEN
        TH(I)=TH(I-1)+2.5D-2
      ELSE IF(TH(I-1).LT.0.9999D+1) THEN
        TH(I)=TH(I-1)+1.0D-1
      ELSE IF(TH(I-1).LT.2.4999D+1) THEN
        TH(I)=TH(I-1)+2.5D-1
      ELSE
        TH(I)=TH(I-1)+5.0D-1
      ENDIF
      IF(I.GT.NGT) STOP 'DPWA0. The NGT parameter is too small.'
      IF(TH(I).LT.180.0D0) GO TO 10
      NTAB=I
C
      DO I=1,NTAB
        THR=TH(I)*PI/180.0D0
        XT(I)=(1.0D0-DCOS(THR))/2.0D0
        CALL DPWA(THR,CF,CG,DCS,SPL,ERRF,ERRG)
        IF(DMAX1(ERRF,ERRG).GT.0.95D0) THEN
          ERR=1.0D0
        ELSE
          ACF=CDABS(CF)**2
          ACG=CDABS(CG)**2
          ERR=2.0D0*(ACF*ERRF+ACG*ERRG)/DMAX1(DCS,1.0D-45)
        ENDIF
        DCST(I)=DCS
        ERROR(I)=DMAX1(ERR,1.0D-7)
        SPOL(I)=SPL
        WRITE(98,2012) TH(I),DCST(I),SPOL(I),CF,CG,ERROR(I)
 2012   FORMAT(1X,1P,E10.3,E12.5,1X,E10.3,2(1X,'(',E10.3,',',
     1    E10.3,')'),E10.2)
      ENDDO
C
C  ************  Total and momentum transfer cross sections.
C                Convergence test (only for finite range fields).
C
      IF(IZINF.EQ.0) THEN
        INC=5
        IF(ISUMP.EQ.1) INC=1
        TST1=0.0D0
        TST2=0.0D0
        ECS=4.0D0*PI*CFL(1)*DCONJG(CFL(1))
        TCS=0.0D0
        ECSO=ECS
        TCSO=TCS
        DO I=2,NPH
          L=I-1
          RL=L
          DECS=CFL(I)*DCONJG(CFL(I))+RL*(L+1)*CGL(I)*DCONJG(CGL(I))
          DECS=4.0D0*PI*DECS/(L+L+1)
          DTCS=CFL(L)*DCONJG(CFL(I))+DCONJG(CFL(L))*CFL(I)
     1        +(L-1)*(RL+1)*(CGL(L)*DCONJG(CGL(I))
     2        +DCONJG(CGL(L))*CGL(I))
          DTCS=4.0D0*PI*DTCS*L/((RL+L-1)*(L+L+1))
          ECS=ECS+DECS
          TCS=TCS+DTCS
C  ****  Convergence test.
          ITW=L-(L/INC)*INC
          IF(ITW.EQ.0) THEN
            TST1=DABS(ECS-ECSO)/(DABS(ECS)+1.0D-35)
            TST2=DABS(TCS-TCSO)/(DABS(TCS)+1.0D-35)
            ECSO=ECS
            TCSO=TCS
          ENDIF
        ENDDO
        TST=DMAX1(TST1,TST2)
        TCS=ECS-TCS
        IF(TST.GT.1.0D-5.AND.NPH.GT.40) THEN
          WRITE(98,2007) TST
          WRITE(6,2007) TST
        ENDIF
        ECS=ECS*A0B2
        TCS=TCS*A0B2
C
C  ****  ECS and TCSs are evaluated from the DCS table.
C
        ECS0=FOURPI*RMOM(XT,DCST,NTAB,0)
        ECS1=FOURPI*RMOM(XT,DCST,NTAB,1)
        ECS2=FOURPI*RMOM(XT,DCST,NTAB,2)
        TST1=DABS(ECS-ECS0)/(DABS(ECS)+1.0D-35)
        WRITE(98,2013) ECS,ECS0,TST1
        WRITE(6,2013) ECS,ECS0,TST1
 2013   FORMAT(/2X,'TOTAL ELASTIC CROSS SECTION =',1P,E13.6,' cm**2',
     1         /2X,'             FROM DCS TABLE =',E13.6,
     2         '  (REL. DIF. =',E9.2,')')
        TCS1=2.0D0*ECS1
        TCS2=6.0D0*(ECS1-ECS2)
        TST2=DABS(TCS-TCS1)/(DABS(TCS)+1.0D-35)
        WRITE(98,2014) TCS,TCS1,TST2
        WRITE(6,2014) TCS,TCS1,TST2
 2014   FORMAT(/2X,'1ST TRANSPORT CROSS SECTION =',1P,E13.6,' cm**2',
     1         /2X,'             FROM DCS TABLE =',E13.6,
     2         '  (REL. DIF. =',E9.2,')')
        WRITE(98,2015) TCS2
        WRITE(6,2015) TCS2
 2015   FORMAT(/2X,'2ND TRANSPORT CROSS SECTION =',1P,E13.6,' cm**2')
        TST=DMAX1(TST1,TST2)
        IF(TST.GT.2.0D-3) THEN
          WRITE(98,2016)
          WRITE(6,2016)
        ENDIF
      ENDIF
 2016 FORMAT(/2X,'WARNING: RELATIVE DIFFERENCES ARE TOO LARGE.',
     1       /11X,'THE DCS TABLE IS NOT CONSISTENT.')
C
      WRITE(98,2017)
 2017 FORMAT(/2X,'**** DPWA0 ENDED ',60('*')/)
      CLOSE(UNIT=98)
C
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE DPWA
C  *********************************************************************
      SUBROUTINE DPWA(TH,CF,CG,DCS,SPL,ERRF,ERRG)
C
C    This subroutine gives various elastic scattering functions at the
C  scattering angle TH (in radians) computed from Dirac phase shifts.
C  It should be previously initialized by calling subroutine DPWA0.
C
C  Input argument:
C     TH ....... scattering angle (in rad)
C
C  Output arguments:
C     CF ....... F scattering amplitude (cm).
C     CG ....... G scattering amplitude (cm).
C     DCS ...... differential cross section per unit solid angle for
C                unpolarized beams.
C     SPL ...... asymmetry function.
C     ERRF ..... relative uncertainty of CF.
C     ERRG ..... relative uncertainty of CG.
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z),COMPLEX*16 (C),
     1   INTEGER*4 (I-N)
      PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
      PARAMETER (HREV=27.21138602D0)  ! Hartree energy (eV)
      PARAMETER (A0B2=A0B*A0B)
      PARAMETER (NDM=25000,NPC=1500,TOL=5.0D-8)
C  ****  Phase shifts and partial wave series coefficients.
      COMMON/PHASES/DP(NDM),DM(NDM),NPH,ISUMP
      COMMON/CSA/CFL(NDM),CGL(NDM),CFM(NDM),CGM(NDM),NPHM,IZINF
      COMMON/CRMORU/CFMC(NPC),CGMC(NPC),DPC(NPC),DMC(NPC),
     1              CFC,CGC,RUTHC,WATSC,RK2,ERRFC,ERRGC,NPC1
C
      X=DCOS(TH)
      Y=DSIN(TH)
      TST=1.0D35
C
C  ************  Reduced series method. Only when TH is greater
C                than 1.0 deg and NPH.ge.250.
C
      IF(TH.LT.1.74D-2.OR.NPH.LT.250.OR.ISUMP.EQ.1) THEN
        CFO=0.0D0
        CGO=0.0D0
        ERRFO=1.0D10
        ERRGO=1.0D10
        GO TO 10
      ENDIF
      FACT=1.0D0/(1.0D0-X)**2
C
C  ****  F scattering amplitude.
C
      P2=1.0D0
      P3=X
      CFS=CFM(1)
      CFSO=CFS
      CFS=CFS+CFM(2)*P3
      DO I=3,NPHM
        L=I-1
        P1=P2
        P2=P3
        P3=((L+L-1)*X*P2-(L-1)*P1)/L
        CTERM=CFM(I)*P3
        CFS=CFS+CTERM
C  ****  Convergence test.
        IF(L.LT.149) THEN
          INC=1
        ELSE IF(L.LT.999) THEN
          INC=5
        ELSE
          INC=25
        ENDIF
        ITW=L-(L/INC)*INC
        IF(ITW.EQ.0) THEN
          TST=CDABS(CFS-CFSO)/DMAX1(CDABS(CFS),1.0D-45)
          CFSO=CFS
        ENDIF
      ENDDO
      CF=FACT*CFS
      ERRF=TST
C
C  ****  G scattering amplitude.
C
      IF(Y.LT.1.0D-30) THEN
        CG=0.0D0
        ERRG=0.0D0
      ELSE
        P2=1.0D0
        P3=3*X
        CGS=CGM(2)
        CGSO=CGS
        CGS=CGS+CGM(3)*P3
        DO I=4,NPHM
          L=I-1
          P1=P2
          P2=P3
          P3=((L+L-1)*X*P2-L*P1)/(L-1)
          CTERM=CGM(I)*P3
          CGS=CGS+CTERM
C  ****  Convergence test.
          IF(L.LT.149) THEN
            INC=1
          ELSE IF(L.LT.999) THEN
            INC=5
          ELSE
            INC=25
          ENDIF
          ITW=L-(L/INC)*INC
          IF(ITW.EQ.0) THEN
            TST=CDABS(CGS-CGSO)/DMAX1(CDABS(CGS),1.0D-45)
            CGSO=CGS
          ENDIF
        ENDDO
        CG=FACT*Y*CGS
        ERRG=TST
      ENDIF
C
      IF(ERRF.LT.TOL.AND.ERRG.LT.TOL) GO TO 20
      CFO=CF
      ERRFO=ERRF
      CGO=CG
      ERRGO=ERRG
C
C  ************  TH smaller than 1.0 deg or NPH.LT.250 or ISUMP=1.
C
   10 CONTINUE
C  ****  If IZINF=1, scattering functions are calculated only for
C        TH larger than 0.5 deg.
      IF(IZINF.EQ.1.AND.TH.LT.0.008726D0) THEN
        CF=0.0D0
        CG=0.0D0
        ERRF=1.0D0
        ERRG=1.0D0
        DCS=1.0D-45
        SPL=0.0D0
        RETURN
      ENDIF
C
C  ****  F scattering amplitude.
C
      P2=1.0D0
      P3=X
      CFS=CFL(1)
      CFSO=CFS
      CFS=CFS+CFL(2)*P3
      DO I=3,NPH
        L=I-1
        P1=P2
        P2=P3
        P3=((L+L-1)*X*P2-(L-1)*P1)/L
        CTERM=CFL(I)*P3
        CFS=CFS+CTERM
C  ****  Convergence test.
        IF(L.LT.149) THEN
          INC=1
        ELSE IF(L.LT.999) THEN
          INC=5
        ELSE
          INC=25
        ENDIF
        ITW=L-(L/INC)*INC
        IF(ITW.EQ.0) THEN
          TST=CDABS(CFS-CFSO)/DMAX1(CDABS(CFS),1.0D-45)
          CFSO=CFS
        ENDIF
      ENDDO
      CF=CFS
      ERRF=TST
C
C  ****  G scattering amplitude.
C
      IF(Y.LT.1.0D-30) THEN
        CG=0.0D0
        ERRG=0.0D0
      ELSE
        P2=1.0D0
        P3=3*X
        CGS=CGL(2)
        CGSO=CGS
        CGS=CGS+CGL(3)*P3
        DO I=4,NPH
          L=I-1
          P1=P2
          P2=P3
          P3=((L+L-1)*X*P2-L*P1)/(L-1)
          CTERM=CGL(I)*P3
          CGS=CGS+CTERM
C  ****  Convergence test.
          IF(L.LT.149) THEN
            INC=1
          ELSE IF(L.LT.999) THEN
            INC=5
          ELSE
            INC=25
          ENDIF
          ITW=L-(L/INC)*INC
          IF(ITW.EQ.0) THEN
            TST=CDABS(CGS-CGSO)/DMAX1(CDABS(CGS),1.0D-45)
            CGSO=CGS
          ENDIF
        ENDDO
        CG=Y*CGS
        ERRG=TST
      ENDIF
C  ****  The following four sentences are introduced to prevent abnormal
C        termination of the calculation when the number of (inner) phase
C        shifts is small. This solves the problem found by M. Berger.
      IF(NPH.LT.20.AND.CDABS(CTERM).LT.TOL) THEN
        ERRF=0.0D0
        ERRG=0.0D0
      ENDIF
C
C  ****  Select the most accurate method.
C
      IF(ERRFO.LT.ERRF) THEN
        CF=CFO
        ERRF=ERRFO
      ENDIF
      IF(ERRGO.LT.ERRG) THEN
        CG=CGO
        ERRG=ERRGO
      ENDIF
C
C  ****  Differential cross section (unpolarized beam).
C
   20 CONTINUE
      CF=CF*A0B
      CG=CG*A0B
      IF(IZINF.EQ.1) THEN
        XAUX=DPWAC(TH)
        CFC=CFC*A0B
        CGC=CGC*A0B
        DCSM=CDABS(CFC)**2+CDABS(CGC)**2
        CF=CF+CFC
        CG=CG+CGC
        ACF=CDABS(CF)**2
        ACG=CDABS(CG)**2
        DCS=ACF+ACG
C  ****  Scattering amplitudes that are much smaller than the Coulomb
C        ones may not be correct due to rounding off.
C        (Modified Coulomb fields only).
        IF(DCS.LT.1.0D-10*DCSM.OR.ERRFC+ERRGC.GT.1.0D0.OR.
     1    TH.LT.1.74D-2) THEN
          CF=0.0D0
          CG=0.0D0
          ERRF=1.0D0
          ERRG=1.0D0
          DCS=1.0D-45
          SPL=0.0D0
          RETURN
        ENDIF
        ERRF=ERRF+ERRFC
        ERRG=ERRG+ERRGC
      ELSE
        ACF=CDABS(CF)**2
        ACG=CDABS(CG)**2
        DCS=ACF+ACG
      ENDIF
C
      ERR=2.0D0*(ACF*ERRF+ACG*ERRG)/DMAX1(DCS,1.0D-45)
      IF(ERR.GT.0.10D0) THEN
        CF=0.0D0
        CG=0.0D0
        ERRF=1.0D0
        ERRG=1.0D0
        DCS=1.0D-45
        SPL=0.0D0
        RETURN
      ENDIF
C
C  ****  Asymmetry function.
C
      CSPL1=DCMPLX(0.0D0,1.0D0)*CF*DCONJG(CG)
      CSPL2=DCMPLX(0.0D0,1.0D0)*CG*DCONJG(CF)
      TST=CDABS(CSPL1-CSPL2)/DMAX1(CDABS(CSPL1),1.0D-45)
      !IF(TST.GT.1.0D-3.AND.ERR.LT.0.01D0) THEN
        SPL=(CSPL1-CSPL2)/DCS
      !ELSE
      !  SPL=0.0D0
      !ENDIF
      RETURN
      END
C  *********************************************************************
C                         SUBROUTINE DPHASE
C  *********************************************************************
      SUBROUTINE DPHASE(E,EPS,PHASE,K,IER)
C
C     This subroutine computes Dirac phase shifts.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER (NDIM=1000,NPPG=NDIM+1,NPTG=NDIM+NPPG)
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (PI=3.1415926535897932D0,PIH=0.5D0*PI)
      COMMON/RGRID/RT(NPTG),P(NPTG),Q(NPTG),IND(NPTG),NRT
      COMMON/VGRID/R(NPPG),RV(NPPG),VA(NPPG),VB(NPPG),VC(NPPG),
     1             VD(NPPG),NVT
      COMMON/STORE/PA(NPTG),QA(NPTG),PB(NPTG),QB(NPTG),D(NPTG)
      EXTERNAL BESJN
C
      IER=0
      IF(K.EQ.0) THEN
        WRITE(6,2001)
 2001   FORMAT(1X,'*** ERROR IN DPHASE: K.EQ.0.')
        STOP
      ENDIF
C
      IF(E.LE.0.0D0) THEN
        IER=7
        WRITE(6,2002)
 2002   FORMAT(1X,'*** ERROR 7  (IN DPHASE): E.LE.0.')
        RETURN
      ENDIF
      EPSCUT=1.0D-9
C  ****  Orbital angular momentum quantum number.
      IF(K.LT.0) THEN
        L=-K-1
        KSIGN=1
      ELSE
        L=K
        KSIGN=-1
      ENDIF
      FL1=0.5D0*L*(L+1)
      RK=DSQRT(E*(E+2.0D0*SL*SL))/SL
C
C  ****  Asymptotic solution.
C
      ZINF=RV(NVT)
      IF(DABS(ZINF).LT.EPS) THEN
C  ****  Finite range fields.
        FACTOR=DSQRT(E/(E+2.0D0*SL*SL))
        ILAST=NRT+1
        DO I=4,NRT
          IL=ILAST-1
          RN=R(IL)
          INJ=IND(IL)
          RVN=VA(INJ)+RN*(VB(INJ)+RN*(VC(INJ)+RN*VD(INJ)))
          T=EPS*RN*DABS(E*RN-FL1/RN)
          X=RK*RN
          IF(DABS(RVN).GT.T) GO TO 1
          BNL=BESJN(2,L,X)
          IF(DABS(BNL).GT.100.0D0) GO TO 1
          BNL1=BESJN(2,L+KSIGN,X)
          IF(DABS(BNL1).GT.100.0D0) GO TO 1
          BJL=BESJN(1,L,X)
          BJL1=BESJN(1,L+KSIGN,X)
          ILAST=IL
          PA(ILAST)=X*BJL
          PB(ILAST)=-X*BNL
          QA(ILAST)=-FACTOR*KSIGN*X*BJL1
          QB(ILAST)=FACTOR*KSIGN*X*BNL1
        ENDDO
    1   CONTINUE
        IF(ILAST.EQ.NRT+1) THEN
          IER=8
          WRITE(6,2003)
 2003   FORMAT(1X,'*** ERROR 8  (IN DPHASE): RAD(NGP) TOO SMALL.'
     1  /5X,'(EXTEND THE GRID TO LARGER RADII).')
          RETURN
        ENDIF
      ELSE
C  ****  Coulomb fields.
        TAS=DMAX1(1.0D-11,EPS)*DABS(ZINF)
        ILAST=NRT+1
        DO I=4,NRT
          IL=ILAST-1
          RN=R(IL)
          INJ=IND(IL)
          RVN=VA(INJ)+RN*(VB(INJ)+RN*(VC(INJ)+RN*VD(INJ)))
          IF(DABS(RVN-ZINF).GT.TAS) GO TO 2
          CALL DCOUL(ZINF,E,K,RN,P0,Q0,P1,Q1,ERR)
          IF(ERR.GT.EPSCUT.OR.DABS(P1).GT.100.0D0) GO TO 2
          ILAST=IL
          PA(ILAST)=P0
          PB(ILAST)=P1
          QA(ILAST)=Q0
          QB(ILAST)=Q1
        ENDDO
    2   CONTINUE
        IF(ILAST.EQ.NRT+1) THEN
          IER=8
          WRITE(6,2003)
          RETURN
        ENDIF
      ENDIF
C
C  ****  Outward solution of the radial equation.
C
      CALL DOUTW(E,EPS,K,1,NZERO,ILAST)
C
C  ****  Phase shift.
C
      RM=R(ILAST)
      IL=IND(ILAST-1)
      VF=VA(IL)/RM+VB(IL)+RM*(VC(IL)+RM*VD(IL))
      FG=(E-VF+2.0D0*SL*SL)/SL
      PO=P(ILAST)
      POP=-K*PO/RM+FG*Q(ILAST)
      IL=IND(ILAST)
      VF=VA(IL)/RM+VB(IL)+RM*(VC(IL)+RM*VD(IL))
      FG=(E-VF+2.0D0*SL*SL)/SL
      PIA=PA(ILAST)
      PIAP=-K*PIA/RM+FG*QA(ILAST)
      PIB=PB(ILAST)
      PIBP=-K*PIB/RM+FG*QB(ILAST)
C
      IF(DABS(PO).GT.EPS) THEN
        RATIO=POP/PO
        PHASE=DATAN2(RATIO*PIA-PIAP,PIBP-RATIO*PIB)
      ELSE
        PHASE=DATAN2(-PIA,PIB)
      ENDIF
      TT=DABS(PHASE)
      IF(TT.GT.PIH) PHASE=PHASE*(1.0D0-PI/TT)
C
      RETURN
      END
C  *********************************************************************
C                       SUBROUTINE DPWAC0
C  *********************************************************************
      SUBROUTINE DPWAC0(ZZP,EV)
C
C     This subroutine computes Coulomb phase shifts and initializes the
C  calculation of the Mott differential cross section for electron or
C  positron elastic scattering by a bare point nucleus.
C
C  Input:
C     ZZP....... product of nuclear and projectile charges, that is, R
C                times the interaction energy at the distance R.
C                Negative for electrons, positive for positrons.
C     EV ....... kinetic energy of the projectile (eV).
C
C  After calling DPWAC0, the function DPWAC(TH) delivers the ratio
C  (Mott DCS / Rutherford DCS) for the scattering angle TH (rad).
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z),COMPLEX*16 (C),
     1   INTEGER*4 (I-N)
C
C  ****  Set IWR=1 to print Coulomb phase shifts on a file.
      PARAMETER (IWR=0)
C
      PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
      PARAMETER (HREV=27.21138602D0)  ! Hartree energy (eV)
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (SL2=SL*SL)
      PARAMETER (A0B2=A0B*A0B)
      PARAMETER (PI=3.1415926535897932D0,PIH=0.5D0*PI)
C  ****  Phase shifts and partial-wave series coefficients.
      PARAMETER (NPC=1500)
      COMMON/CRMORU/CFM(NPC),CGM(NPC),DPC(NPC),DMC(NPC),
     1              CF,CG,RUTHC,WATSC,RK2,ERRFC,ERRGC,NPC1
C
      CI=DCMPLX(0.0D0,1.0D0)
C
C  ************  Coulomb phase shifts.
C
      E=EV/HREV
      RUTHC=(A0B*2.0D0*ZZP*(1.0D0+E/SL2))**2
      PC=DSQRT(E*(E+2.0D0*SL*SL))
      RK=PC/SL
      RK2=RK*RK
      ZETA=ZZP/SL
      W=E+SL2
      ETA=ZETA*W/PC
      RNUR=ZETA*(W+SL2)
C  ****  Negative kappa.
      DO I=1,NPC
        L=I-1
        K=-L-1
        RLAMB=DSQRT(K*K-ZETA*ZETA)
        RNUI=-1.0D0*(K+RLAMB)*PC
        RNU=DATAN2(RNUI,RNUR)
        DELTAC=-CI*CLGAM(RLAMB+CI*ETA)
        DPC(I)=RNU-(RLAMB-(L+1))*PIH+DELTAC
      ENDDO
C  ****  Positive kappa.
      DMC(1)=0.0D0
      DO I=2,NPC
        L=I-1
        K=L
        RLAMB=DSQRT(K*K-ZETA*ZETA)
        RNUI=-1.0D0*(K+RLAMB)*PC
        RNU=DATAN2(RNUI,RNUR)
        DELTAC=-CI*CLGAM(RLAMB+CI*ETA)
        DMC(I)=RNU-(RLAMB-(L+1))*PIH+DELTAC
      ENDDO
C
C  ****  Prints Coulomb phase shifts in file CPHASES.DAT
C        if the parameter IWR equals 1.
C
      IF(IWR.EQ.1) THEN
        OPEN(UNIT=97,FILE='cphases.dat')
        WRITE(97,1000)
 1000   FORMAT(2X,'# COULOMB PHASE SHIFTS',/2X,'#')
        WRITE(97,1001) ZZP,E
 1001   FORMAT(2X,'# Z =',1P,E12.5,5X,'KINETIC ENERGY =',E12.5,/2X,'#')
        WRITE(97,1002)
 1002   FORMAT(2X,'#   L',7X,'PHASE(SPIN UP)',4X,
     1    'PHASE(SPIN DOWN)',/2X,'# ',45('-'))
        DO I=1,NPC
          DPI=DPC(I)
          TT=DABS(DPI)
          IF(TT.GT.PIH) DPI=DPI*(1.0D0-PI/TT)
          DMI=DMC(I)
          TT=DABS(DMI)
          IF(TT.GT.PIH) DMI=DMI*(1.0D0-PI/TT)
          WRITE(97,1003) I,DPI,DMI
 1003     FORMAT(3X,I5,4X,1P,E16.8,4X,E16.8)
        ENDDO
        CLOSE(UNIT=97)
      ENDIF
C
C  ************  Coefficients in the partial wave expansion.
C
      CXP=CDEXP(2*CI*DPC(1))
      CFACT=1.0D0/(2.0D0*CI*RK)
      CFM(1)=(CXP-1.0D0)*CFACT
      CGM(1)=0.0D0
      DO I=2,NPC
        L=I-1
        RL=L
        CXP=CDEXP(2.0D0*CI*DPC(I))
        CXM=CDEXP(2.0D0*CI*DMC(I))
        CFM(I)=((L+1)*(CXP-1)+L*(CXM-1))*CFACT
        CGM(I)=(CXM-CXP)*CFACT
      ENDDO
C
C  ****  Reduced series.
C
      NPC1=NPC
      DO NTR=1,2
        NPC1=NPC1-1
        CFC=0.0D0
        CFP=CFM(1)
        CGC=0.0D0
        CGP=CGM(1)
        DO I=1,NPC1
          RL=I-1
          CFA=CFC
          CFC=CFP
          CFP=CFM(I+1)
          CFM(I)=CFC-CFP*(RL+1)/(RL+RL+3)-CFA*RL/(RL+RL-1)
          CGA=CGC
          CGC=CGP
          CGP=CGM(I+1)
          CGM(I)=CGC-CGP*(RL+2)/(RL+RL+3)-CGA*(RL-1)/(RL+RL-1)
        ENDDO
      ENDDO
C
C  ****  Bartlett and Watson's formula for small angles.
C
      TARG=-2.0D0*CLGAM(DCMPLX(0.5D0,ETA))*CI
      C5=CDEXP(TARG*CI)
      TARG=-2.0D0*CLGAM(DCMPLX(1.0D0,ETA))*CI
      C1=CDEXP(TARG*CI)
      BETA2=E*(E+2.0D0*SL2)/(E+SL2)**2
      WATSC=-PI*BETA2*ETA*(C5/C1)
C
      RETURN
      END
C  *********************************************************************
C                       FUNCTION DPWAC
C  *********************************************************************
      FUNCTION DPWAC(TH)
C
C     Ratio (Mott DCS / Rutherford DCS) for collisions with scattering
C  angle TH (rad). Additional information is provided through the common
C  block /CRMORU/.
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z),COMPLEX*16 (C),
     1   INTEGER*4 (I-N)
      PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
      PARAMETER (HREV=27.21138602D0)  ! Hartree energy (eV)
      PARAMETER (A0B2=A0B*A0B)
      PARAMETER (NPC=1500)
      COMMON/CRMORU/CFM(NPC),CGM(NPC),DPC(NPC),DMC(NPC),
     1              CF,CG,RUTHC,WATSC,RK2,ERRF,ERRG,NPC1
C
      X=DCOS(TH)
      Q2=2.0D0*RK2*(1.0D0-X)
      NTEST=NPC1-5
C
C  ****  TH greater than 0.5 deg.
C
      IF(TH.LT.0.008726D0) GO TO 2
      FACT=1.0D0/(1.0D0-X)**2
C  ****  Direct scattering amplitude.
      P2=1.0D0
      P3=X
      CF=CFM(1)
      CF=CF+CFM(2)*P3
      CFA=0.0D0
      DO I=3,NPC1
        L=I-1
        P1=P2
        P2=P3
        P3=((L+L-1)*X*P2-(L-1)*P1)/L
        CF=CF+CFM(I)*P3
        IF(I.EQ.NTEST) CFA=CF
      ENDDO
      ERRF=CDABS(CFA-CF)/DMAX1(CDABS(CF),1.0D-15)
      CF=FACT*CF
C  ****  Spin-flip scattering amplitude.
      Y=DSIN(TH)
      IF(Y.LT.1.0D-20) THEN
        CG=0.0D0
        ERRG=ERRF
        GO TO 1
      ENDIF
      P2=1.0D0
      P3=3*X
      CG=CGM(2)
      CG=CG+CGM(3)*P3
      CGA=0.0D0
      DO I=4,NPC1
        L=I-1
        P1=P2
        P2=P3
        P3=((L+L-1)*X*P2-L*P1)/(L-1)
        CG=CG+CGM(I)*P3
        IF(I.EQ.NTEST) CGA=CG
      ENDDO
      ERRG=CDABS(CGA-CG)/DMAX1(CDABS(CG),1.0D-15)
    1 CG=FACT*Y*CG
      PAV1=CDABS(CF)**2
      PAV2=CDABS(CG)**2
      ERR=2.0D0*(PAV1*ERRF+PAV2*ERRG)/(PAV1+PAV2)
      DCS=(PAV1+PAV2)*A0B2
      DPWAC=DCS*(Q2*Q2/RUTHC)
      IF(ERR.LT.1.0D-3.OR.TH.GT.0.08726D0) RETURN
C
C  ****  Bartlett and Watson's formula; used only for TH less than
C        5 deg, if needed. The computed DPWAC value may have slight
C        discontinuities, of the order of 0.01 per cent, between
C        0.5 and 5 deg.
C
    2 CONTINUE
      CF=0.0D0
      CG=0.0D0
      ERRF=1.0D10
      ERRG=1.0D10
      DPWAC=1.0D0+WATSC*DSIN(0.5D0*TH)
      RETURN
      END
C  *********************************************************************
C                       FUNCTION RMOM
C  *********************************************************************
      FUNCTION RMOM(X,PDF,NP,N)
C
C     Calculation of momenta of a pdf, PDF(X), obtained from linear
C  log-log interpolation on a given table. The independent variable X
C  is assumed to take only positive values.
C
C     X ..... array of variable values (in increasing order).
C     PDF ... corresponding pdf values.
C     NP .... number of points in the table.
C     N ..... moment order.
C     RMOM = INTEGRAL (X**N)*PDF(X) dX   if N.GT.-100,
C          = INTEGRAL LOG(X)*PDF(X) dX   if N.LT.-100.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER (EPS=1.0D-35)
      DIMENSION X(NP),PDF(NP)
C
      IF(NP.LT.2) STOP 'RMOM. Error code 1.'
      IF(X(1).LT.0.0D0.OR.PDF(1).LT.0.0D0) THEN
        WRITE(6,*) 'X(1),PDF(1) =',X(1),PDF(1)
        STOP 'RMOM. Error code 2'
      ENDIF
      DO I=2,NP
        IF(X(I).LT.0.0D0.OR.PDF(I).LT.0.0D0) THEN
          WRITE(6,*) 'I,X(I),PDF(I) =',I,X(I),PDF(I)
          STOP 'RMOM. Error code 3'
        ENDIF
        IF(X(I).LT.X(I-1)) STOP 'RMOM. Error code 4.'
      ENDDO
C
      IF(N.LT.-100) GO TO 1
      RMOM=0.0D0
      X2=MAX(X(1),EPS)
      Y2=PDF(1)*X(1)**N
      DO I=2,NP
        X1=X2
        Y1=Y2
        X2=X(I)
        Y2=PDF(I)*X(I)**N
        IF(Y1.GT.EPS.AND.Y2.GT.EPS) THEN
          DXL=LOG(X2)-LOG(X1)
          DYL=LOG(Y2)-LOG(Y1)
          IF(ABS(DXL).GT.1.0D-14*ABS(DYL)) THEN
            AP1=1.0D0+(DYL/DXL)
            IF(ABS(AP1).GT.1.0D-12) THEN
              DS=(Y2*X2-Y1*X1)/AP1
            ELSE
              DS=Y1*X1*DXL
            ENDIF
          ELSE
            DS=0.5D0*(Y1+Y2)*(X2-X1)
          ENDIF
          RMOM=RMOM+DS
        ENDIF
      ENDDO
      RETURN
C
    1 CONTINUE
      RMOM=0.0D0
      X2=MAX(X(1),EPS)
      Y2=PDF(1)
      DO I=2,NP
        X1=X2
        Y1=Y2
        X2=X(I)
        Y2=PDF(I)
        IF(Y1.GT.EPS.AND.Y2.GT.EPS) THEN
          DXL=LOG(X2)-LOG(X1)
          DYL=LOG(Y2)-LOG(Y1)
          IF(ABS(DXL).GT.1.0D-14*ABS(DYL)) THEN
            AP1=1.0D0+(DYL/DXL)
            IF(ABS(AP1).GT.1.0D-12) THEN
              APREC=1.0D0/AP1
              DS=(Y2*X2*(LOG(X2)-APREC)-Y1*X1*(LOG(X1)-APREC))*APREC
            ELSE
              DS=Y1*X1*0.5D0*(LOG(X2)**2-LOG(X1)**2)
            ENDIF
          ELSE
            DS=0.5D0*(Y1*LOG(X1)+Y2*LOG(X2))*(X2-X1)
          ENDIF
          RMOM=RMOM+DS
        ENDIF
      ENDDO
      RETURN
      END

C >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
C >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
C
C  The following subroutines perform Dirac partial-wave calculations of
C  scattering of electrons and positrons in a complex central field with
C  an imaginary (absorptive) part.
C
C >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
C >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

C  *********************************************************************
C                      SUBROUTINE DPWAI0
C  *********************************************************************
      SUBROUTINE DPWAI0(EV,TOTCS,ABCS,NDELTA,ISCH)
C
C     This subroutine computes Dirac phase shifts, differential cross
C  sections and scattering amplitudes for elastic scattering of
C  electrons in central fields with an imaginary (absorptive) part.
C
C  Input/output arguments:
C     EV ....... effective kinetic energy of the projectile (eV).
C     TOTCS .... total cross section (cm**2).
C     ABCS ..... absorption cross section (cm**2).
C     NDELTA ... number of required phase shifts (LT.25000).
C     ISCH ..... =1: all phase shifts are computed by solving the radial
C                    equation.
C                =2: only phase shifts of selected orders are computed
C                    from the solution of the radial equation, the
C                    others are obtained by lin-log natural cubic spline
C                    interpolation. For high energies, ISCH=2 leads to a
C                    considerable reduction of the calculation time.
C
C  Input (through the common block /FIELDI/):
C     R(I) .... radial grid points (radii in increasing order). The
C               first point in the grid must be the origin, i.e. R(1)=0.
C               Repeated values are interpreted as discontinuities.
C     RV(I).... R(I) times the potential energy at R=R(I). The last
C               component, RV(NP), is assumed to be equal to the
C               asymptotic value.
C     RW(I).... R(I) times the imaginary potential (it must be negative
C               or zero).
C     IAB ..... 0 if the potential is real, 1 if it has an imaginary
C               part.
C     NP ...... number of input grid points.
C
C *** NOTE: The radii and potential values, R(I) and RV(I), are in
C           atomic units.
C
C  Output (through the common block /DCSTAB/):
C     ECS ........ total cross section (cm**2)
C                    (only for finite range fields).
C     TCS1 ....... 1st transport cross section (cm**2)
C                    (only for finite range fields).
C     TCS2 ....... 2nd transport cross section (cm**2)
C                    (only for finite range fields).
C     TH(I) ...... scattering angles (in deg)
C     XT(I) ...... values of (1-COS(TH(I)))/2.0D0.
C     DCST(I) .... differential cross section per unit solid angle at
C                    TH(I) (cm**2/sr).
C     ERROR(I) ... estimated relative uncertainty of the computed DCS
C                    value.
C     NTAB ....... number of angles in the table.
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1   INTEGER*4 (I-N)
      PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
      PARAMETER (HREV=27.21138602D0)  ! Hartree energy (eV)
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (A0B2=A0B*A0B)
      PARAMETER (PI=3.1415926535897932D0,FOURPI=4.0D0*PI)
C  ****  Input-output.
      PARAMETER (NDIM=1000)
      COMMON/FIELDI/R(NDIM),RV(NDIM),RW(NDIM),IAB,NP
      PARAMETER (NGT=650)
      COMMON/DCSTAB/ECS,TCS1,TCS2,TH(NGT),XT(NGT),DCST(NGT),DCSTLAB(NGT),SPOL(NGT),
     1              ERROR(NGT),NTAB,THLAB(NGT)
C  ****  Link with the RADIAL package.
      PARAMETER (NPPG=NDIM+1,NPTG=NDIM+NPPG)
      COMMON/RGRID/RRR(NPTG),P(NPTG),Q(NPTG),INDD(NPTG),NRT
      COMMON/VGRID/RG(NPPG),RVG(NPPG),VA(NPPG),VB(NPPG),VC(NPPG),
     1             VD(NPPG),NVT
      COMMON/VGRIDI/RWG(NPPG),WA(NPPG),WB(NPPG),WC(NPPG),WD(NPPG)
C  ****  Phase shifts and partial wave series coefficients.
      PARAMETER (NPC=1500,NDM=25000)
      DIMENSION CXP(NDM),CXM(NDM)
      COMMON/PHASES/DP(NDM),DM(NDM),NPH,ISUMP
      COMMON/PHASEI/DPJ(NDM),DMJ(NDM)
      DIMENSION DPI(NDM),DMI(NDM),DPJI(NDM),DMJI(NDM)
      COMMON/WORK/XL(NDM),SA(NDM),SB(NDM),SC(NDM),SD(NDM),P1(NDM)
      COMMON/CSA/CFL(NDM),CGL(NDM),CFM(NDM),CGM(NDM),NPHM,IZINF
      COMMON/CRMORU/CFMC(NPC),CGMC(NPC),DPC(NPC),DMC(NPC),
     1              CFC,CGC,RUTHC,WATSC,RK2,ERRFC,ERRGC,NPC1
C
      CI=DCMPLX(0.0D0,1.0D0)
      ISUMP=0
C
      OPEN(UNIT=98,FILE='dpwai.dat')
      WRITE(98,2000)
 2000 FORMAT(//2X,'**** PARTIAL WAVE ANALYSIS (DPWAI0) ',
     1  42('*')/)
C
      NDELT=NDELTA
      IF(NDELT.GT.NDM) THEN
        WRITE(98,2001)
 2001   FORMAT(/2X,'WARNING: NDELTA IS TOO LARGE')
        NDELT=NDM
      ENDIF
      IF(NDELT.LT.6) NDELT=6
      EPS=1.0D-14
      EPSCUT=1.0D-9
C
      E=EV/HREV
C
C  ****  Initialization of the RADIAL package.
C
      IF(IAB.EQ.0) THEN
        CALL VINT(R,RV,NP)
      ELSE
        CALL VINTI(R,RV,RW,NP)
      ENDIF
C
      ZINF=RVG(NVT)
      IF(DABS(ZINF).GT.1.0D-10) THEN
        IZINF=1
        CALL DPWAC0(ZINF,EV)
        IF(NDELT.GT.8000) NDELT=8000
      ELSE
        IZINF=0
      ENDIF
      DO I=1,NVT
        RRR(I)=RG(I)
        INDD(I)=I
      ENDDO
      NRT=NVT
C
      WRITE(98,2002) EV
 2002 FORMAT(/2X,'KINETIC ENERGY =',1P,E12.5,' eV')
      IF(E.LT.0.0D0) THEN
        WRITE(98,2003)
        WRITE(6,2003)
 2003   FORMAT(//2X,'NEGATIVE ENERGY. STOP.')
        STOP
      ENDIF
      RK=DSQRT(E*(E+2.0D0*SL*SL))/SL
C
      IF(IZINF.EQ.1) WRITE(98,2004)
 2004 FORMAT(/2X,'ONLY INNER PHASE SHIFTS ARE TABULATED')
      WRITE(98,2005)
 2005 FORMAT(/14X,'--------- SPIN UP ---------',6X,
     1  '-------- SPIN DOWN --------',/6X,'L',9X,
     2  'Re(phase)      Im(phase)',9X,'Re(phase)      Im(phase)',
     3  /2X,74('-'))
      ISCH0=ISCH
      IF(ISCH0.EQ.2.AND.EV.GT.1000.0D0) GO TO 1
C
C  ****  ISCH0=1, all phase shifts are computed by solving the radial
C        equation.
C
      L=0
      IF(IAB.EQ.0) THEN
        CALL DPHASE(E,EPS,PHP,-1,IER)
        CXP(1)=CDEXP(2.0D0*CI*PHP)
      ELSE
        CALL ZDPHAS(E,EPS,CXP(1),-1,IER)
      ENDIF
      IF(IER.NE.0) STOP
      CXM(1)=1.0D0
      CDP=CDLOG(CXP(1))/(2.0D0*CI)
      CDM=CDLOG(CXM(1))/(2.0D0*CI)
      WRITE(98,2006) L,CDP,CDM
      WRITE(6,2006) L,CDP,CDM
 2006 FORMAT(3X,I5,4X,1P,E16.8,1X,E12.5,4X,E16.8,1X,E12.5)
      DP(1)=CDP
      DM(1)=0.0D0
C
      IFIRST=2
   33 CONTINUE
      ISUMP=1
      TST=0.0D0
      DO I=IFIRST,NDELT
        L=I-1
        IF(IAB.EQ.0) THEN
          CALL DPHASE(E,EPS,PHP,-L-1,IER)
          CXP(I)=CDEXP(2.0D0*CI*PHP)
        ELSE
          CALL ZDPHAS(E,EPS,CXP(I),-L-1,IER)
        ENDIF
        IF(IER.NE.0) STOP
        IF(IAB.EQ.0) THEN
          CALL DPHASE(E,EPS,PHM,L,IER)
          CXM(I)=CDEXP(2.0D0*CI*PHM)
        ELSE
          CALL ZDPHAS(E,EPS,CXM(I),L,IER)
        ENDIF
        IF(IER.NE.0) STOP
        CDP=CDLOG(CXP(I))/(2.0D0*CI)
        CDM=CDLOG(CXM(I))/(2.0D0*CI)
        DP(I)=CDP
        DM(I)=CDM
        TST=MAX(CDABS(CDP),CDABS(CDM),SQRT(DP(I-1)**2+DM(I-1)**2))
        NPH=I
        WRITE(98,2006) L,CDP,CDM
        WRITE(6,2006) L,CDP,CDM
        IF(TST.LT.EPSCUT.AND.L.GT.30) GO TO 6
C  ****  When the last phase shift (spin up) differs in more than 20 per
C  cent from the quadratic extrapolation, accumulated roundoff errors
C  may be important and the calculation of phase shifts is discontinued.
        IF(I.GT.500) THEN
          DPEXT=DP(I-3)+3.0D0*(DP(I-1)-DP(I-2))
          DPMAX=MAX(ABS(DP(I-3)),ABS(DP(I-2)),ABS(DP(I-1)),
     1              ABS(DP(I)))
          IF(ABS(DP(I)-DPEXT).GT.0.20D0*DPMAX) THEN
            NPH=I-1
            WRITE(98,2107)
            WRITE(6,2107)
 2107 FORMAT(/2X,'WARNING: Possible accumulation of round-off errors.')
            GO TO 6
          ENDIF
        ENDIF
      ENDDO
      WRITE(98,2007) TST
      WRITE(6,2007) TST
 2007 FORMAT(/2X,'WARNING: TST =',1P,E11.4,'. CHECK CONVERGENCE.')
      GO TO 6
C
C  ****  ISCH0=2, only inner phase shifts of orders L in a given grid
C        are computed from the solution of the radial equation. Phase
C        shifts of orders not included in this grid are obtained by
C        lin-log cubic spline interpolation.
C          The adopted grid is: 0(1)100(5)300(10) ...
C
C        This is a somewhat risky procedure, which is based on the
C        observed variation of the calculated phase shifts with L for
C        atomic scattering fields. When a change of sign is found, all
C        the phases are recalculated.
C
    1 L=0
      IF(IAB.EQ.0) THEN
        CALL DPHASE(E,EPS,PHP,-1,IER)
        CXP(1)=CDEXP(2.0D0*CI*PHP)
      ELSE
        CALL ZDPHAS(E,EPS,CXP(1),-1,IER)
      ENDIF
      IF(IER.NE.0) STOP
      CXM(1)=1.0D0
      CDP=CDLOG(CXP(1))/(2.0D0*CI)
      CDM=CDLOG(CXM(1))/(2.0D0*CI)
      WRITE(98,2006) L,CDP,CDM
      WRITE(6,2006) L,CDP,CDM
      DP(1)=CDP
      DPJ(1)=-CI*CDP
      DM(1)=0.0D0
      DMJ(1)=0.0D0
C
      LMAX=NDELT-1
      IND=0
      IADD=1
      LPP=1
    2 L=LPP
      IF(IAB.EQ.0) THEN
        CALL DPHASE(E,EPS,PHP,-L-1,IER)
        CXP(L+1)=CDEXP(2.0D0*CI*PHP)
      ELSE
        CALL ZDPHAS(E,EPS,CXP(L+1),-L-1,IER)
      ENDIF
      IF(IER.NE.0) STOP
      IF(IAB.EQ.0) THEN
        CALL DPHASE(E,EPS,PHM,L,IER)
        CXM(L+1)=CDEXP(2.0D0*CI*PHM)
      ELSE
        CALL ZDPHAS(E,EPS,CXM(L+1),L,IER)
      ENDIF
      IF(IER.NE.0) STOP
      CDP=CDLOG(CXP(L+1))/(2.0D0*CI)
      CDM=CDLOG(CXM(L+1))/(2.0D0*CI)
      WRITE(6,2006) L,CDP,CDM
C
      DP(L+1)=CDP
      DPJ(L+1)=-CI*CDP
      DM(L+1)=CDM
      DMJ(L+1)=-CI*CDM
C
      IF(L.LT.95) THEN
        WRITE(98,2006) L,CDP,CDM
      ELSE
        IF(DMAX1(CDABS(CDP),CDABS(CDM)).LT.EPSCUT) GO TO 3
        IND=IND+1
        XL(IND)=L
        DPI(IND)=DP(L+1)
        DPJI(IND)=DPJ(L+1)
        DMI(IND)=DM(L+1)
        DMJI(IND)=DMJ(L+1)
        IF(IND.GT.1) THEN
          S1=SIGN(PI,DPI(IND))
          S0=SIGN(PI,DPI(IND-1))
          IF(S1*S0.LT.0.0D0) THEN
            IF(DABS(DPI(IND-1)).LT.1.0D-6.AND.L.GT.300) THEN
              IND=IND-1
              L=XL(IND)+0.5D0
              GO TO 3
            ENDIF
            ISCH0=1
            IFIRST=MIN(L,94)
            GO TO 33
          ENDIF
          S1=SIGN(PI,DMI(IND))
          S0=SIGN(PI,DMI(IND-1))
          IF(S1*S0.LT.0.0D0) THEN
            IF(DABS(DMI(IND-1)).LT.1.0D-6.AND.L.GT.300) THEN
              IND=IND-1
              L=XL(IND)+0.5D0
              GO TO 3
            ENDIF
            ISCH0=1
            IFIRST=MIN(L,94)
            GO TO 33
          ENDIF
        ENDIF
        IF(L.GT.500.AND.DABS(DPI(IND-1)).LT.1.0D-5) THEN
          I=IND
          DPEXT=DPI(I-3)+3.0D0*(DPI(I-1)-DPI(I-2))
          DPMAX=MAX(ABS(DPI(I-3)),ABS(DPI(I-2)),ABS(DPI(I-1)),
     1          ABS(DPI(I)))
          IF(ABS(DPI(I)-DPEXT).GT.0.20D0*DPMAX) THEN
            IND=I-1
            WRITE(98,2107)
            WRITE(6,2107)
            GO TO 3
          ENDIF
          DMEXT=DMI(I-3)+3.0D0*(DMI(I-1)-DMI(I-2))
          DMMAX=MAX(ABS(DMI(I-3)),ABS(DMI(I-2)),ABS(DMI(I-1)),
     1          ABS(DMI(I)))
          IF(ABS(DMI(I)-DMEXT).GT.0.20D0*DMMAX) THEN
            IND=I-1
            WRITE(98,2107)
            WRITE(6,2107)
            GO TO 3
          ENDIF
        ENDIF
      ENDIF
      TST=DMAX1(CDABS(CDP),CDABS(CDM))
      IF(TST.LT.EPSCUT.AND.L.GT.3) GO TO 3
      IF(L.GE.LMAX) GO TO 3
C
      IF(L.GT.99) IADD=5
      IF(L.GT.299) IADD=10
      IF(L.GT.599) IADD=20
      IF(L.GT.1199) IADD=50
      IF(L.GT.2999) IADD=100
      IF(L.GT.9999) IADD=250
      LPP=L+IADD
      IF(LPP.GT.LMAX) LPP=LMAX
      GO TO 2
C
C  ****  Check consistency of sparsely tabulated phase shifts.
C        A discontinuity larger than 0.25*PI is considered as
C        a symptom of numerical inconsistencies.
C
    3 CONTINUE
      NPH=L+1
      TST=0.0D0
      DO I=1,IND
        WRITE(98,2008) INT(XL(I)+0.5D0),DPI(I),DPJI(I),DMI(I),DMJI(I)
 2008   FORMAT(3X,I5,4X,1P,E16.8,1X,E12.5,4X,E16.8,1X,E12.5,'  i')
        IF(I.GT.1) THEN
          TST=MAX(TST,DABS(DPI(I)-DPI(I-1)),DABS(DMI(I)-DMI(I-1)))
        ENDIF
      ENDDO
      IF(IND.LT.4) GO TO 6
      IF(TST.GT.0.25D0*PI) THEN
        WRITE(98,2009)
        WRITE(6,2009)
 2009   FORMAT(/2X,'ERROR: DIRECTLY COMPUTED PHASE SHIFTS SHOW',
     1    ' LARGE DISCONTINUITIES.')
        STOP
      ENDIF
C
C  ****  Interpolated phase shifts (lin-log cubic spline).
C
      IF(DPI(IND).GT.0.0D0) THEN
        ITRAN=+1.0D0
      ELSE
        ITRAN=-1.0D0
      ENDIF
      DO I=1,IND
        DPI(I)=DLOG(DABS(DPI(I)))
      ENDDO
      CALL SPLINE(XL,DPI,SA,SB,SC,SD,0.0D0,0.0D0,IND)
      DO 4 I=2,NPH
        L=I-1
        IF(L.LT.95) GO TO 4
        RL=L
        CALL FINDI(XL,RL,IND,J)
        DP(I)=SA(J)+RL*(SB(J)+RL*(SC(J)+RL*SD(J)))
        DP(I)=ITRAN*DEXP(DP(I))
    4 CONTINUE
C
      IF(DPJI(IND).GT.0.0D0) THEN
        ITRAN=+1.0D0
      ELSE
        ITRAN=-1.0D0
      ENDIF
      NHIM=0
      DO I=1,IND
        IF(DABS(DPJI(I)).LT.1.0D-14.AND.NHIM.GT.4) GO TO 44
        DPJI(I)=DLOG(DABS(DPJI(I)))
        NHIM=I
      ENDDO
   44 CONTINUE
      CALL SPLINE(XL,DPJI,SA,SB,SC,SD,0.0D0,0.0D0,NHIM)
      DO 444 I=2,NPH
        L=I-1
        IF(L.LT.95) GO TO 444
        RL=L
        IF(RL.LE.XL(NHIM)) THEN
          CALL FINDI(XL,RL,IND,J)
          DPJ(I)=SA(J)+RL*(SB(J)+RL*(SC(J)+RL*SD(J)))
          DPJ(I)=ITRAN*DEXP(DPJ(I))
        ELSE
          DPJ(I)=0.0D0
        ENDIF
  444 CONTINUE
C
      IF(DMI(IND).GT.0.0D0) THEN
        ITRAN=+1.0D0
      ELSE
        ITRAN=-1.0D0
      ENDIF
      DO I=1,IND
        DMI(I)=DLOG(DABS(DMI(I)))
      ENDDO
      CALL SPLINE(XL,DMI,SA,SB,SC,SD,0.0D0,0.0D0,IND)
      DO 5 I=2,NPH
        L=I-1
        IF(L.LT.95) GO TO 5
        RL=L
        CALL FINDI(XL,RL,IND,J)
        DM(I)=SA(J)+RL*(SB(J)+RL*(SC(J)+RL*SD(J)))
        IF(ITRAN.NE.0) DM(I)=ITRAN*DEXP(DM(I))
    5 CONTINUE
C
      IF(DMJI(IND).GT.0.0D0) THEN
        ITRAN=+1.0D0
      ELSE
        ITRAN=-1.0D0
      ENDIF
      NHIM=0
      DO I=1,IND
        IF(DABS(DPJI(I)).LT.1.0D-14.AND.NHIM.GT.4) GO TO 55
        DMJI(I)=DLOG(DABS(DMJI(I)))
        NHIM=I
      ENDDO
   55 CONTINUE
      CALL SPLINE(XL,DMJI,SA,SB,SC,SD,0.0D0,0.0D0,NHIM)
      DO 555 I=2,NPH
        L=I-1
        IF(L.LT.95) GO TO 555
        RL=L
        IF(RL.LE.XL(NHIM)) THEN
          CALL FINDI(XL,RL,IND,J)
          DMJ(I)=SA(J)+RL*(SB(J)+RL*(SC(J)+RL*SD(J)))
          DMJ(I)=ITRAN*DEXP(DMJ(I))
        ELSE
          DMJ(I)=0.0D0
        ENDIF
  555 CONTINUE
C
      TST=DMAX1(DABS(DP(NPH)),DABS(DM(NPH)))
      IF(TST.GT.EPSCUT) THEN
        WRITE(98,2007) TST
        WRITE(6,2007) TST
      ENDIF
      DO I=1,NPH
        CXP(I)=CDEXP(2.0D0*CI*DCMPLX(DP(I),DPJ(I)))
        CXM(I)=CDEXP(2.0D0*CI*DCMPLX(DM(I),DMJ(I)))
      ENDDO
C
C  ************  Coefficients in the partial-wave expansion.
C
    6 CONTINUE
      CFACT=1.0D0/(2.0D0*CI*RK)
      IF(IZINF.EQ.1) THEN
        CXPC=CDEXP(2*CI*DPC(1))
        CFL(1)=CXPC*(CXP(1)-1)*CFACT
        CGL(1)=0.0D0
        DO I=2,NPH
          L=I-1
          CXPC=CDEXP(2.0D0*CI*DPC(I))
          CXMC=CDEXP(2.0D0*CI*DMC(I))
          CFL(I)=((L+1)*CXPC*(CXP(I)-1)+L*CXMC*(CXM(I)-1))*CFACT
          CGL(I)=(CXMC*(CXM(I)-1)-CXPC*(CXP(I)-1))*CFACT
        ENDDO
      ELSE
        CFL(1)=(CXP(1)-1.0D0)*CFACT
        CGL(1)=0.0D0
        DO I=2,NPH
          L=I-1
          CFL(I)=((L+1)*(CXP(I)-1)+L*(CXM(I)-1))*CFACT
          CGL(I)=(CXM(I)-CXP(I))*CFACT
        ENDDO
      ENDIF
C
C  ****  Reduced series (two iterations).
C
      IF(NPH.GE.250.AND.ISUMP.EQ.0) THEN
        DO I=1,NPH
          CFM(I)=CFL(I)
          CGM(I)=CGL(I)
        ENDDO
C
        NPHM=NPH
        DO 7 NTR=1,2
          NPHM=NPHM-1
          CFC=0.0D0
          CFP=CFM(1)
          CGC=0.0D0
          CGP=CGM(1)
          DO I=1,NPHM
            RL=I-1
            CFA=CFC
            CFC=CFP
            CFP=CFM(I+1)
            CFM(I)=CFC-CFP*(RL+1)/(RL+RL+3)-CFA*RL/(RL+RL-1)
            CGA=CGC
            CGC=CGP
            CGP=CGM(I+1)
            CGM(I)=CGC-CGP*(RL+2)/(RL+RL+3)-CGA*(RL-1)/(RL+RL-1)
          ENDDO
    7   CONTINUE
      ENDIF
C
C  ****  Scattering amplitudes and DCS.
C
      WRITE(98,2010)
 2010 FORMAT(//2X,'*** SCATTERING AMPLITUDES AND DIFFERENT',
     1  'IAL CROSS SECTION ***')
      WRITE(98,2011)
 2011 FORMAT(/4X,'ANGLE',6X,'DCS',7X,'ASYMMETRY',4X,'DIRECT AMPLITU',
     1  'DE',7X,'SPIN-FLIP AMPLITUDE',5X,'ERROR',/4X,'(deg)',3X,
     2  '(cm**2/sr)',22X,'(cm)',20X,'(cm)',/2X,91('-'))
C
C  ****  Angular grid (TH in deg).
C
      TH(1)=0.0D0
      TH(2)=1.0D-4
      I=2
   10 CONTINUE
      I=I+1
      IF(TH(I-1).LT.0.9999D-3) THEN
        TH(I)=TH(I-1)+2.5D-5
      ELSE IF(TH(I-1).LT.0.9999D-2) THEN
        TH(I)=TH(I-1)+2.5D-4
      ELSE IF(TH(I-1).LT.0.9999D-1) THEN
        TH(I)=TH(I-1)+2.5D-3
      ELSE IF(TH(I-1).LT.0.9999D+0) THEN
        TH(I)=TH(I-1)+2.5D-2
      ELSE IF(TH(I-1).LT.0.9999D+1) THEN
        TH(I)=TH(I-1)+1.0D-1
      ELSE IF(TH(I-1).LT.2.4999D+1) THEN
        TH(I)=TH(I-1)+2.5D-1
      ELSE
        TH(I)=TH(I-1)+5.0D-1
      ENDIF
      IF(I.GT.NGT) STOP 'DPWA0. The NGT parameter is too small.'
      IF(TH(I).LT.180.0D0) GO TO 10
      NTAB=I
C
      DO I=1,NTAB
        THR=TH(I)*PI/180.0D0
        XT(I)=(1.0D0-DCOS(THR))/2.0D0
        CALL DPWA(THR,CF,CG,DCS,SPL,ERRF,ERRG)
        IF(DMAX1(ERRF,ERRG).GT.0.95D0) THEN
          ERR=1.0D0
        ELSE
          ACF=CDABS(CF)**2
          ACG=CDABS(CG)**2
          ERR=2.0D0*(ACF*ERRF+ACG*ERRG)/DMAX1(DCS,1.0D-45)
        ENDIF
        DCST(I)=DCS
        ERROR(I)=DMAX1(ERR,1.0D-7)
        SPOL(I)=SPL
        WRITE(98,2012) TH(I),DCST(I),SPOL(I),CF,CG,ERROR(I)
 2012   FORMAT(1X,1P,E10.3,E12.5,1X,E10.3,2(1X,'(',E10.3,',',
     1    E10.3,')'),E10.2)
      ENDDO
C
C  ************  Total and momentum transfer cross sections.
C                Convergence test (only for finite range fields).
C
      IF(IZINF.EQ.0) THEN
        INC=5
        IF(ISUMP.EQ.1) INC=1
        TST1=0.0D0
        TST2=0.0D0
        ECS=4.0D0*PI*CFL(1)*DCONJG(CFL(1))
        TCS=0.0D0
        ECSO=ECS
        TCSO=TCS
        DO I=2,NPH
          L=I-1
          RL=L
          DECS=CFL(I)*DCONJG(CFL(I))+RL*(L+1)*CGL(I)*DCONJG(CGL(I))
          DECS=4.0D0*PI*DECS/(L+L+1)
          DTCS=CFL(L)*DCONJG(CFL(I))+DCONJG(CFL(L))*CFL(I)
     1        +(L-1)*(RL+1)*(CGL(L)*DCONJG(CGL(I))
     2        +DCONJG(CGL(L))*CGL(I))
          DTCS=4.0D0*PI*DTCS*L/((RL+L-1)*(L+L+1))
          ECS=ECS+DECS
          TCS=TCS+DTCS
C  ****  Convergence test.
          ITW=L-(L/INC)*INC
          IF(ITW.EQ.0) THEN
            TST1=DABS(ECS-ECSO)/(DABS(ECS)+1.0D-35)
            TST2=DABS(TCS-TCSO)/(DABS(TCS)+1.0D-35)
            ECSO=ECS
            TCSO=TCS
          ENDIF
        ENDDO
        TST=DMAX1(TST1,TST2)
        TCS=ECS-TCS
        IF(TST.GT.1.0D-5.AND.NPH.GT.40) THEN
          WRITE(98,2007) TST
          WRITE(6,2007) TST
        ENDIF
        ECS=ECS*A0B2
        TCS=TCS*A0B2
C
C  ****  ECS and TCSs are evaluated from the DCS table.
C
        ECS0=FOURPI*RMOM(XT,DCST,NTAB,0)
        ECS1=FOURPI*RMOM(XT,DCST,NTAB,1)
        ECS2=FOURPI*RMOM(XT,DCST,NTAB,2)
        TST1=DABS(ECS-ECS0)/(DABS(ECS)+1.0D-35)
        WRITE(98,2013) ECS,ECS0,TST1
        WRITE(6,2013) ECS,ECS0,TST1
 2013   FORMAT(/2X,'TOTAL ELASTIC CROSS SECTION =',1P,E13.6,' cm**2',
     1         /2X,'             FROM DCS TABLE =',E13.6,
     2         '  (REL. DIF. =',E9.2,')')
        TCS1=2.0D0*ECS1
        TCS2=6.0D0*(ECS1-ECS2)
        TST2=DABS(TCS-TCS1)/(DABS(TCS)+1.0D-35)
        WRITE(98,2014) TCS,TCS1,TST2
        WRITE(6,2014) TCS,TCS1,TST2
 2014   FORMAT(/2X,'1ST TRANSPORT CROSS SECTION =',1P,E13.6,' cm**2',
     1         /2X,'             FROM DCS TABLE =',E13.6,
     2         '  (REL. DIF. =',E9.2,')')
        WRITE(98,2015) TCS2
        WRITE(6,2015) TCS2
 2015   FORMAT(/2X,'2ND TRANSPORT CROSS SECTION =',1P,E13.6,' cm**2')
        TST=DMAX1(TST1,TST2)
        IF(TST.GT.2.0D-3) THEN
          WRITE(98,2016)
          WRITE(6,2016)
        ENDIF
 2016   FORMAT(/2X,'WARNING: RELATIVE DIFFERENCES ARE TOO LARGE.',
     1         /11X,'THE DCS TABLE IS NOT CONSISTENT.')
C
C  ****  Absorption cross section.
C
        CALL DPWA(0.0D0,CF,CG,DCS,SPL,ERRF,ERRG)
        TOTCS=(FOURPI*(A0B/RK))*(-CI*CF)
        ABCS=TOTCS-ECS
        WRITE(98,2018) TOTCS
        WRITE(6,2018) TOTCS
 2018   FORMAT(/2X,'  GRAND TOTAL CROSS SECTION =',1P,E13.6,' cm**2')
        WRITE(98,2019) ABCS
        WRITE(6,2019) ABCS
 2019   FORMAT(2X,'   ABSORPTION CROSS SECTION =',1P,E13.6,' cm**2')
      ENDIF
C
      WRITE(98,2017)
 2017 FORMAT(/2X,'**** DPWAI0 ENDED ',60('*')/)
      CLOSE(UNIT=98)
C
      RETURN
      END
C  **************************************************************
C                        SUBROUTINE VINTI
C  **************************************************************
      SUBROUTINE VINTI(R,RV,RW,NV)
C
C     NATURAL CUBIC SPLINE INTERPOLATION FOR R*V(R) FROM THE
C  INPUT RADII AND POTENTIAL VALUES.
C
C  ****  Complex potential.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER (NDIM=1000,NPPG=NDIM+1,NPTG=NDIM+NPPG)
      COMMON/VGRID/RG(NPPG),RVG(NPPG),VA(NPPG),VB(NPPG),VC(NPPG),
     1             VD(NPPG),NVT
      COMMON/VGRIDI/RWG(NPPG),WA(NPPG),WB(NPPG),WC(NPPG),WD(NPPG)
      COMMON/RGRID/X(NPTG),P(NPTG),Q(NPTG),IND(NPTG),NRT
      COMMON/STORE/Y(NPTG),A(NPTG),B(NPTG),C(NPTG),D(NPTG)
      DIMENSION Z(NPTG),CA(NPTG),CB(NPTG),CC(NPTG),CD(NPTG)
      DIMENSION R(NDIM),RV(NDIM),RW(NDIM)
C
      IF(R(1).LT.0.0D0) THEN
      WRITE(6,2101)
 2101 FORMAT(1X,'*** ERROR IN VINTI: R(1).LT.0.')
      STOP
      ENDIF
      IF(NV.GT.NDIM) THEN
      WRITE(6,2102) NDIM
 2102 FORMAT(1X,'*** ERROR IN VINTI: INPUT POTENTIAL GRID WITH ',
     1  'MORE THAN ',I5,' DATA POINTS.')
      STOP
      ENDIF
      R(1)=0.0D0
C
      IO=0
      I=0
      K=0
    1 I=I+1
      K=K+1
      X(K)=R(I)
      Y(K)=RV(I)
      Z(K)=RW(I)
      IF(I.EQ.NV) GO TO 2
      IF(R(I).LT.R(I+1)-1.0D-12) GO TO 1
    2 CONTINUE
C
      CALL SPLINE(X,Y,A,B,C,D,0.0D0,0.0D0,K)
      CALL SPLINE(X,Z,CA,CB,CC,CD,0.0D0,0.0D0,K)
C
      K=K-1
      DO 3 J=1,K
      IO=IO+1
      RG(IO)=X(J)
      RVG(IO)=Y(J)
      RWG(IO)=Z(J)
      VA(IO)=A(J)
      VB(IO)=B(J)
      VC(IO)=C(J)
      VD(IO)=D(J)
      WA(IO)=CA(J)
      WB(IO)=CB(J)
      WC(IO)=CC(J)
      WD(IO)=CD(J)
    3 CONTINUE
      IF(I.LT.NV) THEN
        K=0
        GO TO 1
      ENDIF
C  ****  AN EXTRA POINT IS ADDED TO THE GRID, AND R*V(R) IS SET
C        EQUAL TO RV(NV) FOR R.GE.R(NV)
      IO=IO+1
      RG(IO)=X(K+1)
      RVG(IO)=Y(K+1)
      RWG(IO)=Z(K+1)
      VA(IO)=RVG(IO)
      VB(IO)=0.0D0
      VC(IO)=0.0D0
      VD(IO)=0.0D0
      WA(IO)=RWG(IO)
      WB(IO)=0.0D0
      WC(IO)=0.0D0
      WD(IO)=0.0D0
      NVT=IO+1
      RG(NVT)=2.0D0*RG(IO)
      RVG(NVT)=RVG(IO)
      RWG(NVT)=RWG(IO)
      VA(NVT)=RVG(IO)
      VB(NVT)=0.0D0
      VC(NVT)=0.0D0
      VD(NVT)=0.0D0
      WA(NVT)=RWG(IO)
      WB(NVT)=0.0D0
      WC(NVT)=0.0D0
      WD(NVT)=0.0D0
      RETURN
      END
C  *********************************************************************
C                         SUBROUTINE ZDPHAS
C  *********************************************************************
      SUBROUTINE ZDPHAS(E,EPS,ZPHASE,K,IER)
C
C   This subroutine computes Dirac phase shifts for complex potentials.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Y), INTEGER*4 (I-N),
     1  COMPLEX*16 (Z)
      PARAMETER (NDIM=1000,NPPG=NDIM+1,NPTG=NDIM+NPPG)
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (PI=3.1415926535897932D0,PIH=0.5D0*PI)
      COMMON/RGRID/RRR(NPTG),P(NPTG),Q(NPTG),INDD(NPTG),NRTT
      COMMON/ZRGRID/R(NPTG),ZP(NPTG),ZQ(NPTG),IND(NPTG),NRT
      COMMON/VGRID/RG(NPPG),RV(NPPG),VA(NPPG),VB(NPPG),VC(NPPG),
     1             VD(NPPG),NVT
      COMMON/VGRIDI/RWG(NPPG),WA(NPPG),WB(NPPG),WC(NPPG),WD(NPPG)
      DIMENSION ZPA(NPTG),ZQA(NPTG),ZPB(NPTG),ZQB(NPTG)
      COMMON/OCOUL/WAVNUM,ETA,DELTA
      EXTERNAL BESJN
C
      NRT=NRTT
      DO I=1,NRT
        R(I)=RRR(I)
        IND(I)=INDD(I)
      ENDDO
C
      ZI=DCMPLX(0.0D0,1.0D0)
      IER=0
      IF(K.EQ.0) THEN
        WRITE(6,2001)
 2001   FORMAT(1X,'*** ERROR IN ZDPHAS: K.EQ.0.')
        STOP
      ENDIF
C
      IF(E.LE.0.0D0) THEN
        IER=7
        WRITE(6,2002)
 2002   FORMAT(1X,'*** ERROR 7  (IN ZDPHAS): E.LE.0.')
        RETURN
      ENDIF
      EPSCUT=1.0D-9
C  ****  Orbital angular momentum quantum number.
      IF(K.LT.0) THEN
        L=-K-1
        KSIGN=1
      ELSE
        L=K
        KSIGN=-1
      ENDIF
      FL1=0.5D0*L*(L+1)
      RK=DSQRT(E*(E+2.0D0*SL*SL))/SL
C
C  ****  Asymptotic solution.
C
      RZINF=RV(NVT)
      IF(DABS(RZINF).LT.EPS) THEN
C  ****  Finite range fields.
        FACTOR=DSQRT(E/(E+2.0D0*SL*SL))
        ILAST=NRT+1
        DO I=4,NRT
          IL=ILAST-1
          RN=R(IL)
          INJ=IND(IL)
          ZRVN=VA(INJ)+RN*(VB(INJ)+RN*(VC(INJ)+RN*VD(INJ)))
     1        +(WA(INJ)+RN*(WB(INJ)+RN*(WC(INJ)+RN*WD(INJ))))*ZI
          T=EPS*RN*DABS(E*RN-FL1/RN)
          X=RK*RN
          IF(ABS(ZRVN).GT.T) GO TO 1
          BNL=BESJN(2,L,X)
          IF(DABS(BNL).GT.100.0D0) GO TO 1
          BNL1=BESJN(2,L+KSIGN,X)
          IF(DABS(BNL1).GT.100.0D0) GO TO 1
          BJL=BESJN(1,L,X)
          BJL1=BESJN(1,L+KSIGN,X)
          ILAST=IL
          ZPA(ILAST)=X*BJL
          ZPB(ILAST)=-X*BNL
          ZQA(ILAST)=-FACTOR*KSIGN*X*BJL1
          ZQB(ILAST)=FACTOR*KSIGN*X*BNL1
        ENDDO
    1   CONTINUE
        IF(ILAST.EQ.NRT+1) THEN
          IER=8
          WRITE(6,2003)
 2003   FORMAT(1X,'*** ERROR 8  (IN ZDPHAS): RAD(NGP) TOO SMALL.'
     1  /5X,'(EXTEND THE GRID TO LARGER RADII).')
          RETURN
        ENDIF
      ELSE
C  ****  Coulomb fields.
        TAS=MAX(1.0D-11,EPS)*DABS(RZINF)
        ILAST=NRT+1
        DO I=4,NRT
          IL=ILAST-1
          RN=R(IL)
          INJ=IND(IL)
          ZRVN=VA(INJ)+RN*(VB(INJ)+RN*(VC(INJ)+RN*VD(INJ)))
     1        +(WA(INJ)+RN*(WB(INJ)+RN*(WC(INJ)+RN*WD(INJ))))*ZI
          IF(ABS(ZRVN-RZINF).GT.TAS) GO TO 2
          CALL DCOUL(RZINF,E,K,RN,P0,Q0,P1,Q1,ERR)
          IF(ERR.GT.EPSCUT.OR.DABS(P1).GT.100.0D0) GO TO 2
          ILAST=IL
          ZPA(ILAST)=P0
          ZPB(ILAST)=P1
          ZQA(ILAST)=Q0
          ZQB(ILAST)=Q1
        ENDDO
    2   CONTINUE
        IF(ILAST.EQ.NRT+1) THEN
          IER=8
          WRITE(6,2003)
          RETURN
        ENDIF
      ENDIF
C
C  ****  Outward solution of the radial equation.
C
      CALL ZDOUTW(E,EPS,K,1,NZERO,ILAST)
C
C  ****  Phase shift.
C
      RM=R(ILAST)
      IL=IND(ILAST-1)
      ZVF=VA(IL)/RM+VB(IL)+RM*(VC(IL)+RM*VD(IL))
     1  +(WA(IL)/RM+WB(IL)+RM*(WC(IL)+RM*WD(IL)))*ZI
      ZFG=(E-ZVF+2.0D0*SL*SL)/SL
      ZPO=ZP(ILAST)
      ZPOP=-K*ZPO/RM+ZFG*ZQ(ILAST)
      IL=IND(ILAST)
      ZVF=VA(IL)/RM+VB(IL)+RM*(VC(IL)+RM*VD(IL))
     1  +(WA(IL)/RM+WB(IL)+RM*(WC(IL)+RM*WD(IL)))*ZI
      ZFG=(E-ZVF+2.0D0*SL*SL)/SL
      ZPIA=ZPA(ILAST)
      ZPIAP=-K*ZPIA/RM+ZFG*ZQA(ILAST)
      ZPIB=ZPB(ILAST)
      ZPIBP=-K*ZPIB/RM+ZFG*ZQB(ILAST)
C
      ZRATIO=ZPOP/ZPO
      ZPHASE=(ZRATIO*(ZPIA+ZI*ZPIB)-(ZPIAP+ZI*ZPIBP))
     1      /((ZPIAP-ZI*ZPIBP)-ZRATIO*(ZPIA-ZI*ZPIB))
C
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE ZDOUTW
C  **************************************************************
      SUBROUTINE ZDOUTW(E,EPS,K,NR,NZERO,IOTP)
C
C     OUTWARD SOLUTION OF THE DIRAC RADIAL EQUATION FOR A COMPLEX
C  PIECEWISE CUBIC POTENTIAL. POWER SERIES METHOD.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Y), INTEGER*4 (I-N),
     1  COMPLEX*16 (Z)
      PARAMETER (NDIM=1000,NPPG=NDIM+1,NPTG=NDIM+NPPG)
      COMMON/ZRADWF/RAD(NDIM),ZPIO(NDIM),ZQIO(NDIM),NGP,ILAST,IER
      COMMON/ZRGRID/R(NPTG),ZP(NPTG),ZQ(NPTG),IND(NPTG),NRT
      COMMON/VGRID/RG(NPPG),RV(NPPG),VA(NPPG),VB(NPPG),VC(NPPG),
     1             VD(NPPG),NVT
      COMMON/VGRIDI/RWG(NPPG),WA(NPPG),WB(NPPG),WC(NPPG),WD(NPPG)
      COMMON/ZPOTEN/RV0,RV1,RV2,RV3,RW0,RW1,RW2,RW3
      COMMON/ZDINOU/ZPI,ZQI,ZPF,ZQF,RA,RB,RLN,NSTEP,NCHS
      COMMON/ZDSAVE/ZP0,ZQ0,ZP1,ZQ1,ZCA(60),ZCB(60),R0,R1,NSUM
      COMMON/NZT/NZMAX
      NZERO=0
      NZMAX=0
      AK=K
      IF(E.LT.0.0D0) THEN
        N1=NRT
      ELSE
        N1=IOTP-1
      ENDIF
C
      ZP(1)=0.0D0
      ZQ(1)=0.0D0
      DO 2 I=1,N1
      RA=R(I)
      RB=R(I+1)
      IN=IND(I)
      RV0=VA(IN)
      RV1=VB(IN)
      RV2=VC(IN)
      RV3=VD(IN)
      RW0=WA(IN)
      RW1=WB(IN)
      RW2=WC(IN)
      RW3=WD(IN)
      ZPI=ZP(I)
      ZQI=ZQ(I)
      CALL ZDIR(E,AK,EPS)
      NZERO=NZERO+NCHS
      IF(NCHS.GT.NZMAX) NZMAX=NCHS
      IF(NZERO.GT.NR.AND.E.LT.0.0D0) RETURN
      ZP(I+1)=ZPF
      ZQ(I+1)=ZQF
      IF(E.LT.0.0D0) THEN
C  ****  TCONV IS THE PRODUCT OF P AND ITS SECOND DERIVATIVE AT
C        THE I-TH GRID POINT (POSITIVE IF P IS CONVEX).
        TCONV=2.0D0*ZCA(3)*ZPI
        IF(I.GE.IOTP.AND.TCONV.GT.1.0D-15) THEN
          IOTP=I+1
          RETURN
        ENDIF
      ENDIF
      IF(I.EQ.1) GO TO 2
C  ****  RENORMALIZATION.
      IF(RLN.GT.0.0D0) THEN
      FACT=DEXP(-RLN)
      DO 1 J=1,I
      ZP(J)=ZP(J)*FACT
      ZQ(J)=ZQ(J)*FACT
    1 CONTINUE
      ENDIF
    2 CONTINUE
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE ZDIR
C  **************************************************************
      SUBROUTINE ZDIR(E,AK,EPS)
C
C  THIS SUBROUTINE SOLVES THE RADIAL DIRAC EQUATION FOR A COMPLEX
C  CENTRAL FIELD V(R) SUCH THAT
C              R*V(R) = RV0+RV1*R+RV2*R**2+RV3*R**3
C                     +ZI*(RW0+RW1*R+RW2*R**2+RW3*R**3)
C     GIVEN THE BOUNDARY CONDITIONS (I.E. THE VALUE OF THE
C  LARGE AND SMALL RADIAL FUNCTIONS) AT RA, THE SOLUTION IN
C  THE INTERVAL BETWEEN RA AND RB IS GENERATED BY USING A
C  PIECEWISE POWER SERIES EXPANSION FOR A PARTITION OF THE
C  INTERVAL, SUITABLY CHOSEN TO ALLOW FAST CONVERGENCE OF THE
C  SERIES.
C
C   INPUT ARGUMENTS:
C      E ..................... PARTICLE KINETIC ENERGY
C      AK .................... RELATIVISTIC ANGULAR MOMENTUM
C                              QUANTUM NUMBER
C
C   INPUT (COMMON POTEN):
C      RV0, RV1, RV2, RV3 .... REAL POTENTIAL PARAMETERS
C      RW0, RW1, RW2, RW3 .... IMAGINARY POTENTIAL PARAMETERS
C
C   INPUT-OUTPUT (COMMON DINOUT):
C      RA, RB ................ INTERVAL END POINTS (INPUT)
C      ZPI, ZQI ................ VALUES OF THE LARGE AND SMALL
C                              RADIAL FUNCTIONS AT RA (INPUT)
C      ZPF, ZQF ................ VALUES OF THE LARGE AND SMALL
C                              RADIAL FUNCTIONS AT RB (OUTPUT)
C      RLN ................... DLOG OF THE RE-NORMALIZING FACTOR
C      EPS ................... ESTIMATE OF THE GLOBAL ERROR IN
C                              PF AND QF
C      NSTEP ................. NUMBER OF STEPS
C      NCHS .................. NUMBER OF ZEROS OF P(R) IN (RA,RB)
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Y), INTEGER*4 (I-N),
     1  COMPLEX*16 (Z)
      COMMON/ZPOTEN/RV0,RV1,RV2,RV3,RW0,RW1,RW2,RW3
      COMMON/ZDINOU/ZPI,ZQI,ZPF,ZQF,RA,RB,RLN,NSTEP,NCHS
      COMMON/ZDSAVE/ZP0,ZQ0,ZP1,ZQ1,ZCA(60),ZCB(60),R0,R1,NSUM
      NCHS=0
      RLN=0.0D0
C
      H=RB-RA
      IF(H.LT.0.0D0) THEN
      DIRECT=-1.0D0
      ELSE
      DIRECT=1.0D0
      ENDIF
      K=-2
      NSTEP=0
C
      R1=RA
      ZP1=ZPI
      ZQ1=ZQI
    1 R0=R1
      ZP0=ZP1
      ZQ0=ZQ1
    2 IOUT=0
      R1=R0+H
      IF(DIRECT*(RB-R1).LT.DIRECT*1.0D-1*H) THEN
      R1=RB
      H=RB-R0
      IOUT=1
      ENDIF
      CALL ZDIR0(E,AK,EPS)
C
      K=K+1
      IF(NSUM.GT.15) GO TO 3
      IF(K.LT.0) GO TO 4
      H=H+H
      K=0
      GO TO 4
    3 IF(NSUM.LT.60) GO TO 4
      H=0.5D0*H
      K=-4
      GO TO 2
    4 NSTEP=NSTEP+1
      TST=ABS(ZP1)
      IF(TST.GT.1.0D2) THEN
C  ****  RENORMALIZATION.
      RLN=RLN+DLOG(TST)
      ZP1=ZP1/TST
      ZQ1=ZQ1/TST
      ENDIF
      TSTN=ZP0*ZP1
      IF(TSTN.LT.0.0D0.AND.R0.GT.0.0D0) NCHS=NCHS+1
      IF(IOUT.EQ.0) GO TO 1
C  ****  OUTPUT.
      ZPF=ZP1
      ZQF=ZQ1
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE ZDIR0
C  **************************************************************
      SUBROUTINE ZDIR0(E,AK,EPS)
C
C  Power series solution of the Dirac eq. for a central potential
C  with an imaginary component (negative for absorptive interac-
C  tions).
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Y), INTEGER*4 (I-N),
     1  COMPLEX*16 (Z)
C  ****  SPEED OF LIGHT AND OVERFLOW LEVEL.
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (OVER=1.0D15)
      COMMON/ZPOTEN/RV0,RV1,RV2,RV3,RW0,RW1,RW2,RW3
      COMMON/ZDSAVE/ZP0,ZQ0,ZP1,ZQ1,ZCA(60),ZCB(60),R0,R1,NSUM
C
      ZI=DCMPLX(0.0D0,1.0D0)
C
      ISIG=1
      IF(AK.GT.0.0D0) ISIG=-1
      H=R1-R0
      H2=H*H
      ZRVE=RV1+ZI*RW1-E
      ZRV0=RV0+ZI*RW0
      ZRV1=RV1+ZI*RW1
      ZRV2=RV2+ZI*RW2
      ZRV3=RV3+ZI*RW3
C
      IF(R0.GT.1.0D-10) GO TO 7
C
C  **** FIRST INTERVAL.
C
      ZU0=ZRV0/SL
      ZU1=ZRVE*R1/SL
      ZU2=ZRV2*R1**2/SL
      ZU3=ZRV3*R1**3/SL
      ZUT=ZU0+ZU1+ZU2+ZU3
      ZUQ=ZUT-2*SL*R1
      ZUH=ZU1-2*SL*R1
      IF(ABS(ZU0).LT.1.0D-10) GO TO 2
C
C  ****  U0.NE.0.
      ZS=SQRT(AK*AK-ZU0*ZU0)
      ZDS=ZS+ZS
      ZCA(1)=1.0D0
      ZCB(1)=-(ZS+AK)/ZU0
      ZCAI=ZU1*ZCA(1)
      ZCBI=ZUH*ZCB(1)
      ZCA(2)=(-ZU0*ZCAI-(ZS+1-AK)*ZCBI)/(ZDS+1)
      ZCB(2)=((ZS+1+AK)*ZCAI-ZU0*ZCBI)/(ZDS+1)
      ZCAI=ZU1*ZCA(2)+ZU2*ZCA(1)
      ZCBI=ZUH*ZCB(2)+ZU2*ZCB(1)
      ZCA(3)=(-ZU0*ZCAI-(ZS+2-AK)*ZCBI)/(2*(ZDS+2))
      ZCB(3)=((ZS+2+AK)*ZCAI-ZU0*ZCBI)/(2*(ZDS+2))
      ZP1=ZCA(1)+ZCA(2)+ZCA(3)
      ZPP1=ZS*ZCA(1)+(ZS+1)*ZCA(2)+(ZS+2)*ZCA(3)
      ZQ1=ZCB(1)+ZCB(2)+ZCB(3)
      ZQP1=ZS*ZCB(1)+(ZS+1)*ZCB(2)+(ZS+2)*ZCB(3)
C
      DO 1 I=4,60
      K=I-1
      ZCAI=ZU1*ZCA(K)+ZU2*ZCA(I-2)+ZU3*ZCA(I-3)
      ZCBI=ZUH*ZCB(K)+ZU2*ZCB(I-2)+ZU3*ZCB(I-3)
      ZCA(I)=(-ZU0*ZCAI-(ZS+K-AK)*ZCBI)/(K*(ZDS+K))
      ZCB(I)=((ZS+K+AK)*ZCAI-ZU0*ZCBI)/(K*(ZDS+K))
      ZP1=ZP1+ZCA(I)
      ZPP1=ZPP1+(ZS+K)*ZCA(I)
      ZQ1=ZQ1+ZCB(I)
      ZQP1=ZQP1+(ZS+K)*ZCB(I)
C  ****  CHECK OVERFLOW LIMIT.
      TST=DMAX1(ABS(ZP1),ABS(ZQ1),ABS(ZPP1),ABS(ZQP1))
      IF(TST.GT.OVER) THEN
      NSUM=100
      RETURN
      ENDIF
      T1A=ABS(R1*ZPP1+H*(AK*ZP1+ZUQ*ZQ1))
      T1B=ABS(R1*ZQP1-H*(AK*ZQ1+ZUT*ZP1))
      T1=MAX(T1A,T1B)
      T2=MAX(ABS(ZCA(I)),ABS(ZCB(I)))
      TST=EPS*MAX(ABS(ZP1),ABS(ZQ1))
      IF(T1.LT.TST.AND.T2.LT.TST) GO TO 6
    1 CONTINUE
      GO TO 6
C
C  ****  ZU0.EQ.0 AND SIG=1.
    2 IF(ISIG.LT.0) GO TO 4
      ZS=ABS(AK)
      ZDS1=ZS+ZS+1
      ZCA(1)=1.0D0
      ZCB(1)=ZU1*ZCA(1)/ZDS1
      ZCA(2)=0.0D0
      ZCB(2)=ZU2*ZCA(1)/(ZDS1+1)
      ZCA(3)=-ZUH*ZCB(1)/2
      ZCB(3)=(ZU1*ZCA(3)+ZU3*ZCA(1))/(ZDS1+2)
      ZCA(4)=-(ZUH*ZCB(2)+ZU2*ZCB(1))/3
      ZCB(4)=(ZU1*ZCA(4)+ZU2*ZCA(3))/(ZDS1+3)
      ZP1=ZCA(1)+ZCA(2)+ZCA(3)+ZCA(4)
      ZPP1=ZS*ZCA(1)+(ZS+1)*ZCA(2)+(ZS+2)*ZCA(3)+(ZS+3)*ZCA(4)
      ZQ1=ZCB(1)+ZCB(2)+ZCB(3)+ZCB(4)
      ZQP1=(ZS+1)*ZCB(1)+(ZS+2)*ZCB(2)+(ZS+3)*ZCB(3)
C
      DO 3 I=5,60
      K=I-1
      ZCA(I)=-(ZUH*ZCB(I-2)+ZU2*ZCB(I-3)+ZU3*ZCB(I-4))/K
      ZCB(I)=(ZU1*ZCA(I)+ZU2*ZCA(K)+ZU3*ZCA(I-2))/(ZDS1+K)
      ZP1=ZP1+ZCA(I)
      ZPP1=ZPP1+(ZS+K)*ZCA(I)
      ZQ1=ZQ1+ZCB(I)
      ZQP1=ZQP1+(ZS+I)*ZCB(I)
C  ****  CHECK OVERFLOW LIMIT.
      TST=MAX(ABS(ZP1),ABS(ZQ1),ABS(ZPP1),ABS(ZQP1))
      IF(TST.GT.OVER) THEN
      NSUM=100
      RETURN
      ENDIF
      T1A=ABS(R1*ZPP1+H*(AK*ZP1+ZUQ*ZQ1))
      T1B=ABS(R1*ZQP1-H*(AK*ZQ1+ZUT*ZP1))
      T1=MAX(T1A,T1B)
      T2=MAX(ABS(ZCA(I)),ABS(ZCB(I)))
      TST=EPS*MAX(ABS(ZP1),ABS(ZQ1))
      IF(T1.LT.TST.AND.T2.LT.TST) GO TO 6
    3 CONTINUE
      GO TO 6
C
C  ****  ZU0.EQ.0 AND SIG=-1.
    4 S=DABS(AK)+1
      DS1=S+DABS(AK)
      RZUH=ZUH
      IF(RZUH.GT.0.0D0) THEN
      ZCB(1)=-1.0D0
      ELSE
      ZCB(1)=1.0D0
      ENDIF
      ZCA(1)=-ZUH*ZCB(1)/DS1
      ZCB(2)=0.0D0
      ZCA(2)=-ZU2*ZCB(1)/(DS1+1)
      ZCB(3)=ZU1*ZCA(1)/2
      ZCA(3)=-(ZUH*ZCB(3)+ZU3*ZCB(1))/(DS1+2)
      ZCB(4)=(ZU1*ZCA(2)+ZU2*ZCA(1))/3
      ZCA(4)=-(ZUH*ZCB(4)+ZU2*ZCB(3))/(DS1+3)
      ZP1=ZCA(1)+ZCA(2)+ZCA(3)+ZCA(4)
      ZPP1=S*ZCA(1)+(S+1)*ZCA(2)+(S+2)*ZCA(3)+(S+3)*ZCA(4)
      ZQ1=ZCB(1)+ZCB(2)+ZCB(3)+ZCB(4)
      ZQP1=(S-1)*ZCB(1)+S*ZCB(2)+(S+1)*ZCB(3)
C
      DO 5 I=5,60
      K=I-1
      ZCB(I)=(ZU1*ZCA(I-2)+ZU2*ZCA(I-3)+ZU3*ZCA(I-4))/K
      ZCA(I)=-(ZUH*ZCB(I)+ZU2*ZCB(K)+ZU3*ZCB(I-2))/(DS1+K)
      ZP1=ZP1+ZCA(I)
      ZPP1=ZPP1+(S+K)*ZCA(I)
      ZQ1=ZQ1+ZCB(I)
      ZQP1=ZQP1+(S+K-1)*ZCB(I)
C  ****  CHECK OVERFLOW LIMIT.
      TST=MAX(ABS(ZP1),ABS(ZQ1),ABS(ZPP1),ABS(ZQP1))
      IF(TST.GT.OVER) THEN
      NSUM=100
      RETURN
      ENDIF
      T1A=ABS(R1*ZPP1+H*(AK*ZP1+ZUQ*ZQ1))
      T1B=ABS(R1*ZQP1-H*(AK*ZQ1+ZUT*ZP1))
      T1=MAX(T1A,T1B)
      T2=MAX(ABS(ZCA(I)),ABS(ZCB(I)))
      TST=EPS*MAX(ABS(ZP1),ABS(ZQ1))
      IF(T1.LT.TST.AND.T2.LT.TST) GO TO 6
    5 CONTINUE
C  ****  RENORMALIZATION.
    6 NSUM=K+1
      ZQ1=ZQ1/ABS(ZP1)
      ZP1=ZP1/ABS(ZP1)
      RETURN
C
C  **** MIDDLE REGION.
C
    7 CONTINUE
      RHO=H/R0
      ZU0=(ZRV0+R0*(ZRVE+R0*(ZRV2+R0*ZRV3)))/SL
      ZU1=(ZRVE+R0*(2*ZRV2+R0*3*ZRV3))*H/SL
      ZU2=(ZRV2+R0*3*ZRV3)*H2/SL
      ZU3=ZRV3*H*H2/SL
      ZUB=ZU0-2*SL*R0
      ZUH=ZU1-2*SL*H
      ZUT=ZU0+ZU1+ZU2+ZU3
      ZUQ=ZUT-2*SL*R1
C
      ZCA(1)=ZP0
      ZCB(1)=ZQ0
      ZCA(2)=-RHO*(AK*ZCA(1)+ZUB*ZCB(1))
      ZCB(2)=RHO*(AK*ZCB(1)+ZU0*ZCA(1))
      ZCA(3)=-RHO*((AK+1)*ZCA(2)+ZUB*ZCB(2)+ZUH*ZCB(1))/2
      ZCB(3)=RHO*((AK-1)*ZCB(2)+ZU0*ZCA(2)+ZU1*ZCA(1))/2
      ZCA(4)=-RHO*((AK+2)*ZCA(3)+ZUB*ZCB(3)+ZUH*ZCB(2)
     1      +ZU2*ZCB(1))/3
      ZCB(4)=RHO*((AK-2)*ZCB(3)+ZU0*ZCA(3)+ZU1*ZCA(2)
     1      +ZU2*ZCA(1))/3
C
      ZP1=ZCA(1)+ZCA(2)+ZCA(3)+ZCA(4)
      ZPP1=ZCA(2)+2*ZCA(3)+3*ZCA(4)
      ZQ1=ZCB(1)+ZCB(2)+ZCB(3)+ZCB(4)
      ZQP1=ZCB(2)+2*ZCB(3)+3*ZCB(4)
C
      DO 9 I=5,60
      K=I-1
      ZCA(I)=-RHO*((AK+K-1)*ZCA(K)+ZUB*ZCB(K)+ZUH*ZCB(I-2)
     1      +ZU2*ZCB(I-3)+ZU3*ZCB(I-4))/K
      ZCB(I)=RHO*((AK-K+1)*ZCB(K)+ZU0*ZCA(K)+ZU1*ZCA(I-2)
     1      +ZU2*ZCA(I-3)+ZU3*ZCA(I-4))/K
      ZP1=ZP1+ZCA(I)
      ZPP1=ZPP1+K*ZCA(I)
      ZQ1=ZQ1+ZCB(I)
      ZQP1=ZQP1+K*ZCB(I)
C  ****  CHECK OVERFLOW LIMIT.
      TST=MAX(ABS(ZP1),ABS(ZQ1),ABS(ZPP1),ABS(ZQP1))
      IF(TST.GT.OVER) THEN
      NSUM=100
      RETURN
      ENDIF
      T1A=ABS(R1*ZPP1+H*(AK*ZP1+ZUQ*ZQ1))
      T1B=ABS(R1*ZQP1-H*(AK*ZQ1+ZUT*ZP1))
      T1=MAX(T1A,T1B)
      T2=MAX(ABS(ZCA(I)),ABS(ZCB(I)))
      TST=EPS*MAX(ABS(ZP1),ABS(ZQ1))
      IF(T1.LT.TST.AND.T2.LT.TST) GO TO 10
    9 CONTINUE
C
   10 NSUM=K+1
      RETURN
      END
C
C >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
C >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
C Subroutines from the RADIAL package (modified to follow Roses's phase
C convention). Here all quantities are in atomic units.
C >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
C >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
C
C  **************************************************************
C                        SUBROUTINE VINT
C  **************************************************************
      SUBROUTINE VINT(R,RV,NV)
C
C     NATURAL CUBIC SPLINE INTERPOLATION FOR R*V(R) FROM THE
C  INPUT RADII AND POTENTIAL VALUES (128).
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER (NDIM=1000,NPPG=NDIM+1,NPTG=NDIM+NPPG)
      COMMON/VGRID/RG(NPPG),RVG(NPPG),VA(NPPG),VB(NPPG),VC(NPPG),
     1             VD(NPPG),NVT
      COMMON/RGRID/X(NPTG),P(NPTG),Q(NPTG),IND(NPTG),NRT
      COMMON/STORE/Y(NPTG),A(NPTG),B(NPTG),C(NPTG),D(NPTG)
      DIMENSION R(NDIM),RV(NDIM)
C
      IF(R(1).LT.0.0D0) THEN
      WRITE(6,2101)
 2101 FORMAT(1X,'*** ERROR IN VINT: R(1).LT.0.')
      STOP
      ENDIF
      IF(NV.GT.NDIM) THEN
      WRITE(6,2102) NDIM
 2102 FORMAT(1X,'*** ERROR IN VINT: INPUT POTENTIAL GRID WITH ',
     1  'MORE THAN ',I5,' DATA POINTS.')
      STOP
      ENDIF
      R(1)=0.0D0
C
      IO=0
      I=0
      K=0
    1 I=I+1
      K=K+1
      X(K)=R(I)
      Y(K)=RV(I)
      IF(I.EQ.NV) GO TO 2
      IF(R(I).LT.R(I+1)-1.0D-12) GO TO 1
    2 CONTINUE
C
      CALL SPLINE(X,Y,A,B,C,D,0.0D0,0.0D0,K)
C
      K=K-1
      DO 3 J=1,K
      IO=IO+1
      RG(IO)=X(J)
      RVG(IO)=Y(J)
      VA(IO)=A(J)
      VB(IO)=B(J)
      VC(IO)=C(J)
      VD(IO)=D(J)
    3 CONTINUE
      IF(I.LT.NV) THEN
        K=0
        GO TO 1
      ENDIF
C  ****  AN EXTRA POINT IS ADDED TO THE GRID, AND R*V(R) IS SET
C        EQUAL TO RV(NV) FOR R.GE.R(NV)
      IO=IO+1
      RG(IO)=X(K+1)
      RVG(IO)=Y(K+1)
      VA(IO)=RVG(IO)
      VB(IO)=0.0D0
      VC(IO)=0.0D0
      VD(IO)=0.0D0
      NVT=IO+1
      RG(NVT)=2.0D0*RG(IO)
      RVG(NVT)=RVG(IO)
      VA(NVT)=RVG(IO)
      VB(NVT)=0.0D0
      VC(NVT)=0.0D0
      VD(NVT)=0.0D0
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE DOUTW
C  **************************************************************
      SUBROUTINE DOUTW(E,EPS,K,NR,NZERO,IOTP)
C
C     OUTWARD SOLUTION OF THE DIRAC RADIAL EQUATION FOR A PIECE-
C   WISE CUBIC FIELD. POWER SERIES METHOD.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      PARAMETER (NDIM=1000,NPPG=NDIM+1,NPTG=NDIM+NPPG)
      COMMON/RADWF/RAD(NDIM),PIO(NDIM),QIO(NDIM),NGP,ILAST,IER
      COMMON/RGRID/R(NPTG),P(NPTG),Q(NPTG),IND(NPTG),NRT
      COMMON/VGRID/RG(NPPG),RV(NPPG),VA(NPPG),VB(NPPG),VC(NPPG),
     1             VD(NPPG),NVT
      COMMON/POTEN/RV0,RV1,RV2,RV3
      COMMON/DINOUT/PI,QI,PF,QF,RA,RB,RLN,NSTEP,NCHS
      COMMON/DSAVE/P0,Q0,P1,Q1,CA(60),CB(60),R0,R1,NSUM
      COMMON/NZT/NZMAX
      NZERO=0
      NZMAX=0
      AK=K
      IF(E.LT.0.0D0) THEN
        N1=NRT
      ELSE
        N1=IOTP-1
      ENDIF
C
      P(1)=0.0D0
      Q(1)=0.0D0
      DO 2 I=1,N1
      RA=R(I)
      RB=R(I+1)
      IN=IND(I)
      RV0=VA(IN)
      RV1=VB(IN)
      RV2=VC(IN)
      RV3=VD(IN)
      PI=P(I)
      QI=Q(I)
      CALL DIR(E,AK,EPS)
      NZERO=NZERO+NCHS
      IF(NCHS.GT.NZMAX) NZMAX=NCHS
      IF(NZERO.GT.NR.AND.E.LT.0.0D0) RETURN
      P(I+1)=PF
      Q(I+1)=QF
      IF(E.LT.0.0D0) THEN
C  ****  TCONV IS THE PRODUCT OF P AND ITS SECOND DERIVATIVE AT
C        THE I-TH GRID POINT (POSITIVE IF P IS CONVEX).
        TCONV=2.0D0*CA(3)*PI
        IF(I.GE.IOTP.AND.TCONV.GT.1.0D-15) THEN
          IOTP=I+1
          RETURN
        ENDIF
      ENDIF
      IF(I.EQ.1) GO TO 2
C  ****  RENORMALIZATION.
      IF(RLN.GT.0.0D0) THEN
      FACT=DEXP(-RLN)
      DO 1 J=1,I
      P(J)=P(J)*FACT
      Q(J)=Q(J)*FACT
    1 CONTINUE
      ENDIF
    2 CONTINUE
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE DIR
C  **************************************************************
      SUBROUTINE DIR(E,AK,EPS)
C
C      THIS SUBROUTINE SOLVES THE RADIAL DIRAC EQUATION FOR A
C   CENTRAL FIELD V(R) SUCH THAT
C              R*V(R) = RV0+RV1*R+RV2*R**2+RV3*R**3
C      GIVEN THE BOUNDARY CONDITIONS (I.E. THE VALUE OF THE
C   LARGE AND SMALL RADIAL FUNCTIONS) AT RA, THE SOLUTION IN
C   THE INTERVAL BETWEEN RA AND RB IS GENERATED BY USING A
C   PIECEWISE POWER SERIES EXPANSION FOR A PARTITION OF THE
C   INTERVAL, SUITABLY CHOSEN TO ALLOW FAST CONVERGENCE OF THE
C   SERIES.
C
C   INPUT ARGUMENTS:
C      E ..................... PARTICLE KINETIC ENERGY
C      AK .................... RELATIVISTIC ANGULAR MOMENTUM
C                              QUANTUM NUMBER
C
C   INPUT (COMMON POTEN):
C      RV0, RV1, RV2, RV3 .... POTENTIAL PARAMETERS
C
C   INPUT-OUTPUT (COMMON DINOUT):
C      RA, RB ................ INTERVAL END POINTS (INPUT)
C      PI, QI ................ VALUES OF THE LARGE AND SMALL
C                              RADIAL FUNCTIONS AT RA (INPUT)
C      PF, QF ................ VALUES OF THE LARGE AND SMALL
C                              RADIAL FUNCTIONS AT RB (OUTPUT)
C      RLN ................... DLOG OF THE RE-NORMALIZING FACTOR
C      EPS ................... ESTIMATE OF THE GLOBAL ERROR IN
C                              PF AND QF
C      NSTEP ................. NUMBER OF STEPS
C      NCHS .................. NUMBER OF ZEROS OF P(R) IN (RA,RB)
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      COMMON/POTEN/RV0,RV1,RV2,RV3
      COMMON/DINOUT/PI,QI,PF,QF,RA,RB,RLN,NSTEP,NCHS
      COMMON/DSAVE/P0,Q0,P1,Q1,CA(60),CB(60),R0,R1,NSUM
      NCHS=0
      RLN=0.0D0
C
      H=RB-RA
      IF(H.LT.0.0D0) THEN
      DIRECT=-1.0D0
      ELSE
      DIRECT=1.0D0
      ENDIF
      K=-2
      NSTEP=0
C
      R1=RA
      P1=PI
      Q1=QI
    1 R0=R1
      P0=P1
      Q0=Q1
    2 IOUT=0
      R1=R0+H
      IF(DIRECT*(RB-R1).LT.DIRECT*1.0D-1*H) THEN
      R1=RB
      H=RB-R0
      IOUT=1
      ENDIF
      CALL DIR0(E,AK,EPS)
C
      K=K+1
      IF(NSUM.GT.15) GO TO 3
      IF(K.LT.0) GO TO 4
      H=H+H
      K=0
      GO TO 4
    3 IF(NSUM.LT.60) GO TO 4
      H=0.5D0*H
      K=-4
      GO TO 2
    4 NSTEP=NSTEP+1
      TST=DABS(P1)
      IF(TST.GT.1.0D2) THEN
C  ****  RENORMALIZATION.
      RLN=RLN+DLOG(TST)
      P1=P1/TST
      Q1=Q1/TST
      ENDIF
      IF(P0*P1.LT.0.0D0.AND.R0.GT.0.0D0) NCHS=NCHS+1
      IF(IOUT.EQ.0) GO TO 1
C  ****  OUTPUT.
      PF=P1
      QF=Q1
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE DIR0
C  **************************************************************
      SUBROUTINE DIR0(E,AK,EPS)
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
C  ****  SPEED OF LIGHT AND OVERFLOW LEVEL.
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (OVER=1.0D15)
      COMMON/POTEN/RV0,RV1,RV2,RV3
      COMMON/DSAVE/P0,Q0,P1,Q1,CA(60),CB(60),R0,R1,NSUM
C
      ISIG=1
      IF(AK.GT.0.0D0) ISIG=-1
      H=R1-R0
      H2=H*H
      RVE=RV1-E
C
      IF(R0.GT.1.0D-10) GO TO 7
C
C  **** FIRST INTERVAL. (147-164)
C
      U0=RV0/SL
      U1=RVE*R1/SL
      U2=RV2*R1**2/SL
      U3=RV3*R1**3/SL
      UT=U0+U1+U2+U3
      UQ=UT-2*SL*R1
      UH=U1-2*SL*R1
      IF(DABS(U0).LT.1.0D-10) GO TO 2
C
C  ****  U0.NE.0. (155-159)
      S=DSQRT(AK*AK-U0*U0)
      DS=S+S
      CA(1)=1.0D0
      CB(1)=-(S+AK)/U0
      CAI=U1*CA(1)
      CBI=UH*CB(1)
      CA(2)=(-U0*CAI-(S+1-AK)*CBI)/(DS+1)
      CB(2)=((S+1+AK)*CAI-U0*CBI)/(DS+1)
      CAI=U1*CA(2)+U2*CA(1)
      CBI=UH*CB(2)+U2*CB(1)
      CA(3)=(-U0*CAI-(S+2-AK)*CBI)/(2*(DS+2))
      CB(3)=((S+2+AK)*CAI-U0*CBI)/(2*(DS+2))
      P1=CA(1)+CA(2)+CA(3)
      PP1=S*CA(1)+(S+1)*CA(2)+(S+2)*CA(3)
      Q1=CB(1)+CB(2)+CB(3)
      QP1=S*CB(1)+(S+1)*CB(2)+(S+2)*CB(3)
C
      DO 1 I=4,60
      K=I-1
      CAI=U1*CA(K)+U2*CA(I-2)+U3*CA(I-3)
      CBI=UH*CB(K)+U2*CB(I-2)+U3*CB(I-3)
      CA(I)=(-U0*CAI-(S+K-AK)*CBI)/(K*(DS+K))
      CB(I)=((S+K+AK)*CAI-U0*CBI)/(K*(DS+K))
      P1=P1+CA(I)
      PP1=PP1+(S+K)*CA(I)
      Q1=Q1+CB(I)
      QP1=QP1+(S+K)*CB(I)
C  ****  CHECK OVERFLOW LIMIT.
      TST=DMAX1(DABS(P1),DABS(Q1),DABS(PP1),DABS(QP1))
      IF(TST.GT.OVER) THEN
      NSUM=100
      RETURN
      ENDIF
      T1A=DABS(R1*PP1+H*(AK*P1+UQ*Q1))
      T1B=DABS(R1*QP1-H*(AK*Q1+UT*P1))
      T1=DMAX1(T1A,T1B)
      T2=DMAX1(DABS(CA(I)),DABS(CB(I)))
      TST=EPS*DMAX1(DABS(P1),DABS(Q1))
      IF(T1.LT.TST.AND.T2.LT.TST) GO TO 6
    1 CONTINUE
      GO TO 6
C
C  ****  U0.EQ.0 AND SIG=1. (160,161)
    2 IF(ISIG.LT.0) GO TO 4
      S=DABS(AK)
      DS1=S+S+1
      CA(1)=1.0D0
      CB(1)=U1*CA(1)/DS1
      CA(2)=0.0D0
      CB(2)=U2*CA(1)/(DS1+1)
      CA(3)=-UH*CB(1)/2
      CB(3)=(U1*CA(3)+U3*CA(1))/(DS1+2)
      CA(4)=-(UH*CB(2)+U2*CB(1))/3
      CB(4)=(U1*CA(4)+U2*CA(3))/(DS1+3)
      P1=CA(1)+CA(2)+CA(3)+CA(4)
      PP1=S*CA(1)+(S+1)*CA(2)+(S+2)*CA(3)+(S+3)*CA(4)
      Q1=CB(1)+CB(2)+CB(3)+CB(4)
      QP1=(S+1)*CB(1)+(S+2)*CB(2)+(S+3)*CB(3)
C
      DO 3 I=5,60
      K=I-1
      CA(I)=-(UH*CB(I-2)+U2*CB(I-3)+U3*CB(I-4))/K
      CB(I)=(U1*CA(I)+U2*CA(K)+U3*CA(I-2))/(DS1+K)
      P1=P1+CA(I)
      PP1=PP1+(S+K)*CA(I)
      Q1=Q1+CB(I)
      QP1=QP1+(S+I)*CB(I)
C  ****  CHECK OVERFLOW LIMIT.
      TST=DMAX1(DABS(P1),DABS(Q1),DABS(PP1),DABS(QP1))
      IF(TST.GT.OVER) THEN
      NSUM=100
      RETURN
      ENDIF
      T1A=DABS(R1*PP1+H*(AK*P1+UQ*Q1))
      T1B=DABS(R1*QP1-H*(AK*Q1+UT*P1))
      T1=DMAX1(T1A,T1B)
      T2=DMAX1(DABS(CA(I)),DABS(CB(I)))
      TST=EPS*DMAX1(DABS(P1),DABS(Q1))
      IF(T1.LT.TST.AND.T2.LT.TST) GO TO 6
    3 CONTINUE
      GO TO 6
C
C  ****  U0.EQ.0 AND SIG=-1. (162,163)
    4 S=DABS(AK)+1
      DS1=S+DABS(AK)
      IF(UH.GT.0.0D0) THEN
      CB(1)=-1.0D0
      ELSE
      CB(1)=1.0D0
      ENDIF
      CA(1)=-UH*CB(1)/DS1
      CB(2)=0.0D0
      CA(2)=-U2*CB(1)/(DS1+1)
      CB(3)=U1*CA(1)/2
      CA(3)=-(UH*CB(3)+U3*CB(1))/(DS1+2)
      CB(4)=(U1*CA(2)+U2*CA(1))/3
      CA(4)=-(UH*CB(4)+U2*CB(3))/(DS1+3)
      P1=CA(1)+CA(2)+CA(3)+CA(4)
      PP1=S*CA(1)+(S+1)*CA(2)+(S+2)*CA(3)+(S+3)*CA(4)
      Q1=CB(1)+CB(2)+CB(3)+CB(4)
      QP1=(S-1)*CB(1)+S*CB(2)+(S+1)*CB(3)
C
      DO 5 I=5,60
      K=I-1
      CB(I)=(U1*CA(I-2)+U2*CA(I-3)+U3*CA(I-4))/K
      CA(I)=-(UH*CB(I)+U2*CB(K)+U3*CB(I-2))/(DS1+K)
      P1=P1+CA(I)
      PP1=PP1+(S+K)*CA(I)
      Q1=Q1+CB(I)
      QP1=QP1+(S+K-1)*CB(I)
C  ****  CHECK OVERFLOW LIMIT.
      TST=DMAX1(DABS(P1),DABS(Q1),DABS(PP1),DABS(QP1))
      IF(TST.GT.OVER) THEN
      NSUM=100
      RETURN
      ENDIF
      T1A=DABS(R1*PP1+H*(AK*P1+UQ*Q1))
      T1B=DABS(R1*QP1-H*(AK*Q1+UT*P1))
      T1=DMAX1(T1A,T1B)
      T2=DMAX1(DABS(CA(I)),DABS(CB(I)))
      TST=EPS*DMAX1(DABS(P1),DABS(Q1))
      IF(T1.LT.TST.AND.T2.LT.TST) GO TO 6
    5 CONTINUE
C  ****  RENORMALIZATION. (164)
    6 NSUM=K+1
      Q1=Q1/DABS(P1)
      P1=P1/DABS(P1)
      RETURN
C
C  **** MIDDLE REGION. (148-152)
C
    7 CONTINUE
      RHO=H/R0
      U0=(RV0+R0*(RVE+R0*(RV2+R0*RV3)))/SL
      U1=(RVE+R0*(2*RV2+R0*3*RV3))*H/SL
      U2=(RV2+R0*3*RV3)*H2/SL
      U3=RV3*H*H2/SL
      UB=U0-2*SL*R0
      UH=U1-2*SL*H
      UT=U0+U1+U2+U3
      UQ=UT-2*SL*R1
C
      CA(1)=P0
      CB(1)=Q0
      CA(2)=-RHO*(AK*CA(1)+UB*CB(1))
      CB(2)=RHO*(AK*CB(1)+U0*CA(1))
      CA(3)=-RHO*((AK+1)*CA(2)+UB*CB(2)+UH*CB(1))/2
      CB(3)=RHO*((AK-1)*CB(2)+U0*CA(2)+U1*CA(1))/2
      CA(4)=-RHO*((AK+2)*CA(3)+UB*CB(3)+UH*CB(2)+U2*CB(1))/3
      CB(4)=RHO*((AK-2)*CB(3)+U0*CA(3)+U1*CA(2)+U2*CA(1))/3
C
      P1=CA(1)+CA(2)+CA(3)+CA(4)
      PP1=CA(2)+2*CA(3)+3*CA(4)
      Q1=CB(1)+CB(2)+CB(3)+CB(4)
      QP1=CB(2)+2*CB(3)+3*CB(4)
C
      DO 9 I=5,60
      K=I-1
      CA(I)=-RHO*((AK+K-1)*CA(K)+UB*CB(K)+UH*CB(I-2)+U2*CB(I-3)
     1     +U3*CB(I-4))/K
      CB(I)=RHO*((AK-K+1)*CB(K)+U0*CA(K)+U1*CA(I-2)+U2*CA(I-3)
     1     +U3*CA(I-4))/K
      P1=P1+CA(I)
      PP1=PP1+K*CA(I)
      Q1=Q1+CB(I)
      QP1=QP1+K*CB(I)
C  ****  CHECK OVERFLOW LIMIT.
      TST=DMAX1(DABS(P1),DABS(Q1),DABS(PP1),DABS(QP1))
      IF(TST.GT.OVER) THEN
      NSUM=100
      RETURN
      ENDIF
      T1A=DABS(R1*PP1+H*(AK*P1+UQ*Q1))
      T1B=DABS(R1*QP1-H*(AK*Q1+UT*P1))
      T1=DMAX1(T1A,T1B)
      T2=DMAX1(DABS(CA(I)),DABS(CB(I)))
      TST=EPS*DMAX1(DABS(P1),DABS(Q1))
      IF(T1.LT.TST.AND.T2.LT.TST) GO TO 10
    9 CONTINUE
C
   10 NSUM=K+1
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE SPLINE
C  **************************************************************
      SUBROUTINE SPLINE(X,Y,A,B,C,D,S1,SN,N)
C
C      CUBIC SPLINE INTERPOLATION BETWEEN TABULATED DATA.
C   INPUT:
C     X(I) (I=1, ...,N) ........ GRID POINTS.
C                    (THE X VALUES MUST BE IN INCREASING ORDER).
C     Y(I) (I=1, ...,N) ........ CORRESPONDING FUNCTION VALUES.
C     S1,SN ..... SECOND DERIVATIVES AT X(1) AND X(N).
C            (THE NATURAL SPLINE CORRESPONDS TO TAKING S1=SN=0).
C     N ........................ NUMBER OF GRID POINTS.
C      THE INTERPOLATING POLYNOMIAL IN THE I-TH INTERVAL, FROM
C   X(I) TO X(I+1), IS
C            PI(X) = A(I)+X*(B(I)+X*(C(I)+X*D(I)))
C   OUTPUT:
C     A(I),B(I),C(I),D(I) ...... SPLINE COEFFICIENTS.
C
C      REF.: M.J. MARON, 'NUMERICAL ANALYSIS: A PRACTICAL
C            APPROACH', MACMILLAN PUBL. CO., NEW YORK 1982.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      DIMENSION X(N),Y(N),A(N),B(N),C(N),D(N)
      IF(N.LT.4) THEN
      WRITE(6,10) N
   10 FORMAT(5X,'SPLINE INTERPOLATION CANNOT BE PERFORMED WITH',
     1I4,' POINTS. STOP.')
      STOP
      ENDIF
      N1=N-1
      N2=N-2
C  ****  AUXILIARY ARRAYS H(=A) AND DELTA(=D).
      DO 1 I=1,N1
      IF(X(I+1)-X(I).LT.1.0D-13) THEN
      WRITE(6,11)
   11 FORMAT(5X,'SPLINE X VALUES NOT IN INCREASING ORDER. STOP.')
      STOP
      ENDIF
      A(I)=X(I+1)-X(I)
    1 D(I)=(Y(I+1)-Y(I))/A(I)
C  ****  SYMMETRIC COEFFICIENT MATRIX (AUGMENTED).
      DO 2 I=1,N2
      B(I)=2.0D0*(A(I)+A(I+1))
      K=N1-I+1
    2 D(K)=6.0D0*(D(K)-D(K-1))
      D(2)=D(2)-A(1)*S1
      D(N1)=D(N1)-A(N1)*SN
C  ****  GAUSS SOLUTION OF THE TRIDIAGONAL SYSTEM.
      DO 3 I=2,N2
      R=A(I)/B(I-1)
      B(I)=B(I)-R*A(I)
    3 D(I+1)=D(I+1)-R*D(I)
C  ****  THE SIGMA COEFFICIENTS ARE STORED IN ARRAY D.
      D(N1)=D(N1)/B(N2)
      DO 4 I=2,N2
      K=N1-I+1
    4 D(K)=(D(K)-A(K)*D(K+1))/B(K-1)
      D(N)=SN
C  ****  SPLINE COEFFICIENTS.
      SI1=S1
      DO 5 I=1,N1
      SI=SI1
      SI1=D(I+1)
      H=A(I)
      HI=1.0D0/H
      A(I)=(HI/6.0D0)*(SI*X(I+1)**3-SI1*X(I)**3)
     1    +HI*(Y(I)*X(I+1)-Y(I+1)*X(I))
     2    +(H/6.0D0)*(SI1*X(I)-SI*X(I+1))
      B(I)=(HI/2.0D0)*(SI1*X(I)**2-SI*X(I+1)**2)
     1    +HI*(Y(I+1)-Y(I))+(H/6.0D0)*(SI-SI1)
      C(I)=(HI/2.0D0)*(SI*X(I+1)-SI1*X(I))
    5 D(I)=(HI/6.0D0)*(SI1-SI)
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE FINDI
C  **************************************************************
      SUBROUTINE FINDI(X,XC,N,I)
C
C      FINDS THE INTERVAL (X(I),X(I+1)) CONTAINING THE VALUE XC.
C   INPUT:
C     X(I) (I=1, ...,N) ........ GRID POINTS.
C                    (THE X VALUES MUST BE IN INCREASING ORDER).
C     XC ....................... POINT TO BE LOCATED.
C     N ........................ NUMBER OF GRID POINTS.
C   OUTPUT:
C     I ........................ INTERVAL INDEX.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      DIMENSION X(N)
      IF(XC.GT.X(N)) THEN
      I=N-1
      RETURN
      ENDIF
      IF(XC.LT.X(1)) THEN
      I=1
      RETURN
      ENDIF
      I=1
      I1=N
    1 IT=(I+I1)/2
      IF(XC.GT.X(IT)) I=IT
      IF(XC.LE.X(IT)) I1=IT
      IF(I1-I.GT.1) GO TO 1
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE DCOUL
C  **************************************************************
      SUBROUTINE DCOUL(Z,E,K,R,FU,FL,GU,GL,ERR)
C
C     THIS SUBROUTINE COMPUTES RADIAL DIRAC-COULOMB WAVE FUNC-
C  TIONS FOR FREE STATES.
C
C  **** ALL QUANTITIES IN ATOMIC UNITS.
C
C  INPUT ARGUMENTS:
C     Z ........ FIELD STRENGTH, I.E. VALUE OF R*V(R) (ASSUMED
C                CONSTANT).
C     E ........ PARTICLE KINETIC ENERGY (POSITIVE).
C     K ........ ANGULAR MOMENTUM QUANTUM NUMBER KAPPA (.NE.0).
C     R ........ RADIAL DISTANCE (POSITIVE).
C
C  OUTPUT ARGUMENTS:
C     FU, FL ... UPPER AND LOWER COMPONENTS OF THE REGULAR RADIAL
C                COULOMB FUNCTION.
C     GU, GL ... UPPER AND LOWER COMPONENTS OF THE IRREGULAR RA-
C                DIAL COULOMB FUNCTION.
C     ERR ...... ACCURACY OF THE COMPUTED FUNCTIONS (RELATIVE UN-
C                CERTAINTY).
C  OUTPUT THROUGH COMMON/OCOUL/:
C     WAVNUM ... WAVE NUMBER.
C     ETA ...... SOMMERFELD'S PARAMETER.
C     DELTA .... COULOMB PHASE SHIFT (MODULUS 2*PI).
C
C     RADIAL FUNCTIONS ARE NORMALIZED SO THAT, FOR LARGE R, THE
C  UPPER COMPONENT OSCILLATES WITH UNIT AMPLITUDE.
C
C     OTHER SUBPROGRAMS REQUIRED: SUBROUTINES FCOUL AND SUM2F0,
C                                 AND FUNCTION CLGAM.
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1  INTEGER*4 (I-N)
      PARAMETER (SL=137.035999139D0)  ! Speed of light (1/alpha)
      PARAMETER (SL2=SL*SL,TSL2=SL2+SL2,ALPHA=1.0D0/SL)
      PARAMETER (PI=3.1415926535897933D0,PIH=0.5D0*PI,TPI=PI+PI)
      COMMON/OCOUL/WAVNUM,ETA,DELTA
C
      IF(DABS(Z).GT.0.00001D0) THEN
        ZETA=Z*ALPHA
        ICAL=0
      ELSE
        ZETA=0.0D0
        ICAL=1
      ENDIF
      RLAMBS=K*K-ZETA*ZETA
      RLAMB=DSQRT(RLAMBS)
      PC=DSQRT(E*(E+TSL2))
      WAVNUM=PC/SL
      X=WAVNUM*R
C
      IF(E.LT.0.0001D0.OR.K.EQ.0) THEN
        FU=0.0D0
        FL=0.0D0
        GU=1.0D35
        GL=-1.0D35
        ERR=1.0D0
        DELTA=0.0D0
        IF(E.LT.0.0001D0) WRITE(6,2101)
 2101   FORMAT(1X,'*** ERROR IN DCOUL: E IS TOO SMALL.')
        IF(K.EQ.0) WRITE(6,2102)
 2102   FORMAT(1X,'*** ERROR IN DCOUL: K.EQ.0.')
        RETURN
      ENDIF
      IF(ICAL.EQ.1) GO TO 1
C
C  ****  PARAMETERS.
C
      RLAMB1=RLAMB-1.0D0
      W=E+SL2
      ETA=ZETA*W/PC
      RLA=DSQRT(RLAMBS+ETA*ETA)
      P1=K+RLAMB
      P2=RLAMB*SL2-K*W
      RNUR=ZETA*(W+SL2)
      RNUI=-P1*PC
      RNU=DATAN2(RNUI,RNUR)
      RNORM=1.0D0/(DSQRT(RNUR*RNUR+RNUI*RNUI)*RLAMB)
C
C  ****  COULOMB PHASE SHIFT.
C
      IF(K.GT.0) THEN
        L=K
      ELSE
        L=-K-1
      ENDIF
      DELTA0=DELTAC(ETA,RLAMB1)
      DELTA=RNU-(RLAMB-L-1)*PIH+DELTA0
      IF(Z.LT.0.0D0.AND.K.LT.0) THEN
        RNORM=-RNORM
        DELTA=DELTA-PI
      ENDIF
      IF(DELTA.GE.0.0D0) THEN
        DELTA=DMOD(DELTA,TPI)
      ELSE
        DELTA=-DMOD(-DELTA,TPI)
      ENDIF
C
C  ****  COULOMB FUNCTIONS.
C
      CALL FCOUL(ETA,RLAMB1,X,FM1,FPM1,GM1,GPM1,ERR)
      IF(ERR.GT.1.0D-6) THEN
        FU=0.0D0
        FL=0.0D0
        GU=1.0D35
        GL=-1.0D35
        ERR=1.0D0
        RETURN
      ENDIF
      SLA=(RLAMB/X)+(ETA/RLAMB)
      F=RLAMB*(SLA*FM1-FPM1)/RLA
      G=RLAMB*(SLA*GM1-GPM1)/RLA
C
C  ****  DIRAC-COULOMB WAVE FUNCTIONS.
C
      Q2=P1*P2*RNORM
      Q1=RLA*PC*RNORM
      P1=P1*Q1
      Q1=ZETA*Q1
      P2=ZETA*P2*RNORM
C
      FU=P1*F+P2*FM1
      FL=-Q1*F-Q2*FM1
      GU=P1*G+P2*GM1
      GL=-Q1*G-Q2*GM1
      RETURN
C
C  ****  Z=0. SPHERICAL BESSEL FUNCTIONS.
C
    1 CONTINUE
      RLAMB=IABS(K)
      CALL FCOUL(0.0D0,RLAMB,X,F,FP,G,GP,ERR)
      DELTA=0.0D0
      IF(ERR.GE.1.0D-6) THEN
        FU=0.0D0
        FL=0.0D0
        GU=1.0D35
        GL=-1.0D35
        ERR=1.0D0
        RETURN
      ENDIF
      FM1=(RLAMB*F/X)+FP
      GM1=(RLAMB*G/X)+GP
      FACT=DSQRT(E/(E+TSL2))
      IF(K.LT.0) THEN
        FU=FM1
        FL=-FACT*F
        GU=GM1
        GL=-FACT*G
      ELSE
        FU=F
        FL=FACT*FM1
        GU=G
        GL=FACT*GM1
      ENDIF
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE FCOUL
C  **************************************************************
      SUBROUTINE FCOUL(ETA,RLAMB,X,F,FP,G,GP,ERR)
C
C     CALCULATION OF COULOMB FUNCTIONS FOR REAL ETA, RLAMB.GT.-1
C  AND X LARGER THAN, OR OF THE ORDER OF XTP0 (THE TURNING POINT
C  FOR RLAMB=0). STEED'S CONTINUED FRACTION METHOD IS COMBINED
C  WITH RECURSION RELATIONS AND AN ASYMPTOTIC EXPANSION. THE
C  OUTPUT VALUE ERR=1.0D0 INDICATES THAT THE ADOPTED EVALUATION
C  ALGORITHM IS NOT APPLICABLE (X IS TOO SMALL).
C
C  INPUT ARGUMENTS:
C     ETA ...... SOMMERFELD'S PARAMETER.
C     RLAMB .... ANGULAR MOMENTUM.
C     X ........ VARIABLE (=WAVE NUMBER TIMES RADIAL DISTANCE).
C
C  OUTPUT ARGUMENTS:
C     F, FP .... REGULAR FUNCTION AND ITS DERIVATIVE.
C     G, GP .... IRREGULAR FUNCTION AND ITS DERIVATIVE.
C     ERR ...... RELATIVE NUMERICAL UNCERTAINTY. A VALUE OF THE
C                ORDER OF 10**(-N) MEANS THAT THE CALCULATED
C                FUNCTIONS ARE ACCURATE TO N DECIMAL FIGURES.
C                THE MAXIMUM ACCURACY ATTAINABLE WITH DOUBLE
C                PRECISION ARITHMETIC IS ABOUT 1.0D-15.
C
C     OTHER SUBPROGRAMS REQUIRED: SUBROUTINE SUM2F0 AND
C                                 FUNCTIONS DELTAC AND CLGAM.
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1  INTEGER*4 (I-N)
      PARAMETER (PI=3.1415926535897932D0,PIH=0.5D0*PI,TPI=PI+PI,
     1  EPS=1.0D-16,TOP=1.0D5,NTERM=1000)
C
      IF(RLAMB.LT.-0.999D0) THEN
        WRITE(6,'(1X,''*** ERROR IN FCOUL: RLAMB.LT.-0.999'')')
        STOP
      ENDIF
      IF(X.LT.EPS) GO TO 10
C
C  ****  NUMERICAL CONSTANTS.
C
      CI=DCMPLX(0.0D0,1.0D0)
      CI2=2.0D0*CI
      CIETA=CI*ETA
      X2=X*X
      ETA2=ETA*ETA
C
C  ****  TURNING POINT (XTP). (44)
C
      IF(RLAMB.GE.0.0D0) THEN
        XTP=ETA+DSQRT(ETA2+RLAMB*(RLAMB+1.0D0))
      ELSE
        XTP=EPS
      ENDIF
      ERRS=10.0D0
      IF(X.LT.XTP) GO TO 1
C
C  ************  ASYMPTOTIC EXPANSION. (71-75)
C
C  ****  COULOMB PHASE-SHIFT.
      DELTA=DELTAC(ETA,RLAMB)
C
      CPA=CIETA-RLAMB
      CPB=CIETA+RLAMB+1.0D0
      CPZ=CI2*X
      CALL SUM2F0(CPA,CPB,CPZ,C2F0,ERR1)
      CQA=CPA+1.0D0
      CQB=CPB+1.0D0
      CALL SUM2F0(CQA,CQB,CPZ,C2F0P,ERR2)
      C2F0P=CI*C2F0P*CPA*CPB/(2.0D0*X2)
C  ****  FUNCTIONS.
      THETA=X-ETA*DLOG(2.0D0*X)-RLAMB*PIH+DELTA
      IF(THETA.GT.1.0D4) THETA=DMOD(THETA,TPI)
      CEITH=CDEXP(CI*THETA)
      CGIF=C2F0*CEITH
      G=CGIF
      F=-CI*CGIF
C  ****  DERIVATIVES.
      CGIFP=(C2F0P+CI*(1.0D0-ETA/X)*C2F0)*CEITH
      GP=CGIFP
      FP=-CI*CGIFP
C  ****  GLOBAL UNCERTAINTY. THE WRONSKIAN MAY DIFFER FROM 1 DUE
C        TO TRUNCATION AND ROUNDOFF ERRORS.
      ERR=DMAX1(ERR1,ERR2,DABS(G*FP-F*GP-1.0D0))
      IF(ERR.LE.EPS) RETURN
      ERRS=ERR
C
C  ************  STEED'S CONTINUED FRACTION METHOD.
C
    1 CONTINUE
      CIETA2=CIETA+CIETA
      ETAX=ETA*X
C
C  ****  CONTINUED FRACTION FOR F. (60-70)
C
      INULL=0
      RLAMBN=RLAMB+1.0D0
      A1=-(RLAMBN+1.0D0)*(RLAMBN**2+ETA2)*X/RLAMBN
      B0=(RLAMBN/X)+(ETA/RLAMBN)
      B1=(2.0D0*RLAMBN+1.0D0)*(RLAMBN*(RLAMBN+1.0D0)+ETAX)
      FA3=B0
      FA2=B0*B1+A1
      FB3=1.0D0
      FB2=B1
      RF=FA3
C
      DO 2 N=2,NTERM
      RFO=RF
      DAF=DABS(RF)
      RLAMBN=RLAMB+N
      AN=-(RLAMBN**2-1.0D0)*(RLAMBN**2+ETA2)*X2
      BN=(2.0D0*RLAMBN+1.0D0)*(RLAMBN*(RLAMBN+1.0D0)+ETAX)
      FA1=FA2*BN+FA3*AN
      FB1=FB2*BN+FB3*AN
      TST=DABS(FB1)
C
      IF(TST.LT.1.0D-25) THEN
        IF(INULL.GT.0) STOP
        INULL=1
        FA3=FA2
        FA2=FA1
        FB3=FB2
        FB2=FB1
        RF=RFO
      ELSE
        FA3=FA2/TST
        FA2=FA1/TST
        FB3=FB2/TST
        FB2=FB1/TST
        RF=FA2/FB2
        IF(DABS(RF-RFO).LT.EPS*DAF) GO TO 3
      ENDIF
    2 CONTINUE
    3 CONTINUE
      IF(DAF.GT.1.0D-25) THEN
        ERRF=DABS(RF-RFO)/DAF
      ELSE
        ERRF=EPS
      ENDIF
      IF(ERRF.GT.ERRS) THEN
        ERR=ERRS
        IF(ERR.GT.1.0D-6) GO TO 10
        RETURN
      ENDIF
C
C  ****  DOWNWARD RECURSION FOR F AND FP. ONLY IF RLAMB.GT.1 AND
C        X.LT.XTP. (48,49)
C
      RLAMB0=RLAMB
      IF(X.GE.XTP.OR.RLAMB0.LT.1.0D0) THEN
        ISHIFT=0
        XTPC=XTP
        RFM=0.0D0
      ELSE
        FT=1.0D0
        FTP=RF
        IS0=RLAMB0+1.0D-6
        TST=X*(X-2.0D0*ETA)
        RL1T=0.0D0
        DO 4 I=1,IS0
        ETARL0=ETA/RLAMB0
        RL=DSQRT(1.0D0+ETARL0**2)
        SL=(RLAMB0/X)+ETARL0
        RLAMB0=RLAMB0-1.0D0
        FTO=FT
        FT=(SL*FT+FTP)/RL
        FTP=SL*FT-RL*FTO
        IF(FT.GT.1.0D10) THEN
          FTP=FTP/FT
          FT=1.0D0
        ENDIF
        RL1T=RLAMB0*(RLAMB0+1.0D0)
        IF(TST.GT.RL1T) THEN
          ISHIFT=I
          GO TO 5
        ENDIF
    4   CONTINUE
        ISHIFT=IS0
    5   CONTINUE
        XTPC=ETA+DSQRT(ETA2+RL1T)
        RFM=FTP/FT
      ENDIF
C
C  ****  CONTINUED FRACTION FOR P+CI*Q WITH RLAMB0. (76-79)
C
      INULL=0
      CAN=CIETA-ETA2-RLAMB0*(RLAMB0+1.0D0)
      CB0=X-ETA
      CBN=2.0D0*(X-ETA+CI)
      CFA3=CB0
      CFA2=CB0*CBN+CAN
      CFB3=1.0D0
      CFB2=CBN
      CPIQ=CFA3
C
      DO 6 N=2,NTERM
      CPIQO=CPIQ
      DAPIQ=CDABS(CPIQ)
      CAN=CAN+CIETA2+(N+N-2)
      CBN=CBN+CI2
      CFA1=CFA2*CBN+CFA3*CAN
      CFB1=CFB2*CBN+CFB3*CAN
      TST=CDABS(CFB1)
C
      IF(TST.LT.1.0D-25) THEN
        IF(INULL.GT.0) STOP
        INULL=1
        CFA3=CFA2
        CFA2=CFA1
        CFB3=CFB2
        CFB2=CFB1
        CPIQ=CPIQO
      ELSE
        CFA3=CFA2/TST
        CFA2=CFA1/TST
        CFB3=CFB2/TST
        CFB2=CFB1/TST
        CPIQ=CFA2/CFB2
        IF(CDABS(CPIQ-CPIQO).LT.EPS*DAPIQ) GO TO 7
      ENDIF
    6 CONTINUE
    7 CONTINUE
      IF(DAPIQ.GT.1.0D-25) THEN
        ERRPIQ=CDABS(CPIQ-CPIQO)/DAPIQ
      ELSE
        ERRPIQ=EPS
      ENDIF
      IF(ERRPIQ.GT.ERRS) THEN
        ERR=ERRS
        IF(ERR.GT.1.0D-6) GO TO 10
        RETURN
      ENDIF
      CPIQ=CI*CPIQ/X
C
      RP=CPIQ
      RQ=-CI*CPIQ
      IF(RQ.LE.1.0D-25) GO TO 10
      ERR=DMAX1(ERRF,ERRPIQ)
C
C  ****  INVERTING STEED'S TRANSFORMATION. (57,58)
C
      IF(ISHIFT.LT.1) THEN
        RFP=RF-RP
        F=DSQRT(RQ/(RFP**2+RQ**2))
        IF(FB2.LT.0.0D0) F=-F
        FP=RF*F
        G=RFP*F/RQ
        GP=(RP*RFP-RQ**2)*F/RQ
        IF(X.LT.XTP.AND.G.GT.TOP*F) GO TO 10
      ELSE
        RFP=RFM-RP
        FM=DSQRT(RQ/(RFP**2+RQ**2))
        G=RFP*FM/RQ
        GP=(RP*RFP-RQ**2)*FM/RQ
        IF(X.LT.XTPC.AND.G.GT.TOP*FM) GO TO 10
C  ****  UPWARD RECURSION FOR G AND GP (IF ISHIFT.GT.0). (50,51)
        DO 8 I=1,ISHIFT
        RLAMB0=RLAMB0+1.0D0
        ETARL0=ETA/RLAMB0
        RL=DSQRT(1.0D0+ETARL0**2)
        SL=(RLAMB0/X)+ETARL0
        GO=G
        G=(SL*GO-GP)/RL
        GP=RL*GO-SL*G
        IF(G.GT.1.0D35) GO TO 10
    8   CONTINUE
    9   W=RF*G-GP
        F=1.0D0/W
        FP=RF/W
      ENDIF
C  ****  THE WRONSKIAN MAY DIFFER FROM 1 DUE TO ROUNDOFF ERRORS.
      ERR=DMAX1(ERR,DABS(FP*G-F*GP-1.0D0))
      IF(ERR.LT.1.0D-6) RETURN
C
   10 F=0.0D0
      FP=0.0D0
      G=1.0D35
      GP=-1.0D35
      ERR=1.0D0
      RETURN
      END
C  **************************************************************
C                       SUBROUTINE SUM2F0
C  **************************************************************
      SUBROUTINE SUM2F0(CA,CB,CZ,CF,ERR)
C
C     SUMMATION OF THE 2F0(CA,CB;CS) HYPERGEOMETRIC ASYMPTOTIC
C  SERIES. THE POSITIVE AND NEGATIVE CONTRIBUTIONS TO THE REAL
C  AND IMAGINARY PARTS ARE ADDED SEPARATELY TO OBTAIN AN ESTIMATE
C  OF ROUNDING ERRORS.
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1  INTEGER*4 (I-N)
      PARAMETER (EPS=1.0D-16,ACCUR=0.5D-15,NTERM=75)
      RRP=1.0D0
      RRN=0.0D0
      RIP=0.0D0
      RIN=0.0D0
      CDF=1.0D0
      ERR2=0.0D0
      ERR3=1.0D0
      AR=0.0D0
      AF=0.0D0
      DO 1 I=1,NTERM
      J=I-1
      CDF=CDF*(CA+J)*(CB+J)/(I*CZ)
      ERR1=ERR2
      ERR2=ERR3
      ERR3=CDABS(CDF)
      IF(ERR1.GT.ERR2.AND.ERR2.LT.ERR3) GO TO 2
      AR=CDF
      IF(AR.GT.0.0D0) THEN
        RRP=RRP+AR
      ELSE
        RRN=RRN+AR
      ENDIF
      AI=DCMPLX(0.0D0,-1.0D0)*CDF
      IF(AI.GT.0.0D0) THEN
        RIP=RIP+AI
      ELSE
        RIN=RIN+AI
      ENDIF
      CF=DCMPLX(RRP+RRN,RIP+RIN)
      AF=CDABS(CF)
      IF(AF.GT.1.0D25) THEN
        CF=0.0D0
        ERR=1.0D0
        RETURN
      ENDIF
      IF(ERR3.LT.1.0D-25*AF.OR.ERR3.LT.EPS) THEN
         ERR=EPS
         RETURN
      ENDIF
    1 CONTINUE
C  ****  ROUNDOFF ERROR.
    2 CONTINUE
      TR=DABS(RRP+RRN)
      IF(TR.GT.1.0D-25) THEN
        ERRR=(RRP-RRN)*ACCUR/TR
      ELSE
        ERRR=1.0D0
      ENDIF
      TI=DABS(RIP+RIN)
      IF(TI.GT.1.0D-25) THEN
        ERRI=(RIP-RIN)*ACCUR/TI
      ELSE
        ERRI=1.0D0
      ENDIF
C  ****  ... AND TRUNCATION ERROR.
      IF(AR.GT.1.0D-25) THEN
      ERR=DMAX1(ERRR,ERRI)+ERR2/AF
      ELSE
      ERR=DMAX1(ERRR,ERRI)
      ENDIF
      RETURN
      END
C  **************************************************************
C                         FUNCTION DELTAC
C  **************************************************************
      FUNCTION DELTAC(ETA,RLAMB)
C
C     CALCULATION OF COULOMB PHASE SHIFT (MODULUS 2*PI). (47)
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1  INTEGER*4 (I-N)
      PARAMETER (PI=3.1415926535897932D0,TPI=PI+PI)
      CI=DCMPLX(0.0D0,1.0D0)
C  ****  COULOMB PHASE-SHIFT.
      DELTAC=-CI*CLGAM(RLAMB+1.0D0+CI*ETA)
      IF(DELTAC.GE.0.0D0) THEN
        DELTAC=DMOD(DELTAC,TPI)
      ELSE
        DELTAC=-DMOD(-DELTAC,TPI)
      ENDIF
      RETURN
      END
C  **************************************************************
C                       FUNCTION CLGAM
C  **************************************************************
      FUNCTION CLGAM(CZ)
C
C     THIS FUNCTION GIVES LOG(GAMMA(CZ)) FOR COMPLEX ARGUMENTS.
C
C   REF.: M. ABRAMOWITZ AND I.A. STEGUN, 'HANDBOOK OF MATHEMATI-
C         CAL FUNCTIONS'. DOVER, NEW YORK (1974). PP 255-257.
C
      IMPLICIT DOUBLE PRECISION (A-B,D-H,O-Z), COMPLEX*16 (C),
     1  INTEGER*4 (I-N)
      CZA=CZ
      ICONJ=0
      AR=CZA
      CLGAM=36.84136149D0
      IF(CDABS(CZA).LT.1.0D-16) RETURN
C
      AI=CZA*DCMPLX(0.0D0,-1.0D0)
      IF(AI.GT.0.0D0) THEN
        ICONJ=0
      ELSE
        ICONJ=1
        CZA=DCONJG(CZA)
      ENDIF
C
      CZFAC=1.0D0
      CZFL=0.0D0
    1 CZFAC=CZFAC/CZA
      IF(CDABS(CZFAC).GT.1.0D8) THEN
        CZFL=CZFL+CDLOG(CZFAC)
        CZFAC=1.0D0
      ENDIF
      CZA=CZA+1.0D0
      AR=CZA
      IF(CDABS(CZA).LT.1.0D-16) RETURN
      IF(CDABS(CZA).GT.15.0D0.AND.AR.GT.0.0D0) GO TO 2
      GO TO 1
C  ****  STIRLING'S EXPANSION OF CDLOG(GAMMA(CZA)).
    2 CZI2=1.0D0/(CZA*CZA)
      CZS=(43867.0D0/244188.0D0)*CZI2
      CZS=(CZS-3617.0D0/122400.0D0)*CZI2
      CZS=(CZS+1.0D0/156.0D0)*CZI2
      CZS=(CZS-691.0D0/360360.0D0)*CZI2
      CZS=(CZS+1.0D0/1188.0D0)*CZI2
      CZS=(CZS-1.0D0/1680.0D0)*CZI2
      CZS=(CZS+1.0D0/1260.0D0)*CZI2
      CZS=(CZS-1.0D0/360.0D0)*CZI2
      CZS=(CZS+1.0D0/12.0D0)/CZA
      CLGAM=(CZA-0.5D0)*CDLOG(CZA)-CZA+9.1893853320467274D-1+CZS
     1     +CZFL+CDLOG(CZFAC)
      IF(ICONJ.EQ.1) CLGAM=DCONJG(CLGAM)
      RETURN
      END
C  **************************************************************
C                         FUNCION BESJN
C  **************************************************************
      FUNCTION BESJN(JY,N,X)
C
C      THIS FUNCTION COMPUTES THE SPHERICAL BESSEL FUNCTIONS OF
C   THE FIRST KIND AND SPHERICAL BESSEL FUNCTIONS OF THE SECOND
C   KIND (ALSO KNOWN AS SPHERICAL NEUMANN FUNCTIONS) FOR REAL
C   POSITIVE ARGUMENTS.
C
C      INPUT:
C         JY ...... KIND: 1(BESSEL) OR 2(NEUMANN).
C         N ....... ORDER (INTEGER).
C         X ....... ARGUMENT (REAL AND POSITIVE).
C
C   REF.: M. ABRAMOWITZ AND I.A. STEGUN, 'HANDBOOK OF MATHEMATI-
C         CAL FUNCTIONS'. DOVER, NEW YORK (1974). PP 435-478.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
      IF(X.LT.0) THEN
        WRITE(6,1000)
 1000   FORMAT(1X,'*** NEGATIVE ARGUMENT IN FUNCTION BESJN.')
        STOP
      ENDIF
C  ****  ORDER AND PHASE CORRECTION FOR NEUMANN FUNCTIONS.
C        ABRAMOWITZ AND STEGUN, EQ. 10.1.15.
      IF(JY.EQ.2) THEN
        NL=-N-1
        IPH=2*MOD(IABS(N),2)-1
      ELSE
        NL=N
        IPH=1
      ENDIF
C  ****  SELECTION OF CALCULATION MODE.
      IF(NL.LT.0) GO TO 10
      IF(X.GT.1.0D0*NL) GO TO 7
      XI=X*X
      IF(XI.GT.NL+NL+3.0D0) GO TO 4
C  ****  POWER SERIES FOR SMALL ARGUMENTS AND POSITIVE ORDERS.
C        ABRAMOWITZ AND STEGUN, EQ. 10.1.2.
      F1=1.0D0
      IP=1
      IF(NL.NE.0) THEN
        DO 1 I=1,NL
        IP=IP+2
    1   F1=F1*X/IP
      ENDIF
      XI=0.5D0*XI
      BESJN=1.0D0
      PS=1.0D0
      DO 2 I=1,500
      IP=IP+2
      PS=-PS*XI/(I*IP)
      BESJN=BESJN+PS
      IF(DABS(PS).LT.1.0D-18*DABS(BESJN)) GO TO 3
    2 CONTINUE
    3 BESJN=IPH*F1*BESJN
      RETURN
C  ****  MILLER'S METHOD FOR POSITIVE ORDERS AND INTERMEDIATE
C        ARGUMENTS. ABRAMOWITZ AND STEGUN, EQ. 10.1.19.
    4 XI=1.0D0/X
      F2=0.0D0
      F3=1.0D-35
      IP=2*(NL+31)+3
      DO 5 I=1,31
      F1=F2
      F2=F3
      IP=IP-2
      F3=IP*XI*F2-F1
      IF(DABS(F3).GT.1.0D30) THEN
        F2=F2/F3
        F3=1.0D0
      ENDIF
    5 CONTINUE
      BESJN=1.0D0
      F2=F2/F3
      F3=1.0D0
      DO 6 I=1,NL
      F1=F2
      F2=F3
      IP=IP-2
      F3=IP*XI*F2-F1
      IF(DABS(F3).GT.1.0D30) THEN
        BESJN=BESJN/F3
        F2=F2/F3
        F3=1.0D0
      ENDIF
    6 CONTINUE
      BESJN=IPH*XI*DSIN(X)*BESJN/F3
      RETURN
C  ****  RECURRENCE RELATION FOR ARGUMENTS GREATER THAN ORDER.
C        ABRAMOWITZ AND STEGUN, EQ. 10.1.19.
    7 XI=1.0D0/X
      F3=XI*DSIN(X)
      IF(NL.EQ.0) GO TO 9
      F2=F3
      F3=XI*(F2-DCOS(X))
      IF(NL.EQ.1) GO TO 9
      IP=1
      DO 8 I=2,NL
      F1=F2
      F2=F3
      IP=IP+2
    8 F3=IP*XI*F2-F1
    9 BESJN=IPH*F3
      RETURN
C  ****  RECURRENCE RELATION FOR NEGATIVE ORDERS.
C        ABRAMOWITZ AND STEGUN, EQ. 10.1.19.
   10 NL=IABS(NL)
      IF(X.LT.7.36D-1*(NL+1)*1.0D-35**(1.0D0/(NL+1))) THEN
        BESJN=-1.0D35
        RETURN
      ENDIF
      XI=1.0D0/X
      F3=XI*DSIN(X)
      F2=XI*(F3-DCOS(X))
      IP=3
      DO 11 I=1,NL
      F1=F2
      F2=F3
      IP=IP-2
      F3=IP*XI*F2-F1
      IF(DABS(F3).GT.1.0D35) THEN
        BESJN=-1.0D35
        RETURN
      ENDIF
   11 CONTINUE
      BESJN=IPH*F3
      RETURN
      END
      
            
 
      SUBROUTINE GAUSSCALC(GAUSS,GAUSSDENS,RA,RAT,Z,ISOT,RMIN,RMAX,N)
C       This subroutine uses Sum-of-Gaussian distribution given in:
C           Vreis et al, At. Data Nucl. Data Tabl. 36 (1987)
C       with the following input parameters:
C           Z - atomic number
C           ISOT - isotop indicator flag 
C           RMIN/RMAX - min/max values of r of the radial grid
C           N - number of grid points
C       to obtain the following output:
C           GAUSS(i) = r(i) V(r(i)) - via interpolation
C           GAUSSDENS(i) = rho(r(i))
C           RA - charge radius of the distribution in fm
C           RAT - charge radius4 of the distribution in fm
C       Oleksandr Koshchii: June 2019
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)
        PARAMETER (ALPHAFS=1.0D0/137.03599976D0) 
        PARAMETER (PI=3.1415926535897932D0)
        PARAMETER (FOURPI=4.0D0*PI)

        DIMENSION DIFR(N+4),RI(N+4),GAUSS(N),GAUSSDENS(N)
      
        NDIN1=N+1

        CALL SGRID(RI,DIFR,RMIN,RMAX,0.5D0*DBLE(N),N)
        CALL GAUSSCOEF(R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12,Q1T,Q2T,Q3T,Q4T,Q5T,Q6T,Q7T,Q8T,Q9T,Q10T,Q11T,Q12T,GAMMA,Z,ISOT)
     
        QNORM=1.D0/(Q1T+Q2T+Q3T+Q4T+Q5T+Q6T+Q7T+Q8T+Q9T+Q10T+Q11T+Q12T)
      
        Q1=Q1T*QNORM
        Q2=Q2T*QNORM
        Q3=Q3T*QNORM
        Q4=Q4T*QNORM
        Q5=Q5T*QNORM
        Q6=Q6T*QNORM
        Q7=Q7T*QNORM
        Q8=Q8T*QNORM
        Q9=Q9T*QNORM
        Q10=Q10T*QNORM
        Q11=Q11T*QNORM
        Q12=Q12T*QNORM
            
        C1=2.0D0*PI**(3.0D0/2.0D0)*GAMMA**3
        C2=4.0D0*PI**(3.0D0/2.0D0)*GAMMA
      
        A1=Z*Q1/(2.0D0*PI**(3.0D0/2.0D0)*
     -     GAMMA**3*(1.0D0+2.0D0*R1**2/GAMMA**2))
        A2=Z*Q2/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R2**2/GAMMA**2))
        A3=Z*Q3/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R3**2/GAMMA**2))
        A4=Z*Q4/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R4**2/GAMMA**2))
        A5=Z*Q5/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R5**2/GAMMA**2))
        A6=Z*Q6/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R6**2/GAMMA**2))
        A7=Z*Q7/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R7**2/GAMMA**2))
        A8=Z*Q8/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R8**2/GAMMA**2))
        A9=Z*Q9/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R9**2/GAMMA**2))
        A10=Z*Q10/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R10**2/GAMMA**2))
        A11=Z*Q11/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R11**2/GAMMA**2))
        A12=Z*Q12/(2.0D0*PI**(3.0D0/2.0D0)*
     -      GAMMA**3*(1.0D0+2.0D0*R12**2/GAMMA**2))

        DO I=1,N
            R=RI(I)
            IF (Z.EQ.6) THEN !need a separate expression because R1=0 
        GAUSS(I)= (2.0D0*GAMMA**2*PI*Q10*R*Z)/
     -   (EXP((R - R10)**2/GAMMA**2)*(C1 + C2*R10**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R10**2)/GAMMA**2 + 
     -       (R10*(2.0D0*R + R10))/GAMMA**2)*GAMMA**2*PI*Q10*R*Z)/
     -   (C1 + C2*R10**2) + 
     -  (2.0D0*GAMMA**2*PI*Q10*R10*Z)/
     -   (EXP(R10**2/GAMMA**2)*(C1 + C2*R10**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q10*R10*Z)/
     -   (EXP((R + R10)**2/GAMMA**2)*(C1 + C2*R10**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R10**2)/GAMMA**2 + 
     -       (R10*(2.0D0*R + R10))/GAMMA**2)*GAMMA**2*PI*Q10*R10*Z)/
     -   (C1 + C2*R10**2) - 
     -  (2.0D0*EXP(-((R + R10)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R10))/GAMMA**2)*GAMMA**2*PI*Q10*R10*Z)/
     -   (C1 + C2*R10**2) + 
     -  (2.0D0*GAMMA**2*PI*Q11*R*Z)/
     -   (EXP((R - R11)**2/GAMMA**2)*(C1 + C2*R11**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R11**2)/GAMMA**2 + 
     -       (R11*(2.0D0*R + R11))/GAMMA**2)*GAMMA**2*PI*Q11*R*Z)/
     -   (C1 + C2*R11**2) + 
     -  (2.0D0*GAMMA**2*PI*Q11*R11*Z)/
     -   (EXP(R11**2/GAMMA**2)*(C1 + C2*R11**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q11*R11*Z)/
     -   (EXP((R + R11)**2/GAMMA**2)*(C1 + C2*R11**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R11**2)/GAMMA**2 + 
     -       (R11*(2.0D0*R + R11))/GAMMA**2)*GAMMA**2*PI*Q11*R11*Z)/
     -   (C1 + C2*R11**2) - 
     -  (2.0D0*EXP(-((R + R11)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R11))/GAMMA**2)*GAMMA**2*PI*Q11*R11*Z)/
     -   (C1 + C2*R11**2) + 
     -  (2.0D0*GAMMA**2*PI*Q2*R*Z)/
     -   (EXP((R - R2)**2/GAMMA**2)*(C1 + C2*R2**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R2**2)/GAMMA**2 + 
     -       (R2*(2.0D0*R + R2))/GAMMA**2)*GAMMA**2*PI*Q2*R*Z)/
     -   (C1 + C2*R2**2) + 
     -  (2.0D0*GAMMA**2*PI*Q2*R2*Z)/
     -   (EXP(R2**2/GAMMA**2)*(C1 + C2*R2**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q2*R2*Z)/
     -   (EXP((R + R2)**2/GAMMA**2)*(C1 + C2*R2**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R2**2)/GAMMA**2 + 
     -       (R2*(2.0D0*R + R2))/GAMMA**2)*GAMMA**2*PI*Q2*R2*Z)/
     -   (C1 + C2*R2**2) - 
     -  (2.0D0*EXP(-((R + R2)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R2))/GAMMA**2)*GAMMA**2*PI*Q2*R2*Z)/
     -   (C1 + C2*R2**2) + 
     -  (2.0D0*GAMMA**2*PI*Q3*R*Z)/
     -   (EXP((R - R3)**2/GAMMA**2)*(C1 + C2*R3**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R3**2)/GAMMA**2 + 
     -       (R3*(2.0D0*R + R3))/GAMMA**2)*GAMMA**2*PI*Q3*R*Z)/
     -   (C1 + C2*R3**2) + 
     -  (2.0D0*GAMMA**2*PI*Q3*R3*Z)/
     -   (EXP(R3**2/GAMMA**2)*(C1 + C2*R3**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q3*R3*Z)/
     -   (EXP((R + R3)**2/GAMMA**2)*(C1 + C2*R3**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R3**2)/GAMMA**2 + 
     -       (R3*(2.0D0*R + R3))/GAMMA**2)*GAMMA**2*PI*Q3*R3*Z)/
     -   (C1 + C2*R3**2) - 
     -  (2.0D0*EXP(-((R + R3)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R3))/GAMMA**2)*GAMMA**2*PI*Q3*R3*Z)/
     -   (C1 + C2*R3**2) + 
     -  (2.0D0*GAMMA**2*PI*Q4*R*Z)/
     -   (EXP((R - R4)**2/GAMMA**2)*(C1 + C2*R4**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R4**2)/GAMMA**2 + 
     -       (R4*(2.0D0*R + R4))/GAMMA**2)*GAMMA**2*PI*Q4*R*Z)/
     -   (C1 + C2*R4**2) + 
     -  (2.0D0*GAMMA**2*PI*Q4*R4*Z)/
     -   (EXP(R4**2/GAMMA**2)*(C1 + C2*R4**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q4*R4*Z)/
     -   (EXP((R + R4)**2/GAMMA**2)*(C1 + C2*R4**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R4**2)/GAMMA**2 + 
     -       (R4*(2.0D0*R + R4))/GAMMA**2)*GAMMA**2*PI*Q4*R4*Z)/
     -   (C1 + C2*R4**2) - 
     -  (2.0D0*EXP(-((R + R4)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R4))/GAMMA**2)*GAMMA**2*PI*Q4*R4*Z)/
     -   (C1 + C2*R4**2) + 
     -  (2.0D0*GAMMA**2*PI*Q5*R*Z)/
     -   (EXP((R - R5)**2/GAMMA**2)*(C1 + C2*R5**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R5**2)/GAMMA**2 + 
     -       (R5*(2.0D0*R + R5))/GAMMA**2)*GAMMA**2*PI*Q5*R*Z)/
     -   (C1 + C2*R5**2) + 
     -  (2.0D0*GAMMA**2*PI*Q5*R5*Z)/
     -   (EXP(R5**2/GAMMA**2)*(C1 + C2*R5**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q5*R5*Z)/
     -   (EXP((R + R5)**2/GAMMA**2)*(C1 + C2*R5**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R5**2)/GAMMA**2 + 
     -       (R5*(2.0D0*R + R5))/GAMMA**2)*GAMMA**2*PI*Q5*R5*Z)/
     -   (C1 + C2*R5**2) - 
     -  (2.0D0*EXP(-((R + R5)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R5))/GAMMA**2)*GAMMA**2*PI*Q5*R5*Z)/
     -   (C1 + C2*R5**2) + 
     -  (2.0D0*GAMMA**2*PI*Q6*R*Z)/
     -   (EXP((R - R6)**2/GAMMA**2)*(C1 + C2*R6**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R6**2)/GAMMA**2 + 
     -       (R6*(2.0D0*R + R6))/GAMMA**2)*GAMMA**2*PI*Q6*R*Z)/
     -   (C1 + C2*R6**2) + 
     -  (2.0D0*GAMMA**2*PI*Q6*R6*Z)/
     -   (EXP(R6**2/GAMMA**2)*(C1 + C2*R6**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q6*R6*Z)/
     -   (EXP((R + R6)**2/GAMMA**2)*(C1 + C2*R6**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R6**2)/GAMMA**2 + 
     -       (R6*(2.0D0*R + R6))/GAMMA**2)*GAMMA**2*PI*Q6*R6*Z)/
     -   (C1 + C2*R6**2) - 
     -  (2.0D0*EXP(-((R + R6)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R6))/GAMMA**2)*GAMMA**2*PI*Q6*R6*Z)/
     -   (C1 + C2*R6**2) + 
     -  (2.0D0*GAMMA**2*PI*Q7*R*Z)/
     -   (EXP((R - R7)**2/GAMMA**2)*(C1 + C2*R7**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R7**2)/GAMMA**2 + 
     -       (R7*(2.0D0*R + R7))/GAMMA**2)*GAMMA**2*PI*Q7*R*Z)/
     -   (C1 + C2*R7**2) + 
     -  (2.0D0*GAMMA**2*PI*Q7*R7*Z)/
     -   (EXP(R7**2/GAMMA**2)*(C1 + C2*R7**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q7*R7*Z)/
     -   (EXP((R + R7)**2/GAMMA**2)*(C1 + C2*R7**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R7**2)/GAMMA**2 + 
     -       (R7*(2.0D0*R + R7))/GAMMA**2)*GAMMA**2*PI*Q7*R7*Z)/
     -   (C1 + C2*R7**2) - 
     -  (2.0D0*EXP(-((R + R7)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R7))/GAMMA**2)*GAMMA**2*PI*Q7*R7*Z)/
     -   (C1 + C2*R7**2) + 
     -  (2.0D0*GAMMA**2*PI*Q8*R*Z)/
     -   (EXP((R - R8)**2/GAMMA**2)*(C1 + C2*R8**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R8**2)/GAMMA**2 + 
     -       (R8*(2.0D0*R + R8))/GAMMA**2)*GAMMA**2*PI*Q8*R*Z)/
     -   (C1 + C2*R8**2) + 
     -  (2.0D0*GAMMA**2*PI*Q8*R8*Z)/
     -   (EXP(R8**2/GAMMA**2)*(C1 + C2*R8**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q8*R8*Z)/
     -   (EXP((R + R8)**2/GAMMA**2)*(C1 + C2*R8**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R8**2)/GAMMA**2 + 
     -       (R8*(2.0D0*R + R8))/GAMMA**2)*GAMMA**2*PI*Q8*R8*Z)/
     -   (C1 + C2*R8**2) - 
     -  (2.0D0*EXP(-((R + R8)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R8))/GAMMA**2)*GAMMA**2*PI*Q8*R8*Z)/
     -   (C1 + C2*R8**2) + 
     -  (2.0D0*GAMMA**2*PI*Q9*R*Z)/
     -   (EXP((R - R9)**2/GAMMA**2)*(C1 + C2*R9**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R9**2)/GAMMA**2 + 
     -       (R9*(2.0D0*R + R9))/GAMMA**2)*GAMMA**2*PI*Q9*R*Z)/
     -   (C1 + C2*R9**2) + 
     -  (2.0D0*GAMMA**2*PI*Q9*R9*Z)/
     -   (EXP(R9**2/GAMMA**2)*(C1 + C2*R9**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q9*R9*Z)/
     -   (EXP((R + R9)**2/GAMMA**2)*(C1 + C2*R9**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R9**2)/GAMMA**2 + 
     -       (R9*(2.0D0*R + R9))/GAMMA**2)*GAMMA**2*PI*Q9*R9*Z)/
     -   (C1 + C2*R9**2) - 
     -  (2.0D0*EXP(-((R + R9)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R9))/GAMMA**2)*GAMMA**2*PI*Q9*R9*Z)/
     -   (C1 + C2*R9**2) + 
     -  (2.0D0*GAMMA**3*PI**1.5*Q1*Z*ERF(R/GAMMA))/C1 + 
     -  (GAMMA**3*PI**1.5*Q10*R*Z*
     -     ERF(DSQRT((R - R10)**2)/GAMMA))/
     -   (DSQRT((R - R10)**2)*(C1 + C2*R10**2)) - 
     -  (GAMMA**3*PI**1.5*Q10*R10*Z*
     -     ERF(DSQRT((R - R10)**2)/GAMMA))/
     -   (DSQRT((R - R10)**2)*(C1 + C2*R10**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R*R10**2*Z*
     -     ERF(DSQRT((R - R10)**2)/GAMMA))/
     -   (DSQRT((R - R10)**2)*(C1 + C2*R10**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R10**3*Z*
     -     ERF(DSQRT((R - R10)**2)/GAMMA))/
     -   (DSQRT((R - R10)**2)*(C1 + C2*R10**2)) - 
     -  (GAMMA**3*PI**1.5*Q10*Z*ERF(R10/GAMMA))/
     -   (C1 + C2*R10**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R10**2*Z*ERF(R10/GAMMA))/
     -   (C1 + C2*R10**2) + 
     -  (GAMMA**3*PI**1.5*Q10*DSQRT(R10**2)*Z*
     -     ERF(DSQRT(R10**2)/GAMMA))/(R10*(C1 + C2*R10**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R10*DSQRT(R10**2)*Z*
     -     ERF(DSQRT(R10**2)/GAMMA))/(C1 + C2*R10**2) + 
     -  (GAMMA**3*PI**1.5*Q10*Z*ERF((R + R10)/GAMMA))/
     -   (C1 + C2*R10**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R10**2*Z*ERF((R + R10)/GAMMA))/
     -   (C1 + C2*R10**2) + 
     -  (GAMMA**3*PI**1.5*Q11*R*Z*
     -     ERF(DSQRT((R - R11)**2)/GAMMA))/
     -   (DSQRT((R - R11)**2)*(C1 + C2*R11**2)) - 
     -  (GAMMA**3*PI**1.5*Q11*R11*Z*
     -     ERF(DSQRT((R - R11)**2)/GAMMA))/
     -   (DSQRT((R - R11)**2)*(C1 + C2*R11**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R*R11**2*Z*
     -     ERF(DSQRT((R - R11)**2)/GAMMA))/
     -   (DSQRT((R - R11)**2)*(C1 + C2*R11**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R11**3*Z*
     -     ERF(DSQRT((R - R11)**2)/GAMMA))/
     -   (DSQRT((R - R11)**2)*(C1 + C2*R11**2)) - 
     -  (GAMMA**3*PI**1.5*Q11*Z*ERF(R11/GAMMA))/
     -   (C1 + C2*R11**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R11**2*Z*ERF(R11/GAMMA))/
     -   (C1 + C2*R11**2) + 
     -  (GAMMA**3*PI**1.5*Q11*DSQRT(R11**2)*Z*
     -     ERF(DSQRT(R11**2)/GAMMA))/(R11*(C1 + C2*R11**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R11*DSQRT(R11**2)*Z*
     -     ERF(DSQRT(R11**2)/GAMMA))/(C1 + C2*R11**2) + 
     -  (GAMMA**3*PI**1.5*Q11*Z*ERF((R + R11)/GAMMA))/
     -   (C1 + C2*R11**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R11**2*Z*ERF((R + R11)/GAMMA))/
     -   (C1 + C2*R11**2) + 
     -  (GAMMA**3*PI**1.5*Q2*R*Z*ERF(DSQRT((R - R2)**2)/GAMMA))/
     -   (DSQRT((R - R2)**2)*(C1 + C2*R2**2)) - 
     -  (GAMMA**3*PI**1.5*Q2*R2*Z*ERF(DSQRT((R - R2)**2)/GAMMA))/
     -   (DSQRT((R - R2)**2)*(C1 + C2*R2**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R*R2**2*Z*
     -     ERF(DSQRT((R - R2)**2)/GAMMA))/
     -   (DSQRT((R - R2)**2)*(C1 + C2*R2**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R2**3*Z*
     -     ERF(DSQRT((R - R2)**2)/GAMMA))/
     -   (DSQRT((R - R2)**2)*(C1 + C2*R2**2)) - 
     -  (GAMMA**3*PI**1.5*Q2*Z*ERF(R2/GAMMA))/(C1 + C2*R2**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R2**2*Z*ERF(R2/GAMMA))/
     -   (C1 + C2*R2**2) + 
     -  (GAMMA**3*PI**1.5*Q2*DSQRT(R2**2)*Z*
     -     ERF(DSQRT(R2**2)/GAMMA))/(R2*(C1 + C2*R2**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R2*DSQRT(R2**2)*Z*
     -     ERF(DSQRT(R2**2)/GAMMA))/(C1 + C2*R2**2) + 
     -  (GAMMA**3*PI**1.5*Q2*Z*ERF((R + R2)/GAMMA))/
     -   (C1 + C2*R2**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R2**2*Z*ERF((R + R2)/GAMMA))/
     -   (C1 + C2*R2**2) + 
     -  (GAMMA**3*PI**1.5*Q3*R*Z*ERF(DSQRT((R - R3)**2)/GAMMA))/
     -   (DSQRT((R - R3)**2)*(C1 + C2*R3**2)) - 
     -  (GAMMA**3*PI**1.5*Q3*R3*Z*ERF(DSQRT((R - R3)**2)/GAMMA))/
     -   (DSQRT((R - R3)**2)*(C1 + C2*R3**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R*R3**2*Z*
     -     ERF(DSQRT((R - R3)**2)/GAMMA))/
     -   (DSQRT((R - R3)**2)*(C1 + C2*R3**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R3**3*Z*
     -     ERF(DSQRT((R - R3)**2)/GAMMA))/
     -   (DSQRT((R - R3)**2)*(C1 + C2*R3**2)) - 
     -  (GAMMA**3*PI**1.5*Q3*Z*ERF(R3/GAMMA))/(C1 + C2*R3**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R3**2*Z*ERF(R3/GAMMA))/
     -   (C1 + C2*R3**2) + 
     -  (GAMMA**3*PI**1.5*Q3*DSQRT(R3**2)*Z*
     -     ERF(DSQRT(R3**2)/GAMMA))/(R3*(C1 + C2*R3**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R3*DSQRT(R3**2)*Z*
     -     ERF(DSQRT(R3**2)/GAMMA))/(C1 + C2*R3**2) + 
     -  (GAMMA**3*PI**1.5*Q3*Z*ERF((R + R3)/GAMMA))/
     -   (C1 + C2*R3**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R3**2*Z*ERF((R + R3)/GAMMA))/
     -   (C1 + C2*R3**2) + 
     -  (GAMMA**3*PI**1.5*Q4*R*Z*ERF(DSQRT((R - R4)**2)/GAMMA))/
     -   (DSQRT((R - R4)**2)*(C1 + C2*R4**2)) - 
     -  (GAMMA**3*PI**1.5*Q4*R4*Z*ERF(DSQRT((R - R4)**2)/GAMMA))/
     -   (DSQRT((R - R4)**2)*(C1 + C2*R4**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R*R4**2*Z*
     -     ERF(DSQRT((R - R4)**2)/GAMMA))/
     -   (DSQRT((R - R4)**2)*(C1 + C2*R4**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R4**3*Z*
     -     ERF(DSQRT((R - R4)**2)/GAMMA))/
     -   (DSQRT((R - R4)**2)*(C1 + C2*R4**2)) - 
     -  (GAMMA**3*PI**1.5*Q4*Z*ERF(R4/GAMMA))/(C1 + C2*R4**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R4**2*Z*ERF(R4/GAMMA))/
     -   (C1 + C2*R4**2) + 
     -  (GAMMA**3*PI**1.5*Q4*DSQRT(R4**2)*Z*
     -     ERF(DSQRT(R4**2)/GAMMA))/(R4*(C1 + C2*R4**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R4*DSQRT(R4**2)*Z*
     -     ERF(DSQRT(R4**2)/GAMMA))/(C1 + C2*R4**2) + 
     -  (GAMMA**3*PI**1.5*Q4*Z*ERF((R + R4)/GAMMA))/
     -   (C1 + C2*R4**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R4**2*Z*ERF((R + R4)/GAMMA))/
     -   (C1 + C2*R4**2) + 
     -  (GAMMA**3*PI**1.5*Q5*R*Z*ERF(DSQRT((R - R5)**2)/GAMMA))/
     -   (DSQRT((R - R5)**2)*(C1 + C2*R5**2)) - 
     -  (GAMMA**3*PI**1.5*Q5*R5*Z*ERF(DSQRT((R - R5)**2)/GAMMA))/
     -   (DSQRT((R - R5)**2)*(C1 + C2*R5**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R*R5**2*Z*
     -     ERF(DSQRT((R - R5)**2)/GAMMA))/
     -   (DSQRT((R - R5)**2)*(C1 + C2*R5**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R5**3*Z*
     -     ERF(DSQRT((R - R5)**2)/GAMMA))/
     -   (DSQRT((R - R5)**2)*(C1 + C2*R5**2)) - 
     -  (GAMMA**3*PI**1.5*Q5*Z*ERF(R5/GAMMA))/(C1 + C2*R5**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R5**2*Z*ERF(R5/GAMMA))/
     -   (C1 + C2*R5**2) + 
     -  (GAMMA**3*PI**1.5*Q5*DSQRT(R5**2)*Z*
     -     ERF(DSQRT(R5**2)/GAMMA))/(R5*(C1 + C2*R5**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R5*DSQRT(R5**2)*Z*
     -     ERF(DSQRT(R5**2)/GAMMA))/(C1 + C2*R5**2) + 
     -  (GAMMA**3*PI**1.5*Q5*Z*ERF((R + R5)/GAMMA))/
     -   (C1 + C2*R5**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R5**2*Z*ERF((R + R5)/GAMMA))/
     -   (C1 + C2*R5**2) + 
     -  (GAMMA**3*PI**1.5*Q6*R*Z*ERF(DSQRT((R - R6)**2)/GAMMA))/
     -   (DSQRT((R - R6)**2)*(C1 + C2*R6**2)) - 
     -  (GAMMA**3*PI**1.5*Q6*R6*Z*ERF(DSQRT((R - R6)**2)/GAMMA))/
     -   (DSQRT((R - R6)**2)*(C1 + C2*R6**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R*R6**2*Z*
     -     ERF(DSQRT((R - R6)**2)/GAMMA))/
     -   (DSQRT((R - R6)**2)*(C1 + C2*R6**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R6**3*Z*
     -     ERF(DSQRT((R - R6)**2)/GAMMA))/
     -   (DSQRT((R - R6)**2)*(C1 + C2*R6**2)) - 
     -  (GAMMA**3*PI**1.5*Q6*Z*ERF(R6/GAMMA))/(C1 + C2*R6**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R6**2*Z*ERF(R6/GAMMA))/
     -   (C1 + C2*R6**2) + 
     -  (GAMMA**3*PI**1.5*Q6*DSQRT(R6**2)*Z*
     -     ERF(DSQRT(R6**2)/GAMMA))/(R6*(C1 + C2*R6**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R6*DSQRT(R6**2)*Z*
     -     ERF(DSQRT(R6**2)/GAMMA))/(C1 + C2*R6**2) + 
     -  (GAMMA**3*PI**1.5*Q6*Z*ERF((R + R6)/GAMMA))/
     -   (C1 + C2*R6**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R6**2*Z*ERF((R + R6)/GAMMA))/
     -   (C1 + C2*R6**2) + 
     -  (GAMMA**3*PI**1.5*Q7*R*Z*ERF(DSQRT((R - R7)**2)/GAMMA))/
     -   (DSQRT((R - R7)**2)*(C1 + C2*R7**2)) - 
     -  (GAMMA**3*PI**1.5*Q7*R7*Z*ERF(DSQRT((R - R7)**2)/GAMMA))/
     -   (DSQRT((R - R7)**2)*(C1 + C2*R7**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R*R7**2*Z*
     -     ERF(DSQRT((R - R7)**2)/GAMMA))/
     -   (DSQRT((R - R7)**2)*(C1 + C2*R7**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R7**3*Z*
     -     ERF(DSQRT((R - R7)**2)/GAMMA))/
     -   (DSQRT((R - R7)**2)*(C1 + C2*R7**2)) - 
     -  (GAMMA**3*PI**1.5*Q7*Z*ERF(R7/GAMMA))/(C1 + C2*R7**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R7**2*Z*ERF(R7/GAMMA))/
     -   (C1 + C2*R7**2) + 
     -  (GAMMA**3*PI**1.5*Q7*DSQRT(R7**2)*Z*
     -     ERF(DSQRT(R7**2)/GAMMA))/(R7*(C1 + C2*R7**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R7*DSQRT(R7**2)*Z*
     -     ERF(DSQRT(R7**2)/GAMMA))/(C1 + C2*R7**2) + 
     -  (GAMMA**3*PI**1.5*Q7*Z*ERF((R + R7)/GAMMA))/
     -   (C1 + C2*R7**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R7**2*Z*ERF((R + R7)/GAMMA))/
     -   (C1 + C2*R7**2) + 
     -  (GAMMA**3*PI**1.5*Q8*R*Z*ERF(DSQRT((R - R8)**2)/GAMMA))/
     -   (DSQRT((R - R8)**2)*(C1 + C2*R8**2)) - 
     -  (GAMMA**3*PI**1.5*Q8*R8*Z*ERF(DSQRT((R - R8)**2)/GAMMA))/
     -   (DSQRT((R - R8)**2)*(C1 + C2*R8**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R*R8**2*Z*
     -     ERF(DSQRT((R - R8)**2)/GAMMA))/
     -   (DSQRT((R - R8)**2)*(C1 + C2*R8**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R8**3*Z*
     -     ERF(DSQRT((R - R8)**2)/GAMMA))/
     -   (DSQRT((R - R8)**2)*(C1 + C2*R8**2)) - 
     -  (GAMMA**3*PI**1.5*Q8*Z*ERF(R8/GAMMA))/(C1 + C2*R8**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R8**2*Z*ERF(R8/GAMMA))/
     -   (C1 + C2*R8**2) + 
     -  (GAMMA**3*PI**1.5*Q8*DSQRT(R8**2)*Z*
     -     ERF(DSQRT(R8**2)/GAMMA))/(R8*(C1 + C2*R8**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R8*DSQRT(R8**2)*Z*
     -     ERF(DSQRT(R8**2)/GAMMA))/(C1 + C2*R8**2) + 
     -  (GAMMA**3*PI**1.5*Q8*Z*ERF((R + R8)/GAMMA))/
     -   (C1 + C2*R8**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R8**2*Z*ERF((R + R8)/GAMMA))/
     -   (C1 + C2*R8**2) + 
     -  (GAMMA**3*PI**1.5*Q9*R*Z*ERF(DSQRT((R - R9)**2)/GAMMA))/
     -   (DSQRT((R - R9)**2)*(C1 + C2*R9**2)) - 
     -  (GAMMA**3*PI**1.5*Q9*R9*Z*ERF(DSQRT((R - R9)**2)/GAMMA))/
     -   (DSQRT((R - R9)**2)*(C1 + C2*R9**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R*R9**2*Z*
     -     ERF(DSQRT((R - R9)**2)/GAMMA))/
     -   (DSQRT((R - R9)**2)*(C1 + C2*R9**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R9**3*Z*
     -     ERF(DSQRT((R - R9)**2)/GAMMA))/
     -   (DSQRT((R - R9)**2)*(C1 + C2*R9**2)) - 
     -  (GAMMA**3*PI**1.5*Q9*Z*ERF(R9/GAMMA))/(C1 + C2*R9**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R9**2*Z*ERF(R9/GAMMA))/
     -   (C1 + C2*R9**2) + 
     -  (GAMMA**3*PI**1.5*Q9*DSQRT(R9**2)*Z*
     -     ERF(DSQRT(R9**2)/GAMMA))/(R9*(C1 + C2*R9**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R9*DSQRT(R9**2)*Z*
     -     ERF(DSQRT(R9**2)/GAMMA))/(C1 + C2*R9**2) + 
     -  (GAMMA**3*PI**1.5*Q9*Z*ERF((R + R9)/GAMMA))/
     -   (C1 + C2*R9**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R9**2*Z*ERF((R + R9)/GAMMA))/
     -   (C1 + C2*R9**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R*R10*Z*ERFC((R - R10)/GAMMA))/
     -   (C1 + C2*R10**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R*R10*Z*ERFC((R + R10)/GAMMA))/
     -   (C1 + C2*R10**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R*R11*Z*ERFC((R - R11)/GAMMA))/
     -   (C1 + C2*R11**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R*R11*Z*ERFC((R + R11)/GAMMA))/
     -   (C1 + C2*R11**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R*R2*Z*ERFC((R - R2)/GAMMA))/
     -   (C1 + C2*R2**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R*R2*Z*ERFC((R + R2)/GAMMA))/
     -   (C1 + C2*R2**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R*R3*Z*ERFC((R - R3)/GAMMA))/
     -   (C1 + C2*R3**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R*R3*Z*ERFC((R + R3)/GAMMA))/
     -   (C1 + C2*R3**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R*R4*Z*ERFC((R - R4)/GAMMA))/
     -   (C1 + C2*R4**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R*R4*Z*ERFC((R + R4)/GAMMA))/
     -   (C1 + C2*R4**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R*R5*Z*ERFC((R - R5)/GAMMA))/
     -   (C1 + C2*R5**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R*R5*Z*ERFC((R + R5)/GAMMA))/
     -   (C1 + C2*R5**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R*R6*Z*ERFC((R - R6)/GAMMA))/
     -   (C1 + C2*R6**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R*R6*Z*ERFC((R + R6)/GAMMA))/
     -   (C1 + C2*R6**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R*R7*Z*ERFC((R - R7)/GAMMA))/
     -   (C1 + C2*R7**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R*R7*Z*ERFC((R + R7)/GAMMA))/
     -   (C1 + C2*R7**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R*R8*Z*ERFC((R - R8)/GAMMA))/
     -   (C1 + C2*R8**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R*R8*Z*ERFC((R + R8)/GAMMA))/
     -   (C1 + C2*R8**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R*R9*Z*ERFC((R - R9)/GAMMA))/
     -   (C1 + C2*R9**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R*R9*Z*ERFC((R + R9)/GAMMA))/
     -   (C1 + C2*R9**2)
        ELSE
        GAUSS(I)=(2.0D0*GAMMA**2*PI*Q1*R*Z)/
     -   (EXP((R + R1)**2/GAMMA**2)*(C1 + C2*R1**2)) - 
     -  (2.0D0*GAMMA**2*PI*Q1*R1*Z)/
     -   (EXP((R - R1)**2/GAMMA**2)*(C1 + C2*R1**2)) - 
     -  (2.0D0*GAMMA**2*PI*Q1*R1*Z)/
     -   (EXP(R1**2/GAMMA**2)*(C1 + C2*R1**2)) + 
     -  (4*GAMMA**2*PI*Q1*R1*Z)/
     -   (EXP((R + R1)**2/GAMMA**2)*(C1 + C2*R1**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q10*R*Z)/
     -   (EXP((R - R10)**2/GAMMA**2)*(C1 + C2*R10**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R10**2)/GAMMA**2 + 
     -       (R10*(2.0D0*R + R10))/GAMMA**2)*GAMMA**2*PI*Q10*R*Z)/
     -   (C1 + C2*R10**2) + 
     -  (2.0D0*GAMMA**2*PI*Q10*R10*Z)/
     -   (EXP(R10**2/GAMMA**2)*(C1 + C2*R10**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q10*R10*Z)/
     -   (EXP((R + R10)**2/GAMMA**2)*(C1 + C2*R10**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R10**2)/GAMMA**2 + 
     -       (R10*(2.0D0*R + R10))/GAMMA**2)*GAMMA**2*PI*Q10*R10*Z)/
     -   (C1 + C2*R10**2) - 
     -  (2.0D0*EXP(-((R + R10)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R10))/GAMMA**2)*GAMMA**2*PI*Q10*R10*Z)/
     -   (C1 + C2*R10**2) + 
     -  (2.0D0*GAMMA**2*PI*Q11*R*Z)/
     -   (EXP((R - R11)**2/GAMMA**2)*(C1 + C2*R11**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R11**2)/GAMMA**2 + 
     -       (R11*(2.0D0*R + R11))/GAMMA**2)*GAMMA**2*PI*Q11*R*Z)/
     -   (C1 + C2*R11**2) + 
     -  (2.0D0*GAMMA**2*PI*Q11*R11*Z)/
     -   (EXP(R11**2/GAMMA**2)*(C1 + C2*R11**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q11*R11*Z)/
     -   (EXP((R + R11)**2/GAMMA**2)*(C1 + C2*R11**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R11**2)/GAMMA**2 + 
     -       (R11*(2.0D0*R + R11))/GAMMA**2)*GAMMA**2*PI*Q11*R11*Z)/
     -   (C1 + C2*R11**2) - 
     -  (2.0D0*EXP(-((R + R11)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R11))/GAMMA**2)*GAMMA**2*PI*Q11*R11*Z)/
     -   (C1 + C2*R11**2) + 
     -  (2.0D0*GAMMA**2*PI*Q12*R*Z)/
     -   (EXP((R - R12)**2/GAMMA**2)*(C1 + C2*R12**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R12**2)/GAMMA**2 + 
     -       (R12*(2.0D0*R + R12))/GAMMA**2)*GAMMA**2*PI*Q12*R*Z)/
     -   (C1 + C2*R12**2) + 
     -  (2.0D0*GAMMA**2*PI*Q12*R12*Z)/
     -   (EXP(R12**2/GAMMA**2)*(C1 + C2*R12**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q12*R12*Z)/
     -   (EXP((R + R12)**2/GAMMA**2)*(C1 + C2*R12**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R12**2)/GAMMA**2 + 
     -       (R12*(2.0D0*R + R12))/GAMMA**2)*GAMMA**2*PI*Q12*R12*Z)/
     -   (C1 + C2*R12**2) - 
     -  (2.0D0*EXP(-((R + R12)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R12))/GAMMA**2)*GAMMA**2*PI*Q12*R12*Z)/
     -   (C1 + C2*R12**2) + 
     -  (2.0D0*GAMMA**2*PI*Q2*R*Z)/
     -   (EXP((R - R2)**2/GAMMA**2)*(C1 + C2*R2**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R2**2)/GAMMA**2 + 
     -       (R2*(2.0D0*R + R2))/GAMMA**2)*GAMMA**2*PI*Q2*R*Z)/
     -   (C1 + C2*R2**2) + 
     -  (2.0D0*GAMMA**2*PI*Q2*R2*Z)/
     -   (EXP(R2**2/GAMMA**2)*(C1 + C2*R2**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q2*R2*Z)/
     -   (EXP((R + R2)**2/GAMMA**2)*(C1 + C2*R2**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R2**2)/GAMMA**2 + 
     -       (R2*(2.0D0*R + R2))/GAMMA**2)*GAMMA**2*PI*Q2*R2*Z)/
     -   (C1 + C2*R2**2) - 
     -  (2.0D0*EXP(-((R + R2)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R2))/GAMMA**2)*GAMMA**2*PI*Q2*R2*Z)/
     -   (C1 + C2*R2**2) + 
     -  (2.0D0*GAMMA**2*PI*Q3*R*Z)/
     -   (EXP((R - R3)**2/GAMMA**2)*(C1 + C2*R3**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R3**2)/GAMMA**2 + 
     -       (R3*(2.0D0*R + R3))/GAMMA**2)*GAMMA**2*PI*Q3*R*Z)/
     -   (C1 + C2*R3**2) + 
     -  (2.0D0*GAMMA**2*PI*Q3*R3*Z)/
     -   (EXP(R3**2/GAMMA**2)*(C1 + C2*R3**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q3*R3*Z)/
     -   (EXP((R + R3)**2/GAMMA**2)*(C1 + C2*R3**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R3**2)/GAMMA**2 + 
     -       (R3*(2.0D0*R + R3))/GAMMA**2)*GAMMA**2*PI*Q3*R3*Z)/
     -   (C1 + C2*R3**2) - 
     -  (2.0D0*EXP(-((R + R3)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R3))/GAMMA**2)*GAMMA**2*PI*Q3*R3*Z)/
     -   (C1 + C2*R3**2) + 
     -  (2.0D0*GAMMA**2*PI*Q4*R*Z)/
     -   (EXP((R - R4)**2/GAMMA**2)*(C1 + C2*R4**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R4**2)/GAMMA**2 + 
     -       (R4*(2.0D0*R + R4))/GAMMA**2)*GAMMA**2*PI*Q4*R*Z)/
     -   (C1 + C2*R4**2) + 
     -  (2.0D0*GAMMA**2*PI*Q4*R4*Z)/
     -   (EXP(R4**2/GAMMA**2)*(C1 + C2*R4**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q4*R4*Z)/
     -   (EXP((R + R4)**2/GAMMA**2)*(C1 + C2*R4**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R4**2)/GAMMA**2 + 
     -       (R4*(2.0D0*R + R4))/GAMMA**2)*GAMMA**2*PI*Q4*R4*Z)/
     -   (C1 + C2*R4**2) - 
     -  (2.0D0*EXP(-((R + R4)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R4))/GAMMA**2)*GAMMA**2*PI*Q4*R4*Z)/
     -   (C1 + C2*R4**2) + 
     -  (2.0D0*GAMMA**2*PI*Q5*R*Z)/
     -   (EXP((R - R5)**2/GAMMA**2)*(C1 + C2*R5**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R5**2)/GAMMA**2 + 
     -       (R5*(2.0D0*R + R5))/GAMMA**2)*GAMMA**2*PI*Q5*R*Z)/
     -   (C1 + C2*R5**2) + 
     -  (2.0D0*GAMMA**2*PI*Q5*R5*Z)/
     -   (EXP(R5**2/GAMMA**2)*(C1 + C2*R5**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q5*R5*Z)/
     -   (EXP((R + R5)**2/GAMMA**2)*(C1 + C2*R5**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R5**2)/GAMMA**2 + 
     -       (R5*(2.0D0*R + R5))/GAMMA**2)*GAMMA**2*PI*Q5*R5*Z)/
     -   (C1 + C2*R5**2) - 
     -  (2.0D0*EXP(-((R + R5)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R5))/GAMMA**2)*GAMMA**2*PI*Q5*R5*Z)/
     -   (C1 + C2*R5**2) + 
     -  (2.0D0*GAMMA**2*PI*Q6*R*Z)/
     -   (EXP((R - R6)**2/GAMMA**2)*(C1 + C2*R6**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R6**2)/GAMMA**2 + 
     -       (R6*(2.0D0*R + R6))/GAMMA**2)*GAMMA**2*PI*Q6*R*Z)/
     -   (C1 + C2*R6**2) + 
     -  (2.0D0*GAMMA**2*PI*Q6*R6*Z)/
     -   (EXP(R6**2/GAMMA**2)*(C1 + C2*R6**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q6*R6*Z)/
     -   (EXP((R + R6)**2/GAMMA**2)*(C1 + C2*R6**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R6**2)/GAMMA**2 + 
     -       (R6*(2.0D0*R + R6))/GAMMA**2)*GAMMA**2*PI*Q6*R6*Z)/
     -   (C1 + C2*R6**2) - 
     -  (2.0D0*EXP(-((R + R6)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R6))/GAMMA**2)*GAMMA**2*PI*Q6*R6*Z)/
     -   (C1 + C2*R6**2) + 
     -  (2.0D0*GAMMA**2*PI*Q7*R*Z)/
     -   (EXP((R - R7)**2/GAMMA**2)*(C1 + C2*R7**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q7*R*Z)/
     -   (EXP((R + R7)**2/GAMMA**2)*(C1 + C2*R7**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R*R7)/GAMMA**2 - 
     -       R7**2/GAMMA**2)*GAMMA**2*PI*Q7*R*Z)/(C1 + C2*R7**2)
     -    - (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R7**2)/GAMMA**2 + 
     -       (R7*(2.0D0*R + R7))/GAMMA**2)*GAMMA**2*PI*Q7*R*Z)/
     -   (C1 + C2*R7**2) + 
     -  (2.0D0*GAMMA**2*PI*Q7*R7*Z)/
     -   (EXP(R7**2/GAMMA**2)*(C1 + C2*R7**2)) + 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R*R7)/GAMMA**2 - 
     -       R7**2/GAMMA**2)*GAMMA**2*PI*Q7*R7*Z)/
     -   (C1 + C2*R7**2) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R7**2)/GAMMA**2 + 
     -       (R7*(2.0D0*R + R7))/GAMMA**2)*GAMMA**2*PI*Q7*R7*Z)/
     -   (C1 + C2*R7**2) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R*R7)/GAMMA**2 - 
     -       R7**2/GAMMA**2 + (R*(R + 2.0D0*R7))/GAMMA**2)*GAMMA**2*
     -     PI*Q7*R7*Z)/(C1 + C2*R7**2) + 
     -  (2.0D0*GAMMA**2*PI*Q8*R*Z)/
     -   (EXP((R - R8)**2/GAMMA**2)*(C1 + C2*R8**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R8**2)/GAMMA**2 + 
     -       (R8*(2.0D0*R + R8))/GAMMA**2)*GAMMA**2*PI*Q8*R*Z)/
     -   (C1 + C2*R8**2) + 
     -  (2.0D0*GAMMA**2*PI*Q8*R8*Z)/
     -   (EXP(R8**2/GAMMA**2)*(C1 + C2*R8**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q8*R8*Z)/
     -   (EXP((R + R8)**2/GAMMA**2)*(C1 + C2*R8**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R8**2)/GAMMA**2 + 
     -       (R8*(2.0D0*R + R8))/GAMMA**2)*GAMMA**2*PI*Q8*R8*Z)/
     -   (C1 + C2*R8**2) - 
     -  (2.0D0*EXP(-((R + R8)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R8))/GAMMA**2)*GAMMA**2*PI*Q8*R8*Z)/
     -   (C1 + C2*R8**2) + 
     -  (2.0D0*GAMMA**2*PI*Q9*R*Z)/
     -   (EXP((R - R9)**2/GAMMA**2)*(C1 + C2*R9**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R9**2)/GAMMA**2 + 
     -       (R9*(2.0D0*R + R9))/GAMMA**2)*GAMMA**2*PI*Q9*R*Z)/
     -   (C1 + C2*R9**2) + 
     -  (2.0D0*GAMMA**2*PI*Q9*R9*Z)/
     -   (EXP(R9**2/GAMMA**2)*(C1 + C2*R9**2)) + 
     -  (2.0D0*GAMMA**2*PI*Q9*R9*Z)/
     -   (EXP((R + R9)**2/GAMMA**2)*(C1 + C2*R9**2)) - 
     -  (2.0D0*EXP(-(R**2/GAMMA**2) - (2.0D0*R9**2)/GAMMA**2 + 
     -       (R9*(2.0D0*R + R9))/GAMMA**2)*GAMMA**2*PI*Q9*R9*Z)/
     -   (C1 + C2*R9**2) - 
     -  (2.0D0*EXP(-((R + R9)**2/GAMMA**2) + 
     -       (R*(R + 2.0D0*R9))/GAMMA**2)*GAMMA**2*PI*Q9*R9*Z)/
     -   (C1 + C2*R9**2) + 
     -  (2.0D0*GAMMA**2*PI*Q1*R1**3*Z)/
     -   (EXP(R1**2/GAMMA**2)*(C1 + C2*R1**2)*ABS(R1)**2) - 
     -  (2.0D0*GAMMA**2*PI*Q1*R**3*Z)/
     -   (EXP((R + R1)**2/GAMMA**2)*(C1 + C2*R1**2)*
     -     ABS(R + R1)**2) - 
     -  (6*GAMMA**2*PI*Q1*R**2*R1*Z)/
     -   (EXP((R + R1)**2/GAMMA**2)*(C1 + C2*R1**2)*
     -     ABS(R + R1)**2) - 
     -  (6*GAMMA**2*PI*Q1*R*R1**2*Z)/
     -   (EXP((R + R1)**2/GAMMA**2)*(C1 + C2*R1**2)*
     -     ABS(R + R1)**2) - 
     -  (2.0D0*GAMMA**2*PI*Q1*R1**3*Z)/
     -   (EXP((R + R1)**2/GAMMA**2)*(C1 + C2*R1**2)*
     -     ABS(R + R1)**2) + 
     -  (GAMMA**3*PI**1.5*Q10*R*Z*
     -     ERF(DSQRT((R - R10)**2)/GAMMA))/
     -   (DSQRT((R - R10)**2)*(C1 + C2*R10**2)) - 
     -  (GAMMA**3*PI**1.5*Q10*R10*Z*
     -     ERF(DSQRT((R - R10)**2)/GAMMA))/
     -   (DSQRT((R - R10)**2)*(C1 + C2*R10**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R*R10**2*Z*
     -     ERF(DSQRT((R - R10)**2)/GAMMA))/
     -   (DSQRT((R - R10)**2)*(C1 + C2*R10**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R10**3*Z*
     -     ERF(DSQRT((R - R10)**2)/GAMMA))/
     -   (DSQRT((R - R10)**2)*(C1 + C2*R10**2)) - 
     -  (GAMMA**3*PI**1.5*Q10*Z*ERF(R10/GAMMA))/
     -   (C1 + C2*R10**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R10**2*Z*ERF(R10/GAMMA))/
     -   (C1 + C2*R10**2) + 
     -  (GAMMA**3*PI**1.5*Q10*DSQRT(R10**2)*Z*
     -     ERF(DSQRT(R10**2)/GAMMA))/(R10*(C1 + C2*R10**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R10*DSQRT(R10**2)*Z*
     -     ERF(DSQRT(R10**2)/GAMMA))/(C1 + C2*R10**2) + 
     -  (GAMMA**3*PI**1.5*Q10*Z*ERF((R + R10)/GAMMA))/
     -   (C1 + C2*R10**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R10**2*Z*ERF((R + R10)/GAMMA))/
     -   (C1 + C2*R10**2) + 
     -  (GAMMA**3*PI**1.5*Q11*R*Z*
     -     ERF(DSQRT((R - R11)**2)/GAMMA))/
     -   (DSQRT((R - R11)**2)*(C1 + C2*R11**2)) - 
     -  (GAMMA**3*PI**1.5*Q11*R11*Z*
     -     ERF(DSQRT((R - R11)**2)/GAMMA))/
     -   (DSQRT((R - R11)**2)*(C1 + C2*R11**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R*R11**2*Z*
     -     ERF(DSQRT((R - R11)**2)/GAMMA))/
     -   (DSQRT((R - R11)**2)*(C1 + C2*R11**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R11**3*Z*
     -     ERF(DSQRT((R - R11)**2)/GAMMA))/
     -   (DSQRT((R - R11)**2)*(C1 + C2*R11**2)) - 
     -  (GAMMA**3*PI**1.5*Q11*Z*ERF(R11/GAMMA))/
     -   (C1 + C2*R11**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R11**2*Z*ERF(R11/GAMMA))/
     -   (C1 + C2*R11**2) + 
     -  (GAMMA**3*PI**1.5*Q11*DSQRT(R11**2)*Z*
     -     ERF(DSQRT(R11**2)/GAMMA))/(R11*(C1 + C2*R11**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R11*DSQRT(R11**2)*Z*
     -     ERF(DSQRT(R11**2)/GAMMA))/(C1 + C2*R11**2) + 
     -  (GAMMA**3*PI**1.5*Q11*Z*ERF((R + R11)/GAMMA))/
     -   (C1 + C2*R11**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R11**2*Z*ERF((R + R11)/GAMMA))/
     -   (C1 + C2*R11**2) + 
     -  (GAMMA**3*PI**1.5*Q12*R*Z*
     -     ERF(DSQRT((R - R12)**2)/GAMMA))/
     -   (DSQRT((R - R12)**2)*(C1 + C2*R12**2)) - 
     -  (GAMMA**3*PI**1.5*Q12*R12*Z*
     -     ERF(DSQRT((R - R12)**2)/GAMMA))/
     -   (DSQRT((R - R12)**2)*(C1 + C2*R12**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q12*R*R12**2*Z*
     -     ERF(DSQRT((R - R12)**2)/GAMMA))/
     -   (DSQRT((R - R12)**2)*(C1 + C2*R12**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q12*R12**3*Z*
     -     ERF(DSQRT((R - R12)**2)/GAMMA))/
     -   (DSQRT((R - R12)**2)*(C1 + C2*R12**2)) - 
     -  (GAMMA**3*PI**1.5*Q12*Z*ERF(R12/GAMMA))/
     -   (C1 + C2*R12**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q12*R12**2*Z*ERF(R12/GAMMA))/
     -   (C1 + C2*R12**2) + 
     -  (GAMMA**3*PI**1.5*Q12*DSQRT(R12**2)*Z*
     -     ERF(DSQRT(R12**2)/GAMMA))/(R12*(C1 + C2*R12**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q12*R12*DSQRT(R12**2)*Z*
     -     ERF(DSQRT(R12**2)/GAMMA))/(C1 + C2*R12**2) + 
     -  (GAMMA**3*PI**1.5*Q12*Z*ERF((R + R12)/GAMMA))/
     -   (C1 + C2*R12**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q12*R12**2*Z*ERF((R + R12)/GAMMA))/
     -   (C1 + C2*R12**2) + 
     -  (GAMMA**3*PI**1.5*Q2*R*Z*ERF(DSQRT((R - R2)**2)/GAMMA))/
     -   (DSQRT((R - R2)**2)*(C1 + C2*R2**2)) - 
     -  (GAMMA**3*PI**1.5*Q2*R2*Z*ERF(DSQRT((R - R2)**2)/GAMMA))/
     -   (DSQRT((R - R2)**2)*(C1 + C2*R2**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R*R2**2*Z*
     -     ERF(DSQRT((R - R2)**2)/GAMMA))/
     -   (DSQRT((R - R2)**2)*(C1 + C2*R2**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R2**3*Z*
     -     ERF(DSQRT((R - R2)**2)/GAMMA))/
     -   (DSQRT((R - R2)**2)*(C1 + C2*R2**2)) - 
     -  (GAMMA**3*PI**1.5*Q2*Z*ERF(R2/GAMMA))/(C1 + C2*R2**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R2**2*Z*ERF(R2/GAMMA))/
     -   (C1 + C2*R2**2) + 
     -  (GAMMA**3*PI**1.5*Q2*DSQRT(R2**2)*Z*
     -     ERF(DSQRT(R2**2)/GAMMA))/(R2*(C1 + C2*R2**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R2*DSQRT(R2**2)*Z*
     -     ERF(DSQRT(R2**2)/GAMMA))/(C1 + C2*R2**2) + 
     -  (GAMMA**3*PI**1.5*Q2*Z*ERF((R + R2)/GAMMA))/
     -   (C1 + C2*R2**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R2**2*Z*ERF((R + R2)/GAMMA))/
     -   (C1 + C2*R2**2) + 
     -  (GAMMA**3*PI**1.5*Q3*R*Z*ERF(DSQRT((R - R3)**2)/GAMMA))/
     -   (DSQRT((R - R3)**2)*(C1 + C2*R3**2)) - 
     -  (GAMMA**3*PI**1.5*Q3*R3*Z*ERF(DSQRT((R - R3)**2)/GAMMA))/
     -   (DSQRT((R - R3)**2)*(C1 + C2*R3**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R*R3**2*Z*
     -     ERF(DSQRT((R - R3)**2)/GAMMA))/
     -   (DSQRT((R - R3)**2)*(C1 + C2*R3**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R3**3*Z*
     -     ERF(DSQRT((R - R3)**2)/GAMMA))/
     -   (DSQRT((R - R3)**2)*(C1 + C2*R3**2)) - 
     -  (GAMMA**3*PI**1.5*Q3*Z*ERF(R3/GAMMA))/(C1 + C2*R3**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R3**2*Z*ERF(R3/GAMMA))/
     -   (C1 + C2*R3**2) + 
     -  (GAMMA**3*PI**1.5*Q3*DSQRT(R3**2)*Z*
     -     ERF(DSQRT(R3**2)/GAMMA))/(R3*(C1 + C2*R3**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R3*DSQRT(R3**2)*Z*
     -     ERF(DSQRT(R3**2)/GAMMA))/(C1 + C2*R3**2) + 
     -  (GAMMA**3*PI**1.5*Q3*Z*ERF((R + R3)/GAMMA))/
     -   (C1 + C2*R3**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R3**2*Z*ERF((R + R3)/GAMMA))/
     -   (C1 + C2*R3**2) + 
     -  (GAMMA**3*PI**1.5*Q4*R*Z*ERF(DSQRT((R - R4)**2)/GAMMA))/
     -   (DSQRT((R - R4)**2)*(C1 + C2*R4**2)) - 
     -  (GAMMA**3*PI**1.5*Q4*R4*Z*ERF(DSQRT((R - R4)**2)/GAMMA))/
     -   (DSQRT((R - R4)**2)*(C1 + C2*R4**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R*R4**2*Z*
     -     ERF(DSQRT((R - R4)**2)/GAMMA))/
     -   (DSQRT((R - R4)**2)*(C1 + C2*R4**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R4**3*Z*
     -     ERF(DSQRT((R - R4)**2)/GAMMA))/
     -   (DSQRT((R - R4)**2)*(C1 + C2*R4**2)) - 
     -  (GAMMA**3*PI**1.5*Q4*Z*ERF(R4/GAMMA))/(C1 + C2*R4**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R4**2*Z*ERF(R4/GAMMA))/
     -   (C1 + C2*R4**2) + 
     -  (GAMMA**3*PI**1.5*Q4*DSQRT(R4**2)*Z*
     -     ERF(DSQRT(R4**2)/GAMMA))/(R4*(C1 + C2*R4**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R4*DSQRT(R4**2)*Z*
     -     ERF(DSQRT(R4**2)/GAMMA))/(C1 + C2*R4**2) + 
     -  (GAMMA**3*PI**1.5*Q4*Z*ERF((R + R4)/GAMMA))/
     -   (C1 + C2*R4**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R4**2*Z*ERF((R + R4)/GAMMA))/
     -   (C1 + C2*R4**2) + 
     -  (GAMMA**3*PI**1.5*Q5*R*Z*ERF(DSQRT((R - R5)**2)/GAMMA))/
     -   (DSQRT((R - R5)**2)*(C1 + C2*R5**2)) - 
     -  (GAMMA**3*PI**1.5*Q5*R5*Z*ERF(DSQRT((R - R5)**2)/GAMMA))/
     -   (DSQRT((R - R5)**2)*(C1 + C2*R5**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R*R5**2*Z*
     -     ERF(DSQRT((R - R5)**2)/GAMMA))/
     -   (DSQRT((R - R5)**2)*(C1 + C2*R5**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R5**3*Z*
     -     ERF(DSQRT((R - R5)**2)/GAMMA))/
     -   (DSQRT((R - R5)**2)*(C1 + C2*R5**2)) - 
     -  (GAMMA**3*PI**1.5*Q5*Z*ERF(R5/GAMMA))/(C1 + C2*R5**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R5**2*Z*ERF(R5/GAMMA))/
     -   (C1 + C2*R5**2) + 
     -  (GAMMA**3*PI**1.5*Q5*Sqrt(R5**2)*Z*
     -     ERF(Sqrt(R5**2)/GAMMA))/(R5*(C1 + C2*R5**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R5*Sqrt(R5**2)*Z*
     -     ERF(Sqrt(R5**2)/GAMMA))/(C1 + C2*R5**2) + 
     -  (GAMMA**3*PI**1.5*Q5*Z*ERF((R + R5)/GAMMA))/
     -   (C1 + C2*R5**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R5**2*Z*ERF((R + R5)/GAMMA))/
     -   (C1 + C2*R5**2) + 
     -  (GAMMA**3*PI**1.5*Q6*R*Z*ERF(DSQRT((R - R6)**2)/GAMMA))/
     -   (DSQRT((R - R6)**2)*(C1 + C2*R6**2)) - 
     -  (GAMMA**3*PI**1.5*Q6*R6*Z*ERF(DSQRT((R - R6)**2)/GAMMA))/
     -   (DSQRT((R - R6)**2)*(C1 + C2*R6**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R*R6**2*Z*
     -     ERF(DSQRT((R - R6)**2)/GAMMA))/
     -   (DSQRT((R - R6)**2)*(C1 + C2*R6**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R6**3*Z*
     -     ERF(DSQRT((R - R6)**2)/GAMMA))/
     -   (DSQRT((R - R6)**2)*(C1 + C2*R6**2)) - 
     -  (GAMMA**3*PI**1.5*Q6*Z*ERF(R6/GAMMA))/(C1 + C2*R6**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R6**2*Z*ERF(R6/GAMMA))/
     -   (C1 + C2*R6**2) + 
     -  (GAMMA**3*PI**1.5*Q6*Sqrt(R6**2)*Z*
     -     ERF(Sqrt(R6**2)/GAMMA))/(R6*(C1 + C2*R6**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R6*Sqrt(R6**2)*Z*
     -     ERF(Sqrt(R6**2)/GAMMA))/(C1 + C2*R6**2) + 
     -  (GAMMA**3*PI**1.5*Q6*Z*ERF((R + R6)/GAMMA))/
     -   (C1 + C2*R6**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R6**2*Z*ERF((R + R6)/GAMMA))/
     -   (C1 + C2*R6**2) + 
     -  (GAMMA**3*PI**1.5*Q7*R*Z*ERF(DSQRT((R - R7)**2)/GAMMA))/
     -   (DSQRT((R - R7)**2)*(C1 + C2*R7**2)) - 
     -  (GAMMA**3*PI**1.5*Q7*R7*Z*ERF(DSQRT((R - R7)**2)/GAMMA))/
     -   (DSQRT((R - R7)**2)*(C1 + C2*R7**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R*R7**2*Z*
     -     ERF(DSQRT((R - R7)**2)/GAMMA))/
     -   (DSQRT((R - R7)**2)*(C1 + C2*R7**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R7**3*Z*
     -     ERF(DSQRT((R - R7)**2)/GAMMA))/
     -   (DSQRT((R - R7)**2)*(C1 + C2*R7**2)) + 
     -  (GAMMA**3*PI**1.5*Q7*R*Z*ERF(DSQRT((R + R7)**2)/GAMMA))/
     -   (DSQRT((R + R7)**2)*(C1 + C2*R7**2)) + 
     -  (GAMMA**3*PI**1.5*Q7*R7*Z*ERF(DSQRT((R + R7)**2)/GAMMA))/
     -   (DSQRT((R + R7)**2)*(C1 + C2*R7**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R*R7**2*Z*
     -     ERF(DSQRT((R + R7)**2)/GAMMA))/
     -   (DSQRT((R + R7)**2)*(C1 + C2*R7**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R7**3*Z*
     -     ERF(DSQRT((R + R7)**2)/GAMMA))/
     -   (DSQRT((R + R7)**2)*(C1 + C2*R7**2)) + 
     -  (GAMMA**3*PI**1.5*Q8*R*Z*ERF(DSQRT((R - R8)**2)/GAMMA))/
     -   (DSQRT((R - R8)**2)*(C1 + C2*R8**2)) - 
     -  (GAMMA**3*PI**1.5*Q8*R8*Z*ERF(DSQRT((R - R8)**2)/GAMMA))/
     -   (DSQRT((R - R8)**2)*(C1 + C2*R8**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R*R8**2*Z*
     -     ERF(DSQRT((R - R8)**2)/GAMMA))/
     -   (DSQRT((R - R8)**2)*(C1 + C2*R8**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R8**3*Z*
     -     ERF(DSQRT((R - R8)**2)/GAMMA))/
     -   (DSQRT((R - R8)**2)*(C1 + C2*R8**2)) - 
     -  (GAMMA**3*PI**1.5*Q8*Z*ERF(R8/GAMMA))/(C1 + C2*R8**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R8**2*Z*ERF(R8/GAMMA))/
     -   (C1 + C2*R8**2) + 
     -  (GAMMA**3*PI**1.5*Q8*Sqrt(R8**2)*Z*
     -     ERF(Sqrt(R8**2)/GAMMA))/(R8*(C1 + C2*R8**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R8*Sqrt(R8**2)*Z*
     -     ERF(Sqrt(R8**2)/GAMMA))/(C1 + C2*R8**2) + 
     -  (GAMMA**3*PI**1.5*Q8*Z*ERF((R + R8)/GAMMA))/
     -   (C1 + C2*R8**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R8**2*Z*ERF((R + R8)/GAMMA))/
     -   (C1 + C2*R8**2) + 
     -  (GAMMA**3*PI**1.5*Q9*R*Z*ERF(DSQRT((R - R9)**2)/GAMMA))/
     -   (DSQRT((R - R9)**2)*(C1 + C2*R9**2)) - 
     -  (GAMMA**3*PI**1.5*Q9*R9*Z*ERF(DSQRT((R - R9)**2)/GAMMA))/
     -   (DSQRT((R - R9)**2)*(C1 + C2*R9**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R*R9**2*Z*
     -     ERF(DSQRT((R - R9)**2)/GAMMA))/
     -   (DSQRT((R - R9)**2)*(C1 + C2*R9**2)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R9**3*Z*
     -     ERF(DSQRT((R - R9)**2)/GAMMA))/
     -   (DSQRT((R - R9)**2)*(C1 + C2*R9**2)) - 
     -  (GAMMA**3*PI**1.5*Q9*Z*ERF(R9/GAMMA))/(C1 + C2*R9**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R9**2*Z*ERF(R9/GAMMA))/
     -   (C1 + C2*R9**2) + 
     -  (GAMMA**3*PI**1.5*Q9*Sqrt(R9**2)*Z*
     -     ERF(Sqrt(R9**2)/GAMMA))/(R9*(C1 + C2*R9**2)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R9*Sqrt(R9**2)*Z*
     -     ERF(Sqrt(R9**2)/GAMMA))/(C1 + C2*R9**2) + 
     -  (GAMMA**3*PI**1.5*Q9*Z*ERF((R + R9)/GAMMA))/
     -   (C1 + C2*R9**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R9**2*Z*ERF((R + R9)/GAMMA))/
     -   (C1 + C2*R9**2) + 
     -  (GAMMA**3*PI**1.5*Q1*R**3*Z*ERF(ABS(R - R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R - R1)**3) - 
     -  (3*GAMMA**3*PI**1.5*Q1*R**2*R1*Z*
     -     ERF(ABS(R - R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R - R1)**3) + 
     -  (3*GAMMA**3*PI**1.5*Q1*R*R1**2*Z*
     -     ERF(ABS(R - R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R - R1)**3) - 
     -  (GAMMA**3*PI**1.5*Q1*R1**3*Z*ERF(ABS(R - R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R - R1)**3) + 
     -  (2.0D0*GAMMA*PI**1.5*Q1*R*R1**2*Z*ERF(ABS(R - R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R - R1)) - 
     -  (2.0D0*GAMMA*PI**1.5*Q1*R1**3*Z*ERF(ABS(R - R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R - R1)) + 
     -  (GAMMA**3*PI**1.5*Q1*R**3*Z*ERF(ABS(R + R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R + R1)**3) + 
     -  (3*GAMMA**3*PI**1.5*Q1*R**2*R1*Z*
     -     ERF(ABS(R + R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R + R1)**3) + 
     -  (3*GAMMA**3*PI**1.5*Q1*R*R1**2*Z*
     -     ERF(ABS(R + R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R + R1)**3) + 
     -  (GAMMA**3*PI**1.5*Q1*R1**3*Z*ERF(ABS(R + R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R + R1)**3) + 
     -  (2.0D0*GAMMA*PI**1.5*Q1*R*R1**2*Z*ERF(ABS(R + R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R + R1)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q1*R1**3*Z*ERF(ABS(R + R1)/GAMMA))/
     -   ((C1 + C2*R1**2)*ABS(R + R1)) + 
     -  (2.0D0*GAMMA*PI**1.5*Q1*R*R1*Z*ERFC((R - R1)/GAMMA))/
     -   (C1 + C2*R1**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q1*R*R1*Z*ERFC((R + R1)/GAMMA))/
     -   (C1 + C2*R1**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R*R10*Z*ERFC((R - R10)/GAMMA))/
     -   (C1 + C2*R10**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q10*R*R10*Z*ERFC((R + R10)/GAMMA))/
     -   (C1 + C2*R10**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R*R11*Z*ERFC((R - R11)/GAMMA))/
     -   (C1 + C2*R11**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q11*R*R11*Z*ERFC((R + R11)/GAMMA))/
     -   (C1 + C2*R11**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q12*R*R12*Z*ERFC((R - R12)/GAMMA))/
     -   (C1 + C2*R12**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q12*R*R12*Z*ERFC((R + R12)/GAMMA))/
     -   (C1 + C2*R12**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R*R2*Z*ERFC((R - R2)/GAMMA))/
     -   (C1 + C2*R2**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q2*R*R2*Z*ERFC((R + R2)/GAMMA))/
     -   (C1 + C2*R2**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R*R3*Z*ERFC((R - R3)/GAMMA))/
     -   (C1 + C2*R3**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q3*R*R3*Z*ERFC((R + R3)/GAMMA))/
     -   (C1 + C2*R3**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R*R4*Z*ERFC((R - R4)/GAMMA))/
     -   (C1 + C2*R4**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q4*R*R4*Z*ERFC((R + R4)/GAMMA))/
     -   (C1 + C2*R4**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R*R5*Z*ERFC((R - R5)/GAMMA))/
     -   (C1 + C2*R5**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q5*R*R5*Z*ERFC((R + R5)/GAMMA))/
     -   (C1 + C2*R5**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R*R6*Z*ERFC((R - R6)/GAMMA))/
     -   (C1 + C2*R6**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q6*R*R6*Z*ERFC((R + R6)/GAMMA))/
     -   (C1 + C2*R6**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R*R7*Z*ERFC((R - R7)/GAMMA))/
     -   (C1 + C2*R7**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q7*R*R7*Z*ERFC((R + R7)/GAMMA))/
     -   (C1 + C2*R7**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R*R8*Z*ERFC((R - R8)/GAMMA))/
     -   (C1 + C2*R8**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q8*R*R8*Z*ERFC((R + R8)/GAMMA))/
     -   (C1 + C2*R8**2) + 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R*R9*Z*ERFC((R - R9)/GAMMA))/
     -   (C1 + C2*R9**2) - 
     -  (2.0D0*GAMMA*PI**1.5*Q9*R*R9*Z*ERFC((R + R9)/GAMMA))/
     -   (C1 + C2*R9**2)
        END IF

        GAUSSDENS(I)=
     -       (A1*(EXP(-((R-R1)/GAMMA)**2)+EXP(-((R+R1)/GAMMA)**2))
     -       +A2*(EXP(-((R-R2)/GAMMA)**2)+EXP(-((R+R2)/GAMMA)**2))
     -       +A3*(EXP(-((R-R3)/GAMMA)**2)+EXP(-((R+R3)/GAMMA)**2))
     -       +A4*(EXP(-((R-R4)/GAMMA)**2)+EXP(-((R+R4)/GAMMA)**2))
     -       +A5*(EXP(-((R-R5)/GAMMA)**2)+EXP(-((R+R5)/GAMMA)**2))
     -       +A6*(EXP(-((R-R6)/GAMMA)**2)+EXP(-((R+R6)/GAMMA)**2))
     -       +A7*(EXP(-((R-R7)/GAMMA)**2)+EXP(-((R+R7)/GAMMA)**2))
     -       +A8*(EXP(-((R-R8)/GAMMA)**2)+EXP(-((R+R8)/GAMMA)**2))
     -       +A9*(EXP(-((R-R9)/GAMMA)**2)+EXP(-((R+R9)/GAMMA)**2))
     -       +A10*(EXP(-((R-R10)/GAMMA)**2)+EXP(-((R+R10)/GAMMA)**2))
     -       +A11*(EXP(-((R-R11)/GAMMA)**2)+EXP(-((R+R11)/GAMMA)**2))
     -       +A12*(EXP(-((R-R12)/GAMMA)**2)+EXP(-((R+R12)/GAMMA)**2)))
        END DO
        RA=RADIUS(INT(Z),ISOT)
        RAT=RADIUST(INT(Z),ISOT)

        RETURN
      END      


      SUBROUTINE BESSELCALC(BESSEL,BESSELDENS,RA,Z,ISOT,RMIN,RMAX,N)
C       This subroutine uses Fourier Bessel distribution given in:
C           Vreis et al, At. Data Nucl. Data Tabl. 36 (1987)
C       with the following input parameters:
C           Z - atomic number
C           ISOT - isotop indicator flag 
C           RMIN/RMAX - min/max values of r of the radial grid
C           N - number of grid points
C       to obtain the following output:
C           BESSEL(i) = r(i) V(r(i)) - via interpolation
C           BESSELDENS(i) = rho(r(i))
C           RA - charge radius of the distribution in fm
C       Oleksandr Koshchii: June 2019
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        EXTERNAL BESJN
        
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)
        PARAMETER (ALPHAFS=1.0D0/137.03599976D0) 
        PARAMETER (PI=3.1415926535897932D0)
        PARAMETER (FOURPI=4.0D0*PI)
        DIMENSION DIFR(N+4),RI(N+4),BESSEL(N),BESSELDENS(N)
      
        NDIN1=N+1

        CALL SGRID(RI,DIFR,RMIN,RMAX,0.5D0*DBLE(N),N)
        CALL BESSELCOEF(A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,A12,A13,A14,A15,A16,A17,C1,Z,ISOT)
      
        DO I=1,N
            R=RI(I)
        
            BESSEL(I)=(4.0D0*A1*C1**3*HEAVISIDETHETA(C1))/PI - 
     -                  (A10*C1**3*HEAVISIDETHETA(C1))/(25.0D0*PI) + 
     -                  (4.0D0*A11*C1**3*HEAVISIDETHETA(C1))/(121.0D0*PI) - 
     -                  (A12*C1**3*HEAVISIDETHETA(C1))/(36.0D0*PI) + 
     -                  (4.0D0*A13*C1**3*HEAVISIDETHETA(C1))/(169.0D0*PI) - 
     -                  (A14*C1**3*HEAVISIDETHETA(C1))/(49.0D0*PI) + 
     -                  (4.0D0*A15*C1**3*HEAVISIDETHETA(C1))/(225.0D0*PI) - 
     -                  (A16*C1**3*HEAVISIDETHETA(C1))/(64.0D0*PI) + 
     -                  (4.0D0*A17*C1**3*HEAVISIDETHETA(C1))/(289.0D0*PI) - 
     -                  (A2*C1**3*HEAVISIDETHETA(C1))/PI + 
     -                  (4.0D0*A3*C1**3*HEAVISIDETHETA(C1))/(9.0D0*PI) - 
     -                   (A4*C1**3*HEAVISIDETHETA(C1))/(4.0D0*PI) + 
     -                  (4.0D0*A5*C1**3*HEAVISIDETHETA(C1))/(25.0D0*PI) - 
     -                  (A6*C1**3*HEAVISIDETHETA(C1))/(9.0D0*PI) + 
     -                  (4.0D0*A7*C1**3*HEAVISIDETHETA(C1))/(49.0D0*PI) - 
     -                  (A8*C1**3*HEAVISIDETHETA(C1))/(16.0D0*PI) + 
     -                  (4.0D0*A9*C1**3*HEAVISIDETHETA(C1))/(81.0D0*PI) + 
     -                  (4.0D0*A1*C1**2*R*HEAVISIDETHETA(C1 - R))/PI + 
     -                  (4.0D0*A11*C1**2*R*HEAVISIDETHETA(C1 - R))/(121.0D0*PI) + 
     -                  (4.0D0*A13*C1**2*R*HEAVISIDETHETA(C1 - R))/(169.0D0*PI) + 
     -                  (4.0D0*A15*C1**2*R*HEAVISIDETHETA(C1 - R))/(225.0D0*PI) + 
     -                  (4.0D0*A17*C1**2*R*HEAVISIDETHETA(C1 - R))/(289.0D0*PI) + 
     -                  (4.0D0*A3*C1**2*R*HEAVISIDETHETA(C1 - R))/(9.0D0*PI) + 
     -                  (4.0D0*A5*C1**2*R*HEAVISIDETHETA(C1 - R))/(25.0D0*PI) + 
     -                  (4.0D0*A7*C1**2*R*HEAVISIDETHETA(C1 - R))/(49.0D0*PI) + 
     -                  (4.0D0*A9*C1**2*R*HEAVISIDETHETA(C1 - R))/(81.0D0*PI) + 
     -                  (4.0D0*A1*C1**2*R*COS((PI*R)/C1)*HEAVISIDETHETA(C1 - R))/PI + 
     -                  (4.0D0*A3*C1**2*R*COS((3.0D0*PI*R)/C1)*HEAVISIDETHETA(C1 - R))/
     -                  (9.0D0*PI) + (4.0D0*A5*C1**2*R*COS((5.0D0*PI*R)/C1)*
     -                  HEAVISIDETHETA(C1 - R))/(25.0D0*PI) + 
     -                  (4.0D0*A7*C1**2*R*COS((7.0D0*PI*R)/C1)*HEAVISIDETHETA(C1 - R))/
     -                  (49.0D0*PI) + (4.0D0*A9*C1**2*R*COS((9.0D0*PI*R)/C1)*
     -                  HEAVISIDETHETA(C1 - R))/(81.0D0*PI) + 
     -                  (4.0D0*A11*C1**2*R*COS((11.0D0*PI*R)/C1)*
     -                  HEAVISIDETHETA(C1 - R))/
     -                  (121.0D0*PI) + (4.0D0*A13*C1**2*R*COS((13.0D0*PI*R)/C1)*
     -                  HEAVISIDETHETA(C1 - R))/(169.0D0*PI) + 
     -                  (4.0D0*A15*C1**2*R*COS((15.0D0*PI*R)/C1)*
     -                  HEAVISIDETHETA(C1 - R))/
     -                  (225.0D0*PI) + (4.0D0*A17*C1**2*R*COS((17.0D0*PI*R)/C1)*
     -                  HEAVISIDETHETA(C1 - R))/(289.0D0*PI) - 
     -                  (4.0D0*A1*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R))/PI + 
     -                  (A10*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R))/
     -                  (25.0D0*PI) - (4.0D0*A11*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(121.0D0*PI) + 
     -                  (A12*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R))/
     -                  (36.0D0*PI) - (4.0D0*A13*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(169.0D0*PI) + 
     -                  (A14*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R))/
     -                  (49.0D0*PI) - (4.0D0*A15*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(225.0D0*PI) + 
     -                  (A16*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R))/
     -                  (64.0D0*PI) - (4.0D0*A17*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(289.0D0*PI) + 
     -                  (A2*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R))/PI - 
     -                  (4.0D0*A3*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R))/
     -                  (9.0D0*PI) + (A4*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(4.0D0*PI) - 
     -                  (4.0D0*A5*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R))/
     -                  (25.0D0*PI) + (A6*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(9.0D0*PI) - 
     -                  (4.0D0*A7*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R))/
     -                  (49.0D0*PI) + (A8*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(16.0D0*PI) - 
     -                  (4.0D0*A9*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R))/
     -                  (81.0D0*PI) - (4.0D0*A1*C1**2*R*COS((PI*R)/C1)*
     -                  HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/PI - 
     -                  (A2*C1**2*R*COS((2.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/PI - 
     -                  (4.0D0*A3*C1**2*R*COS((3.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(9.0D0*PI) - 
     -                  (A4*C1**2*R*COS((4.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(4.0D0*PI) - 
     -                  (4.0D0*A5*C1**2*R*COS((5.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(25.0D0*PI) - 
     -                  (A6*C1**2*R*COS((6.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(9.0D0*PI) - 
     -                  (4.0D0*A7*C1**2*R*COS((7.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(49.0D0*PI) - 
     -                  (A8*C1**2*R*COS((8.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(16.0D0*PI) - 
     -                  (4.0D0*A9*C1**2*R*COS((9.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(81.0D0*PI) - 
     -                  (A10*C1**2*R*COS((10.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(25.0D0*PI) - 
     -                  (4.0D0*A11*C1**2*R*COS((11.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(121.0D0*PI) - 
     -                  (A12*C1**2*R*COS((12.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(36.0D0*PI) - 
     -                  (4.0D0*A13*C1**2*R*COS((13.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(169.0D0*PI) - 
     -                  (A14*C1**2*R*COS((14.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(49.0D0*PI) - 
     -                  (4.0D0*A15*C1**2*R*COS((15.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(225.0D0*PI) - 
     -                  (A16*C1**2*R*COS((16.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(64.0D0*PI) - 
     -                  (4.0D0*A17*C1**2*R*COS((17.0D0*PI*R)/C1)*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R))/(289.0D0*PI) + 
     -                  (4.0D0*A1*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R)*
     -                  SIN((PI*R)/C1))/PI**2 - 
     -                  (2.0D0*A2*C1**2*R*HEAVISIDETHETA(C1 - R)*SIN((PI*R)/C1)**2)/
     -                  PI + (A2*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R)*
     -                  SIN((2.0D0*PI*R)/C1))/(2.0D0*PI**2) - 
     -                  (A4*C1**2*R*HEAVISIDETHETA(C1 - R)*SIN((2.0D0*PI*R)/C1)**2)/
     -                  (2.0D0*PI) + (4.0D0*A3*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R)*SIN((3.0D0*PI*R)/C1))/(27.0D0*PI**2)- 
     -                  (2*A6*C1**2*R*HEAVISIDETHETA(C1 - R)*SIN((3.0D0*PI*R)/C1)**2)/
     -                  (9.0D0*PI) + (A4*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R)*SIN((4.0D0*PI*R)/C1))/(16.0D0*PI**2)- 
     -                  (A8*C1**2*R*HEAVISIDETHETA(C1 - R)*SIN((4.0D0*PI*R)/C1)**2)/
     -                  (8.0D0*PI) + (4.0D0*A5*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R)*SIN((5.0D0*PI*R)/C1))/
     -                  (125.0D0*PI**2) - 
     -                  (2.0D0*A10*C1**2*R*HEAVISIDETHETA(C1 - R)*
     -                  SIN((5.0D0*PI*R)/C1)**2)/
     -                  (25.0D0*PI) + (A6*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R)*SIN((6.0D0*PI*R)/C1))/(54.0D0*PI**2)- 
     -                  (A12*C1**2*R*HEAVISIDETHETA(C1 - R)*SIN((6.0D0*PI*R)/C1)**2)/
     -                  (18.0D0*PI) + (4.0D0*A7*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R)*SIN((7.0D0*PI*R)/C1))/
     -                  (343.0D0*PI**2) - 
     -                  (2.0D0*A14*C1**2*R*HEAVISIDETHETA(C1 - R)*
     -                  SIN((7.0D0*PI*R)/C1)**2)/
     -                  (49.0D0*PI) + (A8*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R)*SIN((8.0D0*PI*R)/C1))/
     -                  (128.0D0*PI**2) - 
     -                  (A16*C1**2*R*HEAVISIDETHETA(C1 - R)*SIN((8.0D0*PI*R)/C1)**2)/
     -                  (32.0D0*PI) + (4.0D0*A9*C1**3*HEAVISIDETHETA(C1)*
     -                  HEAVISIDETHETA(C1 - R)*SIN((9.0D0*PI*R)/C1))/
     -                  (729.0D0*PI**2) + 
     -                  (A10*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R)*
     -                  SIN((10.0D0*PI*R)/C1))/(250.0D0*PI**2) + 
     -                  (4.0D0*A11*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R)*
     -                  SIN((11.0D0*PI*R)/C1))/(1331.0D0*PI**2) + 
     -                  (A12*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R)*
     -                  SIN((12.0D0*PI*R)/C1))/(432.0D0*PI**2) + 
     -                  (4.0D0*A13*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R)*
     -                  SIN((13.0D0*PI*R)/C1))/(2197.0D0*PI**2) + 
     -                  (A14*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R)*
     -                   SIN((14.0D0*PI*R)/C1))/(686.0D0*PI**2) + 
     -                  (4.0D0*A15*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R)*
     -                  SIN((15.0D0*PI*R)/C1))/(3375.0D0*PI**2) + 
     -                  (A16*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R)*
     -                  SIN((16.0D0*PI*R)/C1))/(1024.0D0*PI**2) + 
     -                  (4.0D0*A17*C1**3*HEAVISIDETHETA(C1)*HEAVISIDETHETA(C1 - R)*
     -                  SIN((17.0D0*PI*R)/C1))/(4913.0D0*PI**2)

            BESSELDENS(I)=(A1*BESJN(1,0,PI*R/C1) + A2*BESJN(1,0,2.0D0*PI*R/C1) +            
     -                 A3*BESJN(1,0,3.0D0*PI*R/C1) + A4*BESJN(1,0,4.0D0*PI*R/C1) + 
     -                 A5*BESJN(1,0,5.0D0*PI*R/C1) + A6*BESJN(1,0,6.0D0*PI*R/C1) + 
     -                 A7*BESJN(1,0,7.0D0*PI*R/C1) + A8*BESJN(1,0,8.0D0*PI*R/C1) + 
     -                 A9*BESJN(1,0,9.0D0*PI*R/C1) + A10*BESJN(1,0,10.0D0*PI*R/C1) + 
     -                 A11*BESJN(1,0,11.0D0*PI*R/C1) + A12*BESJN(1,0,12.0D0*PI*R/C1) + 
     -                 A13*BESJN(1,0,13.0D0*PI*R/C1) + A14*BESJN(1,0,14.0D0*PI*R/C1) + 
     -                 A15*BESJN(1,0,15.0D0*PI*R/C1) + A16*BESJN(1,0,16.0D0*PI*R/C1) +
     -                 A17*BESJN(1,0,17.0D0*PI*R/C1))*HEAVISIDETHETA(C1-R)
        END DO
        
        RA=RADIUS(INT(Z),ISOT)
        RAT=RADIUST(INT(Z),ISOT)
        WRITE (*,*), 'BESSEL=', BESSEL(835)
        RETURN
            
      END


      SUBROUTINE FERMICALC(FERMI,FERMIDENS,RA,RAT,Z,C,A,RMIN,RMAX,N)
C       This subroutine uses 2p symmetrized Fermi distribution given by:
C           rho(r) = RHO0*SINH(C/A)/(COSH(r/A)+COSH(C/A))
C       with the following input parameters:
C           Z - atomic number
C           C - half-density radius 
C           A - surface diffusiness 
C           RMIN/RMAX - min/max values of r of the radial grid
C           N - number of grid points
C       to obtain the following output:
C           FERMI(i) = r(i) V(r(i)) - via interpolation
C           FERMIDENS(i) = rho(r(i))
C           RA - charge radius of the distribution
C           RAT - charge radius4 of the distribution
C       Oleksandr Koshchii: June 2019
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)
        PARAMETER (ALPHAFS=1.0D0/137.03599976D0) 
        PARAMETER (PI=3.1415926535897932D0)
        PARAMETER (FOURPI=4.0D0*PI)
        DIMENSION DIFR(N+4),DENN(N+4),RVN(N+4),R(N+4),AUX(N+4),FERMI(N),FERMIDENS(N),RADIUSF(N),RADIUSFT(N)
      
        NDIN1=N+1

        RHO0=3.0D0*Z/(4.0D0*PI*C*(C**2+(PI*A)**2))
        CALL SGRID(R,DIFR,RMIN,RMAX,0.5D0*DBLE(N),N)

        DO I=1,N
          X=R(I)
          DENN(I)=RHO0*SINH(C/A)/(COSH(X/A)+COSH(C/A))
          RVN(I)=FOURPI*DENN(I)*X**2*DIFR(I)
        ENDDO
        
        CALL SLAG6(1.0D0,RVN,RVN,N)
        DO I=1,N
            K=NDIN1-I
            AUX(I)=FOURPI*DENN(K)*R(K)*DIFR(K)
        ENDDO
        CALL SLAG6(1.0D0,AUX,AUX,N)
      
        DO I=1,N
            FERMI(I)=(RVN(I)+AUX(NDIN1-I)*R(I))
            FERMIDENS(I)=DENN(I)
            RADIUSF(I)=FOURPI*FERMIDENS(I)*R(I)**4*DIFR(I)/Z
            RADIUSFT(I)=FOURPI*FERMIDENS(I)*R(I)**6*DIFR(I)/Z
        ENDDO

        CALL SLAG6(1.0D0,RADIUSF,RADIUSF,N)
        CALL SLAG6(1.0D0,RADIUSFT,RADIUSFT,N)
        RA=(RADIUSF(N)**0.5D0)/F2BOHR
        RAT=(RADIUSFT(N)**0.25D0)/F2BOHR
        RETURN
      END


      SUBROUTINE HELMCALC(HELM,HELMDENS,RA,RAT,Z,C0,SIG,RMIN,RMAX,N)
C       This subroutine uses Helm distribution given in:
C       Piekarewicz et al, PRC 94, 034316 (2016)
C       with the following input parameters:
C           Z - atomic number
C           C0 - half-density radius 
C           SIG - surface diffusiness 
C           N - number of grid points
C       to obtain the following output:
C           HELM(I) = r(i) V(r(i)) - via interpolation
C           HELMDENS(i) = rho(r(i))
C           RA - charge radius of the distribution
C           RAT - charge radius4 of the distribution
C       Oleksandr Koshchii: November 2019

        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.889726D-5)!1.0D-13/A0B)
        PARAMETER (ALPHAFS=1.0D0/137.03599976D0) 
        PARAMETER (PI=3.1415926535897932D0)
        PARAMETER (FOURPI=4.0D0*PI)
        DIMENSION DIFR(N+4),DENN(N+4),RVN(N+4),R(N+4),AUX(N+4),HELM(N),HELMDENS(N),RADIUSH(N),RADIUSHT(N)
      
        NDIN1=N+1

        CALL SGRID(R,DIFR,RMIN,RMAX,0.5D0*DBLE(N),N)
        !CALL HELMCOEF(C0,SIG,Z,ISOT)
                
        DO I=1,N
          X=R(I)
          H11=ERF((X+C0)/DSQRT(2.0D0)/SIG)
          H12=ERF((X-C0)/DSQRT(2.0D0)/SIG)
          H21=EXP(-(X+C0)**2/2.0D0/SIG**2)
          H22=EXP(-(X-C0)**2/2.0D0/SIG**2)
          !To avoid singularity at R=0
          IF (I.EQ.1) THEN 
            IF (Z.EQ.6) THEN
                DENN(I)=0.11359906480994857D0/F2BOHR**3
            ELSE IF (Z.EQ.20.AND.ISOT.EQ.0) THEN
                DENN(I)=0.10117341650599423D0/F2BOHR**3
            ELSE IF (Z.EQ.20.AND.ISOT.EQ.1) THEN
                DENN(I)=0.08230113974342985D0/F2BOHR**3
            ELSE IF (Z.EQ.82) THEN
                DENN(I)=0.06350773888614006D0/F2BOHR**3
            END IF
          ELSE
            DENN(I)=0.5D0*(H11-H12)+SIG/X/DSQRT(2.0D0*PI)*(H21-H22)            
          ENDIF
          RVN(I)=FOURPI*X**2*DIFR(I)*DENN(I)
        ENDDO
        
        CALL SLAG6(1.0D0,RVN,RVN,N)
        FNORM=Z/RVN(N)
        DO I=1,N
            K=NDIN1-I
            AUX(I)=FOURPI*DENN(K)*R(K)*DIFR(K)
        ENDDO
        CALL SLAG6(1.0D0,AUX,AUX,N)
      
        DO I=1,N
            HELM(I)=FNORM*(RVN(I)+AUX(NDIN1-I)*R(I))
            HELMDENS(I)=FNORM*DENN(I)
            RADIUSH(I)=FOURPI*HELMDENS(I)*R(I)**4*DIFR(I)/Z
            RADIUSHT(I)=FOURPI*HELMDENS(I)*R(I)**6*DIFR(I)/Z
        ENDDO
        
        CALL SLAG6(1.0D0,RADIUSH,RADIUSH,N)
        CALL SLAG6(1.0D0,RADIUSHT,RADIUSHT,N) 
        RA=(RADIUSH(N)**0.5D0)/F2BOHR
        RAT=(RADIUSHT(N)**0.25D0)/F2BOHR
        RETURN
      END

      SUBROUTINE FERMI3CALC(FERMI,FERMIDENS,RA,FNORM,Z,ISOT,C,A,W,RMIN,RMAX,N)
C       This subroutine uses 3p Fermi distribution given by:
C           rho(r) = RHO0*(1+w*r^2/)/(1+exp(r-c)/a)
C       with the following input parameters:
C           Z - atomic number
C           ISOT - isotop indicator flag
C           C - half-density radius 
C           A,W - parameters of density 
C           RMIN/RMAX - min/max values of r of the radial grid
C           N - number of grid points
C       to obtain the following output:
C           FERMI(I) = r(i) V(r(i)) - via interpolation
C           FERMIDENS(i) = rho(r(i))
C           RA - charge radius of the distribution
C           FNORM - normalization constant in fm 
C       Oleksandr Koshchii: November 2019
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)
        PARAMETER (ALPHAFS=1.0D0/137.03599976D0) 
        DIMENSION DIFR(N+4),DENN(N+4),RVN(N+4),R(N+4),AUX(N+4),FERMI(N),FERMIDENS(N),RADIUSF(N)
      
        PI=3.1415926535897932D0
        FOURPI=4.0D0*PI
        !W=-0.149D0
        
        NDIN1=N+1

        CALL SGRID(R,DIFR,RMIN,RMAX,0.5D0*DBLE(N),N)

        DO I=1,N
          X=R(I)
          DENN(I)=(1.0D0+W*X*X/C/C)/(1.0D0+EXP((X-C)/A))
          RVN(I)=FOURPI*DENN(I)*X**2*DIFR(I)
        ENDDO
        
        CALL SLAG6(1.0D0,RVN,RVN,N)
        DO I=1,N
            K=NDIN1-I
            AUX(I)=FOURPI*DENN(K)*R(K)*DIFR(K)
        ENDDO
        CALL SLAG6(1.0D0,AUX,AUX,N)
        FNORM=Z/RVN(N)
      
        DO I=1,N
            FERMI(I)=FNORM*(RVN(I)+AUX(NDIN1-I)*R(I))
            FERMIDENS(I)=FNORM*DENN(I)
            RADIUSF(I)=FOURPI*FERMIDENS(I)*R(I)**4*DIFR(I)/Z
        ENDDO
        
        CALL SLAG6(1.0D0,RADIUSF,RADIUSF,N)
        RA=DSQRT(RADIUSF(N))/F2BOHR
        RETURN
      END
      
      DOUBLE PRECISION FUNCTION RADIUS(IZN,ISOTN)
C       Returns the radius of a nucleus in fm     
        IMPLICIT DOUBLE PRECISION (A-H,L-Z)

        IF (IZN.EQ.2) THEN
            RADIUS=1.676D0
        ELSE IF (IZN.EQ.6) THEN
            RADIUS=2.46932D0!2.472D0
        ELSE IF (IZN.EQ.20.AND.ISOTN.EQ.0) THEN
            RADIUS=3.480D0
        ELSE IF (IZN.EQ.20.AND.ISOTN.EQ.1) THEN
            RADIUS=3.460D0
        ELSE IF (IZN.EQ.82) THEN
            RADIUS=5.503D0
        END IF
        RETURN
      END FUNCTION RADIUS

      DOUBLE PRECISION FUNCTION RADIUST(IZN,ISOTN)
C       Returns the radius4 of a nucleus in fm     
        IMPLICIT DOUBLE PRECISION (A-H,L-Z)

        IF (IZN.EQ.2) THEN
            RADIUST=1.676D0
        ELSE IF (IZN.EQ.6) THEN
            RADIUST=2.77098D0!2.472D0
        ELSE IF (IZN.EQ.20.AND.ISOTN.EQ.0) THEN
            RADIUST=3.480D0
        ELSE IF (IZN.EQ.20.AND.ISOTN.EQ.1) THEN
            RADIUST=3.460D0
        ELSE IF (IZN.EQ.82) THEN
            RADIUST=5.503D0
        END IF
        RETURN
      END FUNCTION RADIUST

      INTEGER FUNCTION ATN(IZN,ISOTN)
C       Returns the atomic number of a nucleus
        IMPLICIT DOUBLE PRECISION (B-H,L-Z)

        IF (IZN.EQ.2) THEN
            ATN=4
        ELSE IF (IZN.EQ.6) THEN
            ATN=12
        ELSE IF (IZN.EQ.20.AND.ISOTN.EQ.0) THEN
            ATN=40
        ELSE IF (IZN.EQ.20.AND.ISOTN.EQ.1) THEN
            ATN=48
        ELSE IF (IZN.EQ.82) THEN
            ATN=208
        END IF
        RETURN
      END FUNCTION ATN
      

      DOUBLE PRECISION FUNCTION HEAVISIDETHETA(X)
C       Heaviside function
        IMPLICIT DOUBLE PRECISION (A-H,L-Z)
        HEAVISIDETHETA = 1.0D0
        IF (X.LT.0.0D0) HEAVISIDETHETA = 0.0D0
      END FUNCTION HEAVISIDETHETA      
     
      
      SUBROUTINE GAUSSCOEF(R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12,Q1T,Q2T,Q3T,Q4T,Q5T,Q6T,Q7T,Q8T,Q9T,Q10T,Q11T,Q12T,GAMMA,Z,ISOT)
C       Tis subroutine prepares coeffisients of the 
C       Sum-of-Gaussians parametrization.
C       The input parameters are:
C           Z - target charge in units of e
C           ISOT - isotop indicator flag
C       The output is:
C           R1-R12 - radii of gaussians
C           Q1T-Q12T - charge condributions of gaussians
C           GAMMA - sqrt(2/3)*radius of gaussians in this model
C       Oleksandr Koshchii: November 2019 
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  !Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)

        IF (Z.EQ.2) THEN
            R1=0.2D0*F2BOHR
            R2=0.6D0*F2BOHR
            R3=0.9D0*F2BOHR
            R4=1.4D0*F2BOHR
            R5=1.9D0*F2BOHR
            R6=2.3D0*F2BOHR
            R7=2.6D0*F2BOHR
            R8=3.1D0*F2BOHR
            R9=3.5D0*F2BOHR
            R10=4.2D0*F2BOHR
            R11=4.9D0*F2BOHR
            R12=5.2D0*F2BOHR
      
            Q1T=0.034724D0
            Q2T=0.430761D0
            Q3T=0.203166D0
            Q4T=0.192986D0
            Q5T=0.083866D0
            Q6T=0.033007D0
            Q7T=0.014201D0
            Q8T=0.000000D0
            Q9T=0.006860D0
            Q10T=0.000000D0
            Q11T=0.000438D0
            Q12T=0.000000D0
        
            GAMMA=1.00D0*DSQRT(2.0D0/3.0D0)*F2BOHR
        ELSE IF (Z.EQ.6) THEN
            R1=0.0D0*F2BOHR
            R2=0.4D0*F2BOHR
            R3=1.0D0*F2BOHR
            R4=1.3D0*F2BOHR
            R5=1.7D0*F2BOHR
            R6=2.3D0*F2BOHR
            R7=2.7D0*F2BOHR
            R8=3.5D0*F2BOHR
            R9=4.3D0*F2BOHR
            R10=5.4D0*F2BOHR
            R11=6.7D0*F2BOHR
            R12=1.0D0*F2BOHR!Fictitious value not affecting the calculation because Q12T=0
      
            Q1T=0.016690D0
            Q2T=0.050325D0
            Q3T=0.128621D0
            Q4T=0.180515D0
            Q5T=0.219097D0
            Q6T=0.278416D0
            Q7T=0.058779D0
            Q8T=0.057817D0
            Q9T=0.007739D0
            Q10T=0.002001D0
            Q11T=0.000007D0
            Q12T=0.0D0
        
            GAMMA=1.20D0*DSQRT(2.0D0/3.0D0)*F2BOHR
        ELSE IF (Z.EQ.20.AND.ISOT.EQ.0) THEN
            R1=0.4D0*F2BOHR
            R2=1.2D0*F2BOHR
            R3=1.8D0*F2BOHR
            R4=2.7D0*F2BOHR
            R5=3.2D0*F2BOHR
            R6=3.6D0*F2BOHR
            R7=4.3D0*F2BOHR
            R8=4.6D0*F2BOHR
            R9=5.4D0*F2BOHR
            R10=6.3D0*F2BOHR
            R11=6.6D0*F2BOHR
            R12=8.1D0*F2BOHR
      
            Q1T=0.042870D0
            Q2T=0.056020D0
            Q3T=0.167853D0
            Q4T=0.317962D0
            Q5T=0.155450D0
            Q6T=0.161897D0
            Q7T=0.053763D0
            Q8T=0.032612D0
            Q9T=0.004803D0
            Q10T=0.004541D0
            Q11T=0.000015D0
            Q12T=0.002218D0
        
            GAMMA=1.45D0*DSQRT(2.0D0/3.0D0)*F2BOHR
        ELSE IF (Z.EQ.20.AND.ISOT.EQ.1) THEN
            R1=0.6D0*F2BOHR
            R2=1.1D0*F2BOHR
            R3=1.7D0*F2BOHR
            R4=2.1D0*F2BOHR
            R5=2.9D0*F2BOHR
            R6=3.4D0*F2BOHR
            R7=4.3D0*F2BOHR
            R8=5.2D0*F2BOHR
            R9=5.7D0*F2BOHR
            R10=6.2D0*F2BOHR
            R11=6.5D0*F2BOHR
            R12=7.4D0*F2BOHR
      
            Q1T=0.063035D0
            Q2T=0.011672D0
            Q3T=0.064201D0
            Q4T=0.203813D0
            Q5T=0.259070D0
            Q6T=0.307899D0
            Q7T=0.080585D0
            Q8T=0.008498D0
            Q9T=0.000025D0
            Q10T=0.000005D0
            Q11T=0.000004D0
            Q12T=0.001210D0
        
            GAMMA=1.45D0*DSQRT(2.0D0/3.0D0)*F2BOHR
        ELSE IF (Z.EQ.82) THEN
            R1=0.1D0*F2BOHR
            R2=0.7D0*F2BOHR
            R3=1.6D0*F2BOHR
            R4=2.1D0*F2BOHR
            R5=2.7D0*F2BOHR
            R6=3.5D0*F2BOHR
            R7=4.2D0*F2BOHR
            R8=5.1D0*F2BOHR
            R9=6.0D0*F2BOHR
            R10=6.6D0*F2BOHR
            R11=7.6D0*F2BOHR
            R12=8.7D0*F2BOHR
      
            Q1T=0.003845D0
            Q2T=0.009724D0
            Q3T=0.033093D0
            Q4T=0.000120D0
            Q5T=0.083107D0
            Q6T=0.080869D0
            Q7T=0.139957D0
            Q8T=0.260892D0
            Q9T=0.336013D0
            Q10T=0.033637D0
            Q11T=0.018729D0
            Q12T=0.000020D0
        
            GAMMA=1.70D0*DSQRT(2.0D0/3.0D0)*F2BOHR
        END IF      
      END SUBROUTINE
      
      
      SUBROUTINE BESSELCOEF(A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,A12,A13,A14,A15,A16,A17,C1,Z,ISOT)
C       Tis subroutine prepares coeffisients of the 
C       Fourier-Bessel parametrization
C       The input parameters are:
C           Z - target charge in units of e
C           ISOT - isotop indicator flag
C       The output is:
C           A1-A17 - coefficients
C           C1 - effective radius of this model
C       Oleksandr Koshchii: November 2019 
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)
        
        IF (Z.EQ.2.AND.ISOT.EQ.0) THEN
            WRITE (*,*), 'NO BESSEL PARAMETRIZATION FOR HE-4'
        ELSE IF (Z.EQ.6) THEN
            A1=0.15721D-1/F2BOHR**3
            A2=0.38732D-1/F2BOHR**3
            A3=0.36808D-1/F2BOHR**3
            A4=0.14671D-1/F2BOHR**3
            A5=-0.43277D-2/F2BOHR**3

            A6=-0.97752D-2/F2BOHR**3
            A7=-0.68908D-2/F2BOHR**3
            A8=-0.27631D-2/F2BOHR**3
            A9=-0.63568D-3/F2BOHR**3
            A10=0.71809D-4/F2BOHR**3
      
            A11=0.18441D-3/F2BOHR**3
            A12=0.75066D-4/F2BOHR**3
            A13=0.51069D-4/F2BOHR**3
            A14=0.14308D-4/F2BOHR**3
            A15=0.23170D-5/F2BOHR**3
      
            A16=0.68465D-6/F2BOHR**3
            A17=0.0D0
        
            C1=7.999826363946149D0*F2BOHR 
        ELSE IF (Z.EQ.20.AND.ISOT.EQ.0) THEN
            A1=0.44846D-1/F2BOHR**3
            A2=0.61326D-1/F2BOHR**3
            A3=-0.68118D-2/F2BOHR**3
            A4=-0.26217D-1/F2BOHR**3
            A5=-0.29725D-2/F2BOHR**3
      
            A6=0.85534D-2/F2BOHR**3
            A7=0.35322D-2/F2BOHR**3
            A8=-0.48258D-3/F2BOHR**3
            A9=-0.39346D-3/F2BOHR**3
            A10=0.20338D-3/F2BOHR**3
      
            A11=0.25461D-4/F2BOHR**3
            A12=-0.17794D-4/F2BOHR**3
            A13=0.67394D-5/F2BOHR**3
            A14=-0.21033D-5/F2BOHR**3
            A15=0.0D0
      
            A16=0.0D0
            A17=0.0D0
      
            C1=7.999721447699864D0*F2BOHR
        ELSE IF (Z.EQ.20.AND.ISOT.EQ.1) THEN
            A1=0.44782D-1/F2BOHR**3
            A2=0.59523D-1/F2BOHR**3
            A3=-0.74148D-2/F2BOHR**3
            A4=-0.29466D-1/F2BOHR**3
            A5=-0.28350D-3/F2BOHR**3
      
            A6=0.10829D-1/F2BOHR**3
            A7=0.30465D-2/F2BOHR**3
            A8=-0.10237D-2/F2BOHR**3
            A9=-0.17830D-3/F2BOHR**3
            A10=0.55391D-4/F2BOHR**3
      
            A11=-0.22644D-4/F2BOHR**3
            A12=0.82671D-5/F2BOHR**3
            A13=-0.27343D-5/F2BOHR**3
            A14=0.82461D-6/F2BOHR**3
            A15=-0.22780D-6
      
            A16=0.0D0
            A17=0.0D0
      
            C1=7.999791863283003D0*F2BOHR         
        ELSE IF (Z.EQ.82) THEN
            A1=0.51936D-1/F2BOHR**3
            A2=0.50768D-1/F2BOHR**3
            A3=-0.39646D-1/F2BOHR**3
            A4=-0.28218D-1/F2BOHR**3
            A5=0.28916D-1/F2BOHR**3
      
            A6=0.98910D-2/F2BOHR**3
            A7=-0.14388D-1/F2BOHR**3
            A8=-0.98262D-3/F2BOHR**3
            A9=0.72578D-2/F2BOHR**3
            A10=0.82318D-3/F2BOHR**3
      
            A11=-0.14823D-2/F2BOHR**3
            A12=0.13245D-3/F2BOHR**3
            A13=-0.84345D-4/F2BOHR**3
            A14=0.48417D-4/F2BOHR**3
            A15=-0.26562D-4/F2BOHR**3
      
            A16=0.14035D-4/F2BOHR**3
            A17=-0.71863D-5/F2BOHR**3
      
            C1=11.999642678038196D0*F2BOHR 
        END IF
      END SUBROUTINE
      

      SUBROUTINE HELMCOEF(C0,SIG,Z,ISOT)
C       This subroutine generates two parameters of 
C       the Helm distribution that enable
C       the HELM model to reproduce known (from SG model)
C       values for Rch and Rcht.
C       The input parameters are:
C           Z - target charge in units of e
C           ISOT - isotop indicator flag
C       The output is:
C           C0 - box (difraction) radius
C           SIG - surface thickness
C       Oleksandr Koshchii: November 2019      
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)

        IF (Z.EQ.2.AND.ISOT.EQ.0) THEN
            C0=0.0D0
            SIG=0.0D0
            WRITE (*,*), 'NO HELM PARAM FOR HE-4'
        ELSE IF (Z.EQ.6) THEN
            C0=2.047106695359103D0*F2BOHR
            SIG=1.0928823794289586D0*F2BOHR
        ELSE IF(Z.EQ.20.AND.ISOT.EQ.0) THEN
            C0=3.5704896684720953D0*F2BOHR
            SIG=1.2191993570610216D0*F2BOHR            
        ELSE IF(Z.EQ.20.AND.ISOT.EQ.1) THEN
            C0=3.868862211977008D0*F2BOHR
            SIG=0.9985833201755923D0*F2BOHR            
        ELSE IF(Z.EQ.82) THEN
            C0=6.755116823521079D0*F2BOHR
            SIG=0.9841547622003082D0*F2BOHR
        END IF    
      END SUBROUTINE
      
      SUBROUTINE FERMI2PCOEF(C1,A1,Z,ISOT)
C       This subroutine generates two parameters of 
C       2p Symmetrized Fermi distribution that enable
C       the SF model to reproduce known (from SG model)
C       values for Rch and Rcht.
C       The input parameters are:
C           Z - target charge in units of e
C           ISOT - isotop indicator flag
C       The output is:
C           C1 - half-density radius in Bohr
C           A1 - surface diffusiness in Bohr
C       Oleksandr Koshchii: November 2019      
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)

        IF (Z.EQ.2.AND.ISOT.EQ.0) THEN
            C1=1.2969498987673975D0*F2BOHR
            A1=0.3610377503473792D0*F2BOHR     
        ELSE IF (Z.EQ.6) THEN
            C1=2.3425250733227583D0*F2BOHR
            A1=0.4505686556360125D0*F2BOHR
        ELSE IF (Z.EQ.20.AND.ISOT.EQ.0) THEN
            C1=6.665804360673521D0*F2BOHR
            A1=0.5121918139268511*F2BOHR
        ELSE IF (Z.EQ.20.AND.ISOT.EQ.1) THEN
            C1=3.8276759181704283D0*F2BOHR
            A1=0.47986137659392325D0*F2BOHR
        ELSE IF (Z.EQ.82) THEN
            C1=6.665804360673521D0*F2BOHR
            A1=0.5121918139268511*F2BOHR
        END IF
      END SUBROUTINE

      SUBROUTINE FERMI2PCOEFNUCL(CCH1,ACH1,CWK1,AWK1,Z,ISOT,MODFLAG)
C       This subroutine generates two parameters of 
C       2p SFermi distribution for the weak density 
C       and two parameters of 2p SFermi distribution 
C       for the charge density that the nuclear model
C       described by variable modflag predicts
C       The input parameters are:
C           Z - target charge in units of e
C           ISOT - isotop indicator flag
C           MODEFLAG - model flag
C       The output is:
C           CCH1 - half-density radius of EM charge distribution (in Bohr)
C           ACH1 - surface diffusiness of EM charge distribution (in Bohr)
C           CWK1 - half-density radius of EM charge distribution (in Bohr)
C           AWK1 - surface diffusiness of EM charge distribution (in Bohr)
C       Oleksandr Koshchii: February 2020      
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)

        IF (Z.EQ.6) THEN
            IF (MODFLAG.EQ.1) THEN
                CCH1=2.04179D0*F2BOHR
                ACH1=0.50642D0*F2BOHR            
                CWK1=2.06065D0*F2BOHR
                AWK1=0.49389D0*F2BOHR
            ELSE IF (MODFLAG.EQ.2) THEN
                CCH1=2.04938D0*F2BOHR
                ACH1=0.50686D0*F2BOHR
                CWK1=2.06849D0*F2BOHR
                AWK1=0.49445D0*F2BOHR
            ELSE IF (MODFLAG.EQ.3) THEN
                CCH1=2.05553D0*F2BOHR
                ACH1=0.50771D0*F2BOHR            
                CWK1=2.07585D0*F2BOHR
                AWK1=0.49544D0*F2BOHR
            ELSE IF (MODFLAG.EQ.4) THEN
                CCH1=2.04410D0*F2BOHR
                ACH1=0.50594D0*F2BOHR
                CWK1=2.06421D0*F2BOHR
                AWK1=0.49433D0*F2BOHR
            ELSE IF (MODFLAG.EQ.5) THEN
                CCH1=2.23169D0*F2BOHR
                ACH1=0.47946D0*F2BOHR
                CWK1=2.22693D0*F2BOHR
                AWK1=0.47318D0*F2BOHR
            ELSE IF (MODFLAG.EQ.6) THEN
                CCH1=2.13674D0*F2BOHR
                ACH1=0.49359D0*F2BOHR
                CWK1=2.14379D0*F2BOHR
                AWK1=0.48431D0*F2BOHR                
            END IF        
        END IF
      END SUBROUTINE
      
      SUBROUTINE RHOPRIMESF(DENSPR,Z,C,A,RMIN,RMAX,N)
C       This subroutine is for generating the weak skin using 
C       2p symmetrized Fermi distribution.
C       The input parameters are:
C           Z - target charge in units of e
C           C - half-density radius
C           A - surface diffusiness 
C           RMIN/RMAX - min/max values of r of the radial grid
C           N - number of grid points
C       The output is:
C           DENSPR(I) - 2p SF density rhoprimesf 
C       Oleksandr Koshchii: June 2019      
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)
        PARAMETER (PI=3.1415926535897932D0)
        DIMENSION DIFR(N+4),R(N+4),DENSPR(N)

        RHO0=3.0D0*Z/(4.0D0*PI*C*(C**2+(PI*A)**2))
        CALL SGRID(R,DIFR,RMIN,RMAX,0.5D0*DBLE(N),N)
        
        DO I=1,N
          X=R(I)
          IF (C.EQ.0D0) THEN
            DENSPR(I)=3.0D0*Z/(8.0D0*(PI*A)**3*COSH(X/(2.0D0*A))**2)
          ELSE
            DENSPR(I)=RHO0*SINH(C/A)/(COSH(X/A)+COSH(C/A))
          ENDIF
        ENDDO
        RETURN
      END

      SUBROUTINE RHOPRIMEHELM(DENSPR,Z,ISOT,C0,SIG,RMIN,RMAX,N)
C       This subroutine is for generating the weak skin using 
C       2p Helm distribution.
C       The input parameters are:
C           Z - target charge in units of e
C           C0 - half-density radius
C           SIG - surface diffusiness 
C           RMIN/RMAX - min/max values of r of the radial grid
C           N - number of grid points
C       The output is:
C           DENSPR(I) - 2p Helm density 
C       Oleksandr Koshchii: November 2019      
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)
        PARAMETER (PI=3.1415926535897932D0)
        DIMENSION DIFR(N+4),R(N+4),DENSPR(N)

        CALL SGRID(R,DIFR,RMIN,RMAX,0.5D0*DBLE(N),N)

        IF (C0.EQ.0.0D0) THEN
            DO I=1,N
                X=R(I)
                DENSPR(I)=Z*EXP(-X**2/(2.0D0*SIG**2))/(2.0D0*SQRT(2.0D0)*PI**(3.0D0/2.0D0)*SIG**3)
            ENDDO
        ELSE
            RHO0=3.0D0*Z/(4.0D0*PI*C0**3)
            DO I=1,N
                X=R(I)
                H11=ERF((X+C0)/SQRT(2.0D0)/SIG)
                H12=ERF((X-C0)/SQRT(2.0D0)/SIG)
                H21=EXP(-(X+C0)**2/2.0D0/SIG**2)
                H22=EXP(-(X-C0)**2/2.0D0/SIG**2)
                !To avoid singularity at r=0
                IF (I.EQ.1) THEN 
                    IF (Z.EQ.6) THEN
                        DENSPR(I)=0.11359906480994857D0/F2BOHR**3
                    ELSE IF (Z.EQ.20.AND.ISOT.EQ.0) THEN
                        DENSPR(I)=0.10117341650599423D0/F2BOHR**3
                    ELSE IF (Z.EQ.20.AND.ISOT.EQ.1) THEN
                        DENSPR(I)=0.08230113974342985D0/F2BOHR**3
                    ELSE IF (Z.EQ.82) THEN
                        DENSPR(I)=0.06350773888614006D0/F2BOHR**3
                    END IF
                ELSE
                    DENSPR(I)=0.5D0*RHO0*(H11-H12)+1.0D0/SQRT(2.0D0*PI)*SIG/X*RHO0*(H21-H22)
                ENDIF
            ENDDO
        ENDIF
        RETURN
      END

      SUBROUTINE WEAKCHARGE(QWEAK,Z,ISOT)
C       This subroutine is for generating the tree level value for the weak charge 
C       The input parameters are:
C           Z - target charge in units of e
C           ISOT - half-density radius
C           AW - surface diffusiness 
C       The output is:
C           QWEAK - weak charge of the nucleus
C       Oleksandr Koshchii: June 2019      
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (SIN2THETA=0.23868D0)

        IF (Z.EQ.82) THEN
            W=DBLE(208)
        ELSE IF (Z.EQ.20.AND.ISOT.EQ.0) THEN
            W=DBLE(40)
        ELSE IF (Z.EQ.20.AND.ISOT.EQ.1) THEN
            W=DBLE(48)
        ELSE IF (Z.EQ.6) THEN
            W=DBLE(12)
        ELSE
            W=0.0D0
            Z=0
        END IF
        
        QWEAK=Z*(1.0D0-4*SIN2THETA)-(W-Z)
        
        RETURN
      END

      
      SUBROUTINE CSKINMOM4(WKSKF,N,RCHT,WKSK,RC2,Z,ISOT,RCH,IWEAK)
C       This subroutine for 2p symmetrized Fermi distribution
C       uses the following input parameters:
C           WKSK - weak skin (as a fraction of Rch)
C           RC2 - radius (C2) of SF density in units of C1 of another SF density
C           Z - atomic number
C           ISOT - isotop indicator
C           RCH - charge radius that sum of gaussians produces
C           IWEAK - weak density model flag 
C       to obtain the following output:
C           WKSKF - second moment weak skin (as a fraction of Rcht)
C           N - normalisation constant that weak density should have for given values of DRW and C2
C           RCHT - Root mean fourth radius fourth of the gaussian parametrization
C       Oleksandr Koshchii: November 2019
        IMPLICIT DOUBLE PRECISION (A-H,L-Z)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)
        PARAMETER (ALPHAFS=1.0D0/137.03599976D0) 
        PI=3.1415926535897932D0        

        IF (Z.EQ.82) THEN
          RCHT=5.850579238405826D0*F2BOHR !Root mean fourth radius fourth of the gaussian parametrization
        ELSE IF (Z.EQ.20.AND.ISOT.EQ.0) THEN
          RCHT=3.83584820330176D0*F2BOHR !Root mean fourth radius fourth of the gaussian parametrization
        ELSE IF (Z.EQ.20.AND.ISOT.EQ.1) THEN
          RCHT=3.762896217781865D0*F2BOHR
        ELSE
          RCHT=2.7709779888103627D0*F2BOHR !Root mean fourth radius fourth of the gaussian parametrization for C12
        END IF
        
        IF (IWEAK.EQ.1) THEN
            WKSKF=0.0D0
            GO TO 1
        ELSE IF (IWEAK.EQ.2) THEN
            CALL FERMI2PCOEF(C1,A1,Z,ISOT) !2pSF
        ELSE
            CALL HELMCOEF(C1,A1,Z,ISOT) !HELM
        ENDIF

        DRW = WKSK*RCH!DRW = -0.01D0*RCH !weak skin is fixed to be 1% of Rch 
        C2 = RC2*C1

        N=(5.0D0*DRW*(DRW+2.0D0*RCH))/(3.0D0*(C2**2-C1**2)) ! the same expression for SF and Helm
        IF (IWEAK.EQ.2) THEN
            DRWT=-RCHT+((5.0D0*DRW*(DRW+2.0D0*RCH)*(C1**2+C2**2+6.0D0*(PI*A1)**2)+7.0D0*RCHT**4)/7.0D0)**(0.25D0)     
        ELSE
            DRWT=-RCHT+((5.0D0*DRW*(DRW+2.0D0*RCH)*(C1**2+C2**2+14.0D0*A1**2)+7.0D0*RCHT**4)/7.0D0)**(0.25D0)     
        ENDIF

        WKSKF=DRWT/RCHT
    1   CONTINUE        
      END SUBROUTINE CSKINMOM4
      

      SUBROUTINE GRIDCOEF(RMIN,RMAX)
C       This subroutine generates min and max range points
C       that will be consistenly used by the subroutine SGRID 
C       subroutines EFIELD and ELSEPA.
C       The output is:
C           RMAX - the last grid point for numerical integr
C           RMIN - the 1st grid point for numerical integr
C       Oleksandr Koshchii: November 2019      
        IMPLICIT DOUBLE PRECISION (A-H,O-Z), INTEGER*4 (I-N)
        PARAMETER (A0B=5.2917721067D-9)  ! Bohr radius (cm)
        PARAMETER (F2BOHR=1.0D-13/A0B)
        
*************C12 input************
        R=2.355D0*F2BOHR
        RMIN=R/2500.0D0
        RMAX=20.0D0*F2BOHR
**********************************        
        RETURN
      END
