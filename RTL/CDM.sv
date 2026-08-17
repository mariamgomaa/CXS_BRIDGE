module central_data_memory #(
    parameter int DATA_WIDTH = 17,
    parameter int ADDR_WIDTH = 8,
    parameter int DEPTH      = 512

)(

    input  logic                  i_cdm_clk,
    input  logic                  i_cdm_rst_n,


    input  logic [ADDR_WIDTH-1:0] i_cdm_wr_address,
    input  logic                  i_cdm_addr_valid,
    input  logic [DATA_WIDTH-1:0] i_cdm_wdata,
    input  logic                  i_cdm_data_valid,
    input  logic                  i_cdm_wr_en,


    input  logic                  i_cdm_rd_en,
    input  logic [ADDR_WIDTH-1:0] i_cdm_rd_address,
    output logic [DATA_WIDTH-1:0] o_cdm_rd_data,
    output logic                  o_cdm_rd_valid,
    output logic                  o_cdm_write_done,
    output logic                  o_cdm_write_error,
    output logic                  o_cdm_read_error
);
    integer i;
    // Internal memory
    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];
    // Memory controller
    always_ff @(posedge i_cdm_clk or negedge i_cdm_rst_n) begin
        if (!i_cdm_rst_n) begin
            for(i=0;i<DEPTH;i=i+1)
            begin
                memory[i]<= 'b0;
            end
            o_cdm_rd_data   <= '0;
            o_cdm_rd_valid  <= 1'b0;
            o_cdm_write_done  <= 1'b0;
            o_cdm_write_error <= 1'b0;
            o_cdm_read_error  <= 1'b0;
        end
        else begin
            //================================================
            // Default status signals
            //================================================
            o_cdm_rd_valid  <= 1'b0;
            o_cdm_write_done  <= 1'b0;
            o_cdm_write_error <= 1'b0;
            o_cdm_read_error <= 1'b0;

            if (i_cdm_wr_en) begin
                // All write conditions must be valid
                if (i_cdm_addr_valid &&
                    i_cdm_data_valid ) begin
                    memory[i_cdm_wr_address] <= i_cdm_wdata;
                    o_cdm_write_done <= 1'b1;
                end
                else begin
                    // Invalid write request
                    o_cdm_write_error <= 1'b1;
                end
            end

            if (i_cdm_rd_en) begin
                    o_cdm_rd_data <= memory[i_cdm_rd_address];
                    o_cdm_rd_valid <= 1'b1;
            end
        end
    end

endmodule