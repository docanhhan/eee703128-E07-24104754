`default_nettype none
module tt_um_eee703128_E07(input wire [7:0] ui_in, output wire [7:0] uo_out, input wire [7:0] uio_in, output wire [7:0] uio_out, output wire [7:0] uio_oe, input wire ena, input wire clk, input wire rst_n);
wire nap=uio_in[0]; wire mode=uio_in[1];
wire [7:0] dao_bit={ui_in[0],ui_in[1],ui_in[2],ui_in[3],ui_in[4],ui_in[5],ui_in[6],ui_in[7]};
wire [7:0] dao_nibble={ui_in[3:0],ui_in[7:4]};
assign uio_out=8'b0; assign uio_oe=8'b0; wire _u=&{ena,uio_in[7:2],1'b0};
reg [7:0] q; always @(posedge clk or negedge rst_n) begin if(!rst_n) q<=8'h00; else if(nap) q<=ui_in; end
assign uo_out = mode ? {q[3:0],q[7:4]} : {q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7]};
endmodule
