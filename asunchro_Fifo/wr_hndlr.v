module wr_hndlr(
    input wclk, wrst_n, w_en,
    input [3:0] g_rptr_sync,        
    output reg [3:0] b_wptr, g_wptr,
    output reg full                 
);


    wire [3:0] b_wptr_next, g_wptr_next;
    wire wfull;

    assign b_wptr_next = b_wptr + (w_en & !full);

    assign g_wptr_next = (b_wptr_next >> 1) ^ b_wptr_next; 

    assign wfull = (g_wptr_next == {~g_rptr_sync[3:2], g_rptr_sync[1:0]}); 
    
    
    always @(posedge wclk or negedge wrst_n) begin
        if(!wrst_n) begin
            b_wptr <= 4'b0;
            g_wptr <= 4'b0;         
            full   <= 1'b0;
            end
        else begin
            b_wptr <= b_wptr_next;
            g_wptr <= g_wptr_next;  
            full   <= wfull;
        end
    end
endmodule