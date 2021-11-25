import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
    input clk,
    input rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input mem_resp,
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
    output logic mem_read,  //added from here
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
    output branch_funct3_t cmpop,
    input rv32i_word mar_out,
    input rv32i_word rs2_out,
    input rv32i_word store_data
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: begin
                    if(mar_out[0]==1'b1)    rmask = 4'b0000;  //operation is not valid as the alu_out is not aligned correctly, must be divisible by 2
                    else    rmask = (4'b0011 << mar_out[1:0]);  //can adopt state of 1100 and 0011 so shift left twice or dont shift
                end
                // rmask = mem_byte_enable; /* Modify for MP1 Final */ 
                lb, lbu: rmask = (4'b0001 << mar_out[1:0]); /* Modify for MP1 Final */ 
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: begin
                    if(mar_out[0]==1'b1)    wmask = 4'b0000;  //operation is not valid as the alu_out is not aligned correctly, must be divisible by 2
                    else    wmask = (4'b0011 << mar_out[1:0]);  //can adopt state of 1100 and 0011 so shift left twice or dont shift
                end
                // wmask = mem_byte_enable; /* Modify for MP1 Final */ 
                sb: wmask = (4'b0001 << mar_out[1:0]); /* Modify for MP1 Final */ 
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    fetch1,
    fetch2,
    fetch3,
    decode,
    s_br,
    s_auipc,
    s_lui,
    s_imm,
    s_lw,
    s_sw,
    s_lw1,
    s_sw1,
    s_lw2,
    s_sw2,
    s_reg,
    s_jal,
    s_jalr
} state, next_states;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
    load_pc =1'b0;
    load_ir = 1'b0;
    load_regfile = 1'b0;
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_data_out = 1'b0;
    pcmux_sel = pcmux::pc_plus4;
    regfilemux_sel=regfilemux::alu_out;
    marmux_sel = marmux::pc_out;
    cmpmux_sel = cmpmux::rs2_out;
    alumux1_sel =alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
    aluop = alu_ops'(funct3);
    cmpop= branch_funct3_t'(funct3);  //add these signals to the function output
    mem_read = 1'b0;
    mem_write = 1'b0;
    mem_byte_enable = 4'b1111;
    // store_data = rs2_out;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    load_regfile = 1'b1;
    regfilemux_sel = sel;
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
    load_mar = 1'b1;
    marmux_sel = sel;
endfunction

function void loadMDR();
    load_mdr = 1'b1;
endfunction

/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
                               logic setop = 1'b0, alu_ops op = alu_add);
    /* Student code here */
    alumux1_sel = sel1;
    alumux2_sel = sel2;
    aluop = op;


    if (setop)
        aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    cmpmux_sel = sel;
    cmpop = op;
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    unique case(state)
        fetch1: loadMAR(marmux::pc_out);
        fetch2: begin
            loadMDR();
            mem_read=1;
        end
        fetch3: load_ir = 1'b1;
        decode:;
        s_imm: begin
            case(funct3)
                rv32i_types::add,rv32i_types::axor,rv32i_types::aor,rv32i_types::aand,rv32i_types::sll: begin  //ADDI,XORI,ORI,ANDI,SLLI
                    load_regfile =1'b1;
                    load_pc=1'b1;   //set pcmux sel to pc+4 and alu1 to rs1_out and alu2 to i_imm
                    pcmux_sel = pcmux::pc_plus4;
                    alumux1_sel = alumux::rs1_out;
                    alumux2_sel = alumux::i_imm;
                    aluop =  alu_ops'(funct3);
                    regfilemux_sel = regfilemux::alu_out; 
                end
                rv32i_types::slt: begin  //SLTI
                    load_regfile =1'b1; //add pcmux sel fn
                    load_pc=1'b1;
                    cmpop =  rv32i_types::blt;
                    pcmux_sel = pcmux::pc_plus4;
                    alumux1_sel = alumux::rs1_out;
                    alumux2_sel = alumux::i_imm;
                    aluop =  rv32i_types::alu_add;
                    regfilemux_sel = regfilemux::br_en;
                    cmpmux_sel = cmpmux::i_imm;
                end
                rv32i_types::sltu: begin  //SLTIU
                    load_regfile =1'b1;
                    load_pc=1'b1;
                    cmpop =  rv32i_types::bltu;
                    regfilemux_sel = regfilemux::br_en;
                    cmpmux_sel = cmpmux::i_imm;
                    // pcmux_sel = pcmux::pc_plus4;
                    // alumux1_sel = alumux::rs1_out;
                    // alumux2_sel = alumux::i_imm; //these are already set by the default value but needed here too
                    // aluop =  rv32i_types::alu_add;
                end
                rv32i_types::sr: begin  //SRLI or SRAI  //for both add rs1_out alu1 and i_imm for alu2 and add pc_sel
                    if(funct7[5]==1'b1) begin   //SRAI
                        load_regfile =1'b1;
                        load_pc=1'b1;
                        aluop =  rv32i_types::alu_sra;
                        pcmux_sel = pcmux::pc_plus4;
                        alumux1_sel = alumux::rs1_out;
                        alumux2_sel = alumux::i_imm;
                        regfilemux_sel = regfilemux::alu_out;
                    end
                    else begin  //SRLI
                        load_regfile =1'b1;
                        load_pc=1'b1;
                        aluop =  rv32i_types::alu_srl;
                        pcmux_sel = pcmux::pc_plus4;
                        alumux1_sel = alumux::rs1_out;
                        alumux2_sel = alumux::i_imm;
                        regfilemux_sel = regfilemux::alu_out;
                    end
                end
            endcase
        end
        s_reg: begin
            case(funct3)
                rv32i_types::add: begin  //ADD and SUB
                    if(funct7[5]==1'b1)    begin   //SUB
                        load_regfile =1'b1;
                        load_pc=1'b1;
                        aluop =  rv32i_types::alu_sub;
                        regfilemux_sel = regfilemux::alu_out;
                        alumux2_sel = alumux::rs2_out;
                        alumux1_sel = alumux::rs1_out;
                        pcmux_sel = pcmux::pc_plus4;    //not sure
                    end
                    else begin  //ADD
                        load_regfile =1'b1;
                        load_pc=1'b1;
                        aluop =  rv32i_types::alu_add;
                        regfilemux_sel = regfilemux::alu_out;
                        alumux2_sel = alumux::rs2_out;
                        alumux1_sel = alumux::rs1_out;
                        pcmux_sel = pcmux::pc_plus4;
                    end
                end
                rv32i_types::slt: begin  //SLT
                    load_regfile =1'b1;
                    load_pc=1'b1;
                    cmpop =  rv32i_types::blt;
                    aluop =  rv32i_types::alu_add;
                    regfilemux_sel = regfilemux::br_en;
                    cmpmux_sel = cmpmux::rs2_out;
                    alumux2_sel = alumux::rs2_out;
                    alumux1_sel = alumux::rs1_out;
                    pcmux_sel = pcmux::pc_plus4;
                end
                rv32i_types::sltu: begin  //SLTU
                    load_regfile =1'b1;
                    load_pc=1'b1;
                    cmpop =  rv32i_types::bltu;
                    aluop =  rv32i_types::alu_add;
                    regfilemux_sel = regfilemux::br_en;
                    cmpmux_sel = cmpmux::rs2_out;
                    alumux2_sel = alumux::rs2_out;
                    alumux1_sel = alumux::rs1_out;
                    pcmux_sel = pcmux::pc_plus4;
                end
                rv32i_types::sr: begin  //SRLI or SRAI
                    if(funct7[5]==1'b1) begin   //SRAI
                        load_regfile =1'b1;
                        load_pc=1'b1;
                        aluop =  rv32i_types::alu_sra;
                        alumux2_sel = alumux::rs2_out;
                        regfilemux_sel = regfilemux::alu_out;
                        alumux1_sel = alumux::rs1_out;
                        pcmux_sel = pcmux::pc_plus4;
                    end
                    else begin  //SRLI
                        load_regfile =1'b1;
                        load_pc=1'b1;
                        aluop =  rv32i_types::alu_srl;
                        alumux2_sel = alumux::rs2_out;
                        regfilemux_sel = regfilemux::alu_out;
                        alumux1_sel = alumux::rs1_out;
                        pcmux_sel = pcmux::pc_plus4;
                    end
                end
                rv32i_types::axor,rv32i_types::aor,rv32i_types::aand,rv32i_types::sll:  begin   //XOR, OR, AND, SLL
                    load_regfile =1'b1;
                    load_pc=1'b1;
                    aluop =  alu_ops'(funct3);
                    regfilemux_sel = regfilemux::alu_out;
                    alumux2_sel = alumux::rs2_out;
                    alumux1_sel = alumux::rs1_out;
                    pcmux_sel = pcmux::pc_plus4;
                end
            endcase
        end
        s_br:   begin
            pcmux_sel = pcmux:: pcmux_sel_t'(br_en);    //if br_en is 0, then it sets the pc_sel to pc+4, it is 1, then its setsto alu_out
            load_pc =1'b1;
            alumux1_sel = alumux::pc_out;
            alumux2_sel = alumux::b_imm;    //the alu_out is b_imm so set to pc, check if you need an if statement to set this val and need to compare it to br_en to actually set this, may not be needed
            aluop = rv32i_types::alu_add;
            cmpop= branch_funct3_t'(funct3);

        end
        s_lui: begin
            load_regfile = 1'b1;
            load_pc=1'b1;
            regfilemux_sel = regfilemux::u_imm;
            pcmux_sel = pcmux::pc_plus4;
        end
        s_auipc: begin
            alumux1_sel = alumux::pc_out;
            alumux2_sel = alumux::u_imm;
            load_regfile = 1'b1;
            load_pc=1'b1;
            aluop = rv32i_types::alu_add;
            pcmux_sel = pcmux::pc_plus4;
        end
        s_lw:   begin   //same as calc_addr for load
            aluop = rv32i_types::alu_add;
            alumux1_sel = alumux::rs1_out;
            alumux2_sel = alumux::i_imm;
            loadMAR(marmux::alu_out);
        end
        s_lw1:  begin
            loadMDR();
            mem_read=1'b1;
        end
        s_lw2:  begin
            case(funct3)
                rv32i_types::lb:    regfilemux_sel = regfilemux::lb;
                rv32i_types::lh:    regfilemux_sel = regfilemux::lh;
                rv32i_types::lw:    regfilemux_sel = regfilemux::lw;
                rv32i_types::lbu:    regfilemux_sel = regfilemux::lbu;
                rv32i_types::lhu:    regfilemux_sel = regfilemux::lhu;
                default:    regfilemux_sel = regfilemux::lw;
            endcase
            // regfilemux_sel = regfilemux::lw;
            load_regfile=1'b1;
            load_pc=1'b1;
            pcmux_sel = pcmux::pc_plus4;
        end
        s_sw:   begin   //calc address for store
            aluop = rv32i_types::alu_add;
            alumux1_sel = alumux::rs1_out;
            alumux2_sel = alumux::s_imm;
            loadMAR(marmux::alu_out);
            
            load_data_out=1'b1;
        end
        s_sw1:  begin
            mem_write=1'b1;
            unique case(funct3)
                rv32i_types::sb:    mem_byte_enable = (4'b0001 << mar_out[1:0]);  //it can left shift 4 times to achieve byte granularity. alu_out still holds the low 2 bits so can achieve byte gran.
                rv32i_types::sh:    begin
                    if(mar_out[0]==1'b1)    mem_byte_enable = 4'b0000;  //operation is not valid as the alu_out is not aligned correctly, must be divisible by 2
                    else    mem_byte_enable = (4'b0011 << mar_out[1:0]);  //can adopt state of 1100 and 0011 so shift left twice or dont shift
                end
                rv32i_types::sw:    mem_byte_enable = 4'b1111;  //write all bytes
            endcase //changed this from sw1 to sw
            // load_data_out=1'b1;
        end
        s_sw2:  begin
            load_pc=1'b1;
            pcmux_sel = pcmux::pc_plus4;
        end

        s_jal:  begin
            load_regfile = 1'b1;
            load_pc=1'b1;
            alumux1_sel = alumux::pc_out;
            alumux2_sel = alumux::j_imm;
            aluop = rv32i_types::alu_add;   //adding pc + j_imm to find the new target addr
            pcmux_sel = pcmux::alu_mod2;    //since the alu_out is going to hold the new target addr, we are 2 byte aligning alu val so when it becomes the next pc, it is aligned
            regfilemux_sel = regfilemux::pc_plus4;  //current pc+4 , next instr of current sequence needs to be written to rd
        end

        s_jalr:  begin
            load_regfile = 1'b1;
            load_pc=1'b1;
            alumux1_sel = alumux::rs1_out;
            alumux2_sel = alumux::i_imm;
            aluop = rv32i_types::alu_add;   //adding rs1_out + i_imm to find the new target addr
            pcmux_sel = pcmux::alu_mod2;    //since the alu_out is going to hold the new target addr, we are 2 byte aligning alu val so when it becomes the next pc, it is aligned
            regfilemux_sel = regfilemux::pc_plus4;  //current pc+4 , next instr of current sequence needs to be written to rd
        end
    endcase

end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
    next_states = state;
    case(state)
        fetch1: next_states = fetch2;
        fetch2: if(mem_resp)  next_states= fetch3;
        fetch3: next_states = decode;
        decode: begin
            case(opcode)
                op_jal: next_states = s_jal;
                op_jalr: next_states = s_jalr;
                op_reg: next_states = s_reg;
                op_lui: next_states = s_lui;
                op_auipc:   next_states = s_auipc;
                op_imm: next_states = s_imm;
                op_br: next_states = s_br;
                op_load:    next_states = s_lw;
                op_store:   next_states = s_sw; //same as calc_addr

                default:    $display("Wrong opcode = %0h", opcode);
            endcase
        end
        s_lui: next_states = fetch1;
        s_reg: next_states = fetch1;
        s_auipc: next_states = fetch1;
        s_imm: next_states = fetch1;
        s_br: next_states = fetch1;
        s_lw:   next_states = s_lw1;
        s_lw1: if(mem_resp) next_states = s_lw2;
        s_lw2: next_states = fetch1;
        s_sw:   next_states = s_sw1;
        s_sw1: if(mem_resp) next_states = s_sw2;
        s_sw2: next_states = fetch1;
        s_jal: next_states = fetch1;
        s_jalr:    next_states = fetch1;
        default: next_states = fetch1;
    endcase

end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if(rst)
        state <= fetch1;
    else
        state <= next_states;
end

endmodule : control
