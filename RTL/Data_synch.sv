 // for clock domain crossing between the system and CXS_TX_interface (slow to fast ) 
module DATA_SYNC #(
    parameter int NUM_STAGES = 2 ,
    parameter int  BUS_WIDTH  = 32 
    
) (
    input logic                           i_DATA_SYNC_CLK,
    input logic                           i_DATA_SYNC_RST_n,
    input logic [BUS_WIDTH-1 : 0]         i_DATA_SYNC_uni_DATA_SYNC_sync_bus ,
    input logic                           i_DATA_i_DATA_SYNC_sync_bus_enable,

    output logic [BUS_WIDTH-1 : 0]        i_DATA_SYNC_sync_bus,
    output logic                          i_DATA_SYNC_enable_pulse

);

    logic [NUM_STAGES-1 : 0] i_DATA_i_DATA_SYNC_sync_bus_enable_FF;
    logic generated_pulse_logic;
    logic sync_bulse_enable;
    logic generated_pulse;
    logic [BUS_WIDTH-1 : 0] mux_out;

    //multi flip flop block 
    always @(posedge i_DATA_SYNC_CLK or negedge i_DATA_SYNC_RST_n)
    begin
        if(!i_DATA_SYNC_RST_n)
        begin
            i_DATA_i_DATA_SYNC_sync_bus_enable_FF <= 'b0;
        end
        else
        begin
        i_DATA_i_DATA_SYNC_sync_bus_enable_FF <= {i_DATA_i_DATA_SYNC_sync_bus_enable_FF[NUM_STAGES-2 : 0] ,i_DATA_i_DATA_SYNC_sync_bus_enable };
        end
    end 
    assign sync_bulse_enable = i_DATA_i_DATA_SYNC_sync_bus_enable_FF [NUM_STAGES-1 ];

    //pulse geneartor block 
    always @(posedge i_DATA_SYNC_CLK or negedge i_DATA_SYNC_RST_n)
    begin
        if(!i_DATA_SYNC_RST_n)
        begin
        generated_pulse_logic <= 'b0;
        end
        else
        begin
        generated_pulse_logic <= sync_bulse_enable;
        end
    end

    //compinational logic 

    assign generated_pulse = (~generated_pulse_logic) & sync_bulse_enable;
    assign mux_out = (generated_pulse ) ? i_DATA_SYNC_uni_DATA_SYNC_sync_bus : i_DATA_SYNC_sync_bus; 
    
    
    // logicister output 
        always @(posedge i_DATA_SYNC_CLK or negedge i_DATA_SYNC_RST_n)
    begin
        if(!i_DATA_SYNC_RST_n)
        begin
            i_DATA_SYNC_enable_pulse <= 'b0;
            i_DATA_SYNC_sync_bus <= 'b0;
        end
        else
        begin
                i_DATA_SYNC_enable_pulse <= generated_pulse ;
                i_DATA_SYNC_sync_bus     <= mux_out;
        end
    end



 
    
endmodule