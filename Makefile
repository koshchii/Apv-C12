PROG     = apv
EXE      = $(PROG).exe
SOURCE   = $(PROG).f

COMPILER = gfortran

F77OPT  =-fno-align-commons -fno-automatic -ffixed-line-length-none -std=legacy

all:
	$(COMPILER) $(F77OPT) $(SOURCE) -o $(EXE)