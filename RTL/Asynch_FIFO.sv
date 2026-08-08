module async_fifo #(parameter DEPTH = 16, WIDTH = 39) ( // DEPTH FOR THIS VERSION SHOULD ALWAYS BE A POWER OF 2
    input logic wr_clk,
    input logic rd_clk,

    input logic rd_rstn,
    input logic wr_rstn,

    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,

    input logic rd_en,
    input logic wr_en,

    output logic full,
    output logic empty
    
);

localparam N = $clog2(DEPTH);

logic [N:0]  rd_ptr, wr_ptr; // Read and Write Pointers (binary)

logic [N:0]  rd_ptr_gray, wr_ptr_gray; // Read and Write Pointers (gray)

logic [N:0]  rd_ptr_gray_FF1, wr_ptr_gray_FF1; 
logic [N:0]  rd_ptr_gray_FF2, wr_ptr_gray_FF2; 

assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1); // Binary to Gray code read ptr

assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1); // Binary to Gray code write ptr

assign full = (wr_ptr_gray[N-2:0]==rd_ptr_gray_FF2[N-2:0]) && (wr_ptr_gray[N :N-1] == ~rd_ptr_gray_FF2[N : N-1]);

assign empty = (wr_ptr_gray_FF2 == rd_ptr_gray);

logic [WIDTH-1:0] FIFO [0:DEPTH-1];


// WRITE DOMAIN

always_ff @(posedge wr_clk or negedge wr_rstn) begin

    if (!wr_rstn)
        wr_ptr <= 0;

    else if (!full && wr_en) begin

        FIFO[wr_ptr[N-1:0]] <= data_in;
        wr_ptr <= wr_ptr + 1;
        
    end

end


//READ DOMAIN

always_ff @(posedge rd_clk or negedge rd_rstn) begin

    if (!rd_rstn)
        rd_ptr <= 0;

    else if (!empty && rd_en) begin

        data_out <= FIFO[rd_ptr[N-1:0]];
        rd_ptr <= rd_ptr + 1;
        
    end

end

// 2-FF WRITE PTR

always_ff @(posedge rd_clk or negedge rd_rstn) begin

    if (!rd_rstn) begin

        wr_ptr_gray_FF1 <= 0;
        wr_ptr_gray_FF2 <= 0;
    end
    
    else begin

        wr_ptr_gray_FF1 <= wr_ptr_gray;
        wr_ptr_gray_FF2 <= wr_ptr_gray_FF1;
    end
  
end

// 2-FF READ PTR

always_ff @(posedge wr_clk or negedge wr_rstn) begin

    if (!wr_rstn) begin

        rd_ptr_gray_FF1 <= 0;
        rd_ptr_gray_FF2 <= 0;
    end
    
    else begin

        rd_ptr_gray_FF1 <= rd_ptr_gray;
        rd_ptr_gray_FF2 <= rd_ptr_gray_FF1;
    end
  
end

endmodule