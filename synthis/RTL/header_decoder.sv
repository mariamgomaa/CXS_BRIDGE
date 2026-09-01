module header_decoder # (HEADER_W = 16)
(
    input  logic [HEADER_W-1:0] i_header_decoder_header,

    output logic [1:0] o_header_decoder_pkt_type,
    output logic [1:0] o_header_decoder_parity_mode,
    output logic [2:0]  o_header_decoder_enc_mode,
    output logic [7:0]  o_header_decoder_dev_count
    
    

);

always_comb
begin

    //---------------------------------------------------
    // Configuration Fields
    //---------------------------------------------------

    o_header_decoder_dev_count   = i_header_decoder_header[14:7];

    o_header_decoder_enc_mode    = i_header_decoder_header[6:4];

    o_header_decoder_parity_mode = i_header_decoder_header[3:2];

    o_header_decoder_pkt_type = i_header_decoder_header[1:0];

end

endmodule