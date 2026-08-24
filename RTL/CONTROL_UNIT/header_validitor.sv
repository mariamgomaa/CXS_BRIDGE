module header_validitor 
(
    input logic [1:0] i_header_validitor_pkt_type,
    input logic [1:0] i_header_validitor_parity_mode,
    input logic [2:0]  i_header_validitor_enc_mode,
    input logic [7:0]  i_header_validitor_dev_count,
    output logic o_header_validitor_valid    
);

logic parity_valid;
logic encryption_valid;
logic device_count_valid;
logic pkt_type_valid ;

typedef enum logic [1:0] {
    PARITY_ODD=2'b00,
    PARITY_EVEN=2'b01
} PARITY_TYPE;


typedef enum logic [2:0] {
    ENCRYPTION_ODD=3'b000,
   ENCRYPTION_EVEN=3'b001
} ENCRYPTION_TYPE;


typedef enum logic [1:0] {
    CONFIG_PKT = 2'b00,
    LINK_PKT   = 2'b01,
    DATA_PKT   = 2'b10,
    INVALID    = 2'b11
} packet_t;


always_comb 
begin
    o_header_validitor_valid = 1'b0 ;
    parity_valid      = 1'b0;
    encryption_valid  = 1'b0;
    device_count_valid= 1'b0;
    pkt_type_valid    = 1'b0;

    //parity validate 
    if (i_header_validitor_parity_mode == PARITY_ODD || i_header_validitor_parity_mode == PARITY_EVEN)
    begin
        parity_valid = 1'b1;
    end  
    else 
    begin
        parity_valid = 1'b0;
    end

    //encryption validate 
    if (i_header_validitor_enc_mode == ENCRYPTION_ODD || i_header_validitor_enc_mode == ENCRYPTION_EVEN)
    begin
        encryption_valid = 1'b1;
    end  
    else 
    begin
        encryption_valid = 1'b0;
    end 

    //device count valid 
    if(i_header_validitor_dev_count !=0)
    begin
        device_count_valid =1'b1;
    end 
    else 
    begin
        device_count_valid = 1'b0;
    end 

    // pkt_type validation 
        if(i_header_validitor_pkt_type != INVALID)
    begin
        pkt_type_valid = 1'b1;
    end 
    else 
    begin
        pkt_type_valid = 1'b0;
    end 

    if (parity_valid && encryption_valid && device_count_valid && pkt_type_valid)
    begin
    o_header_validitor_valid = 1'b1;
    end 
    else 
    begin
    o_header_validitor_valid = 1'b0;
    end 
end 
endmodule 