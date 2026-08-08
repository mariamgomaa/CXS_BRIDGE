module CXS_Boundry_Extractor #(
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH = 32,
    parameter int CNTL_W = 3*CXSMAXPAYLOADPERFLIT,
    parameter int FIFO_WIDTH = CNTL_W + CXSDATAFLITWIDTH
) (
    input logic [CXSDATAFLITWIDTH-1 : 0 ]      i_boundry_extractor_cxsdata,
    input logic [CNTL_W-1 : 0 ]                i_boundry_extractor_cxscntl_data,
    input logic [CXSMAXPAYLOADPERFLIT-1 : 0 ]  i_boundry_extractor_start_field,
    input logic [CXSMAXPAYLOADPERFLIT-1 : 0 ]  i_boundry_extractor_end_filed,
    input logic [CXSMAXPAYLOADPERFLIT-1 : 0 ]  i_boundry_extractor_error_field,

    output logic[FIFO_WIDTH-1 : 0 ]            o_boundry_extractor_data

);

    logic [(FIFO_WIDTH/2)-1 : 0 ] payload01,payload02;
    always_comb
    begin
        payload01 = {i_boundry_extractor_start_field[0],
                     i_boundry_extractor_end_filed [0] ,
                     i_boundry_extractor_error_field [0],
                     i_boundry_extractor_cxsdata[15:0]};

        payload02 = {i_boundry_extractor_start_field[1],
                     i_boundry_extractor_end_filed [1] ,
                     i_boundry_extractor_error_field [1],
                     i_boundry_extractor_cxsdata[31:16]};
        o_boundry_extractor_data = {payload01 , payload02};
    end
    
endmodule