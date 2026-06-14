module fifo_mem(
    input  wclk , wrst_n , rclk , w_en , r_en , full,
    input [3:0] b_wptr , b_rptr,
    input [7:0] data_in,
    output  [7:0] data_out
);

reg [7:0] mem [0:7];

always @(posedge wclk) begin
if (w_en & !full) begin
mem[b_wptr[2:0]] <= data_in;
end
end
assign data_out = mem[b_rptr[2:0]];
endmodule