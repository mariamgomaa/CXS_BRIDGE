module CXS_flit_transmitter #(
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH     = 32
)(
    input  logic                              i_CXS_flit_transmitter_clk,
    input  logic                              i_CXS_flit_transmitter_rst_n,

    // from CXS_Pkt_Formatter
    input  logic                              i_CXS_flit_transmitter_pkt_valid,
    input  logic [CXSDATAFLITWIDTH-1:0]       i_CXS_flit_transmitter_data,
    input  logic [CXSMAXPAYLOADPERFLIT-1:0]   i_CXS_flit_transmitter_start,
    input  logic [CXSMAXPAYLOADPERFLIT-1:0]   i_CXS_flit_transmitter_end,
    input  logic [CXSMAXPAYLOADPERFLIT-1:0]   i_CXS_flit_transmitter_error,

    // from CXS_TX_Credit_Counter
    input  logic                              i_CXS_flit_transmitter_credit_avail,

    input  logic                              i_CXS_flit_state_valid_sending,

    output logic                              o_CXS_flit_transmitter_CXSVALID,
    output logic [CXSDATAFLITWIDTH-1:0]       o_CXS_flit_transmitter_CXSDATA,
    output logic [CXSMAXPAYLOADPERFLIT-1:0]   o_CXS_flit_transmitter_start_field,
    output logic [CXSMAXPAYLOADPERFLIT-1:0]   o_CXS_flit_transmitter_end_field,
    output logic [CXSMAXPAYLOADPERFLIT-1:0]   o_CXS_flit_transmitter_end_error,

    output logic                              o_CXS_flit_transmitter_busy          // packet queued or arriving, used to drive link activation
);

    // pending buffer: holds a packet that could not be sent immediately
    logic                              pending_reg;
    logic [CXSDATAFLITWIDTH-1:0]       pending_data_reg;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   pending_start_reg;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   pending_end_reg;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   pending_error_reg;

    logic                              send_now;
    logic [CXSDATAFLITWIDTH-1:0]       send_data;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   send_start;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   send_end;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   send_error;

    logic can_send;
    assign can_send = i_CXS_flit_transmitter_credit_avail && i_CXS_flit_state_valid_sending;

    // Something queued (pending) or arriving this cycle (formatter has a fresh packet)
    assign o_CXS_flit_transmitter_busy = pending_reg | i_CXS_flit_transmitter_pkt_valid;

    always_comb begin
        if (pending_reg) begin
            send_data  = pending_data_reg;
            send_start = pending_start_reg;
            send_end   = pending_end_reg;
            send_error = pending_error_reg;
            send_now   = can_send;
        end
        else begin
            send_data  = i_CXS_flit_transmitter_data;
            send_start = i_CXS_flit_transmitter_start;
            send_end   = i_CXS_flit_transmitter_end;
            send_error = i_CXS_flit_transmitter_error;
            send_now   = i_CXS_flit_transmitter_pkt_valid && can_send;
        end
    end

    always_ff @(posedge i_CXS_flit_transmitter_clk or negedge i_CXS_flit_transmitter_rst_n) begin
        if (!i_CXS_flit_transmitter_rst_n) begin
            o_CXS_flit_transmitter_CXSVALID    <= 1'b0;
            o_CXS_flit_transmitter_CXSDATA     <= '0;
            o_CXS_flit_transmitter_start_field <= '0;
            o_CXS_flit_transmitter_end_field   <= '0;
            o_CXS_flit_transmitter_end_error   <= '0;
            pending_reg       <= 1'b0;
            pending_data_reg  <= '0;
            pending_start_reg <= '0;
            pending_end_reg   <= '0;
            pending_error_reg <= '0;
        end
        else begin
            if (send_now) begin
                o_CXS_flit_transmitter_CXSVALID    <= 1'b1;
                o_CXS_flit_transmitter_CXSDATA     <= send_data;
                o_CXS_flit_transmitter_start_field <= send_start;
                o_CXS_flit_transmitter_end_field   <= send_end;
                o_CXS_flit_transmitter_end_error   <= send_error;
                pending_reg <= 1'b0;
            end
            else begin
                o_CXS_flit_transmitter_CXSVALID <= 1'b0;

                // latch a new packet if we could not send it this cycle
                if (i_CXS_flit_transmitter_pkt_valid && !pending_reg) begin
                    pending_reg       <= 1'b1;
                    pending_data_reg  <= i_CXS_flit_transmitter_data;
                    pending_start_reg <= i_CXS_flit_transmitter_start;
                    pending_end_reg   <= i_CXS_flit_transmitter_end;
                    pending_error_reg <= i_CXS_flit_transmitter_error;
                end
            end
        end
    end

endmodule
