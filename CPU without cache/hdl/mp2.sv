import rv32i_types::*;

module mp2
(
    input clk,
    input rst,
    input mem_resp,
    input rv32i_word mem_rdata,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
    output rv32i_word mem_address,
    output rv32i_word mem_wdata
);

/******************* Signals Needed for RVFI Monitor *************************/
logic load_pc;
logic load_ir;
logic load_regfile;
logic load_mar;
logic load_mdr;
logic load_data_out;

rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic br_en;
logic [4:0] rs1;
logic [4:0] rs2;
alu_ops aluop;
branch_funct3_t cmpop;

rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word regfilemux_out;
rv32i_word marmux_out;
rv32i_word alu_out;
rv32i_word mar_out;
rv32i_word cmpmux_out;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word pc_out;
rv32i_word pcmux_out;
rv32i_word mdrreg_out;

logic [31:0] i_imm;
logic [31:0] s_imm;
logic [31:0] b_imm;
logic [31:0] u_imm;
logic [31:0] j_imm;
logic [4:0] rd;

rv32i_word store_data;
rv32i_word g_wdata;


/*****************************************************************************/

/**************************** Control Signals ********************************/
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
marmux::marmux_sel_t marmux_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
/*****************************************************************************/

/* Instantiate MP 1 top level blocks here */

// Keep control named `control` for RVFI Monitor
control control(
    .clk(clk),
    .rst(rst),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .br_en(br_en),
    .rs1(rs1),
    .rs2(rs2),
    .mem_resp(mem_resp),
    .pcmux_sel(pcmux_sel),
    .alumux1_sel(alumux1_sel),
    .alumux2_sel(alumux2_sel),
    .regfilemux_sel(regfilemux_sel),
    .marmux_sel(marmux_sel),
    .cmpmux_sel(cmpmux_sel),
    .aluop(aluop),
    .load_pc(load_pc),
    .load_ir(load_ir),
    .load_regfile(load_regfile),
    .load_mar(load_mar),
    .load_mdr(load_mdr),
    .load_data_out(load_data_out),
    .mem_read(mem_read),  
    .mem_write(mem_write),
    .mem_byte_enable(mem_byte_enable),
    .cmpop(cmpop),
    .mar_out(mar_out),
    .store_data(store_data),
    .rs2_out(rs2_out)
);

// Keep datapath named `datapath` for RVFI Monitor
datapath datapath(
    .clk(clk),
    .rst(rst),
    .mem_rdata(mem_rdata),
    .g_wdata(g_wdata),
    .load_mdr(load_mdr),
    .load_ir(load_ir),
    .load_pc(load_pc),
    .load_regfile(load_regfile),
    .load_mar(load_mar),
    .load_data_out(load_data_out),
    .pcmux_sel(pcmux_sel),
    .alumux1_sel(alumux1_sel),
    .alumux2_sel(alumux2_sel),
    .regfilemux_sel(regfilemux_sel),
    .marmux_sel(marmux_sel),
    .cmpmux_sel(cmpmux_sel),
    .aluop(aluop),
    .cmpop(cmpop),
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .br_en(br_en),
    .mem_address(mem_address),
    .mem_wdata(mem_wdata),
    .rs1(rs1),
    .rs2(rs2),
    .alumux1_out(alumux1_out),
    .alumux2_out(alumux2_out),
    .regfilemux_out(regfilemux_out),
    .marmux_out(marmux_out),
    .alu_out(alu_out),
    .cmpmux_out(cmpmux_out),
    .rs1_out(rs1_out),
    .rs2_out(rs2_out),
    .pc_out(pc_out),
    .pcmux_out(pcmux_out),
    .mdrreg_out(mdrreg_out),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm),
    .rd(rd),
    .mar_out(mar_out),
    .store_data(store_data),
    .mem_byte_enable(mem_byte_enable)
);


endmodule : mp2
