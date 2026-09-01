// =============================================================================
// CXS_Pkt_Formatter.sv
// Packs status information (pkt_type, error_type) from control_unit into a
// single-flit CXS packet occupying slot0. Inverse of CXS_Boundry_Extractor.
// =============================================================================

module CXS_Pkt_Formatter #(
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH     = 32,
    parameter int PAYLOAD_W            = CXSDATAFLITWIDTH/CXSMAXPAYLOADPERFLIT
)(
    input  logic                        i_CXS_Pkt_Formatter_clk,
    input  logic                        i_CXS_Pkt_Formatter_rst_n,

    // status info from control_unit
    input  logic                        i_CXS_Pkt_Formatter_status_valid,
    input  logic [1:0]                  i_CXS_Pkt_Formatter_status_pkt_type,
    input  logic [1:0]                  i_CXS_Pkt_Formatter_status_error_type,

    output logic [CXSDATAFLITWIDTH-1:0]      o_CXS_Pkt_Formatter_data,
    output logic [CXSMAXPAYLOADPERFLIT-1:0]  o_CXS_Pkt_Formatter_start,
    output logic [CXSMAXPAYLOADPERFLIT-1:0]  o_CXS_Pkt_Formatter_end,
    output logic [CXSMAXPAYLOADPERFLIT-1:0]  o_CXS_Pkt_Formatter_error,
    output logic                              o_CXS_Pkt_Formatter_pkt_valid
);

    //----------------------------------------------------------
    // Status word layout (slot0, PAYLOAD_W bits)
    //----------------------------------------------------------
    // bit[1:0]  : status_pkt_type
    // bit[3:2]  : status_error_type
    // bit[15:4] : reserved (0)
    //----------------------------------------------------------

    logic [PAYLOAD_W-1:0] status_word;
    logic [CXSDATAFLITWIDTH-1:0] pkt_data;
    logic [CXSMAXPAYLOADPERFLIT-1:0] start_field;
    logic [CXSMAXPAYLOADPERFLIT-1:0] end_field;
    logic [CXSMAXPAYLOADPERFLIT-1:0] error_field;

    always_comb begin
        status_word [PAYLOAD_W-1 : 4] = '0;
        status_word[1:0] = i_CXS_Pkt_Formatter_status_pkt_type;
        status_word[3:2] = i_CXS_Pkt_Formatter_status_error_type;

        // slot0 = status word, slot1 = unused (single-flit packet)
        pkt_data = {{PAYLOAD_W{1'b0}}, status_word};

        start_field = 2'b01; // only one packet, starting in slot0
        end_field   = 2'b01; // packet completes in the same flit
        error_field = 2'b00; // no protocol-level transmission error
    end

    always_ff @(posedge i_CXS_Pkt_Formatter_clk or negedge i_CXS_Pkt_Formatter_rst_n) begin
        if (!i_CXS_Pkt_Formatter_rst_n) begin
            o_CXS_Pkt_Formatter_data      <= '0;
            o_CXS_Pkt_Formatter_start     <= '0;
            o_CXS_Pkt_Formatter_end       <= '0;
            o_CXS_Pkt_Formatter_error     <= '0;
            o_CXS_Pkt_Formatter_pkt_valid <= 1'b0;
        end
        else if (i_CXS_Pkt_Formatter_status_valid) begin
            o_CXS_Pkt_Formatter_data      <= pkt_data;
            o_CXS_Pkt_Formatter_start     <= start_field;
            o_CXS_Pkt_Formatter_end       <= end_field;
            o_CXS_Pkt_Formatter_error     <= error_field;
            o_CXS_Pkt_Formatter_pkt_valid <= 1'b1;
        end
        else begin
            o_CXS_Pkt_Formatter_pkt_valid <= 1'b0;
        end
    end

endmodule
