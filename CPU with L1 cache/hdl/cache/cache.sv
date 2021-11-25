/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,
    //between CPU and cache
    input logic [31:0] mem_address,
    output logic [31:0] mem_rdata,
    input logic [31:0] mem_wdata,
    input logic mem_read,
    input logic mem_write,
    input logic [3:0] mem_byte_enable,
    output logic mem_resp,    
    //between cache and Memory interface
    output logic [31:0] pmem_address,
    input logic [255:0] pmem_rdata,
    output logic [255:0] pmem_wdata,
    output logic pmem_read,
    output logic pmem_write,
    input logic pmem_resp
);

logic [255:0] bus_wdata;
logic [255:0] cacheline_out;
logic [255:0] bus_rdata;
logic [31:0] mem_byte_enable256;
logic data1_in_sel;
logic data2_in_sel;
logic [1:0] way1_wr_sel;
logic [1:0] way2_wr_sel;
logic cache_out_sel;
logic [1:0] pmem_mux_sel;
logic load_tag1;
logic load_tag2;
logic load_lru;
logic load_dirty1;
logic load_dirty2;
logic load_valid1;
logic load_valid2;
logic read_tag1;
logic read_tag2;
logic read_lru;
logic read_dirty1;
logic read_dirty2;
logic read_valid1;
logic read_valid2;
logic read_way1;
logic read_way2;
logic valid1_in;
logic valid2_in;
logic lru_input;
logic dirty1_in;
logic dirty2_in;
logic [23:0] tag1;
logic [23:0] tag2;
logic lru;
logic valid1_out;
logic valid2_out;
logic dirty1_out;
logic dirty2_out;
logic [255:0] way1_data_in;
logic [255:0] way2_data_in;  
logic [255:0] way1_data_out;
logic [255:0] way2_data_out;
logic [31:0] write_en1;
logic [31:0] write_en2;




assign pmem_wdata = cacheline_out;
assign bus_rdata = cacheline_out;

cache_control control
(
    .clk(clk),
    .rst(rst),
    .mem_address(mem_address),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .pmem_resp(pmem_resp),
    .mem_resp(mem_resp),
    .pmem_read(pmem_read),
    .pmem_write(pmem_write),


    .data1_in_sel(data1_in_sel),
    .data2_in_sel(data2_in_sel),
    .way1_wr_sel(way1_wr_sel),
    .way2_wr_sel(way2_wr_sel),
    .cache_out_sel(cache_out_sel),
    .pmem_mux_sel(pmem_mux_sel),
    .load_tag1(load_tag1),
    .load_tag2(load_tag2),
    .load_lru(load_lru),
    .load_dirty1(load_dirty1),
    .load_dirty2(load_dirty2),
    .load_valid1(load_valid1),
    .load_valid2(load_valid2),
    .read_tag1(read_tag1),
    .read_tag2(read_tag2),
    .read_lru(read_lru),
    .read_dirty1(read_dirty1),
    .read_dirty2(read_dirty2),
    .read_valid1(read_valid1),
    .read_valid2(read_valid2),
    .read_way1(read_way1),
    .read_way2(read_way2),
    .valid1_in(valid1_in),
    .valid2_in(valid2_in),
    .lru_input(lru_input),
    .dirty1_in(dirty1_in),
    .dirty2_in(dirty2_in),

    .tag1(tag1),
    .tag2(tag2),
    .lru(lru),
    .valid1_out(valid1_out),
    .valid2_out(valid2_out),
    .dirty1_out(dirty1_out),
    .dirty2_out(dirty2_out),
    .way1_data_in(way1_data_in),  
    .way2_data_in(way2_data_in),  
    .way1_data_out(way1_data_out),
    .way2_data_out(way2_data_out),
    .write_en1(write_en1),  
    .write_en2(write_en2)
);

cache_datapath datapath
(
    .clk(clk),
    .rst(rst),

    .mem_address(mem_address),
    .mem_byte_enable256(mem_byte_enable256),
    .pmem_address(pmem_address),
    .pmem_rdata(pmem_rdata), //cacheline_in
    .bus_wdata(bus_wdata), //bus_in
    .cacheline_out(cacheline_out),
    .mem_read(mem_read),

    .data1_in_sel(data1_in_sel),
    .data2_in_sel(data2_in_sel),
    .way1_wr_sel(way1_wr_sel),
    .way2_wr_sel(way2_wr_sel),
    .cache_out_sel(cache_out_sel),
    .pmem_mux_sel(pmem_mux_sel),

    .load_tag1(load_tag1),
    .load_tag2(load_tag2),
    .load_lru(load_lru),
    .load_dirty1(load_dirty1),
    .load_dirty2(load_dirty2),
    .load_valid1(load_valid1),
    .load_valid2(load_valid2),
    .read_tag1(read_tag1),
    .read_tag2(read_tag2),
    .read_lru(read_lru),
    .read_dirty1(read_dirty1),
    .read_dirty2(read_dirty2),
    .read_valid1(read_valid1),
    .read_valid2(read_valid2),
    .read_way1(read_way1),
    .read_way2(read_way2),
    .valid1_in(valid1_in),
    .valid2_in(valid2_in),
    .lru_input(lru_input),
    .dirty1_in(dirty1_in),
    .dirty2_in(dirty2_in),
    .tag1(tag1),
    .tag2(tag2),
    .lru(lru),
    .valid1_out(valid1_out),
    .valid2_out(valid2_out),
    .dirty1_out(dirty1_out),
    .dirty2_out(dirty2_out),
    .way1_data_in(way1_data_in),
    .way2_data_in(way2_data_in),  
    .way1_data_out(way1_data_out),
    .way2_data_out(way2_data_out),
    .write_en1(write_en1),
    .write_en2(write_en2)
);

bus_adapter bus_adapter
(
    .mem_wdata256(bus_wdata),
    .mem_rdata256(bus_rdata),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(mem_byte_enable256),
    .address(mem_address)
);

endmodule : cache
