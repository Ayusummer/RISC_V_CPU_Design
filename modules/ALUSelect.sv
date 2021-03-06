//ALU多路选择器模块

module ALUSelect
#(parameter N = 32 )
(
    input  logic [N-1:0] X,            //源数据X
    input  logic [N-1:0] Y,            //源数据Y
    input  logic [N-1:0] result_adder, //加法器结果
    input  logic S0,S1,                //多路选择器功能开关
    output logic [N-1:0]result         //最终结果
);

always_comb 
begin
   case ({S1,S0})
      2'b00: result = result_adder;        
      2'b01: result = X & Y;
      2'b10: result = X | Y;
      2'b11: result = X ^ Y;
      default: result ={ N {1'bx} };
   endcase
end

endmodule