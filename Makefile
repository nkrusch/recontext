SHELL := /bin/bash

# supress Make output
MAKEFLAGS += --no-print-directory

ifndef $PYTHON
PYTHON := python3
endif

ifndef $OUT  
OUT := results
endif

ifndef $TMP
TMP := .tmp
endif

ifndef $TO # seconds
TO := 600
endif

ifndef $DOPT # DIG options
DOPT :=
endif


MATH_F := xy xxy xxxy 2x₊y 2xy 3xy 2x3y axby axbycz \
		  m2x0 m8x0 m2xa mbxa mbxya logxy sinxy

LINEAR := 001 003 007 009 015 023 024 025 028 035 038 \
		  040 050 063 065 067 071 077 083 087 091 093 \
		  094 095 097 099 101 107 108 109 110 114 120 \
		  124 128 130 132 133

UTILS   := src
IN_CSV	:= input/csv
IN_TRC	:= input/traces
ARGS_F  := config.txt
LOG 	:= $(OUT)/_log.txt
MACHINE := $(OUT)/_host.txt
STATS   := $(OUT)/_inputs.txt
SCORE   := $(OUT)/_results.txt
RUNNER  := bash $(UTILS)/runner.sh $(TO) "$(LOG)"
TIMER   := bash $(UTILS)/timer.sh
SIZES   := 5 25

# problems
INPUTS  := $(wildcard $(IN_TRC)/*.csv)
M_PROBS := $(wildcard $(IN_TRC)/f_*.csv)
L_PROBS := $(wildcard $(IN_TRC)/l_*.csv)
D_PROBS := $(wildcard $(IN_TRC)/ds_*.csv)

DIG_ALL := ${INPUTS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
DIG_MTH := ${M_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
DIG_LIN := ${L_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
DIG_DSS := ${D_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.dig}
DIG_UPS := ${D_PROBS:$(IN_TRC)/%.csv=$(OUT)/%.digup}

#SZ_CSV  := $(foreach N,$(SIZES),$(patsubst $(IN_TRC)/%.csv,$(OUT)/%.$(N).tacle,$(INPUTS)))
#SZ_TRC  := $(foreach N,$(SIZES),$(patsubst $(IN_TRC)/%.csv,$(TMP)/%.$(N).trc,$(INPUTS)))

CHECKS  := $(patsubst %.dig,%.check,$(wildcard $(OUT)/*.dig))
CSV_IN  := ${INPUTS:$(IN_TRC)/%.csv=$(IN_CSV)/%.csv}
GEN_F   := ${MATH_F:%=gen/f_%}
GEN_L   := ${LINEAR:%=gen/l_%}

# main recipes
all:   stats host dig digup score
stats: $(STATS)
host:  $(MACHINE)
dig:   $(DIG_ALL)
digup: $(DIG_UPS)
score: $(SCORE)

# debugging + generators
check:   $(CHECKS)
math:    $(DIG_MTH) score
linear:  $(DIG_LIN) score
sets:    $(DIG_DSS) digup score
trc_f:   $(GEN_F)
trc_l:   $(GEN_L)

$(IN_CSV)/%.csv: $(IN_TRC)/%.csv $(IN_CSV)
	@$(PYTHON) -m $(UTILS) -a csv $< > $@

$(OUT)/%.dig: $(IN_TRC)/%.csv $(OUT)
	$(eval ARGS := $(shell grep $(basename $(notdir $@)) $(ARGS_F) | head -n 1 | cut -d' ' -f 2-))
	$(RUNNER) "$(PYTHON) -O dig/src/dig.py $< -log 0 -noss -nomp -noarrays $(DOPT)$(ARGS) > $@"

$(OUT)/%.digup: $(IN_TRC)/%.csv $(OUT)
	$(eval proc_to=$(shell echo $$(($(TO)-1))))
	export TO=$(proc_to) && $(RUNNER) "$(PYTHON) src/digup.py $< -log 0 -noss -nomp -noarrays $(DOPT) > $@"
	@$(PYTHON) src/digup.py $@

$(OUT)/%.tacle: $(IN_CSV)/%.csv $(OUT)
	$(RUNNER) "cd tacle && $(PYTHON) -m tacle ../$< -g > ../$@"

$(TMP)/%.csv: $(IN_CSV)/%.csv $(TMP)
	@$(foreach N,$(SIZES),\
		head -n $$(($(N)+1)) $< > $(subst .csv,.$(N).csv,$@) && \
		head -n $$(($(N)+1)) $(subst $(IN_CSV),$(IN_TRC),$<) > $(subst .csv,.$(N).trc,$@) ;)

$(OUT)/%.time: $(TMP)/%.csv $(TMP) $(OUT)
	$(eval f := $(subst .csv,,$(subst $(TMP)/,,$<)))
	$(foreach N,$(SIZES), \
	  $(TIMER) "Tacle" $(N) "(cd tacle && $(PYTHON) -m tacle ../$(TMP)/$(f).$(N).csv -g) 1> $(OUT)/$(f).$(N).tacle" >> $@ ; \
	  $(TIMER) "Dig"   $(N) "$(PYTHON) -O dig/src/dig.py $(TMP)/$(f).$(N).trc -log 0 -noss -nomp -noarrays $(DOPT) 1>/dev/null" >> $@ ; )

$(OUT)/%.check:
	$(PYTHON) -m $(UTILS) -a check $(subst .check,.dig,$@) > $@

gen/%:
	$(eval fname := $(subst gen/,,$@))
	$(PYTHON) -m $(UTILS) -a gen $(fname) > $(IN_TRC)/$(fname).csv

$(MACHINE): $(OUT)
	@bash $(UTILS)/machine.sh > $@

$(STATS): $(OUT)
	@$(PYTHON) -m $(UTILS) -a stats $(IN_TRC) > $@

$(SCORE): $(OUT)
	$(PYTHON) -m $(UTILS) -a score $(OUT) > $@

$(OUT) $(IN_CSV) $(TMP):
	@mkdir -p $@

clean_tmp:
	@rm -rf $(OUT)/*.check $(LOG) $(TMP)

clean: clean_tmp
	@rm -rf $(OUT)

.PHONY: $(SCORE) $(STATS) $(MACHINE)