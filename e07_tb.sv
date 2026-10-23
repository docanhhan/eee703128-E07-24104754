`timescale 1ns/1ps
module e07_tb;
    reg  [7:0] ui_in;
    reg  [7:0] uio_in;
    reg        clk, rst_n, ena;
    wire [7:0] uo_out, uio_out, uio_oe;
    integer    errors, n;

    tt_um_eee703128_E07 dut (.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
        .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));

    always #50 clk = ~clk;   // 10 MHz

    // mo hinh chuan doc lap: dao bit / dao nibble bang vong lap
    function [7:0] ref_model(input [7:0] x, input m);
        integer i;
        begin
            if (m) ref_model = {x[3:0], x[7:4]};
            else for (i = 0; i < 8; i = i + 1) ref_model[i] = x[7-i];
        end
    endfunction

    task check(input [7:0] exp, input [511:0] name);
        begin
            n = n + 1;
            if (uo_out !== exp) begin
                errors = errors + 1;
                $display("FAIL %0s: uo_out=%02h expected=%02h", name, uo_out, exp);
            end else $display("ok   %0s: uo_out=%02h", name, uo_out);
        end
    endtask

    task nap_byte(input [7:0] x, input m);   // nap 1 byte o che do m
        begin
            @(negedge clk); ui_in = x; uio_in = {6'b0, m, 1'b1};
            @(negedge clk); uio_in = 8'h00;
            #1;
        end
    endtask

    integer k;
    initial begin
        $dumpfile("e07.vcd"); $dumpvars(0, e07_tb);
        errors = 0; n = 0; clk = 0; rst_n = 0; ena = 1; ui_in = 0; uio_in = 0;
        #120 rst_n = 1;
        #1 check(8'h00, "reset ->0");

        // ---- CA BAT BUOC ----
        nap_byte(8'h01, 0); check(8'h80, "BB1 0x01->0x80");
        nap_byte(8'hFF, 0); check(8'hFF, "BB2 0xFF->0xFF");
        nap_byte(8'hA5, 0); check(8'hA5, "BB3 0xA5->0xA5");
        nap_byte(8'hA5, 0); check(ref_model(8'hA5,0), "BB4 A5 mode0");
        nap_byte(8'hA5, 1); check(8'h5A, "BB4 A5 mode1 (khac mode0)");

        // ---- CA TU XAY DUNG 1: giu du lieu khi nap=0 ----
        nap_byte(8'h12, 1); check(8'h21, "TC1 nap 0x12 nibble");
        @(negedge clk); ui_in = 8'hFF; uio_in = 8'h00;      // nap=0, mode=0
        repeat (3) @(negedge clk); #1;
        check(8'h21, "TC1 giu khi nap=0");
        @(negedge clk); uio_in = 8'h02;                     // doi mode, van nap=0
        repeat (2) @(negedge clk); #1;
        check(8'h21, "TC1 doi mode khi nap=0 khong doi q");

        // ---- CA TU XAY DUNG 2 (BIEN): reset bat dong bo giua chung ----
        nap_byte(8'hC3, 0);
        #13 rst_n = 0; #1;                                  // khong co canh clock nao
        check(8'h00, "TC2 reset bat dong bo ->0 tuc thi");
        uio_in = 8'h01; ui_in = 8'hFF;
        repeat (2) @(negedge clk); #1;
        check(8'h00, "TC2 reset thang nap");
        rst_n = 1; uio_in = 8'h00;
        @(negedge clk); #1;
        check(8'h00, "TC2 nha reset, chua nap -> van 0");

        // ---- CA TU XAY DUNG 3: quet het 256 gia tri x 2 che do ----
        for (k = 0; k < 512; k = k + 1) begin
            nap_byte(k[7:0], k[8]);
            n = n + 1;
            if (uo_out !== ref_model(k[7:0], k[8])) begin
                errors = errors + 1;
                $display("FAIL quet: in=%02h mode=%0d out=%02h", k[7:0], k[8], uo_out);
            end
        end
        $display("Da quet 512 to hop (256 x 2 che do)");

        // chan khong dung
        n = n + 1;
        if (uio_out !== 8'h00 || uio_oe !== 8'h00) begin
            errors = errors + 1; $display("FAIL uio_out/uio_oe khac 0");
        end

        if (errors == 0) $display("E07 TB PASS (%0d phep kiem)", n);
        else             $display("E07 TB FAIL (%0d loi / %0d phep kiem)", errors, n);
        $finish;
    end
endmodule
