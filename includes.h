
/*****************************************************************************

Copyright � 1994, Digital Equipment Corporation, Maynard, Massachusetts. 

                        All Rights Reserved

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose and without fee is hereby granted, provided  
that the copyright notice and this permission notice appear in all copies  
of software and supporting documentation, and that the name of Digital not  
be used in advertising or publicity pertaining to distribution of the software 
without specific, written prior permission. Digital grants this permission 
provided that you prominently mark, as not part of the original, any 
modifications made to this software or documentation.

Digital Equipment Corporation disclaims all warranties and/or guarantees  
with regard to this software, including all implied warranties of fitness for 
a particular purpose and merchantability, and makes no representations 
regarding the use of, or the results of the use of, the software and 
documentation in terms of correctness, accuracy, reliability, currentness or
otherwise; and you rely on the software, documentation and results solely at 
your own risk. 

******************************************************************************/
/*
***************************************************************
*                       INCLUDES.H
***************************************************************
*/
#include    "system.h"
#include    "eb.h"

#define ULONGLONG ul           /* 64 bits */
#define ULONG ui               /* 32 bits */
#define UWORD uw               /* 16 bits */
#define WORD short int           
#define UBYTE ub               /* 8 bits  */
#define BOOLEAN ub

extern void OSInterruptHandler(ULONGLONG a0, ULONGLONG a1, ULONGLONG a2);
extern void OSEnterCritical(void);
extern void OSExitCritical(void);
extern void OSLoadThread(ULONGLONG *context);
extern ub rdps(void);

#define OS_ENTER_CRITICAL() OSEnterCritical()
#define OS_EXIT_CRITICAL() OSExitCritical()

extern void OSTaskSwap(void);
#define OS_TASK_SW() OSTaskSwap()

#include    "ucos.h"
