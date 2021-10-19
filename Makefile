SRCDIR = src
OUTDIR = out
BINDIR = $(OUTDIR)/bin
DATADIR = $(OUTDIR)/data
OBJDIR = $(OUTDIR)/obj

AHI2CHR = $(BINDIR)/ahi2chr
LABEL2NL = $(BINDIR)/label2nl

CFGFILE = $(SRCDIR)/linker.cfg
LABELFILE = $(OUTDIR)/nesfxr.labels.txt
ROMFILE = $(OUTDIR)/nesfxr.nes

AHIFILES := $(shell find $(SRCDIR) -name '*.ahi')
ASMFILES := $(shell find $(SRCDIR) -name '*.asm')
INCFILES := $(shell find $(SRCDIR) -name '*.inc')

CHRFILES := $(patsubst $(SRCDIR)/%.ahi,$(DATADIR)/%.chr,$(AHIFILES))
OBJFILES := $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(ASMFILES))

#=============================================================================#

.PHONY: rom
rom: $(ROMFILE)

.PHONY: run
run: $(ROMFILE) $(ROMFILE).ram.nl $(ROMFILE).0.nl $(ROMFILE).1.nl
	fceux --style=macintosh $<

.PHONY: clean
clean:
	rm -rf $(OUTDIR)

#=============================================================================#

define compile-c99
	@echo "Compiling $<"
	@mkdir -p $(@D)
	@cc -Wall -Werror -o $@ $<
endef

$(AHI2CHR): build/ahi2chr.c
	$(compile-c99)

$(DATADIR)/%.chr: $(SRCDIR)/%.ahi $(AHI2CHR)
	@echo "Converting $<"
	@mkdir -p $(@D)
	@$(AHI2CHR) < $< > $@

$(LABEL2NL): build/label2nl.c
	$(compile-c99)

$(ROMFILE).ram.nl: $(LABELFILE) $(LABEL2NL)
	@echo "Generating $@"
	@mkdir -p $(@D)
	@$(LABEL2NL) 0000 07ff < $< > $@

$(ROMFILE).0.nl: $(LABELFILE) $(LABEL2NL)
	@echo "Generating $@"
	@mkdir -p $(@D)
	@$(LABEL2NL) 8000 bfff < $< > $@

$(ROMFILE).1.nl: $(LABELFILE) $(LABEL2NL)
	@echo "Generating $@"
	@mkdir -p $(@D)
	@$(LABEL2NL) c000 ffff < $< > $@

#=============================================================================#

$(ROMFILE) $(LABELFILE): $(CFGFILE) $(OBJFILES)
	@echo "Linking $@"
	@mkdir -p $(@D)
	@ld65 -Ln $(LABELFILE) -o $@ -C $(CFGFILE) $(OBJFILES)
$(LABELFILE): $(ROMFILE)

define compile-asm
	@echo "Compiling $<"
	@mkdir -p $(@D)
	@ca65 --target nes -W1 --debug-info -o $@ $<
endef

$(OBJDIR)/chr.o: $(SRCDIR)/chr.asm $(INCFILES) $(CHRFILES)
	$(compile-asm)

$(OBJDIR)/%.o: $(SRCDIR)/%.asm $(INCFILES)
	$(compile-asm)

#=============================================================================#
