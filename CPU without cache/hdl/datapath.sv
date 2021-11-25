`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module cmp_register(
    input branch_funct3_t cmpop,
    input rv32i_word rs1_out,
    input rv32i_word cmpmux_out,
    output logic br_en
);

    always_comb 
    begin
        unique case (cmpop)
            rv32i_types::beq: br_en=(rs1_out == cmpmux_out);
            rv32i_types::bne: br_en=(rs1_out != cmpmux_out);
            rv32i_types::blt: br_en=($signed(rs1_out) < $signed(cmpmux_out));
            rv32i_types::bge: br_en=($signed(rs1_out) >= $signed(cmpmux_out));
            rv32i_types::bltu: br_en=(rs1_out < cmpmux_out);
            rv32i_types::bgeu: br_en=(rs1_out >= cmpmux_out);
            // default: `BAD_MUX_SEL;
        endcase
    end 
endmodule

module store_align(
    input logic [2:0] funct3,
    input rv32i_word rs2_out,
    output rv32i_word store_data,
    input rv32i_word alu_out,
    input logic [3:0] mem_byte_enable
);

    // always_comb 
    // begin
    //     unique case (funct3)
    //         rv32i_types::sb:    begin
    //             unique case (mem_byte_enable)
    //                 4'b0001:  store_data = rs2_out;   //data needs to be stored in the lowest addr, so no need to shift
    //                 4'b0010:  store_data = rs2_out<<8;   //data needs to be stored in the second lowest addr, so shift left by 1 byte
    //                 4'b0100:  store_data = rs2_out<<16;   //data needs to be stored in the second highest addr, so shift left by 2 byte
    //                 4'b1000:  store_data = rs2_out<<24;   //data needs to be stored in the highest addr, so shift left by 3 byte
    //             endcase
    //         end
    //         rv32i_types::sh:    begin
    //             unique case (mem_byte_enable)
    //                 4'b0011:  store_data = rs2_out;   //data needs to be stored in the lower half, so no need to shift
    //                 4'b1100:  store_data = rs2_out<<16;   //data needs to be stored in the upper half, so shift left by 2 byte
    //                 default:    store_data = 32'b0;
    //             endcase
    //         end
    //         rv32i_types::sw: store_data = rs2_out;
    //     endcase
    // end 
    always_comb 
    begin
        unique case (funct3)
            rv32i_types::sb:    begin
                unique case (alu_out[1:0])
                    2'b00:  store_data = rs2_out;   //data needs to be stored in the lowest addr, so no need to shift
                    2'b01:  store_data = rs2_out<<8;   //data needs to be stored in the second lowest addr, so shift left by 1 byte
                    2'b10:  store_data = rs2_out<<16;   //data needs to be stored in the second highest addr, so shift left by 2 byte
                    2'b11:  store_data = rs2_out<<24;   //data needs to be stored in the highest addr, so shift left by 3 byte
                endcase
            end
            rv32i_types::sh:    begin
                unique case (alu_out[1:0])
                    2'b00:  store_data = rs2_out;   //data needs to be stored in the lower half, so no need to shift
                    2'b10:  store_data = rs2_out<<16;   //data needs to be stored in the upper half, so shift left by 2 byte
                    default:    store_data = 32'b0;
                endcase
            end
            rv32i_types::sw: store_data = rs2_out;
        endcase
    end 
endmodule

module datapath
(
    input clk,
    input rst,
    input rv32i_word mem_rdata,
    output rv32i_word g_wdata, // signal used by RVFI Monitor
    /* You will need to connect more signals to your datapath module*/
    input logic load_mdr,
    input logic load_ir,
    input logic load_pc,
    input logic load_regfile,
    input logic load_mar,
    input logic load_data_out,
    input pcmux::pcmux_sel_t pcmux_sel,
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input marmux::marmux_sel_t marmux_sel,
    input cmpmux::cmpmux_sel_t cmpmux_sel,
    input alu_ops aluop,
    input branch_funct3_t cmpop,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output rv32i_opcode opcode,
    output logic br_en,
    output rv32i_word mem_address,
    output rv32i_word mem_wdata,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output rv32i_word mar_out,
    output rv32i_word alumux1_out,
    output rv32i_word alumux2_out,
    output rv32i_word regfilemux_out,
    output rv32i_word marmux_out,
    output rv32i_word alu_out,
    output rv32i_word cmpmux_out,
    output rv32i_word rs1_out,
    output rv32i_word rs2_out,
    output rv32i_word pc_out,
    output rv32i_word pcmux_out,
    output rv32i_word mdrreg_out,
    output logic [31:0] i_imm,
    output logic [31:0] s_imm,
    output logic [31:0] b_imm,
    output logic [31:0] u_imm,
    output logic [31:0] j_imm,
    output logic [4:0] rd,
    output rv32i_word store_data,
    input logic [3:0] mem_byte_enable

);


/******************* Signals Needed for RVFI Monitor *************************/


assign mem_address = {mar_out[31:2], 2'b00};

assign g_wdata = mem_wdata; //not sure about the monitor


store_align STalign(
    .funct3(funct3),
    .rs2_out(rs2_out),
    .store_data(store_data),
    .alu_out(alu_out),
    .mem_byte_enable(mem_byte_enable)
    );

/*****************************************************************************/

/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
    .clk(clk),
    .rst(rst),
    .load(load_ir),
    .in(mdrreg_out),
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd)
    );

register MDR(
    .clk  (clk),
    .rst (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

register MAR(
    .clk  (clk),
    .rst (rst),
    .load (load_mar),
    .in   (marmux_out),
    .out  (mar_out)
);

register mem_data_out(
    .clk  (clk),
    .rst (rst),
    .load (load_data_out),
    .in   (store_data), //store_data holds all the possibilities for store byte and half word addressibility
    .out  (mem_wdata)
);

cmp_register CMP(
    .cmpop(cmpop),
    .rs1_out(rs1_out),
    .cmpmux_out(cmpmux_out),
    .br_en(br_en)
); 

alu ALU(
    .aluop(aluop),
    .a(alumux1_out),
    .b(alumux2_out),
    .f(alu_out)
);

regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(load_regfile),
    .in(regfilemux_out),
    .src_a(rs1), 
    .src_b(rs2), 
    .dest(rd),
    .reg_a(rs1_out), 
    .reg_b(rs2_out)
);

pc_register PC(
    .clk(clk),
    .rst(rst),
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
); 


/*****************************************************************************/

/******************************* ALU and CMP *********************************/
/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog.  In this case, we actually use
    // Offensive programming --- making simulation halt with a fatal message
    // warning when an unexpected mux select value occurs

    unique case (pcmux_sel) //PC MUX
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = {alu_out[31:2], 2'b00};  //the updated pc val with the aligned addr of the instr to be jumped to
        default: `BAD_MUX_SEL;
    endcase

    unique case (marmux_sel)    //MAR MUX
        marmux::pc_out: marmux_out = pc_out;
        marmux::alu_out: marmux_out= alu_out;
        default: `BAD_MUX_SEL;
    endcase

    unique case (cmpmux_sel)    //CMP MUX   //these sel come as input to the datapth module
        cmpmux::rs2_out: cmpmux_out = rs2_out;  //cmpmux_out is output of the module
        cmpmux::i_imm: cmpmux_out= i_imm;
        default: `BAD_MUX_SEL;
    endcase

    unique case (alumux1_sel)    //ALU1 MUX
        alumux::rs1_out: alumux1_out = rs1_out;
        alumux::pc_out: alumux1_out= pc_out;
        default: `BAD_MUX_SEL;
    endcase

    unique case (alumux2_sel)    //ALU2 MUX
        alumux::i_imm: alumux2_out = i_imm;
        alumux::u_imm: alumux2_out = u_imm;
        alumux::b_imm: alumux2_out = b_imm;
        alumux::s_imm: alumux2_out = s_imm;
        alumux::j_imm: alumux2_out = j_imm;
        alumux::rs2_out: alumux2_out = rs2_out;
        default: `BAD_MUX_SEL;
    endcase

    unique case (regfilemux_sel)    //
        regfilemux::alu_out: regfilemux_out = alu_out;
        regfilemux::br_en: regfilemux_out = {31'b0,br_en};
        regfilemux::u_imm: regfilemux_out = u_imm;
        regfilemux::lw: regfilemux_out = mdrreg_out;    //the 3rd input of regfile mux is the output of the MDR register
        regfilemux::pc_plus4: regfilemux_out = pc_out +4;
        regfilemux::lb: begin
            unique case(mar_out[1:0])  //byte aligned
                2'b00:  regfilemux_out = {{24{mdrreg_out[7]}},mdrreg_out[7:0]}; //SEXT mdrreg_out and store byte, need to clarify if only LSB byte is stored
                2'b01:  regfilemux_out = {{24{mdrreg_out[15]}},mdrreg_out[15:8]}; //SEXT mdrreg_out and store byte, need to clarify if only LSB byte is stored
                2'b10:  regfilemux_out = {{24{mdrreg_out[23]}},mdrreg_out[23:16]}; //SEXT mdrreg_out and store byte, need to clarify if only LSB byte is stored
                2'b11:  regfilemux_out = {{24{mdrreg_out[31]}},mdrreg_out[31:24]}; //SEXT mdrreg_out and store byte, need to clarify if only LSB byte is stored
            endcase
        end
        regfilemux::lbu:    begin
            unique case(mar_out[1:0])  //byte aligned
                2'b00:  regfilemux_out = {24'b0,mdrreg_out[7:0]}; //ZEXT mdrreg_out and store byte, need to clarify if only LSB byte is stored
                2'b01:  regfilemux_out = {24'b0,mdrreg_out[15:8]}; //ZEXT mdrreg_out and store byte, need to clarify if only LSB byte is stored
                2'b10:  regfilemux_out = {24'b0,mdrreg_out[23:16]}; //ZEXT mdrreg_out and store byte, need to clarify if only LSB byte is stored
                2'b11:  regfilemux_out = {24'b0,mdrreg_out[31:24]}; //ZEXT mdrreg_out and store byte, need to clarify if only LSB byte is stored
            endcase
        end
        regfilemux::lh: begin
            unique case(mar_out[1:0])  //2 byte aligned
                2'b00:  regfilemux_out = {{16{mdrreg_out[15]}},mdrreg_out[15:0]};   //SEXT load the lower half
                2'b10:  regfilemux_out = {{16{mdrreg_out[31]}},mdrreg_out[31:16]}; //SEXT load the upper half
                default: regfilemux_out = 32'b0;    //not aligned correctly
            endcase
        end
        regfilemux::lhu: begin
            unique case(mar_out[1:0])  //2 byte aligned
                2'b00:  regfilemux_out = {16'b0,mdrreg_out[15:0]};   //ZEXT load the lower half
                2'b10:  regfilemux_out = {16'b0,mdrreg_out[31:16]}; //ZEXT load the upper half
                default: regfilemux_out = 32'b0;    //not aligned correctly
            endcase
        end
        
        default: `BAD_MUX_SEL;
    endcase

end
/*****************************************************************************/
endmodule : datapath
