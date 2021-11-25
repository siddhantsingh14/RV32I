/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input logic clk,
    input logic rst,
    input logic [31:0] mem_address,
    input logic mem_read,
    input logic mem_write,
    input pmem_resp,
    output logic mem_resp,
    output logic pmem_read,
    output logic pmem_write,


    output logic data1_in_sel,
    output logic data2_in_sel,
    output logic [1:0] way1_wr_sel,
    output logic [1:0] way2_wr_sel,
    output logic cache_out_sel,
    output logic [1:0] pmem_mux_sel,
    output logic load_tag1,
    output logic load_tag2,
    output logic load_lru,
    output logic load_dirty1,
    output logic load_dirty2,
    output logic load_valid1,
    output logic load_valid2,
    output logic read_tag1,
    output logic read_tag2,
    output logic read_lru,
    output logic read_dirty1,
    output logic read_dirty2,
    output logic read_valid1,
    output logic read_valid2,
    output logic read_way1,
    output logic read_way2,
    output logic valid1_in,
    output logic valid2_in,
    output logic lru_input,
    output logic dirty1_in,
    output logic dirty2_in,

    input logic [23:0] tag1,
    input logic [23:0] tag2,
    input logic lru,
    input logic valid1_out,
    input logic valid2_out,
    input logic dirty1_out,
    input logic dirty2_out,
    input logic [255:0] way1_data_in,  
    input logic [255:0] way2_data_in,  
    input logic [255:0] way1_data_out,
    input logic [255:0] way2_data_out,
    input logic [31:0] write_en1,  
    input logic [31:0] write_en2 
);
logic hit1, hit2;
logic hit;
logic miss;

assign hit1 = ((tag1 == mem_address[31:8]) & valid1_out);
assign hit2 = ((tag2 == mem_address[31:8]) & valid2_out);
assign hit = (hit1 | hit2);
assign miss = ~hit;


function void set_defaults();
    data1_in_sel=1'b0;
    data2_in_sel=1'b0;
    way1_wr_sel=2'b00;
    way2_wr_sel=2'b00;
    cache_out_sel=1'b0;
    pmem_mux_sel=2'b00;
    load_tag1=1'b0;
    load_tag2=1'b0;
    load_lru=1'b0;
    pmem_write=1'b0;
    load_dirty1=1'b0;
    load_dirty2=1'b0;
    load_valid1=1'b0;
    load_valid2=1'b0;
    read_tag1=1'b0;
    read_tag2=1'b0;
    read_lru=1'b0;
    read_dirty1=1'b0;
    read_dirty2=1'b0;
    read_valid1=1'b0;
    read_valid2=1'b0;
    read_way1=1'b0;
    read_way2=1'b0;
    valid1_in=1'b0;
    valid2_in=1'b0;
    lru_input=1'b0;
    mem_resp=1'b0;
    pmem_read=1'b0;
    dirty1_in=1'b0;
    dirty2_in=1'b0;
endfunction

enum int unsigned {
    polling,
    hit_check,
    read_miss,
    write_back,
    write_cacheline
} state, next_states;

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    unique case(state)
        polling:    begin
            read_tag1=1'b1;
            read_tag2=1'b1;
            read_lru=1'b1;
            // read_dirty1=1'b1;
            // read_dirty2=1'b1;
            read_valid1=1'b1;
            read_valid2=1'b1;
            read_way1=1'b1;
            read_way2=1'b1;
            way1_wr_sel=2'b00;
            way2_wr_sel=2'b00;
        end

        hit_check:   begin
            if(mem_read)    begin   //READ
                if(hit) begin
                    if(hit1)    begin
                        read_lru=1'b1;
                        load_lru=1'b1;  //load the lru 
                        lru_input = 1'b0;   //hit was in cacheline 1, so set LRU to 0 to indicate the MRU
                        way1_wr_sel=2'b00;  //read hit case so set the wr_en to 0's, datain to the data_arr doesnt matter
                        cache_out_sel=1'b0; //take the cacheline_out from cacheline1
                    end
                    else if(hit2)   begin
                        read_lru=1'b1;
                        load_lru=1'b1;  //load the lru 
                        lru_input = 1'b1;   //hit was in cacheline 1, so set LRU to 0 to indicate the MRU
                        way2_wr_sel=2'b00;  //read hit case so set the wr_en to 0's
                        cache_out_sel=1'b1; //take the cacheline_out from cacheline2
                    end
                    mem_resp=1'b1;
                end
                else if(miss)   begin
                    if(~valid1_out) begin   //cacheline1 is not valid so evict it
                        read_tag1=1'b1;
                        // load_tag1=1'b1;

                        read_way1=1'b1;
                        data1_in_sel=1'b0;  //setting datain for cacheline1
                        way1_wr_sel=2'b01;  //miss case
                        pmem_read=1'b1;
                        pmem_write=1'b0;

                    end
                    else if(~valid2_out) begin   //cacheline2 is not valid so evict it
                        read_tag2=1'b1;
                        // load_tag2=1'b1;

                        read_way2=1'b1;
                        data2_in_sel=1'b0;  //setting datain for cacheline1
                        way2_wr_sel=2'b01;  //miss case
                        pmem_read=1'b1;
                        pmem_write=1'b0;
                    end
                    else if(lru) begin   //cacheline2 is MRU so evict cacheline1
                        if(dirty1_out)  begin
                            pmem_mux_sel=1'b01;
                            pmem_read=1'b0;
                            pmem_write=1'b1;
                            cache_out_sel=1'b0; //telling the memory that take the memory of cacheline 2 and write it in memory because its dirty
                        end
                        else if(~dirty1_out)    begin
                            read_tag1=1'b1;
                            // load_tag1=1'b1;

                            read_way1=1'b1;
                            data1_in_sel=1'b0;  //setting datain for cacheline1
                            way1_wr_sel=2'b01;  //miss case
                            pmem_read=1'b1;
                            pmem_write=1'b0;
                        end
                    end
                    else if(~lru) begin   //cacheline1 is MRU so evict cachelin2
                        if(dirty2_out)  begin
                            pmem_mux_sel=1'b10;
                            pmem_read=1'b0;
                            pmem_write=1'b1;
                            cache_out_sel=1'b1; //telling the memory that take the memory of cacheline 2 and write it in memory because its dirty
                        end
                        else if(~dirty2_out)    begin
                            read_tag2=1'b1;
                            // load_tag2=1'b1;

                            read_way2=1'b1;
                            data2_in_sel=1'b0;  //setting datain for cacheline1
                            way2_wr_sel=2'b01;  //miss case
                            pmem_read=1'b1;
                            pmem_write=1'b0;
                        end 
                    end
                end
            end
            else if(mem_write)  begin   //WRITE
                if(hit) begin
                    if(hit1)    begin
                        read_lru=1'b1;
                        load_lru=1'b1;  //load the lru 
                        lru_input = 1'b0;   //hit was in cacheline 1, so set LRU to 0 to indicate the MRU
                        way1_wr_sel=2'b10;  //write hit case
                        // cache_out_sel=1'b0; //take the cacheline_out from cacheline1
                        data1_in_sel=1'b1;
                        dirty1_in=1'b1;
                        read_dirty1=1'b1;
                        load_dirty1=1'b1;
                    end
                    else if(hit2)   begin
                        read_lru=1'b1;
                        load_lru=1'b1;  //load the lru 
                        lru_input = 1'b1;   //hit was in cacheline 1, so set LRU to 0 to indicate the MRU
                        way2_wr_sel=2'b10;  //write hit case
                        // cache_out_sel=1'b1; //take the cacheline_out from cacheline2
                        data2_in_sel=1'b1;
                        dirty2_in=1'b1;
                        read_dirty2=1'b1;
                        load_dirty2=1'b1;
                    end
                    mem_resp=1'b1;
                end
                else if(miss)   begin
                    if(~valid1_out) begin   //cacheline1 is not valid so evict it
                        read_tag1=1'b1;
                        // load_tag1=1'b1;

                        read_way1=1'b1;
                        data1_in_sel=1'b0;  //setting datain for cacheline1
                        way1_wr_sel=2'b01;  //miss case
                        pmem_read=1'b1;
                        pmem_write=1'b0;

                    end
                    else if(~valid2_out) begin   //cacheline2 is not valid so evict it
                        read_tag2=1'b1;
                        // load_tag2=1'b1;

                        read_way2=1'b1;
                        data2_in_sel=1'b0;  //setting datain for cacheline1
                        way2_wr_sel=2'b01;  //miss case
                        pmem_read=1'b1;
                        pmem_write=1'b0;
                    end
                    else if(lru) begin   //cacheline2 is MRU so evict cacheline1
                        if(dirty1_out)  begin
                            pmem_mux_sel=1'b01;
                            pmem_read=1'b0;
                            pmem_write=1'b1;
                            cache_out_sel=1'b0; //telling the memory that take the memory of cacheline 2 and write it in memory because its dirty
                        end
                        else if(~dirty1_out)    begin
                            read_tag1=1'b1;
                            // load_tag1=1'b1;

                            read_way1=1'b1;
                            data1_in_sel=1'b0;  //setting datain for cacheline1
                            way1_wr_sel=2'b01;  //miss case
                            pmem_read=1'b1;
                            pmem_write=1'b0;
                        end
                    end
                    else if(~lru) begin   //cacheline1 is MRU so evict cachelin2
                        if(dirty2_out)  begin
                            pmem_mux_sel=1'b10;
                            pmem_read=1'b0;
                            pmem_write=1'b1;
                            cache_out_sel=1'b1; //telling the memory that take the memory of cacheline 2 and write it in memory because its dirty
                        end
                        else if(~dirty2_out)    begin
                            read_tag2=1'b1;
                            // load_tag2=1'b1;

                            read_way2=1'b1;
                            data2_in_sel=1'b0;  //setting datain for cacheline1
                            way2_wr_sel=2'b01;  //miss case
                            pmem_read=1'b1;
                            pmem_write=1'b0;
                        end 
                    end
                end
            end
            
        end

        read_miss:  begin
            if(~valid1_out) begin   //cacheline1 is not valid so evict it
                read_lru=1'b1;
                load_lru=1'b1;
                lru_input=1'b0; //cacheline1 is MRU

                read_tag1=1'b1;
                load_tag1=1'b1;  
                
                read_valid1=1'b1;
                load_valid1=1'b1;
                valid1_in=1'b1; //setting valid of cacheline1 to high
                cache_out_sel=1'b0;
                mem_resp=1'b1;

                dirty1_in=1'b0;
                read_dirty1=1'b1;
                load_dirty1=1'b1;
            end
            else if(~valid2_out) begin   //cacheline2 is not valid so evict it
                read_lru=1'b1;
                load_lru=1'b1;
                lru_input=1'b1; //cacheline2 is MRU
                
                read_tag2=1'b1;
                load_tag2=1'b1; 

                read_valid2=1'b1;
                load_valid2=1'b1;
                valid2_in=1'b1; //setting valid of cacheline1 to high
                
                cache_out_sel=1'b1;
                mem_resp=1'b1;

                dirty2_in=1'b0;
                read_dirty2=1'b1;
                load_dirty2=1'b1;
            end
            else if(lru) begin   //cacheline2 is MRU so evict cacheline1
                read_lru=1'b1;
                load_lru=1'b1;
                lru_input=1'b0;

                read_tag1=1'b1;
                load_tag1=1'b1; 
                
                read_valid1=1'b1;
                load_valid1=1'b1;
                valid1_in=1'b1; //setting valid of cacheline1 to high
                cache_out_sel=1'b0;
                mem_resp=1'b1;

                dirty1_in=1'b0;
                read_dirty1=1'b1;
                load_dirty1=1'b1;
            end
            else if(~lru) begin   //cacheline1 is MRU so evict cachelin2
                read_lru=1'b1;
                load_lru=1'b1;
                lru_input=1'b1;

                read_tag2=1'b1;
                load_tag2=1'b1; 
                
                read_valid2=1'b1;
                load_valid2=1'b1;
                valid2_in=1'b1; //setting valid of cacheline1 to high
                cache_out_sel=1'b1;
                mem_resp=1'b1;

                dirty2_in=1'b0;
                read_dirty2=1'b1;
                load_dirty2=1'b1;
            end
        end
        write_back: begin
            if(lru) begin
                read_tag1=1'b1;
                load_tag1=1'b1;
                pmem_read=1'b1;
                read_way1=1'b1;
                data1_in_sel=1'b0;  
                way1_wr_sel=2'b01;  
            end
            else if(~lru)   begin
                read_tag2=1'b1;
                load_tag2=1'b1;
                pmem_read=1'b1;
                read_way2=1'b1;
                data2_in_sel=1'b0;  
                way2_wr_sel=2'b01;
            end
        end
        write_cacheline:  begin
            if(~valid1_out) begin   //cacheline1 is not valid so evict it
                read_lru=1'b1;
                load_lru=1'b1;
                lru_input=1'b0; //cacheline1 is MRU

                read_tag1=1'b1;
                load_tag1=1'b1; 
                
                read_valid1=1'b1;
                load_valid1=1'b1;
                valid1_in=1'b1; //setting valid of cacheline1 to high
                
                data1_in_sel=1'b1;  
                way1_wr_sel=2'b10;
                mem_resp=1'b1;

                dirty1_in=1'b1;
                read_dirty1=1'b1;
                load_dirty1=1'b1;
            end
            else if(~valid2_out) begin   //cacheline2 is not valid so evict it
                read_lru=1'b1;
                load_lru=1'b1;
                lru_input=1'b1; //cacheline2 is MRU

                read_tag2=1'b1;
                load_tag2=1'b1; 
                
                read_valid2=1'b1;
                load_valid2=1'b1;
                valid2_in=1'b1; //setting valid of cacheline1 to high
                
                data2_in_sel=1'b1;  
                way2_wr_sel=2'b10;
                mem_resp=1'b1;

                dirty2_in=1'b1;
                read_dirty2=1'b1;
                load_dirty2=1'b1;
            end
            else if(lru) begin   //cacheline2 is MRU so evict cacheline1
                read_lru=1'b1;
                load_lru=1'b1;
                lru_input=1'b0;
                
                read_tag1=1'b1;
                load_tag1=1'b1; 
                
                read_valid1=1'b1;
                load_valid1=1'b1;
                valid1_in=1'b1; //setting valid of cacheline1 to high
                
                data1_in_sel=1'b1;  
                way1_wr_sel=2'b10;
                mem_resp=1'b1;

                dirty1_in=1'b1;
                read_dirty1=1'b1;
                load_dirty1=1'b1;
            end
            else if(~lru) begin   //cacheline1 is MRU so evict cachelin2
                read_lru=1'b1;
                load_lru=1'b1;
                lru_input=1'b1;
                
                read_tag2=1'b1;
                load_tag2=1'b1; 

                read_valid2=1'b1;
                load_valid2=1'b1;
                valid2_in=1'b1; //setting valid of cacheline1 to high
                
                data2_in_sel=1'b1;  
                way2_wr_sel=2'b10;
                mem_resp=1'b1;

                dirty2_in=1'b1;
                read_dirty2=1'b1;
                load_dirty2=1'b1;
            end
        end
    endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
    next_states = state;
    case(state)
        polling:    begin
            if(mem_read)
                next_states = hit_check;
            else if (mem_write)
                next_states = hit_check;
        end
        hit_check: begin
            if(hit) //Any hit
                next_states = polling;
            else if(miss)   begin
                if(mem_read)    begin   //READ MISS
                    if(lru==1'b0 && dirty2_out==1'b1) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                        if(pmem_resp)       //need to evict cl2 so checking if that cacheline is dirty or not
                            next_states = write_back;    //it is so go to writeback
                        else
                            next_states = hit_check;
                    end

                    else if(lru==1'b1 && dirty1_out==1'b1) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                        if(pmem_resp)       //need to evict cl1 so checking if that cacheline is dirty or not
                            next_states = write_back;    //it is so go to writeback
                        else
                            next_states = hit_check;
                    end
                    else if(~valid1_out | ~valid2_out) begin //valid check means the chance of the cacheline is not dirty. so we dont need to go to write back 
                        if(pmem_resp)
                            next_states = read_miss;
                        else
                            next_states = hit_check;
                    end

                    else if(lru==1'b0 && dirty2_out==1'b0) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                        if(pmem_resp)       //need to evict cl2 so checking if that cacheline is dirty or not
                            next_states = read_miss;    //its not so go to read_miss
                        else
                            next_states = hit_check;
                    end

                    else if(lru==1'b1 && dirty1_out==1'b0) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                        if(pmem_resp)       //need to evict cl1 so checking if that cacheline is dirty or not
                            next_states = read_miss;    //its not so go to read_miss
                        else
                            next_states = hit_check;
                    end

                    // else if(lru==1'b0 && dirty2_out==1'b1) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                    //     if(pmem_resp)       //need to evict cl2 so checking if that cacheline is dirty or not
                    //         next_states = write_back;    //it is so go to writeback
                    //     else
                    //         next_states = hit_check;
                    // end

                    // else if(lru==1'b1 && dirty1_out==1'b1) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                    //     if(pmem_resp)       //need to evict cl1 so checking if that cacheline is dirty or not
                    //         next_states = write_back;    //it is so go to writeback
                    //     else
                    //         next_states = hit_check;
                    // end
                end

                else if(mem_write)    begin //WRITE MISS
                    if(lru==1'b0 && dirty2_out==1'b1) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                        if(pmem_resp)       //need to evict cl2 so checking if that cacheline is dirty or not
                            next_states = write_back;    //it is so go to writeback
                        else
                            next_states = hit_check;
                    end

                    else if(lru==1'b1 && dirty1_out==1'b1) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                        if(pmem_resp)       //need to evict cl1 so checking if that cacheline is dirty or not
                            next_states = write_back;    //it is so go to writeback
                        else
                            next_states = hit_check;
                    end
                    
                    else if(~valid1_out | ~valid2_out) begin //valid check means the chance of the cacheline is not dirty. so we dont need to go to write back 
                        if(pmem_resp)
                            next_states = write_cacheline;
                        else
                            next_states = hit_check;
                    end

                    else if(lru==1'b0 && dirty2_out==1'b0) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                        if(pmem_resp)       //need to evict cl2 so checking if that cacheline is dirty or not
                            next_states = write_cacheline;    //its not so go to read_miss
                        else
                            next_states = hit_check;
                    end

                    else if(lru==1'b1 && dirty1_out==1'b0) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                        if(pmem_resp)       //need to evict cl1 so checking if that cacheline is dirty or not
                            next_states = write_cacheline;    //its not so go to read_miss
                        else
                            next_states = hit_check;
                    end

                    // else if(lru==1'b0 && dirty2_out==1'b1) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                    //     if(pmem_resp)       //need to evict cl2 so checking if that cacheline is dirty or not
                    //         next_states = write_back;    //it is so go to writeback
                    //     else
                    //         next_states = hit_check;
                    // end

                    // else if(lru==1'b1 && dirty1_out==1'b1) begin //checking lru and dirty on eviction cases to see if we need to writeback or not
                    //     if(pmem_resp)       //need to evict cl1 so checking if that cacheline is dirty or not
                    //         next_states = write_back;    //it is so go to writeback
                    //     else
                    //         next_states = hit_check;
                    // end
                end
                
            end
        end

        read_miss: next_states = polling;
        write_back: begin
            if(mem_read)    begin
                if(pmem_resp)     
                    next_states = read_miss;
                else
                    next_states = write_back;
            end
            else if(mem_write)    begin
                if(pmem_resp)     
                    next_states = write_cacheline;
                else
                    next_states = write_back;
            end
        end
        write_cacheline:next_states = polling;
        default: next_states = polling;
    endcase

end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if(rst)
        state <= polling;
    else
        state <= next_states;
end


endmodule : cache_control
