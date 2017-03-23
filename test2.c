/*
************************************************************
*                         TEST2.C
*                      uCOS EXAMPLE
************************************************************
*/
#include "INCLUDES.H"
#define          OS_MAX_TASKS    10
#define          STK_SIZE      1024
#define          Q_SIZE          10
OS_TCB           OSTCBTbl[OS_MAX_TASKS];
UWORD            OSIdleTaskStk[STK_SIZE];
UWORD            KeyStk[STK_SIZE];
UWORD            DispStk[STK_SIZE];
UWORD            Task1Stk[STK_SIZE];
UWORD            Task2Stk[STK_SIZE];
UWORD            Task3Stk[STK_SIZE];
OS_SEM           Sem;
OS_MBOX          Mbox;
OS_Q             Q;
void            *QData[Q_SIZE];
UWORD            Ctr1 = 0;
UWORD            Ctr2 = 0;
UBYTE            Min  = 0;
UBYTE            Sec  = 0;
void far         KeyTask(void *data);
void far         DispTask(void *data);
void far         Task1(void *data);
void far         Task2(void *data);
void far         Task3(void *data);
void interrupt (*OldTickISR)(void);


void main(void)
{
    clrscr();
    OldTickISR = getvect(0x08);
    setvect(UCOS, (void interrupt (*)(void))OSCtxSw);
    setvect(0xF2, OldTickISR);
    OSInit(&OSIdleTaskStk[STK_SIZE], OS_MAX_TASKS);
    OSSemInit(&Sem, 1);
    OSMboxInit(&Mbox, (void *)0);
    OSQInit(&Q, &QData[0], Q_SIZE);
    OSTaskCreate(DispTask, (void *)0, (void *)&DispStk[STK_SIZE],   0);
    OSTaskCreate(KeyTask,  (void *)0, (void *)&KeyStk[STK_SIZE],    1);
    OSTaskCreate(Task1,    (void *)0, (void *)&Task1Stk[STK_SIZE], 10);
    OSTaskCreate(Task2,    (void *)0, (void *)&Task2Stk[STK_SIZE], 20);
    OSTaskCreate(Task3,    (void *)0, (void *)&Task3Stk[STK_SIZE], 30);
    OSStart();
}

void far KeyTask(void *data)
{
    UBYTE i;


    setvect(0x08, (void interrupt (*)(void))OSTickISR);
    while (1) {
        OSTimeDly(1);
        if (kbhit()) {
            switch (getch()) {
                case '1': OSMboxPost(&Mbox, (void *)1);
                          break;
                case '2': OSQPost(&Q, (void *)1);
                          break;
                case 'x':
                case 'X': setvect(0x08, OldTickISR);
                          exit(0);
                          break;
            }
        }
    }
}


void far Task1(void *data)
{
    UBYTE err;

    while (1) {
        OSMboxPend(&Mbox, 36, &err);
        OSSemPend(&Sem, 0);
        Ctr1++;
        OSSemPost(&Sem);
    }
}


void far Task2(void *data)
{
    UBYTE err;

    while (1) {
        OSQPend(&Q, 72, &err);
        OSSemPend(&Sem, 0);
        Ctr2++;
        OSSemPost(&Sem);
    }
}


void far Task3(void *data)
{
    while (1) {
        OSTimeDly(18);
        OSSemPend(&Sem, 0);
        Sec++;
        if (Sec > 59) {
            Sec = 0;
            Min++;
        }
        OSSemPost(&Sem);
    }
}


void far DispTask(void *data)
{
    UWORD ctr1, ctr2;
    UBYTE min,  sec;

    while (1) {
        OSTimeDly(6);
        OSSemPend(&Sem, 0);
        ctr1 = Ctr1;
        ctr2 = Ctr2;
        min  = Min;
        sec  = Sec;
        OSSemPost(&Sem);
        gotoxy(1, 9);
        printf("Clock = %02d:%02d", min, sec);
        gotoxy(1, 10);
        printf("Ctr1  =  %4d", ctr1);
        gotoxy(1, 11);
        printf("Ctr2  =  %4d", ctr2);
    }
}
