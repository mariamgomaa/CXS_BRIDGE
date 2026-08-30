module RST_SYNCH #(
    parameter int NUMBER_STAGES =  4
) (
    input logic CLK,
    input logic RST,
    output logic SYNCH_RST
);
    logic [NUMBER_STAGES -1 : 0 ] flip_synchronizer;
    always @(posedge CLK or negedge RST)
    begin
        if(!RST)
        begin
            flip_synchronizer <= 'b0;
        end  
        else 
        flip_synchronizer <= {flip_synchronizer[NUMBER_STAGES-2 : 0 ],1'b1};
    end 
    assign SYNCH_RST = flip_synchronizer [NUMBER_STAGES-1];
endmodule