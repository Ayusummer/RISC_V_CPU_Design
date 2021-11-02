// --------------------------------------------------------------------
// 单周期 RISC-V CPU 模块
// 修订历史 :
// --------------------------------------------------------------------
//   版本 | 作者                      | 修改日期    | 所做改变
//   V1.0 |                          | 2019.02.16  | 初始版本
//   V1.1 |                          | 2019.12.16  | 整理代码
//   V1.2 |                          | 2020.06.06  | 修改扫描链
//   v1.3 |                          | 2020.6.26   | 添加与数据存储器的端口连接    
// --------------------------------------------------------------------
`default_nettype none 
module CPU
 #(
     parameter DATAWIDTH = 32,
     parameter ADDRWIDTH = 32
 )
(
    input  wire iCPU_Reset,                       //CPU复位信号
    input  wire iCPU_Clk,                         //时钟信号
    input  wire [DATAWIDTH-1:0] iReadData,        //数据存储器读数据
    output wire [DATAWIDTH-1:0] oWriteData,       //数据存储器写数据
    output wire [ADDRWIDTH - 1: 0] oAB,           //数据存储器写地址
    output wire oWR,                              //数据存储器写使能
    // 连接调试器的信号                             
    output wire [ADDRWIDTH-1:0] oIM_Addr,         //指令存储器地址
    input  wire [DATAWIDTH-1:0] iIM_Data,         //从模块外面过来的指令
    output wire [ADDRWIDTH-1:0] oCurrent_PC,      //当前PC地址
    output wire oFetch,
    input  wire iScanClk,
    input  wire iScanIn,
    output wire oScanOut,
    input  wire [1:0] iScanCtrl
);

  /** The input port is replaced with an internal signal **/
  wire   clk   = iCPU_Clk;
  wire   reset = iCPU_Reset;

/*************************** Instruction parts 指令部分 *********************************************/
  logic [31:0] pc, nextPC, offsetPC;  //地址，下一个地址，递增数
  logic [31:0] instr_code;            //指令代码
  assign offsetPC = 4;                /*- 仅支持PC+4，增加分支转移指令时需修改 -（后面如果有转移的话就不一定是+4了）*/
  assign nextPC = pc + offsetPC;      //下条指令的地址
  DataReg #(32) pcreg(.iD(nextPC), .oQ(pc), .Clk(clk), .Load(1'b1), .Reset(reset));
                                      //实例化PC所在的32位寄存器
  assign oIM_Addr = pc;               //指令存储器地址（32位2进制数据）
  assign instr_code = iIM_Data;       //指令存储器取出来的指令 
  logic [6:0] op;                     //用于区分指令的类别
  logic [2:0] funct3;                 //用于区分某类指令下的具体指令
  logic [6:0] funct7;                 //用于区分某类指令下的具体指令
  logic [4:0] ra1,ra2,wa;             //寄存器号
  assign funct7 = instr_code[31:25];
  assign ra2    = instr_code[24:20]; 
  assign ra1    = instr_code[19:15]; 
  assign funct3 = instr_code[14:12];
  assign wa     = instr_code[11:7];   //目的寄存器号
  assign op     = instr_code[6:0];    //用于区分指令类别
/***************************************************************************************************/

  /************************************Control unit 控制模块**************************************/
  logic cRegWrite;
  logic [4:0] cImm_type;  //J, U, B, S, I type
  logic [1:0]  cALUctrl;  //ALU的功能选择端口
  logic cMemWrite;        //主译码器译出的数据存储器写使能信号
  //实例化主译码器
  MainDecoder mainDecoder(
    .iOpcode(op),           //opcode判断指令类别
    .oImm_type(cImm_type),  //译出立即数类型
    .oRegWrite(cRegWrite),  //译出寄存器堆写使能信号
    .ALUop(cALUctrl),       //译出ALU功能选择信号（ALU译码器用）
    //v1.3 || 2020.6.26 |修改主译码器实例化语句（增添数据存储器写使能信号） 
    .MemWrite(cMemWrite)    //译出的数据存储器写使能信号
  );
/*************************************************************************************************/


/****************************Immediate number generation 立即数生成模块***************************/
  logic [31:0] immData;     //接收输出的立即数
  ImmeGen  immGen(.iInstruction(instr_code), .iImm_type(cImm_type), .oImmediate(immData));
                            //实例化立即数生成模块
/*************************************************************************************************/


/****************************** Register file 寄存器堆*********************************************/
  logic [31:0] regWriteData, regReadData1, regReadData2;  //写数据和两个读取数据
  RegisterFile_5_32bit regFile(.Clk(clk), 
    .iWE(cRegWrite), .iWA(wa), .iWD(regWriteData), 
    .iRA1(ra1), .oRD1(regReadData1),
    .iRA2(ra2), .oRD2(regReadData2));
  assign regWriteData = aluOut;                     /*- 仅支持将ALU运算结果写入寄存器堆，需修改 -*/
/************************************************************************************************/


/****************************************** ALU *************************************************/
  logic [31:0] alu_y;       //ALU的源数据Y
  logic [31:0] aluOut;      //ALU的结果输出
  logic zero;               //ALU的零标志
  assign alu_y = immData;  /*- 仅支持立即数作为ALU的Y输入，需修改 -*/
  //assign aluOut = regReadData1 + alu_y; assign zero=0; /*- 仅支持加法运算，需用自己设计的ALU模块代替。
  logic [2:0] ALUop;        //ALU功能选择端

  //实例化ALU译码器，将ALU功能选择端的数据译出来
  ALUDecode aludecode(.iData(cALUctrl),   //输入数据ALU功能选择信号
                      .funct7(funct7),    //输入数据funct7
                      .funct3(funct3),    //输入数据funct3
                      .oSeg(ALUop));      //输出数据ALU三个控制信号的集合信号
                                          //即{M0,S1,S0}

  //实例化ALU
  ALU #(32) alu(
    .X(regReadData1),       //寄存器上端口读出来的数据作为ALU的源数据X
    .Y(alu_y),              //ALU的源数据Y
    .ALUop(ALUop),          //ALU功能选择端   
    .F(aluOut),             //ALU的输出结果
    .zero(zero));           //零标志
    /* -*/ 
   /*- 参考如下端口设计ALUop2ctrl模块
  AluDecoder aluDecoder(
    .iALUop(cALUop),
    .iFunct7(funct7),
    .iFunct3(funct3),
    .oALUctrl(cALUctrl)
  ); -*/
/***********************************************************************************************/

/************************v1.3 | | 2020.6.26 | 添加与数据存储器的端口连接  ***********************/  
logic [31:0] memReadData;         //读数据
assign oWR = cMemWrite;           //将控制器产生的写信号传给数据存储器的写信号
assign oAB = aluOut;              //将ALU的输出传给数据存储器作地址
assign oWriteData = regReadData2; //将寄存器堆的第二个读取数据传给数据存储器作写入数据
assign memReadData = iReadData;   /*将数据存储器的数据给数据存储器的读取数据  
                                  （我认为是写在虚拟面板旁边的那里了）*/

/*********************************************************************************************/


/*************-----------------------送给调试器的信号-------------------------****************/
    assign oCurrent_PC = pc;    //当前PC地址
    assign oFetch = 1'b1;       //

    //送入扫描链的控制信号，需要与虚拟面板的信号框相对应
    localparam SIZEWS = 5+2+1+1;      //WS的位宽
    wire [SIZEWS-1:0] WS;
    assign WS = {
                  cMemWrite,          //3_数据存储器的写使能信号
                  cRegWrite,          //2_寄存器堆写使能信号
                  cALUctrl[1:0] ,     //1_ALU功能选择信号
                  cImm_type[4:0]};    //0_指令类型信号

    
    //送入扫描链的数据，需要与虚拟面板的数据框相对应
    localparam SIZEWD = 1 + 32*6 + 5*3 +32;
    wire [SIZEWD-1:0] WD;
    assign WD = {
        regReadData2, //32位 寄存器堆输出2
        aluOut,       //32位ALU输出
        zero,         // 1位 ALU零标志
        immData,      //32位 立即数
        regReadData1, //32位 寄存器堆输出1
        ra2,          // 5位 寄存器堆读地址2  
        ra1,          // 5位 寄存器堆读地址1
        wa,           // 5位 寄存器堆写地址
        instr_code,   //32位 指令码
        pc,           //32位 地址
        nextPC        //32位 下个指令的地址
    };
/*******************************************************************************************/
    //实例化扫描链（不需要了解）
    WatchChain #(.DATAWIDTH(SIZEWS+SIZEWD)) WatchChain_inst(
      .DataIn({WS,WD}), 
      .ScanIn(iScanIn), 
      .ScanOut(oScanOut), 
      .ShiftDR(iScanCtrl[1]), 
      .CaptureDR(iScanCtrl[0]), 
      .TCK(iScanClk)
    );
endmodule
