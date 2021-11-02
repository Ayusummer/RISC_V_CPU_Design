////32个32位数据的寄存器堆
module RegisterFile_5_32bit
(
	input  logic  Clk,
	input  logic  iWE,
	input  logic  [4:0] iWA, iRA1, iRA2,
    input  logic  [31:0] iWD,
    output logic  [31:0] oRD1, oRD2
);
    logic [31:0] mem[0:31];
    always_ff @(posedge Clk)
        if (iWE) mem[iWA] <= iWD;	

    assign oRD1 = (iRA1 != 0) ? mem[iRA1] : 0;
    assign oRD2 = (iRA2 != 0) ? mem[iRA2] : 0;

endmodule

