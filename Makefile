#
# $Id$
#
# $Log$
#
#

include ../rules.osf

BOOTADR = 200000
CCFLAGS = $(CCFLAGS_GLOBAL) -DDEBUG
LIBS = $(OBJDIR)librom.a

default:	$(BOOTDIR)/ucos

all:		$(BOOTDIR)/ucos

BOOTADR = 200000

#-----------------
#
#  Objects common to both forms of image (.nh and .exe).
#  If you add new modules, then add them to this list.
#
SRCS = $(SRCDIR)eb.c \
	  $(SRCDIR)ucos.c $(SRCDIR)support.s 

OBJECTS = $(OBJDIR)eb.o $(OBJDIR)ucos.o $(OBJDIR)support.o $(OBJDIR)app.o

#--------------------------- ucos.nh ---------------------------------

$(OBJDIR)support.o:	 	support.s eb.h
	$(AS) $(ASFLAGS) -I../h  -o $(OBJDIR)$*.o support.s

$(OBJDIR)ucos.o:		ucos.c eb.h includes.h 
	$(CC) $(CCFLAGS) -o $(OBJDIR)$*.o -c -I../h $*.c

$(OBJDIR)eb.o:			eb.c eb.h includes.h
	$(CC) $(CCFLAGS) -o $(OBJDIR)$*.o -c -I../h $*.c

$(OBJDIR)app.o:			app.c includes.h
	$(CC) $(CCFLAGS) -o $(OBJDIR)$*.o -c -I../h $*.c
	
$(BOOTDIR)/ucos: $(OBJDIR)ucos.nh
	cp $(OBJDIR)ucos.nh $(BOOTDIR)/ucos
	chmod 775 $(BOOTDIR)/ucos

$(OBJDIR)ucos.exe: $(CRT) ${OBJECTS} ${LIBS}
	$(LD) -N -T $(BOOTADR) -non_shared -o $@ $(CRT) ${OBJECTS} ${LIBS} -lc

$(OBJDIR)ucos.nh:  $(OBJDIR)ucos.exe
	$(STRIP) $(STRIP_FLAGS) $(OBJDIR)ucos.exe $@

#----------------

depend: $(SRCS)
	makedepend -p'$$(OBJDIR)' -- $(DEPENDFLAGS) -- $(SRCS)

#----------------
clean:	
	-rm -f  $(OBJECTS)
	-rm -f $(SRCDIR)*~
	-rm -f $(SRCDIR)a.out
	$(CLEAN)

# DO NOT DELETE THIS LINE -- make depend depends on it.

$(OBJDIR)eb.o: includes.h ../h/system.h ../h/eb64.h ../h/eb66.h ../h/eb64p.h
$(OBJDIR)eb.o: eb.h ucos.h ../h/uart.h ../h/kbdscan.h
$(OBJDIR)ucos.o: includes.h ../h/system.h ../h/eb64.h ../h/eb66.h
$(OBJDIR)ucos.o: ../h/eb64p.h eb.h ucos.h
$(OBJDIR)support.o: /usr/include/alpha/regdef.h ../h/osf.h eb.h
