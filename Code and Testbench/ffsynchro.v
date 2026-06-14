module ffsynchro (
    input clk, 
    input rst, 
    input [3:0] din, 
    output reg [3:0] dout 
);

    reg [3:0] out_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dout <= 4'b0;
            out_reg <= 4'b0; // Added missing semicolon
        end
        else begin
            out_reg <= din;
            dout <= out_reg;
        end
    end 
    
endmodule