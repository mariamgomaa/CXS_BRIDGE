module address_translation_unit #(
    parameter int ADD_W         = 8,
    parameter int LOGICAL_ADD_W = 9
)(

    input  logic                      i_atu_mode,      // 0 = Limit Mode (future work), 1 = Region Mode
    input  logic [ADD_W-1:0]          i_atu_address,
    input  logic                      i_atu_valid,
    input  logic [ADD_W-1:0]  i_atu_base_address,  // from device count: base = device_count + 1
    input  logic [ADD_W-1:0]  i_atu_start_address,

    output logic [LOGICAL_ADD_W-1:0]  o_atu_address,
    output logic                      o_atu_valid
);

    //========================================================
    // Translation
    //========================================================
    always_comb begin
        o_atu_address = 'b0;
        o_atu_valid   = 1'b0;

        if (i_atu_valid) begin

            // Region Mode: address = incoming address + stored base
            if (i_atu_mode) begin
                o_atu_address = {1'b0,i_atu_address} - {1'b0,i_atu_base_address} + {1'b0,i_atu_start_address} +2'b10 ; // base address configrable
                o_atu_valid   = 1'b1;
            end

            // Limit Mode: not implemented yet -> future work
            else begin
                o_atu_address = 'b0;
                o_atu_valid   = 1'b0;
            end

        end
    end

endmodule