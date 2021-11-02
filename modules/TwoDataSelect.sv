//2选1数据多路选择器
module TwoDataSelect
#(parameter N = 32 )
(
    input  logic [N-1:0] X,     //源数据X
    input  logic [N-1:0] Y,     //源数据Y
    input  logic S,             //多路选择器功能开关
    output logic [N-1:0] result //最终结果
);

always_comb 
begin
   case (S)
      1'b0: result = X;        
      1'b1: result = Y;
      default: result = 1'bx;
   endcase
end

endmodule