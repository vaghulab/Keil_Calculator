/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

/* This file is designed for use with ISim build 0x1cce1bb2 */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
static const char *ng0 = "D:/NUS Course Files/Semester V/EE3207E/Miscellaneous/EE3207E_Project/int_ram.vhd";
extern char *IEEE_P_3620187407;
extern char *IEEE_P_2592010699;

int ieee_p_3620187407_sub_514432868_3965413181(char *, char *, char *);


static void work_a_0946206428_0000452272_p_0(char *t0)
{
    char t26[16];
    char t34[16];
    char t35[16];
    char t40[16];
    char *t1;
    char *t2;
    unsigned char t3;
    unsigned char t4;
    char *t5;
    int t6;
    int t7;
    char *t8;
    char *t9;
    unsigned char t10;
    char *t11;
    int t12;
    int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    unsigned char t22;
    unsigned int t23;
    unsigned int t24;
    unsigned int t25;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    char *t30;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    char *t36;
    char *t37;
    int t38;
    unsigned int t39;
    char *t41;
    int t42;
    int t43;
    int t44;
    unsigned int t45;
    unsigned int t46;
    unsigned int t47;
    unsigned char t48;
    char *t49;
    char *t50;
    char *t51;
    char *t52;
    char *t53;
    unsigned char t54;
    unsigned char t55;
    unsigned char t56;
    unsigned char t57;

LAB0:    xsi_set_current_line(33, ng0);
    t1 = (t0 + 1192U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB2;

LAB4:    t1 = (t0 + 1672U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB12;

LAB13:    t1 = (t0 + 1832U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB17;

LAB18:    t1 = (t0 + 992U);
    t4 = xsi_signal_has_event(t1);
    if (t4 == 1)
        goto LAB24;

LAB25:    t3 = (unsigned char)0;

LAB26:    if (t3 != 0)
        goto LAB22;

LAB23:
LAB3:    t1 = (t0 + 4272);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(34, ng0);
    t1 = (t0 + 8631);
    *((int *)t1) = 0;
    t5 = (t0 + 8635);
    *((int *)t5) = 127;
    t6 = 0;
    t7 = 127;

LAB5:    if (t6 <= t7)
        goto LAB6;

LAB8:    xsi_set_current_line(37, ng0);
    t1 = (t0 + 8647);
    t5 = (t0 + 4416);
    t8 = (t5 + 56U);
    t9 = *((char **)t8);
    t11 = (t9 + 56U);
    t17 = *((char **)t11);
    memcpy(t17, t1, 8U);
    xsi_driver_first_trans_fast_port(t5);
    xsi_set_current_line(38, ng0);
    t1 = (t0 + 4480);
    t2 = (t1 + 56U);
    t5 = *((char **)t2);
    t8 = (t5 + 56U);
    t9 = *((char **)t8);
    *((unsigned char *)t9) = (unsigned char)4;
    xsi_driver_first_trans_fast_port(t1);
    goto LAB3;

LAB6:    xsi_set_current_line(35, ng0);
    t8 = (t0 + 8639);
    t10 = (8U != 8U);
    if (t10 == 1)
        goto LAB9;

LAB10:    t11 = (t0 + 8631);
    t12 = *((int *)t11);
    t13 = (t12 - 127);
    t14 = (t13 * -1);
    t15 = (8U * t14);
    t16 = (0U + t15);
    t17 = (t0 + 4352);
    t18 = (t17 + 56U);
    t19 = *((char **)t18);
    t20 = (t19 + 56U);
    t21 = *((char **)t20);
    memcpy(t21, t8, 8U);
    xsi_driver_first_trans_delta(t17, t16, 8U, 0LL);

LAB7:    t1 = (t0 + 8631);
    t6 = *((int *)t1);
    t2 = (t0 + 8635);
    t7 = *((int *)t2);
    if (t6 == t7)
        goto LAB8;

LAB11:    t12 = (t6 + 1);
    t6 = t12;
    t5 = (t0 + 8631);
    *((int *)t5) = t6;
    goto LAB5;

LAB9:    xsi_size_not_matching(8U, 8U, 0);
    goto LAB10;

LAB12:    xsi_set_current_line(41, ng0);
    t1 = (t0 + 1992U);
    t5 = *((char **)t1);
    t6 = (7 - 7);
    t14 = (t6 * -1);
    t15 = (1U * t14);
    t16 = (0 + t15);
    t1 = (t5 + t16);
    t10 = *((unsigned char *)t1);
    t22 = (t10 == (unsigned char)2);
    if (t22 != 0)
        goto LAB14;

LAB16:    xsi_set_current_line(44, ng0);
    t1 = (t0 + 8655);
    t5 = (t0 + 4416);
    t8 = (t5 + 56U);
    t9 = *((char **)t8);
    t11 = (t9 + 56U);
    t17 = *((char **)t11);
    memcpy(t17, t1, 8U);
    xsi_driver_first_trans_fast_port(t5);

LAB15:    goto LAB3;

LAB14:    xsi_set_current_line(42, ng0);
    t8 = (t0 + 2792U);
    t9 = *((char **)t8);
    t8 = (t0 + 1992U);
    t11 = *((char **)t8);
    t23 = (7 - 6);
    t24 = (t23 * 1U);
    t25 = (0 + t24);
    t8 = (t11 + t25);
    t17 = (t26 + 0U);
    t18 = (t17 + 0U);
    *((int *)t18) = 6;
    t18 = (t17 + 4U);
    *((int *)t18) = 0;
    t18 = (t17 + 8U);
    *((int *)t18) = -1;
    t7 = (0 - 6);
    t27 = (t7 * -1);
    t27 = (t27 + 1);
    t18 = (t17 + 12U);
    *((unsigned int *)t18) = t27;
    t12 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t8, t26);
    t13 = (t12 - 127);
    t27 = (t13 * -1);
    xsi_vhdl_check_range_of_index(127, 0, -1, t12);
    t28 = (8U * t27);
    t29 = (0 + t28);
    t18 = (t9 + t29);
    t19 = (t0 + 4416);
    t20 = (t19 + 56U);
    t21 = *((char **)t20);
    t30 = (t21 + 56U);
    t31 = *((char **)t30);
    memcpy(t31, t18, 8U);
    xsi_driver_first_trans_fast_port(t19);
    goto LAB15;

LAB17:    xsi_set_current_line(48, ng0);
    t1 = (t0 + 1992U);
    t5 = *((char **)t1);
    t6 = (7 - 7);
    t14 = (t6 * -1);
    t15 = (1U * t14);
    t16 = (0 + t15);
    t1 = (t5 + t16);
    t10 = *((unsigned char *)t1);
    t22 = (t10 == (unsigned char)2);
    if (t22 != 0)
        goto LAB19;

LAB21:    xsi_set_current_line(51, ng0);
    t1 = (t0 + 4480);
    t2 = (t1 + 56U);
    t5 = *((char **)t2);
    t8 = (t5 + 56U);
    t9 = *((char **)t8);
    *((unsigned char *)t9) = (unsigned char)4;
    xsi_driver_first_trans_fast_port(t1);

LAB20:    goto LAB3;

LAB19:    xsi_set_current_line(49, ng0);
    t8 = (t0 + 2792U);
    t9 = *((char **)t8);
    t8 = (t0 + 1992U);
    t11 = *((char **)t8);
    t23 = (7 - 2);
    t24 = (t23 * 1U);
    t25 = (0 + t24);
    t8 = (t11 + t25);
    t17 = (t26 + 0U);
    t18 = (t17 + 0U);
    *((int *)t18) = 2;
    t18 = (t17 + 4U);
    *((int *)t18) = 0;
    t18 = (t17 + 8U);
    *((int *)t18) = -1;
    t7 = (0 - 2);
    t27 = (t7 * -1);
    t27 = (t27 + 1);
    t18 = (t17 + 12U);
    *((unsigned int *)t18) = t27;
    t12 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t8, t26);
    t13 = (t12 - 7);
    t27 = (t13 * -1);
    xsi_vhdl_check_range_of_index(7, 0, -1, t12);
    t28 = (1U * t27);
    t18 = (t0 + 8663);
    t20 = (t0 + 1992U);
    t21 = *((char **)t20);
    t29 = (7 - 6);
    t32 = (t29 * 1U);
    t33 = (0 + t32);
    t20 = (t21 + t33);
    t31 = ((IEEE_P_2592010699) + 4024);
    t36 = (t35 + 0U);
    t37 = (t36 + 0U);
    *((int *)t37) = 0;
    t37 = (t36 + 4U);
    *((int *)t37) = 3;
    t37 = (t36 + 8U);
    *((int *)t37) = 1;
    t38 = (3 - 0);
    t39 = (t38 * 1);
    t39 = (t39 + 1);
    t37 = (t36 + 12U);
    *((unsigned int *)t37) = t39;
    t37 = (t40 + 0U);
    t41 = (t37 + 0U);
    *((int *)t41) = 6;
    t41 = (t37 + 4U);
    *((int *)t41) = 3;
    t41 = (t37 + 8U);
    *((int *)t41) = -1;
    t42 = (3 - 6);
    t39 = (t42 * -1);
    t39 = (t39 + 1);
    t41 = (t37 + 12U);
    *((unsigned int *)t41) = t39;
    t30 = xsi_base_array_concat(t30, t34, t31, (char)97, t18, t35, (char)97, t20, t40, (char)101);
    t43 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t30, t34);
    t44 = (t43 - 127);
    t39 = (t44 * -1);
    xsi_vhdl_check_range_of_index(127, 0, -1, t43);
    t45 = (8U * t39);
    t46 = (0 + t45);
    t47 = (t46 + t28);
    t41 = (t9 + t47);
    t48 = *((unsigned char *)t41);
    t49 = (t0 + 4480);
    t50 = (t49 + 56U);
    t51 = *((char **)t50);
    t52 = (t51 + 56U);
    t53 = *((char **)t52);
    *((unsigned char *)t53) = t48;
    xsi_driver_first_trans_fast_port(t49);
    goto LAB20;

LAB22:    xsi_set_current_line(55, ng0);
    t2 = (t0 + 1352U);
    t8 = *((char **)t2);
    t54 = *((unsigned char *)t8);
    t55 = (t54 == (unsigned char)3);
    if (t55 == 1)
        goto LAB30;

LAB31:    t48 = (unsigned char)0;

LAB32:    if (t48 != 0)
        goto LAB27;

LAB29:
LAB28:    xsi_set_current_line(59, ng0);
    t1 = (t0 + 1512U);
    t2 = *((char **)t1);
    t4 = *((unsigned char *)t2);
    t10 = (t4 == (unsigned char)3);
    if (t10 == 1)
        goto LAB36;

LAB37:    t3 = (unsigned char)0;

LAB38:    if (t3 != 0)
        goto LAB33;

LAB35:
LAB34:    goto LAB3;

LAB24:    t2 = (t0 + 1032U);
    t5 = *((char **)t2);
    t10 = *((unsigned char *)t5);
    t22 = (t10 == (unsigned char)3);
    t3 = t22;
    goto LAB26;

LAB27:    xsi_set_current_line(56, ng0);
    t11 = (t0 + 2152U);
    t17 = *((char **)t11);
    t11 = (t0 + 1992U);
    t18 = *((char **)t11);
    t23 = (7 - 6);
    t24 = (t23 * 1U);
    t25 = (0 + t24);
    t11 = (t18 + t25);
    t19 = (t26 + 0U);
    t20 = (t19 + 0U);
    *((int *)t20) = 6;
    t20 = (t19 + 4U);
    *((int *)t20) = 0;
    t20 = (t19 + 8U);
    *((int *)t20) = -1;
    t7 = (0 - 6);
    t27 = (t7 * -1);
    t27 = (t27 + 1);
    t20 = (t19 + 12U);
    *((unsigned int *)t20) = t27;
    t12 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t11, t26);
    t13 = (t12 - 127);
    t27 = (t13 * -1);
    t28 = (8U * t27);
    t29 = (0U + t28);
    t20 = (t0 + 4352);
    t21 = (t20 + 56U);
    t30 = *((char **)t21);
    t31 = (t30 + 56U);
    t36 = *((char **)t31);
    memcpy(t36, t17, 8U);
    xsi_driver_first_trans_delta(t20, t29, 8U, 0LL);
    goto LAB28;

LAB30:    t2 = (t0 + 1992U);
    t9 = *((char **)t2);
    t6 = (7 - 7);
    t14 = (t6 * -1);
    t15 = (1U * t14);
    t16 = (0 + t15);
    t2 = (t9 + t16);
    t56 = *((unsigned char *)t2);
    t57 = (t56 == (unsigned char)2);
    t48 = t57;
    goto LAB32;

LAB33:    xsi_set_current_line(60, ng0);
    t8 = (t0 + 2312U);
    t9 = *((char **)t8);
    t54 = *((unsigned char *)t9);
    t8 = (t0 + 8667);
    t17 = (t0 + 1992U);
    t18 = *((char **)t17);
    t23 = (7 - 6);
    t24 = (t23 * 1U);
    t25 = (0 + t24);
    t17 = (t18 + t25);
    t20 = ((IEEE_P_2592010699) + 4024);
    t21 = (t34 + 0U);
    t30 = (t21 + 0U);
    *((int *)t30) = 0;
    t30 = (t21 + 4U);
    *((int *)t30) = 3;
    t30 = (t21 + 8U);
    *((int *)t30) = 1;
    t7 = (3 - 0);
    t27 = (t7 * 1);
    t27 = (t27 + 1);
    t30 = (t21 + 12U);
    *((unsigned int *)t30) = t27;
    t30 = (t35 + 0U);
    t31 = (t30 + 0U);
    *((int *)t31) = 6;
    t31 = (t30 + 4U);
    *((int *)t31) = 3;
    t31 = (t30 + 8U);
    *((int *)t31) = -1;
    t12 = (3 - 6);
    t27 = (t12 * -1);
    t27 = (t27 + 1);
    t31 = (t30 + 12U);
    *((unsigned int *)t31) = t27;
    t19 = xsi_base_array_concat(t19, t26, t20, (char)97, t8, t34, (char)97, t17, t35, (char)101);
    t13 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t19, t26);
    t38 = (t13 - 127);
    t27 = (t38 * -1);
    t28 = (8U * t27);
    t29 = (0U + t28);
    t31 = (t0 + 1992U);
    t36 = *((char **)t31);
    t32 = (7 - 2);
    t33 = (t32 * 1U);
    t39 = (0 + t33);
    t31 = (t36 + t39);
    t37 = (t40 + 0U);
    t41 = (t37 + 0U);
    *((int *)t41) = 2;
    t41 = (t37 + 4U);
    *((int *)t41) = 0;
    t41 = (t37 + 8U);
    *((int *)t41) = -1;
    t42 = (0 - 2);
    t45 = (t42 * -1);
    t45 = (t45 + 1);
    t41 = (t37 + 12U);
    *((unsigned int *)t41) = t45;
    t43 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t31, t40);
    t44 = (t43 - 7);
    t45 = (t44 * -1);
    t46 = (1 * t45);
    t47 = (t29 + t46);
    t41 = (t0 + 4352);
    t49 = (t41 + 56U);
    t50 = *((char **)t49);
    t51 = (t50 + 56U);
    t52 = *((char **)t51);
    *((unsigned char *)t52) = t54;
    xsi_driver_first_trans_delta(t41, t47, 1, 0LL);
    goto LAB34;

LAB36:    t1 = (t0 + 1992U);
    t5 = *((char **)t1);
    t6 = (7 - 7);
    t14 = (t6 * -1);
    t15 = (1U * t14);
    t16 = (0 + t15);
    t1 = (t5 + t16);
    t22 = *((unsigned char *)t1);
    t48 = (t22 == (unsigned char)2);
    t3 = t48;
    goto LAB38;

}


extern void work_a_0946206428_0000452272_init()
{
	static char *pe[] = {(void *)work_a_0946206428_0000452272_p_0};
	xsi_register_didat("work_a_0946206428_0000452272", "isim/test_ee3207e_project_isim_beh.exe.sim/work/a_0946206428_0000452272.didat");
	xsi_register_executes(pe);
}
