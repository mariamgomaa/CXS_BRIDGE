module CXS_TOP #(
    //parameter for reciever and decoder 
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH = 32,
    parameter int CNTL_W = 3*CXSMAXPAYLOADPERFLIT,
    //parameter for credit generator 
    parameter int FIFO_DEPTH = 16,
    parameter int MAX_CREDITS = 15,
    parameter int CREDIT_W = $clog2(MAX_CREDITS+1),
    parameter int FIFO_WIDTH = CNTL_W + CXSDATAFLITWIDTH

) 
(
    input logic                          i_CXS_TOP_CLK,
    input logic                          i_CXS_TOP_rst_n,
    // CXS RECIEVER INTERFACE 
    input logic [CXSDATAFLITWIDTH-1 :0]  i_CXS_TOP_CXSDATA ,
    input logic [CNTL_W-1 : 0]           i_CXS_TOP_CXSCNTL,
    input logic                          i_CXS_TOP_CXSVALID,
    input logic                          i_CXS_TOP_CXSACTIVEREQ,
    input logic                          i_CXS_TOP_CXSCRDRTN,
    input logic                          i_CXS_TOP_buf_release,  //from asynchronous fifo 


    output logic                         o_CXS_TOP_CXSCRDGNT,
    output logic                         o_CXS_TOP_CXSACTIVEACK,
    output logic                         o_CXS_TOP_VALID,
    output logic[FIFO_WIDTH-1 : 0]       o_CXS_TOP_DATA,

    // CXS TRANSMITTER INTERFACE 
    ///////////////////////////////
    ///////////////////////////////
    // status information to send (e.g. from control_unit)
    input logic                          i_CXS_TOP_status_valid,
    input logic [1:0]                    i_CXS_TOP_status_pkt_type,
    input logic [1:0]                    i_CXS_TOP_status_error_type,

    // CXS link inputs from the receiver
    input logic                          i_CXS_TOP_CXSCRDGNT,
    input logic                          i_CXS_TOP_CXSACTIVEACK,

    // CXS link outputs to the receiver
    output logic                         o_CXS_TOP_CXSVALID,
    output logic [CXSDATAFLITWIDTH-1:0]  o_CXS_TOP_CXSDATA,
    output logic [CNTL_W-1:0]            o_CXS_TOP_CXSCNTL,
    output logic                         o_CXS_TOP_CXSACTIVEREQ
);

CXS_RX_TOP #(
    //parameter for reciever and decoder 
    .CXSMAXPAYLOADPERFLIT(CXSMAXPAYLOADPERFLIT),
    .CXSDATAFLITWIDTH (CXSDATAFLITWIDTH),
    .CNTL_W (CNTL_W),
    //parameter for credit generator 
    .FIFO_DEPTH (FIFO_DEPTH),
    .MAX_CREDITS (MAX_CREDITS),
    .CREDIT_W (CREDIT_W),
    .FIFO_WIDTH (FIFO_WIDTH)

)
    u_CXS_RX_TOP
 (

    .i_CXS_RX_TOP_CLK(i_CXS_TOP_CLK),
    .i_CXS_RX_TOP_rst_n(i_CXS_TOP_rst_n),
    .i_CXS_RX_TOP_CXSDATA (i_CXS_TOP_CXSDATA),
    .i_CXS_RX_TOP_CXSCNTL(i_CXS_TOP_CXSCNTL),
    .i_CXS_RX_TOP_CXSVALID(i_CXS_TOP_CXSVALID),
    .i_CXS_RX_TOP_CXSACTIVEREQ(i_CXS_TOP_CXSACTIVEREQ),
    .i_CXS_RX_TOP_CXSCRDRTN(i_CXS_TOP_CXSCRDRTN),
    .i_CXS_RX_TOP_buf_release(i_CXS_TOP_buf_release),  //from asynchronous fifo 
    .o_CXS_RX_TOP_CXSCRDGNT(o_CXS_TOP_CXSCRDGNT),
    .o_CXS_RX_TOP_CXSACTIVEACK(o_CXS_TOP_CXSACTIVEACK),
    .o_CXS_RX_TOP_VALID(o_CXS_TOP_VALID),
    .o_CXS_RX_TOP_DATA(o_CXS_TOP_DATA)

);

    CXS_TX_TOP #(
    // parameters for pkt formatter, cntl encoder
    .CXSMAXPAYLOADPERFLIT(CXSMAXPAYLOADPERFLIT),
    .CXSDATAFLITWIDTH(CXSDATAFLITWIDTH),
    .CNTL_W(CNTL_W),
    // parameters for credit counter
    .MAX_CREDITS          (MAX_CREDITS),
    .CREDIT_W             (CREDIT_W)
)
    u_CXS_TX_TOP
(

    .i_CXS_TX_TOP_CLK(i_CXS_TOP_CLK),
    .i_CXS_TX_TOP_rst_n(i_CXS_TOP_rst_n),

    // status information to send (e.g. from control_unit)
    .i_CXS_TX_TOP_status_valid(i_CXS_TOP_status_valid),
    .i_CXS_TX_TOP_status_pkt_type(i_CXS_TOP_status_pkt_type),
    .i_CXS_TX_TOP_status_error_type(i_CXS_TOP_status_error_type),

    // CXS link inputs from the receiver
    .i_CXS_TX_TOP_CXSCRDGNT(i_CXS_TOP_CXSCRDGNT),
    .i_CXS_TX_TOP_CXSACTIVEACK(i_CXS_TOP_CXSACTIVEACK),

    // CXS link outputs to the receiver
    .o_CXS_TX_TOP_CXSVALID(o_CXS_TOP_CXSVALID),
    .o_CXS_TX_TOP_CXSDATA(o_CXS_TOP_CXSDATA),
    .o_CXS_TX_TOP_CXSCNTL(o_CXS_TOP_CXSCNTL),
    .o_CXS_TX_TOP_CXSACTIVEREQ(o_CXS_TOP_CXSACTIVEREQ)
);
endmodule 