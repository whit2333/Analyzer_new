#----------------------------------------------------------------------------*
# Copyright (c) 1991, 1992  Southeastern Universities Research Association,  * 
#			    Continuous Electron Beam Accelerator Facility    *
#									     *
#   This software was developed under a United States Government license     *
#    described in the NOTICE file included as part of this distribution.     *
#									     *
#CEBAF Data Acquisition Group, 12000 Jefferson Ave., Newport News, VA 23606  *
#     heyescebaf.gov	Tel: (804) 249-7030    Fax: (804) 249-7363	     *
#----------------------------------------------------------------------------*
#Description: follows this header.
#
#Author:
#	Graham Heyes
#	CEBAF Data Acquisition Group
#
#  Revision History:
#    $Log: Makefile,v $
#    Revision 1.5.24.1  2007/09/10 20:08:03  pcarter
#    Implemented changes to allow compilation on RHEL 3,4,5 and MacOSX
#
#    Revision 1.5  2002/12/20 21:58:57  jones
#    reduce output echoing
#
#    Revision 1.4  1999/11/04 20:37:27  saw
#    Linux/G77 compatibility fixes
#
#    Revision 1.3  1998/12/07 22:09:50  saw
#    Remove dependency on $Csoft
#
#    Revision 1.1  1996/02/02 14:14:46  saw
#    Initial revision
#
#    
#    93/12/14 saw Copied from $(Csoft)/etc
#
#----------------------------------------------------------------------------
# Generic Makefile add more directories here

.DELETE_ON_ERROR: ;
AR = ar
PW := $(shell pwd)
MAKEREG=$(PW)/../../../$(MYOS)$(OSEXT)/bin/makereg

include $(sources:.f=.d) 
include $(sources:.c=.d) 

#EVGENLIB   = ../../../$(MYOS)$(OSEXT)/lib/libevgen.a
LIBROOT   = ../../../$(MYOS)$(OSEXT)/lib
#INCROOT   = $(Csoft)/$(MYOS)/include
#OS     := $(shell echo $(MYOS) | tr "[A-Z]" "[a-z]")

#MAKEDIRS:=$(addprefix $(shell pwd)/,$(shell find . -type d -print | sed -e '/RCS/d'|xargs echo))


#TIMESTAMP := "\"$(shell date +%h\ %d\ %Y)\""
#CSOFT_VERSION := "\"$(shell grep define $(Csoft)/.version.h | sed -e 's|.*CSOFTVERSION ||')\""
#CSOFT_VERSION := "Version 0"

# OS dependent declarations of library and include directories etc...

.PRECIOUS: %.d
#.PRECIOUS: %.cmn ../%.cmn %.par ../%.par %.dte ../%.dte %.dec ../%.dec

.PHONY : default depend CLEAN clean ALL_CLEAN all_clean directory csoft ALL_CSOFT all_csoft

ifdef NFSDIRECTORY
DEPENDS_RULE.c =  $(CC) -MM $(CFLAGS) $< |\
	(sed -e 's|$*.o|& $@|g' -e 's|:|: .os$(MYOS) Makefile |' ;\
	cat $< | sed -n -e \ "s|\#include \"|$@: ../|p" |\
	sed -e "s|\".*$$||" | sed -e 's|.d:|.o:|') >$@
else
DEPENDS_RULE.c =  $(CC) -MM $(CFLAGS) $< |\
	 sed -e 's|$*.o|& $@|g' -e 's|:|: .os$(MYOS) Makefile |' > $@
endif
DEPENDS_RULE.f = 	( cat $< | sed -n -e \
	"s|^[ 	]*[Ii][Nn][Cc][Ll][Uu][Dd][Ee][ 	]*['\"]|$@: |p" | \
	sed -e "s|['\"].*$$||" | sed -e 's|.d:|.o:|' ; \
	echo $*.o: .os$(MYOS) ) > $@
COMPILE_RULE.f = $(FC) $(FFLAGS) -c $< -o $@ 
COMPILE_RULE.c = $(CC) $(CFLAGS) -c $< -o $@
# Don't "Makefile" to .d files anymore

ifdef NEWSTYLE
%.d: ../%.c
#	@echo remaking $@
	$(DEPENDS_RULE.c)

%.d: ../%.cpp
#	@echo remaking $@
	$(DEPENDS_RULE.c)

#r_%.d:
#	@echo r_$*.o: r_$*.f > $@

%.d: ../%.f
	@echo remaking $@
	$(DEPENDS_RULE.f)

%.o: ../%.f
	$(COMPILE_RULE.f)

%.o: ../%.c
	$(COMPILE_RULE.c)

else
%.d: %.c
#	@echo remaking $@
	$(DEPENDS_RULE.c)

%.d: %.cpp
#	@echo remaking $@
	$(DEPENDS_RULE.c)

#%.d: %.f .os$(MYOS)
%.d: %.f
	@echo remaking $@
	$(DEPENDS_RULE.f)
#	( cat $< | sed -n -e \
#	"s/^[ 	]*[Ii][Nn][Cc][Ll][Uu][Dd][Ee][ 	]*['\"]/$<: /p" | \
#	sed -e "s/['\"].*$$//" | sed -e 's/.f:/.o:/' ; \
#	@echo $*.o: .os$(MYOS) ) > $@

%.o: %.f
	$(COMPILE_RULE.f)
endif

#%.f : %.F
#	$(FC) -F $<

(%.o): %.o
#	@echo Adding $*.o to $@
	$(AR) $(ARFLAGS) $@ $*.o
ifdef RANLIB
	$(RANLIB) $@
endif

TARGET_PATH := ../../../$(OSPREFIX)$(SUBDIR)/
# Phil: the quot variable is used to keep from confusing my syntax highligher
# I put it twice because the syntax highlighter likes to see two quotes
# You could replace $(quot) with a literal " below, but it looks wierd
# and doubly so with VIM's syntax highlighting
quot = "
quot = "
FILES       = $(addsuffix $(quot),$(addprefix $(quot)$(TARGET_PATH),$($(SUBDIR)_targets)))

ifdef TARGET_PATH
$(TARGET_PATH)%: %	
	@echo "Making $@ from $< "
	$(RM) -r $@
	$(CP) $< $@
	$(RM) $<
endif

.os$(MYOS):
	$(RM) *.d .os*
	@echo $(MYOS) > .os$(MYOS)
	@echo remade marker .os$(MYOS)

csoft: $(REGSOURCES)
#	@echo "CSOFT - Arch. $(MYOS) sys.vers $(MYOS)$(OSEXT)"
#	@echo "`pwd` $(REGSOURCES)"
# if ! ( $(MAKE) ... ) exits the for loop if there's an error. Otherwise the for loop will only return
# an error if the last make command fails. This follows the default behavior of make but breaks the
# -p option. This section could use a rewrite.
	@echo "Considering $(shell pwd) ... "
	@if test -z "$(install-dirs)"; then \
	  echo Nothing to do for $(MYOS)$(OSEXT); \
	else \
	for subdir in $(install-dirs) dummy; do \
            if test $$subdir != dummy; then \
	        echo $(MAKE) SUBDIR=$$subdir OSPREFIX=$(MYOS)$(OSEXT)/ directory;\
	        if ! ( $(MAKE) SUBDIR=$$subdir OSPREFIX=$(MYOS)$(OSEXT)/ directory ); then exit 1; fi; \
	    fi \
	done \
	fi
	@echo "Done $(shell pwd)"

depend: .os$(MYOS)
	@ echo depending...
	@$(MAKE) $(sources:.f=.d) 
	@$(MAKE) $(sources:.c=.d) 

CLEAN clean::
	@ echo Cleaning `pwd`
	$(RM) -f *.o *.d .os*
	@ echo Done.

ALL_CLEAN all_clean: 
	@  for makefile in `find . -name Makefile -print | sed -e '/Eiffel/d'  -e '/pre_/d'`; do \
	  echo ; \
	  echo Considering `dirname $$makefile` ... ; \
	  $(MAKE) -C `dirname $$makefile` clean ; \
        done

directory:
	@echo Doing directory SUBDIR=$(SUBDIR) OSPREFIX=$(OSPREFIX)
#	@echo 'FILES=$(FILES)'
	mkdir -p $(TARGET_PATH)
	$(MAKE) SUBDIR=$(SUBDIR) OSPREFIX=$(OSPREFIX) $(FILES)

ALL_CSOFT all_csoft: 
	@ for makefile in `find . -name Makefile -print | sed -e '/Eiffel/d'  -e '/pre_/d' -e '/dev_/d`; do \
	  echo ; \
	  $(MAKE) -C `dirname $$makefile` csoft ; \
        done
	@ echo Made csoft for $(MYOS)
