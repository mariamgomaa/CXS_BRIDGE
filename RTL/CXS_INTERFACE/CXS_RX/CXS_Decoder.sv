
module cxscntl_decoder #(
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH = 32,

    parameter int CNTL_W =
            (
                3*CXSMAXPAYLOADPERFLIT
            )

)
(
    input  logic                          i_cxscntl_decoder_flit_valid,
    input  logic [CNTL_W-1:0]             i_cxscntl_decoder_cxscntl_data,

    output logic [CXSMAXPAYLOADPERFLIT-1:0] o_cxscntl_decoder_start_field,
    output logic [CXSMAXPAYLOADPERFLIT-1:0] o_cxscntl_decoder_end_field,
    output logic [CXSMAXPAYLOADPERFLIT-1:0] o_cxscntl_decoder_end_error

);

// Custom 32-bit implementation

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



//======================================================================
// // ARM CXS implementation

//     localparam int START_BASE     = 0;

//     localparam int STARTPTR_BASE  =
//         START_BASE + CXSMAXPKTPERFLIT;

//     localparam int END_BASE =
//         STARTPTR_BASE +
//         CXSMAXPKTPERFLIT*STARTPTR_W;

//     localparam int ENDERR_BASE =
//         END_BASE +
//         CXSMAXPKTPERFLIT;

//     localparam int ENDPTR_BASE =
//         ENDERR_BASE +
//         CXSMAXPKTPERFLIT;
//     //assign the poionters values 
//     assign o_cxscntl_decoder_start_field =
//         i_cxscntl_decoder_flit_valid ?
//         i_cxscntl_decoder_cxscntl_data[START_BASE +: CXSMAXPKTPERFLIT] :
//         '0;
//     assign o_cxscntl_decoder_end_field =
//         i_cxscntl_decoder_flit_valid ?
//         i_cxscntl_decoder_cxscntl_data[END_BASE +: CXSMAXPKTPERFLIT] :
//         '0;
//     assign o_cxscntl_decoder_end_error =
//         i_cxscntl_decoder_flit_valid ?
//         i_cxscntl_decoder_cxscntl_data[ENDERR_BASE +: CXSMAXPKTPERFLIT] :
//         '0;
//     //decode the cxs_ntl
//     genvar i;
//     for(i=0;i<CXSMAXPKTPERFLIT;i++) begin : PTRS
//         assign o_cxscntl_decoder_start_ptr[(i+1)*STARTPTR_W-1 -: STARTPTR_W] =
//             i_cxscntl_decoder_flit_valid ?
//             i_cxscntl_decoder_cxscntl_data[
//                 STARTPTR_BASE+i*STARTPTR_W +:
//                 STARTPTR_W
//             ] :
//             '0;

//         assign o_cxscntl_decoder_end_ptr[(i+1)*ENDPTR_W-1 -: ENDPTR_W] =
//             i_cxscntl_decoder_flit_valid ?
//             i_cxscntl_decoder_cxscntl_data[
//                 ENDPTR_BASE+i*ENDPTR_W +:
//                 ENDPTR_W
//             ] :
//             '0;

//     end


endmodule