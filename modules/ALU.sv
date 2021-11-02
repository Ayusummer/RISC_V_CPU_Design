//算术逻辑单元ALU模块

module ALU
 #(parameter DATAWIDTH = 32)
(
    output logic[DATAWIDTH-1:0] F,      //ALU输出结果
    output logic zero,                  //零标志
    //input  logic[1:0] ALUop,            //功能选择端{M0,S1,S0}
    //上一句出错了，ALUop少了一位，2020.6.28修改：
    input  logic[2:0] ALUop,            //功能选择端{M0,S1,S0}
    input  logic[DATAWIDTH-1:0] X,      //源数据X
    input  logic[DATAWIDTH-1:0] Y       //源数据Y
);

/********************************译码器部分*****************************************/
logic M0;                         
logic S1,S0;                    //多路选择器选择开关
assign {M0,S1,S0} = ALUop;      //组合起来在CPU主设计程序中的ALUDecode中获得数据
/**********************************************************************************/

/********************************加法器部分*****************************************/
logic [DATAWIDTH:0] result_Adder;       //加法器结果
ALUAdder #(DATAWIDTH) Adder(.M0(M0),.X(X),.Y(Y),.result(result_Adder),.zero(zero));
                //systemVerilog换行直接回车即可，毕竟不像python一样缩进就可以直接表示层次
                //实例化加法器
                //carryout删去，因为加法器的进位并非最后整个器件结果的进位，因此并入F
/**********************************************************************************/

/******************************多路选择器部分***************************************/
ALUSelect #(DATAWIDTH) Select(.X(X),.Y(Y),.result_adder(result_Adder),
                                .S0(S0),.S1(S1),.result(F));
                //实例化多路选择器

endmodule