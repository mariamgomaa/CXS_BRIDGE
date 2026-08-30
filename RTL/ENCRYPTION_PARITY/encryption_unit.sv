module encryption_unit  #(
    parameter int DATA_WIDTH =8 
) (
    input  logic [DATA_WIDTH-1 : 0] i_encryption_unit_payload_data,
    input  logic                    i_encryption_unit_payload_valid,
    input  logic                    i_encryption_unit_encryption_mode,   // 0: Even, 1: Odd

    output logic [(DATA_WIDTH*2)-1 : 0] o_encryption_unit_encrypted_data,
    output logic                           o_encryption_unit_encrypted_valid
);
    
    
    integer i;
    integer ones_cnt;
    integer zeros_cnt;

    always_comb begin

        //default values 
        o_encryption_unit_encrypted_data  = 16'd0;
        o_encryption_unit_encrypted_valid =  i_encryption_unit_payload_valid;

        // Count number of ones
        ones_cnt = 0;
        zeros_cnt = 0;
        for (i = 0; i < 8; i = i + 1)
        begin
        if (i_encryption_unit_payload_data[i] ==1'b1)
            ones_cnt = ones_cnt + 1;
        else 
            zeros_cnt = zeros_cnt + 1;
        end 


        if ( i_encryption_unit_payload_valid) begin
            o_encryption_unit_encrypted_valid = 1'b1;
            //----------------------------------------
            // Special Case
            //----------------------------------------
            if ((ones_cnt == zeros_cnt)) begin
                for (i = 0; i < 8; i = i + 1) begin
                    if (i_encryption_unit_payload_data[i] == 1'b0)
                        o_encryption_unit_encrypted_data[2*i +: 2] = 2'b01;
                    else
                        o_encryption_unit_encrypted_data[2*i +: 2] = 2'b10;
                end

            end

            //----------------------------------------
            // Even Expansion Mode
            //----------------------------------------
            else if (i_encryption_unit_encryption_mode == 1'b0) begin

                for (i = 0; i < 8; i = i + 1) begin
                    if (i_encryption_unit_payload_data[i] == 1'b0)
                        o_encryption_unit_encrypted_data[2*i +: 2] = 2'b00;
                    else
                        o_encryption_unit_encrypted_data[2*i +: 2] = 2'b10;
                end

            end

            //----------------------------------------
            // Odd Expansion Mode
            //----------------------------------------
            else begin

                for (i = 0; i < 8; i = i + 1) begin
                    if (i_encryption_unit_payload_data[i] == 1'b0)
                        o_encryption_unit_encrypted_data[2*i +: 2] = 2'b01;
                    else
                        o_encryption_unit_encrypted_data[2*i +: 2] = 2'b11;
                end

            end
        end
    end
    
endmodule



