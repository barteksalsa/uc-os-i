/*****************************************************************************

Copyright © 1994, Digital Equipment Corporation, Maynard, Massachusetts. 

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

#ifndef LINT
static char *rcsid = "$Id: ";
#endif

/*
 * $Log: 
 */

/*****************************************************************************
 * Include Files.							     *
 *****************************************************************************/

#include "includes.h"
#include "uart.h"
#include "eb.h"
#include "syms.h"

/*****************************************************************************
 * External routines implemented in support.s                                *
 *****************************************************************************/

/*****************************************************************************
 * Forward Declarations 	 					     *
 *****************************************************************************/


/*****************************************************************************
 * Data Structures                                                           *
 *****************************************************************************/

OS_TCB OSTCBTbl[OS_MAX_TASKS];


/*****************************************************************************
 * Global Variables						 	     *
 *****************************************************************************/

extern void *_end;
void *stack_ptr = (void *) STACK_BASE;

/*****************************************************************************
 * Routines        						 	     *
 *****************************************************************************/
main()
{
/*
 *  Start off at IPL 0
 */
    swpipl(0);

/*
 *  Disable interrupts.
 */
    OS_ENTER_CRITICAL();
/*
 *  Set up the uart.
 */
    uart_init();
    outVti(com1Ier, 0x00);		/* disable interrupts from the UART */

    printf("uC/OS(EB): Initialising...\n");
    printf("uC/OS(EB): PS = 0x%X\n", rdps());
/*
 *  Set up trap and interrupt handling routines.
 */
    OSInitEntries();
/*
 *  Initialize uC/OS.
 */
    OSInit(OS_MAX_TASKS);
/*
 *  Get the apps started.
 */
    appmain();
/*
 *  Finally, enable interrupts and start the OS.
 */
    OS_EXIT_CRITICAL();

    OSStart();

    printf("uC/OS(EB): Finished\n");
}

/*
 *  Create a new task and put it into the list of tasks maintained
 *  by the OS.   Note that because the idle task is created first, it is
 *  always the last in the list as each new task is added to the front of
 *  that list.
 */
void OSTaskCreate(void (*task)(void *dptr), void *data, UBYTE prio)
{
    printf("uC/OS(EB): OSTaskCreate() called\n");
    printf("...Task = 0x%X, data = 0x%X\n", task, data);
    OS_ENTER_CRITICAL();
    if (OSTCBPrioTbl[prio] != (OS_TCB *) 0) {
/*
 *  Error: you can only have one task at any given priority.
 */
	printf("UCOS(EB): System error (OSTaskCreate() - 1)\n");
	halt();
    } else {
	OS_TCB *ptcb;

	ptcb = OSTCBGetFree();
	if (ptcb == (OS_TCB *) 0) {
	    printf("UCOS(EB): System error (OSTaskCreate() - 2)\n");
	    halt();
	} else {
	    printf("uC/OS(EB): TCB = 0x%X\n", ptcb);
	    ptcb->OSTCBPrio = prio;
	    ptcb->OSTCBStat = OS_STAT_RDY;
	    ptcb->OSTCBDly = 0;
	    ptcb->OSTCBSavedRegs = stack_ptr;
	    ptcb->OSTCBStkPtr =
	      (void *) ((ULONGLONG) stack_ptr + STACK_SIZE + SAVED_REG_SIZE);
	    printf("...Saved register pointer = 0x%X, Stack pointer = 0x%X\n",
	      ptcb->OSTCBSavedRegs, ptcb->OSTCBStkPtr);
	    stack_ptr =
	      (void *) ((ULONGLONG) stack_ptr + SAVED_REG_SIZE + STACK_SIZE);
/*
 *  Set up the initial register values for this new thread.
 */
	    memset(ptcb->OSTCBSavedRegs, 0x42, SAVED_REG_SIZE);
	    OSInitThread(ptcb->OSTCBSavedRegs, ptcb->OSTCBStkPtr, task, data);
/*
 *  Insert the TCB into the list of TCBs.
 */
	    ptcb->OSTCBNext = OSTCBList;
	    if (OSTCBList)
		ptcb->OSTCBPrev = ptcb;
	    else
		ptcb->OSTCBPrev = (OS_TCB *) 0;
	    OSTCBList = ptcb;
	    printf("Added: OSTCBList = 0x%X, next = 0x%X, prev = 0x%X\n",
	      OSTCBList, ptcb->OSTCBNext, ptcb->OSTCBPrev);
/*
 *  Set up the scheduling data.
 */
	    OSRdyGrp |= OSMapTbl[prio >> 3];
	    OSRdyTbl[prio >> 3] |= OSMapTbl[prio & 0x07];
	    OSTCBPrioTbl[prio] = ptcb;
	}
    }
    OS_EXIT_CRITICAL();
}

/*
 *  Start the highest priority thread.  OSLoadThread() just loads the
 *  thread's context and runs it.   Note that OSStartHighRdy() is called
 *  by OSStart() which is at IPL 0.
 */
void OSStartHighRdy(void) 
{
    printf("uC/OS(EB): OSStartHighRdy() called\n");
    printf("uC/OS(EB): ...Saved Register area = 0x%X\n",
      OSTCBCur->OSTCBSavedRegs);
    OSLoadThread(OSTCBCur->OSTCBSavedRegs);
}

/*
 *  This routine is called by OSIntExit() when it discovers that
 *  because of interrupt processing there is a thread which can run
 *  and is of higher priority than the currently executing thread.
 *  Note that this routine only sets a flag, the real processing is
 *  done in OSInterrupt() when the interrupt processing is over.  It
 *  needs to be there as that is the point at which we understand
 *  just what's on the current stack.
 */
ui OSIntSwap = FALSE;
void OSIntCtxSw(void) 
{
    OSIntSwap = TRUE;
}

/*
 *  Called by OSInterrupt() when an interrupt has occured.
 */
void OSInterruptHandler(ULONGLONG a0, ULONGLONG a1, ULONGLONG a2)
{
    extern ui OSRunning;

    if (OSRunning == 1) {
	OSIntEnter();
	if (a0 == 1)
	    OSTimeTick();
	OSIntExit();
    }
}

#define IPL_STACK_SIZE 20
static ub iplstack[IPL_STACK_SIZE];
static ui iplindex = 0;
void OSEnterCritical(void) 
{
    iplstack[iplindex++] = rdps() & 0x7;
    swpipl(7);
}

void OSExitCritical(void) 
{
    ub ipl;

    ipl = iplstack[--iplindex];
    swpipl(ipl);
}
