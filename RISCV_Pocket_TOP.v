// --------------------------------------------------------------------
//
// 修订历史 :
// --------------------------------------------------------------------
//   版本  | 作者                      | 修改日期   | 所做改变
//   V1.0  | 肖铁军                    | 2017.08.29| 初始版本
//   V1.1  |                           | 2020.06.06| 存储器模块的地址对齐
// --------------------------------------------------------------------

`default_nettype none
module RISCV_Pocket_TOP(

    //////////// CLOCK //////////
    input               CLOCK_50,
    
    //////////// LED //////////
    output       [7:0]  LEDG,
    output       [15:0]  LEDR,
     
    ///////// DEBUG IO ///////////
    input               JTCK,
    input               JTMS,
    input               JTDI,
    output              JTDO
);

    // Virtual Component Declaration
    localparam N_LED = 36;
    localparam N_SW  = 36;
    localparam N_BTN = 20;
    wire [N_LED-1:0] vLED;    // Virtual LED    
    wire [N_SW-1:0]  vSWITCH; // Virtual Switch
    wire [N_BTN-1:0] vBUTTON; // Virtual Button
    // wire [7:0] vSSLED [0:7];  // Virtual seven-segment display          
    wire [7:0]  vSSLED0;    //虚拟七段数码管0          
    wire [7:0]  vSSLED1;    //虚拟七段数码管1
    wire [7:0]  vSSLED2;    //虚拟七段数码管2
    wire [7:0]  vSSLED3;    //虚拟七段数码管3
    wire [7:0]  vSSLED4;    //虚拟七段数码管4
    wire [7:0]  vSSLED5;    //虚拟七段数码管5
    wire [7:0]  vSSLED6;    //虚拟七段数码管6
    wire [7:0]  vSSLED7;    //虚拟七段数码管7

    // Logic level settings of actual component
    // The logic level when the actual button is loosened
    localparam ButtonReleaseLevel = {N_BTN{1'b0}}; 
    // The logical level of the lit segment of actual component
    localparam LightLevelOfSevenSeg = {8{1'b0}}; 
    // The logical level when the actual LED is not lit   
    localparam DarkLevelOfLED = {N_LED{1'b0}};       

    // Actual components connected to virtual components
    assign LEDR[15:0] = vLED[15:0] ^ DarkLevelOfLED;
    assign LEDG[7:0] = vLED[25:18] ^ DarkLevelOfLED;
    assign vSWITCH[N_SW-1:0] = {N_SW{1'b0}};
    assign vBUTTON[N_BTN-1:0] = {N_BTN{1'h0}}; 
    // 该模型机未使用的LED设置为0不点亮
    assign vLED[N_LED-1:0] = {N_LED{1'b0}}; 
    // 该模型机未使用数码管，将其消隐。若将数码管扩展为模型机外设，需删除下面这些代码。
    // assign vSSLED7 = 8'b11111111;
    // assign vSSLED6 = 8'b11111111;
    // assign vSSLED5 = 8'b11111111;
    // assign vSSLED4 = 8'b11111111;
    // assign vSSLED3 = 8'b11111111;
    // assign vSSLED2 = 8'b11111111;
    // assign vSSLED1 = 8'b11111111;
    // assign vSSLED0 = 8'b11111111;	

//---------------------------------------------------------------------------//
    wire TCK;
    GlobalCLK global_TCK(
        .ena (1'b1),
        .inclk (JTCK),
        .outclk (TCK)
    );

    wire CLK_50,CLK_10,CLK_200;
    pll clock_PLL(
        .inclk0 (CLOCK_50),
        .c0 (CLK_50), //50MHz
        .c1 (CLK_10), //10MHz
        .c2 (CLK_200) //200Mhz
    );
    wire CLK = CLK_10;

    wire [N_BTN-1:0] key_bsc;
    wire [N_SW-1:0]  sw_bsc;

//---------------------------------------------------------------------------//

	localparam DATAWIDTH = 32;
	localparam ADDRWIDTH = 32;
    localparam IMADDRWIDTH = 9;
	
    wire cpuReset, cpuClk;
    wire [ADDRWIDTH-1:0] cpuAB, memAB;
    wire cpuWR, memWR;
    wire inta, intr;

    wire scan_clk, scan_in, scan_out;
    wire [1:0] scan_ctrl; 
    
    wire [DATAWIDTH-1:0] cpuWriteData, readData, memWriteData, instruction_code; 
    wire [ADDRWIDTH - 1: 0] current_pc, instruction_addr;
	 wire fetching;
    
    //实例化CPU
    CPU #(.ADDRWIDTH(ADDRWIDTH), .DATAWIDTH(DATAWIDTH)) CPU_RISC (
        .iCPU_Reset(cpuReset),          //CPU复位信号
        .iCPU_Clk(cpuClk),              //CPU时钟信号
        .iReadData(readData),           //数据存储器读数据
        .oWriteData(cpuWriteData),      //数据存储器写数据
        .oAB (cpuAB),                   //数据存储器写地址
        .oWR (cpuWR),                   //数据存储器写使能
        // 连接调试器的信号
        .oIM_Addr(instruction_addr),    //指令存储器地址
        .iIM_Data(instruction_code),    //从模块外面过来的指令
        .oCurrent_PC(current_pc),       //当前PC地址
		.oFetch(fetching),
        .iScanClk(scan_clk),
        .iScanIn(scan_in),
        .oScanOut(scan_out),
        .iScanCtrl(scan_ctrl)
    );
    
    //实例化数据存储器                 
	RAM #(.ADDRWIDTH(6), .DATAWIDTH(DATAWIDTH)) MM      
	(   
		.iClk(CLK),                 //系统时钟信号
		.iWR(memWR),                //存储器写使能
		.iAddress(memAB[31:2]),     //存储器只能按字访问
        .iWriteData(memWriteData),  //数据存储器写入数据
        .oReadData(readData)        //数据存储器读出数据
    );
    

//----------------- On-chip Debug -------------------------------------------//
    JuTAG_CPU  #(.ADDRWIDTH(ADDRWIDTH), .DATAWIDTH(DATAWIDTH))  jutag
    (              
        .TCK(TCK),
        .TMS(JTMS),
        .TDI(JTDI),
        .TDO(JTDO),
        // 与IO连接的虚拟元件
        .iLED(vLED),   
        .iSWITCH(vSWITCH),
        .oSW_BSC(sw_bsc),
        .iBUTTON(vBUTTON),
        .oKEY_BSC(key_bsc),
        .iSSLED0(vSSLED0),          
        .iSSLED1(vSSLED1),          
        .iSSLED2(vSSLED2),          
        .iSSLED3(vSSLED3),          
        .iSSLED4(vSSLED4),          
        .iSSLED5(vSSLED5),          
        .iSSLED6(vSSLED6),          
        .iSSLED7(vSSLED7), 
        // 系统总线
        .iWR(cpuWR),
        .oWR(memWR),
        .iCpuAB(cpuAB),
        .oSysAB(memAB),
        .iCPUWriteData(cpuWriteData),
        .iMemReadData(readData),
        .oMemWriteData(memWriteData),
        // 调试与运行控制
        .iClock(CLK),
        .oCPU_Reset(cpuReset),
        .oCPU_Clk(cpuClk),
        .iROM_Addr(instruction_addr[IMADDRWIDTH+1:2]),
        .oROM_Data(instruction_code),
        .iCurrent_PC(current_pc),
        .iROM_Addr(),
        .oROM_Data(),
		.iFetch(fetching),
        .oScanClk(scan_clk),
        .oScanIn(scan_in),
        .iScanOut(scan_out),
        .oScanCtrl(scan_ctrl)
    );

endmodule
