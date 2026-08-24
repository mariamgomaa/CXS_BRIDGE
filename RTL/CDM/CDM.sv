module central_data_memory #(
    parameter int DATA_WIDTH    = 17,
    parameter int CONFIG_DATA_W = 32,
    parameter int LOGICAL_ADD_W = 9,
    parameter int DEPTH         = 512
)(
    input  logic                     i_cdm_clk,
    input  logic                     i_cdm_rst_n,

    // Write port
    input  logic [LOGICAL_ADD_W-1:0] i_cdm_wr_address,
    input  logic                     i_cdm_addr_valid,
    input  logic [DATA_WIDTH-1:0]    i_cdm_wdata,
    input  logic                     i_cdm_data_valid,
    input  logic                     i_cdm_wr_en,

    input logic                      i_cdm_cfg_rd_en,
    // Config read port - fixed, always reads location 0 & 1 together,
    // packed into CONFIG_DATA_W bits, sent to the control unit.
    // No address/enable input - it runs every cycle.
    output logic [CONFIG_DATA_W-1:0] o_cdm_cfg_data,
    output logic                     o_cdm_cfg_valid,

    // Application read port - addressable, driven from testbench /
    // application layer, e.g. to check a location before overwriting it.
    input  logic                     i_cdm_app_rd_en,
    input  logic [LOGICAL_ADD_W-1:0] i_cdm_app_rd_address,
    output logic [DATA_WIDTH-1:0]    o_cdm_app_rd_data,
    output logic                     o_cdm_app_rd_valid
);

    integer i;
    // Internal memory
    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    // Memory controller
    always_ff @(posedge i_cdm_clk or negedge i_cdm_rst_n) begin
        if (!i_cdm_rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                memory[i] <= 'b0;
            end
            o_cdm_cfg_data      <= '0;
            o_cdm_cfg_valid     <= 1'b0;
            o_cdm_app_rd_data   <= '0;
            o_cdm_app_rd_valid  <= 1'b0;
        end
        else begin
            //================================================
            // Default status signals
            //================================================
            o_cdm_app_rd_valid <= 1'b0;

            //================================================
            // Write port
            //================================================
            if (i_cdm_wr_en) begin
                // All write conditions must be valid
                if (i_cdm_addr_valid && i_cdm_data_valid) begin
                    memory[i_cdm_wr_address] <= i_cdm_wdata;
                end
            end
            //configration data read port
            if (i_cdm_cfg_rd_en)
            begin
            o_cdm_cfg_data  <= {memory[1][DATA_WIDTH-2:0],
                                memory[0][DATA_WIDTH-2:0]};
            o_cdm_cfg_valid <= 1'b1;
            end
            //================================================
            // Application read port
            //================================================
            if (i_cdm_app_rd_en) begin
                o_cdm_app_rd_data  <= memory[i_cdm_app_rd_address];
                o_cdm_app_rd_valid <= 1'b1;
            end
        end
    end

endmodule