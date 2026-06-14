module rd_hndlr(
    input rrst_n , rclk , r_en,
    input [3:0] g_wptr_sync,
    output reg [3:0] g_rptr , b_rptr,
    output reg empty
);
    wire [3:0] g_rptr_next , b_rptr_next;
    wire rempty;

    assign b_rptr_next = b_rptr + (r_en & !empty);
    assign g_rptr_next = (b_rptr_next>>1) ^ b_rptr_next;
    assign rempty = (g_wptr_sync == g_rptr_next );
    always @(posedge rclk or negedge rrst_n) begin
        if(!rrst_n) begin
             g_rptr <= 4'b0;
             b_rptr <= 4'b0;
             empty <= 1'b1;
        end
        else begin
            g_rptr <= g_rptr_next;
            b_rptr <= b_rptr_next;
            empty <= rempty;
        end
    end
endmodule