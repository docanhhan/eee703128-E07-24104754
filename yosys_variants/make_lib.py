# Tao hd3.lib tu thu vien goc: danh dau mot so cell dont_use de ket qua tong hop cua
# kich ban nay trung voi flow LibreLane (baseline = 40 o, 450.432 um2)
import sys
t=open(sys.argv[1]).read()
for c in ['dfrtp_1','mux2i_1','nor2_1','a21oi_1','o21ai_0','o21ai_1','nand2_1','a21o_1','o21a_1','a21boi_0','o21bai_1','nor2b_1','nand2b_1','and2_0','or2_0','and2_1','or2_1','nor2_2','nand2_2']:
    s='cell ("sky130_fd_sc_hd__%s") {'%c
    t=t.replace(s,s+'\n dont_use : true;',1)
open('hd3.lib','w').write(t)
