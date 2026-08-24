// =============================================================================
// cxs_flit_receiver.sv
// =============================================================================

module CXS_flit_receiver #(
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH = 32,

    parameter int CNTL_W =
            (
                3*CXSMAXPAYLOADPERFLIT
            )

) (
    input  logic                        i_CXS_flit_receiver_CXS_CLK,
    input  logic                        i_CXS_flit_receiver_RST_N,

    input  logic                        i_CXS_flit_receiver_CXSVALID,
    input  logic [CXSDATAFLITWIDTH-1:0] i_CXS_flit_receiver_CXSDATA,
    input  logic [CNTL_W-1:0]           i_CXS_flit_receiver_CXSCNTL,

    input logic                       i_CXS_flit_state_valid_recieving,

    output logic                        o_CXS_flit_receiver_flit_valid,
    output logic [CXSDATAFLITWIDTH-1:0] o_CXS_flit_receiver_rx_data,
    output logic [CNTL_W-1:0]           o_CXS_flit_receiver_cxscntl_data
);

    always_ff @(posedge i_CXS_flit_receiver_CXS_CLK or negedge i_CXS_flit_receiver_RST_N) begin
        if (!i_CXS_flit_receiver_RST_N) begin
            o_CXS_flit_receiver_flit_valid     <= 1'b0;
            o_CXS_flit_receiver_rx_data      <= '0;
            o_CXS_flit_receiver_cxscntl_data <= '0;
        end 
        else if (i_CXS_flit_receiver_CXSVALID &&i_CXS_flit_state_valid_recieving) 
        begin
            o_CXS_flit_receiver_flit_valid   <= i_CXS_flit_receiver_CXSVALID;
            o_CXS_flit_receiver_rx_data      <= i_CXS_flit_receiver_CXSDATA;
            o_CXS_flit_receiver_cxscntl_data <= i_CXS_flit_receiver_CXSCNTL;
        end
        else 
        begin
            o_CXS_flit_receiver_flit_valid   <= 1'b0;
            o_CXS_flit_receiver_rx_data      <= '0;
            o_CXS_flit_receiver_cxscntl_data <= '0;
        end
        end

endmodule