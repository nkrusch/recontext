SHELL := /bin/bash

# supress Make output
MAKEFLAGS += --no-print-directory

ifndef $IN  
IN := ./input
endif

ifndef $OUT  
OUT := ./results
endif

ifndef $TO # seconds
TO := 60
endif

ifndef $DOPT # DIG options
DOPT := -nocongruences
endif

ifndef $LOG
LOG := $(OUT)/_log.txt
endif

MATH_F := xy xxy xxxy 2xy 3xy 2x3y axby axbycz xymodba logxy factxy
LINEAR := 001 003 007 009 015 023 024 025 028 035 038 040 045 050 063 \
		  065 067 071 077 083 084 085 087 091 093 094 095 097 099 101 \
		  103 107 108 109 110 114 118 120 124 128 130 132 133

UTILS   := src
VENV	:= .venv
IN_CSV	:= $(IN)/csv
IN_TRC	:= $(IN)/traces

INPUTS  := $(wildcard $(IN_TRC)/*.csv)
DIG_EXP := ${INPUTS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
TCL_EXP := ${INPUTS:$(IN_TRC)/%.csv=$(OUT)/%.tacle}

M_PROBS := $(wildcard $(IN_TRC)/f_*.csv)
L_PROBS := $(wildcard $(IN_TRC)/f_*.csv)
D_PROBS := $(wildcard $(IN_TRC)/ds_*.csv)
DIG_MTH := ${M_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
DIG_LIN := ${L_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
DIG_DSS := ${D_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.dig}

CSV_IN  := ${INPUTS:$(IN_TRC)/%.csv=$(IN_CSV)/%.csv}
GEN_F   := ${MATH_F:%=gen/f_%}
GEN_L   := ${LINEAR:%=gen/l_%}
CHECKS  := $(patsubst %.dig,%.check,$(wildcard $(OUT)/*.dig))
RUNNER  := bash $(UTILS)/runner.sh $(TO) "$(LOG)"
MACHINE := $(OUT)/_host.txt
IN_STAT := $(OUT)/_inputs.txt
OU_STAT := $(OUT)/_results.txt

all:   csv dig tacle ist
dig:   $(DIG_EXP) $(MACHINE)
tacle: $(TCL_EXP) $(MACHINE)
csv:   $(CSV_IN)
trcf:  $(GEN_F)
trcl:  $(GEN_L)
trc:   trcf trcl
ist:   $(IN_STAT) $(OU_STAT)

dig_f: $(DIG_MTH)
check: $(CHECKS)

$(IN_CSV)/%.csv: $(IN_TRC)/%.csv ensure_csv
	python3 -m $(UTILS) -a csv $< > $@

$(OUT)/%.dig: $(IN_TRC)/%.csv ensure_out
	$(RUNNER) "python3 -O dig/src/dig.py -log 0 $< -noss -nomp -noarrays $(DOPT) > $@"

$(OUT)/%.tacle: $(IN_CSV)/%.csv ensure_out
	$(RUNNER) "cd tacle && python3 -m tacle ../$< -g > ../$@"

$(OUT)/%.check:
	python3 -m $(UTILS) -a check $(subst .check,.dig,$@) > $@

gen/%:
	$(eval fname := $(subst gen/,,$@))
	python3 -m $(UTILS) -a gen $(fname) > $(IN_TRC)/$(fname).csv

$(VENV):
	@test -d .venv || python3 -m venv .venv;
	@source .venv/bin/activate;
	@pip3 install -q -r requirements.txt

$(MACHINE):
	@bash $(UTILS)/machine.sh > $@

$(IN_STAT):
	python3 -m $(UTILS) -a stats $(IN_TRC) > $@

$(OU_STAT):
	python3 -m $(UTILS) -a stats $(OUT) > $@

ensure_out:
	@mkdir -p $(OUT)

ensure_csv:
	@mkdir -p $(IN_CSV)

clean_check:
	@rm -rf $(OUT)/*.check

clean:
	@rm -rf $(OUT)
