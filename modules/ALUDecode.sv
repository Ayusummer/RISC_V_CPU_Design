//ALU译码器
// 修订历史 :
// --------------------------------------------------------------------
//   版本 | 作者  | 修改日期    | 所做改变
//   V1.0 | 233  | 2020.6.24   | 肖老师给的初始版本
//   v1.1 | 233  | 2020.6.26   | 增加iData=00时的译码
//   v1.2 | 233  | 2020.6.26   | 增加iData=01,10时的译码
// --------------------------------------------------------------------
module ALUDecode
(
    input  logic [1:0] iData,   //功能选择信号
    input  logic [6:0] funct7,  //funct7
    input  logic [2:0] funct3,  //funct3
    output logic [2:0] oSeg     //{M0,S1,S0}

);

localparam ADD=3'b000;  //加法
localparam SUB=3'b100;  //减法
localparam AND=3'b001;  //与
localparam OR =3'b010;  //或
localparam XOR=3'b011;  //异或


always_comb
  case(iData)
    /*******v1.1 | 233  | 2020.6.26   | 增加IData=00时的译码*******/
    2'b00 : oSeg <= ADD;      //加法 load，store
    /**************************************************************/


    /*******v1.2 | 233  | 2020.6.26   | 增加iData=01,10时的译码********/
    2'b01 : oSeg <= SUB;    //减法 beq，bne
    2'b10 :                 //根据funct3和funct7 R型运算指令
      case(funct7)
        7'b0100000 : 
          case(funct3)
            3'b000 : oSeg <= SUB;
            default: oSeg <= 3'bxxx;
          endcase
        7'b0000000 :
          case(funct3)
            3'b000 : oSeg <= ADD;
            3'b111 : oSeg <= AND;
            3'b110 : oSeg <= OR;
            3'b100 : oSeg <= XOR;
            default: oSeg <= 3'bxxx;
          endcase 
        default: oSeg <= 3'bxxx;
      endcase 
    /*****************************************************************/


    2'b11 :                   //根据funct3 I型运算指令
      case(funct3)
        3'b000 : oSeg <= ADD; //addi 
        3'b111 : oSeg <= AND; //andi
        3'b110 : oSeg <= OR;  //ori
        3'b100 : oSeg <= XOR; //xori
        default: oSeg <= 3'bxxx;
      endcase
    default : oSeg=3'bx; 
  endcase   
endmodule