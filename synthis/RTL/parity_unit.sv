module parity_unit #(parameter int DATA_W = 16) (

    input  logic [DATA_W-1:0] i_parity_unit_encrypted_data,
    input  logic        i_parity_unit_encrypted_valid,
    input  logic    [1:0]    i_parity_unit_parity_mode,     // 0: Even, 1: Odd

    output logic [DATA_W:0] o_parity_unit_data_with_parity,
    output logic        o_parity_unit_parity_done

);

    logic parity_bit;

    always_comb begin

        // Default outputs
        o_parity_unit_data_with_parity = '0;
        o_parity_unit_parity_done      = 1'b0;
        parity_bit                     = 1'b0;

        if (i_parity_unit_encrypted_valid) begin

            // XOR reduction of all data bits odd detection 
            parity_bit = ^i_parity_unit_encrypted_data; // if number odd --> 1 even -->0 

            // Even parity
            if (i_parity_unit_parity_mode == 2'b00)
            // Append parity as MSB
            o_parity_unit_data_with_parity = {parity_bit,
                                              i_parity_unit_encrypted_data};
            // Odd parity
            else if (i_parity_unit_parity_mode == 2'b01)
            // Append parity as MSB
            o_parity_unit_data_with_parity = {~parity_bit,
                                              i_parity_unit_encrypted_data};

            o_parity_unit_parity_done = 1'b1;

        end

    end

endmodule