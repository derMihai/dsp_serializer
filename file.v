// Simple State Machine WITHOUT SystemVerilog for Quartus support
module simple_fsm (
    input wire clk,
    input wire reset,
    input wire in_signal,
    output reg fsm_output
);

    // State encoding using parameters (traditional Verilog)
    parameter S0 = 2'b00;
    parameter S1 = 2'b01;
    parameter S2 = 2'b10;

    reg [1:0] state, next_state;

    // State Register
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    // Next State Logic and Output
    always @(*) begin
        case(state)
            S0: if (in_signal) begin
                    next_state = S1;
                    fsm_output = 1'b0;
                end else begin
                    next_state = S0;
                    fsm_output = 1'b1;
                end
            S1: begin
                    next_state = S2;
                    fsm_output = 1'b0;
                end
            S2: begin
                    next_state = S0;
                    fsm_output = 1'b1;
                end
            default: begin
                    next_state = S0;
                    fsm_output = 1'b0;
                end
        endcase
    end

endmodule
