module blram(clk, rst, we, addr, din, dout);
    parameter SIZE = 14, DEPTH = 2**SIZE;
    input clk;
    input rst;
    input we;
    input [SIZE-1:0] addr;
    input [31:0] din;
    output reg [31:0] dout;
    reg [31:0] mem [DEPTH-1:0];
    always @(posedge clk) begin
        dout <= #1 mem[addr[SIZE-1:0]];
        if (we) mem[addr[SIZE-1:0]] <= #1 din;
    end
endmodule