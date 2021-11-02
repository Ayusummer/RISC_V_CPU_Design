//主译码器，译opcode；判断指令类别；译ALU功能选择数据；判断寄存器堆写使能；
//          判断数据存储器写使能；
// 修订历史 :
// --------------------------------------------------------------------
//   版本 | 作者  | 修改日期    | 所做改变
//   V1.0 | 233  | 2020.6.24   | 肖老师给的初始版本
//   v1.1 | 233  | 2020.6.26   | 增加store指令译码及MemWrite控制信号；    
//   v1.2 | 233  | 2020.6.26   | 增加load指令译码及MemToReg控制信号；
//   v1.3 | 233  | 2020.6.27   | 增加R,beq指令译码及immToALU,PCjump控制信号；
//   v1.3 | 233  | 2020.6.28   | 通过加法及与或运算来实现RegReadData1-RegReadData2
// --------------------------------------------------------------------
module MainDecoder(
  input  logic [6:0] iOpcode,    //输入数据opcode，判断指令类别
  output logic [4:0] oImm_type,  //J, U, B, S, I type 立即数类型
  output logic oRegWrite,        //寄存器堆写使能
  output logic [1:0] ALUop,      //ALU功能选择信号
  /********v1.1 | 233  | 2020.6.26   | 增加MemWrite控制信号**********/  
  output logic MemWrite,         //数据存储器写使能
  /*****************************************************************/
  /*v1.2 | 233  | 2020.6.26   | 增加load,R,beq指令译码及PCjump,immToALU,MemToReg控制信号； */
  output logic MemToReg,        //写入到寄存器堆的数据选择器的数据选择信号
  /**************************************************************************************/
  /********* v1.3 | 233  | 2020.6.27   | 增加R,beq指令译码及immToALU,PCjump控制信号*******/
  output logic immToALU,        //ALU_y数据选择端口数据
  output logic PCjump,          //地址跃迁选择端口数据
  input  logic regReadData1,    //寄存器堆读数据1
  input  logic regReadData2     //寄存器堆读数据2
  /*************************************************************************************/
);
  
/*v1.3 | 233  | 2020.6.28   | 通过加法及与或运算来实现RegReadData1-RegReadData2*********/
 logic tool_1;                      //减法工具数1
 assign tool_1 = 1'b1;       
 logic [31:0] result_SUB;           //工具数减法结果 
 assign result_SUB = regReadData1 + (regReadData2 ^ {32{tool_1}}) + tool_1 ; 
 logic zero_regSub ;
 assign zero_regSub = (result_SUB==0) ? 1:0 ;                                
/*************************************************************************************/  
  
  localparam K = 5+2+1+1+1+1+1;   // 输出的控制信号个数（位数）
                                  //【5：立即数类型；2：ALU功能选择信号；1：寄存器堆写使能
                                  //  1：数据存储器写使能 ； 1：数据选择器的数据选择信号
                                  //  1：ALU_y数据选择端口数据；1：地址跃迁选择端口数据】
  logic [K-1:0] controls;         //声明输出（译出）的控制信号
  assign {PCjump,                 //地址跃迁选择端口数据
          immToALU,               //ALU_y数据选择端口数据
          MemToReg,               //寄存器写入端数据选择器的数据选择信号
          MemWrite,               //数据存储器写使能
          ALUop,                  //ALU功能选择信号
          oImm_type[4:0],         //立即数类型
          oRegWrite               //寄存器堆写使能
          } = controls;
                                  //将译出的控制信号分发给相应组件
  always_comb
    case(iOpcode)
      /*v1.3 | 233  | 2020.6.27   | 增加R,beq指令译码及immToALU,PCjump控制信号；*/
      7'b0010011 : controls <= 12'b0_1_0_0_11_00001_1;  // I-TYPE
      /*- 在下面补充指令译码-*/
      7'b0110011 : controls <= 12'b0_0_0_0_10_00000_1;  //R-Type
      /********* v1.1 | 233  | 2020.6.26   | 增加store指令译码********/
      7'b0100011 : controls <= 12'b0_1_x_1_00_00010_0;  //Stroe
      /**************************************************************/
      7'b0000011 : controls <= 12'b0_1_1_0_00_00001_1;  //Load
      7'b1100011 : 
        /**********
        case(regReadData1-regReadData2)
          8'h00000000:controls <= 12'b1_0_x_0_01_00100_0;  //Branch 
          default:    controls <= 12'b0_0_x_0_01_00100_0;
         **********/
        /*v1.3|233|2020.6.28|通过加法及与或运算来实现RegReadData1-RegReadData2*/        
        case(zero_regSub) //答辩的时候被老师指出了问题，本来误写成tool_1了
          1      :controls <= 12'b1_0_x_0_01_00100_0;  //Branch 
          default:controls <= 12'b0_0_x_0_01_00100_0;
        endcase  
         /*******************************************************************/
      /*-  ...... -*/
      /***********************************************************************/
      default:    controls <= {K{1'b0}}; // illegal opcode
    endcase

endmodule

