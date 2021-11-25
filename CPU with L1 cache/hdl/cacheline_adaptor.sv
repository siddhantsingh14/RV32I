// module cacheline_adaptor
// (
//     input clk,
//     input reset_n,

//     // Port to LLC (Lowest Level Cache)
//     input logic [255:0] line_i,
//     output logic [255:0] line_o,
//     input logic [31:0] address_i,
//     input read_i,
//     input write_i,
//     output logic resp_o,

//     // Port to memory
//     input logic [63:0] burst_i,
//     output logic [63:0] burst_o,
//     output logic [31:0] address_o,
//     output logic read_o,
//     output logic write_o,
//     input resp_i
// );


// enum logic [3:0]{
//     reset, rd_burst_1, rd_burst_2, rd_burst_3, rd_burst_4, done_rd, wr_burst_1, wr_burst_2, wr_burst_3, wr_burst_4, done_wr, wr_wait, rest1_wr /*rest2_wr*/
// } curr_state, next_state;

// logic [255:0] adapter_buf;

// always_ff @(posedge clk)    begin
//     if(~reset_n)
//         curr_state <= reset;
//     else
//         curr_state <=next_state;
// end

// always_comb begin
//     next_state = curr_state;

//     unique case(curr_state)
//     reset:  begin
//         if(read_i==1)   next_state = rd_burst_1;
//         else if(write_i==1)   next_state = wr_wait;
//     end
//     rd_burst_1:    if(resp_i ==1)   next_state = rd_burst_2;
//     rd_burst_2:    if(resp_i ==1)   next_state = rd_burst_3;
//     rd_burst_3:    if(resp_i ==1)   next_state = rd_burst_4;
//     rd_burst_4:    if(resp_i ==1)   next_state = done_rd;
//     wr_wait:       next_state = rest1_wr;
//     rest1_wr:      next_state = wr_burst_1;
//     // rest2_wr:      if(resp_i==1)   next_state = wr_burst_1;
//     wr_burst_1:    if(resp_i ==1)   next_state = wr_burst_2;
//     wr_burst_2:    if(resp_i ==1)   next_state = wr_burst_3;
//     wr_burst_3:    if(resp_i ==1)   next_state = wr_burst_4;
//     wr_burst_4:    if(resp_i ==1)   next_state = done_wr;
    
//     done_rd:   next_state = reset;
//     done_wr: next_state =reset; 
//     default: ;
//     endcase

//     case(curr_state)
//     reset:  begin
//         read_o =1'b0;   //according to assertation in the task for reset in testbench
//         write_o = 1'b0;
//         // read_i = 1'b0;
//         // write_i = 1'b0;
//         // // reset_n = 1'b0;
//         // resp_i = 1'b0;
//         resp_o = 1'b0;
//     end
//     rd_burst_1:   begin
//         address_o= address_i;
//         // if(read_i)  begin   //that means the llc is requesting to read 
//             read_o=1'b1;    //llc lets the dram know that we need to read memory
//             line_o[64*0+:64]= burst_i;
//         // end
//     end
//     rd_burst_2:   begin
        
//         line_o[64*1+:64]= burst_i;
//     end
//     rd_burst_3:    line_o[64*2+:64]= burst_i;
//     rd_burst_4:   begin
//         resp_o=1'b1;
//         line_o[64*3+:64]= burst_i;
//         // read_o=1'b0;
//     end
//     done_rd:  read_o=1'b0;//resp_o=1'b0;

//     wr_wait: begin
//         address_o = address_i;
//         write_o = 1'b1;
//     end
//     rest1_wr:    ;
//     // rest2_wr:    burst_o=line_i[64*0+:64];
//     wr_burst_1:   begin
//         burst_o=line_i[64*0+:64];
//     end
//     wr_burst_2:   begin
//         burst_o=line_i[64*1+:64];
//     end
//     wr_burst_3:   burst_o=line_i[64*2+:64];
//     wr_burst_4:   begin
//         resp_o=1'b1;
//         burst_o=line_i[64*3+:64];
//     end
//     done_wr:  write_o=1'b0;
//     endcase

// end


// endmodule : cacheline_adaptor


// module cacheline_adaptor
// (
//     input clk,
//     input reset_n,

//     // Port to LLC (Lowest Level Cache)
//     input logic [255:0] line_i,
//     output logic [255:0] line_o,
//     input logic [31:0] address_i,
//     input read_i,
//     input write_i,
//     output logic resp_o,

//     // Port to memory
//     input logic [63:0] burst_i,
//     output logic [63:0] burst_o,
//     output logic [31:0] address_o,
//     output logic read_o,
//     output logic write_o,
//     input resp_i
// );

//     typedef enum bit [2:0] {IDLE, WAITR, WAITW, R, W, DONE} macro_t;
//     struct packed {
//         macro_t macro;
//         logic [1:0] count;
//     } state;
//     localparam logic [1:0] maxcount = 2'b11;


//     logic [255:0] linebuf;
//     logic [31:0] addressbuf;
//     assign line_o = linebuf;
//     assign address_o = addressbuf;
//     assign burst_o = linebuf[64 * state.count +: 64];
//     assign read_o = ((state.macro == WAITR) || (state.macro == R));
//     assign write_o = ((state.macro == WAITW) || (state.macro == W));
//     assign resp_o = state.macro == DONE;
//     enum bit [1:0] {READ_OP, WRITE_OP, NO_OP} op;
//     assign op = read_i ? READ_OP : write_i ? WRITE_OP : NO_OP;

//     always_ff @(posedge clk) begin
//         if (~reset_n) begin
//             state.macro <= IDLE;
//         end
//         else begin
//             case (state.macro)
//             IDLE: begin
//                 case (op)
//                     NO_OP: ;
//                     WRITE_OP: begin
//                         state.macro <= WAITW;
//                         linebuf <= line_i;
//                         addressbuf <= address_i;
//                         state.count <= 2'b00;
//                     end
//                     READ_OP: begin
//                         state.macro <= WAITR;
//                         addressbuf <= address_i;
//                     end
//                 endcase
//             end
//             WAITR: begin
//                 if (resp_i) begin
//                     state.macro <= R;
//                     state.count <= 2'b01;
//                     linebuf[63:0] <= burst_i;
//                 end
//             end
//             WAITW: begin
//                 if (resp_i) begin
//                     state.macro <= W;
//                     state.count <= 2'b01;
//                 end
//             end
//             R: begin
//                 if (state.count == maxcount) begin
//                     state.macro <= DONE;
//                 end
//                 linebuf[64*state.count +: 64] <= burst_i;
//                 state.count <= state.count + 2'b01;
//             end
//             W: begin
//                 if (state.count == maxcount) begin
//                     state.macro <= DONE;
//                 end
//                 state.count <= state.count + 2'b01;
//             end
//             DONE: begin
//                 state.macro <= IDLE;
//             end
//             endcase
//         end
//     end

// endmodule : cacheline_adaptor