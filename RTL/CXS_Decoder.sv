
module cxscntl_decoder #(
    parameter int CXSMAXPKTPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH = 256,
    //----------------------------------------------------------
    // Internal parameters
    //----------------------------------------------------------
    localparam bit CUSTOM32_MODE = (CXSDATAFLITWIDTH == 32),

    // keep at least one bit to avoid illegal zero-width vectors
    localparam int STARTPTR_W =
        CUSTOM32_MODE ? 1 :
        $clog2(CXSDATAFLITWIDTH/128),
    localparam int ENDPTR_W =
        CUSTOM32_MODE ? 1 :
        $clog2(CXSDATAFLITWIDTH/32),

    localparam int CNTL_W =
        CUSTOM32_MODE ?
            6 :
            (
                CXSMAXPKTPERFLIT +
                CXSMAXPKTPERFLIT*STARTPTR_W +
                2*CXSMAXPKTPERFLIT +
                CXSMAXPKTPERFLIT*ENDPTR_W
            )

)
(
    input  logic                          i_cxscntl_decoder_flit_valid,
    input  logic [CNTL_W-1:0]             i_cxscntl_decoder_cxscntl_data,

    output logic [CXSMAXPKTPERFLIT-1:0] o_cxscntl_decoder_start_field,
    output logic [CXSMAXPKTPERFLIT-1:0] o_cxscntl_decoder_end_field,
    output logic [CXSMAXPKTPERFLIT-1:0] o_cxscntl_decoder_end_error,

    output logic [CXSMAXPKTPERFLIT*STARTPTR_W-1:0] o_cxscntl_decoder_start_ptr,
    output logic [CXSMAXPKTPERFLIT*ENDPTR_W-1:0]   o_cxscntl_decoder_end_ptr
);

generate

// Custom 32-bit implementation

if (CUSTOM32_MODE) begin : GEN_CUSTOM32
    //----------------------------------------------------------
    // Bit mapping
    //----------------------------------------------------------
    //
    // bit0 : START0
    // bit1 : START1
    // bit2 : END0
    // bit3 : END1
    // bit4 : o_cxscntl_decoder_end_error
    //
    //----------------------------------------------------------
    always_comb begin
        o_cxscntl_decoder_start_field = '0;
        o_cxscntl_decoder_end_field   = '0;
        o_cxscntl_decoder_end_error   = '0;
        o_cxscntl_decoder_start_ptr   = '0;
        o_cxscntl_decoder_end_ptr     = '0;
        if(i_cxscntl_decoder_flit_valid) begin
            o_cxscntl_decoder_start_field[0] = i_cxscntl_decoder_cxscntl_data[0];
            o_cxscntl_decoder_start_field[1] = i_cxscntl_decoder_cxscntl_data[1];
            o_cxscntl_decoder_end_field[0]   = i_cxscntl_decoder_cxscntl_data[2];
            o_cxscntl_decoder_end_field[1]   = i_cxscntl_decoder_cxscntl_data[3];
            // same error reported for both packets
            o_cxscntl_decoder_end_error[0] = i_cxscntl_decoder_cxscntl_data[4];
            o_cxscntl_decoder_end_error[1] = i_cxscntl_decoder_cxscntl_data[5];
        end
    end

end

//======================================================================
// ARM CXS implementation

else begin : GEN_ARM

    localparam int START_BASE     = 0;

    localparam int STARTPTR_BASE  =
        START_BASE + CXSMAXPKTPERFLIT;

    localparam int END_BASE =
        STARTPTR_BASE +
        CXSMAXPKTPERFLIT*STARTPTR_W;

    localparam int ENDERR_BASE =
        END_BASE +
        CXSMAXPKTPERFLIT;

    localparam int ENDPTR_BASE =
        ENDERR_BASE +
        CXSMAXPKTPERFLIT;
    //assign the poionters values 
    assign o_cxscntl_decoder_start_field =
        i_cxscntl_decoder_flit_valid ?
        i_cxscntl_decoder_cxscntl_data[START_BASE +: CXSMAXPKTPERFLIT] :
        '0;
    assign o_cxscntl_decoder_end_field =
        i_cxscntl_decoder_flit_valid ?
        i_cxscntl_decoder_cxscntl_data[END_BASE +: CXSMAXPKTPERFLIT] :
        '0;
    assign o_cxscntl_decoder_end_error =
        i_cxscntl_decoder_flit_valid ?
        i_cxscntl_decoder_cxscntl_data[ENDERR_BASE +: CXSMAXPKTPERFLIT] :
        '0;
    //decode the cxs_ntl
    genvar i;
    for(i=0;i<CXSMAXPKTPERFLIT;i++) begin : PTRS
        assign o_cxscntl_decoder_start_ptr[(i+1)*STARTPTR_W-1 -: STARTPTR_W] =
            i_cxscntl_decoder_flit_valid ?
            i_cxscntl_decoder_cxscntl_data[
                STARTPTR_BASE+i*STARTPTR_W +:
                STARTPTR_W
            ] :
            '0;

        assign o_cxscntl_decoder_end_ptr[(i+1)*ENDPTR_W-1 -: ENDPTR_W] =
            i_cxscntl_decoder_flit_valid ?
            i_cxscntl_decoder_cxscntl_data[
                ENDPTR_BASE+i*ENDPTR_W +:
                ENDPTR_W
            ] :
            '0;

    end

end

endgenerate

endmodule