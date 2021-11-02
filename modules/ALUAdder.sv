//ALU加法器模块

//我觉得这里面参数化的价值不大所以只对端口参数化处理了
module ALUAdder
#(parameter N = 32)
(
    input  logic M0,            //控制数据&辅助加法数据
    input  logic [N-1:0] X,Y,   //源数据X,Y
    output logic [N-1:0] result,//结果
    output logic zero           //零标志
);

logic [N-1:0] B;                //加数B
logic C0;                       //加法器控制端
logic [N:0]result_origin;      //加法原始结果
    
//assign B = Y ^ {(N-1){M0}};   
//这里有问题，2020.6.28修改：
assign B = Y ^ {N{M0}};    
assign C0 = M0 ;

//加法器计算模块
assign result_origin = X + B + C0;     //加法原始结果
assign result = result_origin[N-1:0];  //加法器结果为原始结果出掉溢出位
assign zero = (result==0) ? 1 : 0;     //零标志  ~|F;  |F表示各位相或（规约或运算）

endmodule