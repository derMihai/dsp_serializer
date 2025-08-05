module state_machine (
    input wire clk,
    input wire rst,          // synchronous reset (active high)
    input wire is_matching,
    output reg is_waiting,
    output reg is_waiting_ending,
    output reg is_running
);

// Define states using localparam
localparam WAITING         = 2'b00;
localparam WAITING_ENDING  = 2'b01;
localparam RUNNING         = 2'b10;

reg [1:0] state, next_state;

// State transition logic (combinational)
always @(*) begin
    case (state)
        WAITING: begin
            if (is_matching)
                next_state = WAITING_ENDING;
            else
                next_state = WAITING;
        end

        WAITING_ENDING: begin
            if (is_matching)
                next_state = WAITING_ENDING;
            else
                next_state = RUNNING;
        end

        RUNNING: begin
            next_state = RUNNING;
        end

        default: next_state = WAITING;
    endcase
end

// State register (sequential)
always @(posedge clk) begin
    if (rst)
        state <= WAITING;
    else
        state <= next_state;
end

// Output logic
always @(*) begin
    is_waiting          = 1'b0;
    is_waiting_ending   = 1'b0;
    is_running          = 1'b0;

    case (state)
        WAITING:          is_waiting = 1'b1;
        WAITING_ENDING:   is_waiting_ending = 1'b1;
        RUNNING:          is_running = 1'b1;
        default:          ; // all zero by default
    endcase
end

endmodule
