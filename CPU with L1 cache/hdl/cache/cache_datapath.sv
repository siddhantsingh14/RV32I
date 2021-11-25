/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(   //put io for datapath
  input logic clk,
  input logic rst,

  input logic [31:0] mem_address,
  input logic [31:0] mem_byte_enable256,
  output logic [31:0] pmem_address,
  input logic [255:0] pmem_rdata, //cacheline_in
  input logic [255:0] bus_wdata, //bus_in
  output logic [255:0] cacheline_out,
  input logic mem_read,

  input logic data1_in_sel,
  input logic [1:0] pmem_mux_sel,
  input logic data2_in_sel,
  input logic [1:0] way1_wr_sel,
  input logic [1:0] way2_wr_sel,
  input logic cache_out_sel,

  input logic load_tag1,
  input logic load_tag2,
  input logic load_lru,
  input logic load_dirty1,
  input logic load_dirty2,
  input logic load_valid1,
  input logic load_valid2,
  input logic read_tag1,
  input logic read_tag2,
  input logic read_lru,
  input logic read_dirty1,
  input logic read_dirty2,
  input logic read_valid1,
  input logic read_valid2,
  input logic read_way1,
  input logic read_way2,
  input logic valid1_in,
  input logic valid2_in,
  input logic lru_input,
  input logic dirty1_in,
  input logic dirty2_in,
  output logic [23:0] tag1,
  output logic [23:0] tag2,
  output logic lru,
  output logic valid1_out,
  output logic valid2_out,
  output logic dirty1_out,
  output logic dirty2_out,
  output logic [255:0] way1_data_in,  //just to connect these to the top cache
  output logic [255:0] way2_data_in,  
  output logic [255:0] way1_data_out,
  output logic [255:0] way2_data_out,
  output logic [31:0] write_en1,  //just to connect these to the top cache
  output logic [31:0] write_en2

);

// assign pmem_address = {mem_address[31:5],5'b00000}; //aligning the mem address bits

array #(.s_index(3), .width(24))    // the tag bits are 32- 3(bits for idxing the correct set) - 5 (generally for idxing the byte in the cacheline. 32 byte cachline so needs 5 bits) but we have the last 5 bits zero'd
  tag_array1 (
    .clk(clk),
    .rst(rst),
    .read(read_tag1),  //add seperate read signals
    .load(load_tag1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag1)
  );

array #(.s_index(3), .width(24))    // the tag bits are 32- 3(bits for idxing the correct set) - 5 (generally for idxing the byte in the cacheline. 32 byte cachline so needs 5 bits) but we have the last 5 bits zero'd
  tag_array2 (
    .clk(clk),
    .rst(rst),
    .read(read_tag2),
    .load(load_tag2),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag2)
  );

array #(.s_index(3), .width(1)) //tells us which cacheline was most recently accessed. 0 means cacheline1 was accessed most recently
  LRU_array(    //1 means cacheline 2 was accessed most recently
    .clk(clk),
    .rst(rst),
    .read(read_lru),
    .load(load_lru),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(lru_input),
    .dataout(lru)
  );

array #(.s_index(3), .width(1))
  valid_array1(
    .clk(clk),
    .rst(rst),
    .read(read_valid1),
    .load(load_valid1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(valid1_in),
    .dataout(valid1_out)
  );

array #(.s_index(3), .width(1))
  valid_array2(
    .clk(clk),
    .rst(rst),
    .read(read_valid2),
    .load(load_valid2),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(valid2_in),
    .dataout(valid2_out)
  );

array #(.s_index(3), .width(1))
  dirty_array1(
    .clk(clk),
    .rst(rst),
    .read(read_dirty1),
    .load(load_dirty1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(dirty1_in),
    .dataout(dirty1_out)
  );

array #(.s_index(3), .width(1))
  dirty_array2(
    .clk(clk),
    .rst(rst),
    .read(read_dirty2),
    .load(load_dirty2),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(dirty2_in),
    .dataout(dirty2_out)
  );

data_array #(.s_offset(5), .s_index(3))
  cacheline1(
    .clk(clk),
    .rst(rst),
    .read(read_way1),  //set a new read signal for this as well
    .write_en(write_en1),  
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(way1_data_in),
    .dataout(way1_data_out)
  );

data_array #(.s_offset(5), .s_index(3))
  cacheline2(
    .clk(clk),
    .rst(rst),
    .read(read_way2),
    .write_en(write_en2),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(way2_data_in),
    .dataout(way2_data_out)
  );

always_comb begin
  unique case (pmem_mux_sel)
    2'b00: pmem_address = {mem_address[31:5],5'b00000};
    2'b01: pmem_address = {tag1,mem_address[7:5],5'b00000};
    2'b10: pmem_address = {tag2,mem_address[7:5],5'b00000};
    default: pmem_address = {mem_address[31:5],5'b00000};
  endcase
  unique case (data1_in_sel)
    1'b0: way1_data_in = pmem_rdata;
    1'b1: way1_data_in = bus_wdata;
    default: way1_data_in = pmem_rdata;
  endcase

  unique case (way1_wr_sel)
    2'b00: write_en1 = 32'd0; //read case
    2'b01: write_en1 = {32{1'b1}};  //miss case
    2'b10: write_en1 = mem_byte_enable256;  //write hit case
    default: write_en1 = 32'd0;
  endcase

  unique case (data2_in_sel)
    1'b0: way2_data_in = pmem_rdata;
    1'b1: way2_data_in = bus_wdata;
    default: way2_data_in = pmem_rdata;
  endcase

  unique case (way2_wr_sel)
    2'b00: write_en2 = 32'd0; //read case
    2'b01: write_en2 = {32{1'b1}};  //miss case
    2'b10: write_en2 = mem_byte_enable256;  //write hit case
    default: write_en2 = 32'd0;
  endcase

  unique case (cache_out_sel)
    1'b0: cacheline_out = way1_data_out;
    1'b1: cacheline_out = way2_data_out;
    default: cacheline_out = way1_data_out;
  endcase

end

endmodule : cache_datapath
