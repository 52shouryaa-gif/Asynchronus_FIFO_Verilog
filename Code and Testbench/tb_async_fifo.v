`timescale 1ns / 1ps

module tb_fifo_top();

    reg wclk, rclk;
    reg wrst_n, rrst_n;
    reg w_en, r_en;
    reg [7:0] data_in;

    wire [7:0] data_out;
    wire full, empty;

    
    fifo_top uut (
        .wclk(wclk), .w_en(w_en), 
        .rclk(rclk), .r_en(r_en), 
        .wrst_n(wrst_n), .rrst_n(rrst_n),
        .data_in(data_in),
        .data_out(data_out),
        .full(full), .empty(empty)
    );

   
    initial wclk = 0;
    always #5 wclk = ~wclk;

    
    initial rclk = 0;
    always #12.5 rclk = ~rclk;

  
    initial begin
        
        $dumpfile("fifo_wave.vcd");
        $dumpvars(0, tb_fifo_top);

   
        w_en = 0; r_en = 0; data_in = 0;
        wrst_n = 0; rrst_n = 0;
        
    
        #30; 
        wrst_n = 1; rrst_n = 1;
        #20;

      
        $display("--- Starting WRITE Phase ---");
        while (!full) begin
            @(negedge wclk); 
            w_en = 1;
            data_in = $random; 
        end
        @(negedge wclk);
        w_en = 0;
        $display("FIFO is FULL at time %0t", $time);

        #50; 

        $display("--- Starting READ Phase ---");
        while (!empty) begin
            @(negedge rclk);
            r_en = 1;
        end
        @(negedge rclk);
        r_en = 0;
        $display("FIFO is EMPTY at time %0t", $time);

        #50;

 
        $display("--- Starting CONCURRENT Read/Write ---");
        w_en = 1; r_en = 1;
        
        repeat(15) begin
            @(negedge wclk);
            data_in = data_in + 1; 
        end
        
        w_en = 0; r_en = 0;
        #100;

        $display("--- Simulation Complete ---");
        $finish;
    end

    
    initial begin
        $monitor("Time=%0t | W_EN=%b DATA_IN=%h FULL=%b | R_EN=%b DATA_OUT=%h EMPTY=%b", 
                 $time, w_en, data_in, full, r_en, data_out, empty);
    end

endmodule
