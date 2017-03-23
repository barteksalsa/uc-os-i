/*
************************************************************
*                         TEST1.C
*                      uCOS EXAMPLE
************************************************************
*/
#include "includes.h"

OS_SEM           Sem;
OS_MBOX          Mbox;
OS_Q             Q;
#define          Q_SIZE          10
void            *QData[Q_SIZE];

void             Task(void *value);

void appmain(void)
{
    ui i;

    OSSemInit(&Sem, 2);
    OSMboxInit(&Mbox, (void *)0);
    OSQInit(&Q, &QData[0], Q_SIZE);

    for (i = 1; i < 6; i++)
	OSTaskCreate(Task, (void *)i, i);

}

void Task(void *data)
{
    extern ub rdps();
    ui number = (ui)data;

    while (1) {
 	printf("...Task (%d) starting waiting\n", number);
	OSTimeDly(5000 / number); 
 	printf("...Task (%d) finished waiting\n", number);
	if (number < 20)
	    number += 20;
	else
	    number -= 20;
	OSChangePrio(number);
    }
}
