module async_fifo #(parameter DEPTH = 16, WIDTH = 39) ( // DEPTH FOR THIS VERSION SHOULD ALWAYS BE A POWER OF 2
    input logic i_Asynch_FIFO_wr_clk,
    input logic i_Asynch_FIFO_rd_clk,

    input logic i_Asynch_FIFO_rd_rstn,
    input logic i_Asynch_FIFO_wr_rstn,

    input logic [WIDTH-1:0] i_Asynch_FIFO_data_in,
    output logic [WIDTH-1:0] o_Asynch_FIFO_data_out,

    input logic i_Asynch_FIFO_rd_en,
    input logic i_Asynch_FIFO_wr_en,

    output logic o_Asynch_FIFO_full,
    output logic o_Asynch_FIFO_empty,
    output logic o_Asynch_FIFO_buf_release
    
);

localparam N = $clog2(DEPTH);

logic [N:0]  rd_ptr, wr_ptr; // Read and Write Pointers (binary)

logic [N:0]  rd_ptr_gray, wr_ptr_gray; // Read and Write Pointers (gray)

logic [N:0]  rd_ptr_gray_FF1, wr_ptr_gray_FF1; 
logic [N:0]  rd_ptr_gray_FF2, wr_ptr_gray_FF2; 

//extra signal to represent the buf release for credit generator update 


logic rd_en_FF1,rd_en_FF2 ;
assign o_Asynch_FIFO_buf_release = rd_en_FF2;

////////////////////////////////////////////////////////////////////////

assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1); // Binary to Gray code read ptr

assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1); // Binary to Gray code write ptr

assign o_Asynch_FIFO_full = (wr_ptr_gray[N-2:0]==rd_ptr_gray_FF2[N-2:0]) && (wr_ptr_gray[N :N-1] == ~rd_ptr_gray_FF2[N : N-1]);

assign o_Asynch_FIFO_empty = (wr_ptr_gray_FF2 == rd_ptr_gray);

logic [WIDTH-1:0] FIFO [0:DEPTH-1];


// WRITE DOMAIN

always_ff @(posedge i_Asynch_FIFO_wr_clk or negedge i_Asynch_FIFO_wr_rstn) begin

    if (!i_Asynch_FIFO_wr_rstn)
        wr_ptr <= 0;

    else if (!o_Asynch_FIFO_full && i_Asynch_FIFO_wr_en) begin

        FIFO[wr_ptr[N-1:0]] <= i_Asynch_FIFO_data_in;
        wr_ptr <= wr_ptr + 1;
        
    end

end


//READ DOMAIN

always_ff @(posedge i_Asynch_FIFO_rd_clk or negedge i_Asynch_FIFO_rd_rstn) begin

    if (!i_Asynch_FIFO_rd_rstn)
        rd_ptr <= 0;

    else if (!o_Asynch_FIFO_empty && i_Asynch_FIFO_rd_en) begin

        o_Asynch_FIFO_data_out <= FIFO[rd_ptr[N-1:0]];
        rd_ptr <= rd_ptr + 1;     
    end

end

// 2-FF WRITE PTR

always_ff @(posedge i_Asynch_FIFO_rd_clk or negedge i_Asynch_FIFO_rd_rstn) begin

    if (!i_Asynch_FIFO_rd_rstn) begin

        wr_ptr_gray_FF1 <= 0;
        wr_ptr_gray_FF2 <= 0;
    end
    
    else begin

        wr_ptr_gray_FF1 <= wr_ptr_gray;
        wr_ptr_gray_FF2 <= wr_ptr_gray_FF1;
    end
  
end

// 2-FF READ PTR

always_ff @(posedge i_Asynch_FIFO_wr_clk or negedge i_Asynch_FIFO_wr_rstn) begin

    if (!i_Asynch_FIFO_wr_rstn) begin

        rd_ptr_gray_FF1 <= 0;
        rd_ptr_gray_FF2 <= 0;
    end
    
    else begin

        rd_ptr_gray_FF1 <= rd_ptr_gray;
        rd_ptr_gray_FF2 <= rd_ptr_gray_FF1;
    end
  
end

// 2-FF READ en for o_Asynch_FIFO_buf_release logic 
always_ff @(posedge i_Asynch_FIFO_wr_clk or negedge i_Asynch_FIFO_wr_rstn) begin

    if (!i_Asynch_FIFO_wr_rstn) begin

        rd_en_FF1 <= 0;
        rd_en_FF2 <= 0;
    end
    
    else begin

        rd_en_FF1 <= i_Asynch_FIFO_rd_en;
        rd_en_FF2 <= rd_en_FF1;
    end
  
end

endmodule