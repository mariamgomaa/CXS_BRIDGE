
module cxscntl_encoder #(
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH     = 32,

    parameter int CNTL_W =
            (
                3*CXSMAXPAYLOADPERFLIT
            )
)
(
    input  logic                             i_cxscntl_encoder_pkt_valid,
    input  logic [CXSMAXPAYLOADPERFLIT-1:0]  i_cxscntl_encoder_start_field,
    input  logic [CXSMAXPAYLOADPERFLIT-1:0]  i_cxscntl_encoder_end_field,
    input  logic [CXSMAXPAYLOADPERFLIT-1:0]  i_cxscntl_encoder_end_error,

    output logic [CNTL_W-1:0]                o_cxscntl_encoder_cxscntl_data
);

    // bit0 : START0
    // bit1 : START1
    // bit2 : END0
    // bit3 : END1
    // bit4 : ENDERROR0
    // bit5 : ENDERROR1
    always_comb begin
        o_cxscntl_encoder_cxscntl_data = '0;
        if (i_cxscntl_encoder_pkt_valid) begin
            o_cxscntl_encoder_cxscntl_data[0] = i_cxscntl_encoder_start_field[0];
            o_cxscntl_encoder_cxscntl_data[1] = i_cxscntl_encoder_start_field[1];
            o_cxscntl_encoder_cxscntl_data[2] = i_cxscntl_encoder_end_field[0];
            o_cxscntl_encoder_cxscntl_data[3] = i_cxscntl_encoder_end_field[1];
            o_cxscntl_encoder_cxscntl_data[4] = i_cxscntl_encoder_end_error[0];
            o_cxscntl_encoder_cxscntl_data[5] = i_cxscntl_encoder_end_error[1];
        end
    end

endmodule
