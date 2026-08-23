module CXS_TX_TOP #(
    // parameters for pkt formatter, cntl encoder
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH     = 32,
    parameter int CNTL_W               = 3*CXSMAXPAYLOADPERFLIT,
    // parameters for credit counter
    parameter int MAX_CREDITS          = 15,
    parameter int CREDIT_W             = $clog2(MAX_CREDITS+1)
) (

    input logic                          i_CXS_TX_TOP_CLK,
    input logic                          i_CXS_TX_TOP_rst_n,

    // status information to send (e.g. from control_unit)
    input logic                          i_CXS_TX_TOP_status_valid,
    input logic [1:0]                    i_CXS_TX_TOP_status_pkt_type,
    input logic [1:0]                    i_CXS_TX_TOP_status_error_type,

    // CXS link inputs from the receiver
    input logic                          i_CXS_TX_TOP_CXSCRDGNT,
    input logic                          i_CXS_TX_TOP_CXSACTIVEACK,

    // CXS link outputs to the receiver
    output logic                         o_CXS_TX_TOP_CXSVALID,
    output logic [CXSDATAFLITWIDTH-1:0]  o_CXS_TX_TOP_CXSDATA,
    output logic [CNTL_W-1:0]            o_CXS_TX_TOP_CXSCNTL,
    output logic                         o_CXS_TX_TOP_CXSACTIVEREQ
);
    // internal wires

    // wires for connect pkt formatter <--> flit transmitter
    logic                              fmt_pkt_valid;
    logic [CXSDATAFLITWIDTH-1:0]       fmt_data;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   fmt_start;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   fmt_end;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   fmt_error;

    // wires for connect credit counter <--> flit transmitter
    logic                              credit_avail;

    // wires for connect flit transmitter <--> cntl encoder
    logic [CXSMAXPAYLOADPERFLIT-1:0]   tx_start_field;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   tx_end_field;
    logic [CXSMAXPAYLOADPERFLIT-1:0]   tx_end_error;
    logic                              tx_busy;

    // wires for connect flit transmitter <--> link control
    logic                              valid_sending;

    // pkt formatter module instantiation

    CXS_Pkt_Formatter #(
        .CXSMAXPAYLOADPERFLIT (CXSMAXPAYLOADPERFLIT),
        .CXSDATAFLITWIDTH     (CXSDATAFLITWIDTH)
    )
        u_CXS_Pkt_Formatter
    (
        .i_CXS_Pkt_Formatter_clk               (i_CXS_TX_TOP_CLK),
        .i_CXS_Pkt_Formatter_rst_n             (i_CXS_TX_TOP_rst_n),

        .i_CXS_Pkt_Formatter_status_valid      (i_CXS_TX_TOP_status_valid),
        .i_CXS_Pkt_Formatter_status_pkt_type   (i_CXS_TX_TOP_status_pkt_type),
        .i_CXS_Pkt_Formatter_status_error_type (i_CXS_TX_TOP_status_error_type),

        .o_CXS_Pkt_Formatter_data              (fmt_data),
        .o_CXS_Pkt_Formatter_start             (fmt_start),
        .o_CXS_Pkt_Formatter_end               (fmt_end),
        .o_CXS_Pkt_Formatter_error             (fmt_error),
        .o_CXS_Pkt_Formatter_pkt_valid         (fmt_pkt_valid),
    );

    // TX credit counter module instantiation

    CXS_TX_Credit_Counter #(
        .MAX_CREDITS (MAX_CREDITS),
        .CREDIT_W    (CREDIT_W)
    )
        u_CXS_TX_Credit_Counter
    (
        .i_CXS_TX_Credit_Counter_clk       (i_CXS_TX_TOP_CLK),
        .i_CXS_TX_Credit_Counter_rst_n     (i_CXS_TX_TOP_rst_n),

        .i_CXS_TX_Credit_Counter_CXSCRDGNT (i_CXS_TX_TOP_CXSCRDGNT),
        .i_CXS_TX_Credit_Counter_flit_sent (o_CXS_TX_TOP_CXSVALID),
        .o_CXS_TX_Credit_Counter_credit_avail (credit_avail)
    );

    // flit transmitter module instantiation

    CXS_flit_transmitter #(
        .CXSMAXPAYLOADPERFLIT (CXSMAXPAYLOADPERFLIT),
        .CXSDATAFLITWIDTH     (CXSDATAFLITWIDTH)
    )
        u_CXS_flit_transmitter
    (
        .i_CXS_flit_transmitter_clk          (i_CXS_TX_TOP_CLK),
        .i_CXS_flit_transmitter_rst_n        (i_CXS_TX_TOP_rst_n),

        .i_CXS_flit_transmitter_pkt_valid    (fmt_pkt_valid),
        .i_CXS_flit_transmitter_data         (fmt_data),
        .i_CXS_flit_transmitter_start        (fmt_start),
        .i_CXS_flit_transmitter_end          (fmt_end),
        .i_CXS_flit_transmitter_error        (fmt_error),

        .i_CXS_flit_transmitter_credit_avail (credit_avail),
        .i_CXS_flit_state_valid_sending      (valid_sending),

        .o_CXS_flit_transmitter_CXSVALID     (o_CXS_TX_TOP_CXSVALID),
        .o_CXS_flit_transmitter_CXSDATA      (o_CXS_TX_TOP_CXSDATA),
        .o_CXS_flit_transmitter_start_field  (tx_start_field),
        .o_CXS_flit_transmitter_end_field    (tx_end_field),
        .o_CXS_flit_transmitter_end_error    (tx_end_error),

        .o_CXS_flit_transmitter_busy         (tx_busy)
    );

    // cxscntl encoder module instantiation

    cxscntl_encoder #(
        .CXSMAXPAYLOADPERFLIT (CXSMAXPAYLOADPERFLIT),
        .CXSDATAFLITWIDTH     (CXSDATAFLITWIDTH),
        .CNTL_W               (CNTL_W)
    )
        u_cxscntl_encoder
    (
        .i_cxscntl_encoder_pkt_valid   (o_CXS_TX_TOP_CXSVALID),
        .i_cxscntl_encoder_start_field (tx_start_field),
        .i_cxscntl_encoder_end_field   (tx_end_field),
        .i_cxscntl_encoder_end_error   (tx_end_error),

        .o_cxscntl_encoder_cxscntl_data (o_CXS_TX_TOP_CXSCNTL)
    );

    // TX link control module instantiation

    CXS_Link_Control_TX u_CXS_Link_Control_TX
    (
        .i_CXS_Link_Control_TX_clk         (i_CXS_TX_TOP_CLK),
        .i_CXS_Link_Control_TX_rst_n       (i_CXS_TX_TOP_rst_n),

        .i_CXS_Link_Control_TX_pkt_pending (tx_busy),
        .i_CXS_Link_Control_TX_CXSACTIVEACK(i_CXS_TX_TOP_CXSACTIVEACK),

        .o_CXS_Link_Control_TX_CXSACTIVEREQ (o_CXS_TX_TOP_CXSACTIVEREQ),
        .o_CXS_Link_Control_TX_valid_sending(valid_sending)
    );

endmodule
