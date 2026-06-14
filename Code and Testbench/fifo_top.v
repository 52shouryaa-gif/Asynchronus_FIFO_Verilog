module fifo_top (
    // FIX 1: Properly defined Inputs and Outputs with their sizes
    input wclk, w_en, rclk, r_en, wrst_n, rrst_n,
    input [7:0] data_in,
    output [7:0] data_out,
    output full, empty
);

    wire [3:0] g_rptr_sync, b_wptr, g_wptr, g_wptr_sync, b_rptr, g_rptr;

    wr_hndlr wr_hndl (
        .wclk(wclk), .wrst_n(wrst_n), .w_en(w_en),
        .g_rptr_sync(g_rptr_sync),        
        .b_wptr(b_wptr), .g_wptr(g_wptr), 
        .full(full)                 
    );

    rd_hndlr rd_hndl (
        .rclk(rclk), .rrst_n(rrst_n), .r_en(r_en),
        .g_wptr_sync(g_wptr_sync),
        .g_rptr(g_rptr), .b_rptr(b_rptr),
        .empty(empty)
    );

    fifo_mem fifo_mem_inst (
      
        .wclk(wclk), .w_en(w_en), .full(full),
        .b_wptr(b_wptr),
        .b_rptr(b_rptr),
        .data_in(data_in),
        .data_out(data_out)
    );

    
    ffsynchro ffsynchror (
        .clk(wclk),         
        .rst(wrst_n),        
        .din(g_rptr), 
        .dout(g_rptr_sync)
    );

    // Sync WRITE Pointer into READ Domain
    ffsynchro ffsynchrow (
        .clk(rclk),          
        .rst(rrst_n),       
        .din(g_wptr), 
        .dout(g_wptr_sync)
    );

endmodule