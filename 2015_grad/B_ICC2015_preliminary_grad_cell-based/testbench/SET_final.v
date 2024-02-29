module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate;

reg [2:0] state, nextstate;
reg [3:0] x; 
reg [3:0] y; 

reg  [3:0] Tx, Ty, r;
wire [7:0] x_part;
wire [7:0] y_part;
wire [7:0] distance;
wire [7:0] r_square;
reg insideA,insideB;
wire inside_t;

//calculate inside number 
assign x_part = (x-Tx);
assign y_part = (y-Ty);
assign distance = (x_part*x_part) + (y_part*y_part);
assign r_square = r*r;
assign inside_t = (r_square>=distance)? 1 : 0;


parameter Mode1 = 2'b00,
          Mode2 = 2'b01,
          Mode3 = 2'b10, 
          Mode4 = 2'b11;

parameter LOAD_DATA = 3'd0,
          InA       = 3'd1,
	  InB       = 3'd2,
	  InC       = 3'd3,
	  COUNTING  = 3'd4,
          DONE      = 3'd5;


always@(*) //control state
begin
	case(state)

        LOAD_DATA: nextstate = InA; //after set first state, set nextstate

	InA: nextstate = InB;

	InB: nextstate = InC;

	InC: nextstate = COUNTING;
        
        COUNTING: nextstate = DONE;
        
        DONE: nextstate = LOAD_DATA;
        
        default: nextstate = 'hx;
        
        endcase
end


always @(posedge clk or posedge rst) 
begin
     if (rst) 
     begin
          busy <= 0;
          valid <= 0;
          candidate<=0;
	     x<=1;
	     y<=1;
          state<= LOAD_DATA; //set first state
     end 
     else 
     state<=nextstate; 
     case(state) //first state still LOAD_DATA

     LOAD_DATA:
     begin
          if(en) //en signal for loaddata
          begin
               busy <=1; //start process 
               candidate<=0;
               valid<=0;
          end
     end
     InA:
     begin
          Tx <= central[23:20];
          Ty <= central[19:16];
          r  <= radius[11:8];
     end
     InB:
     begin
          Tx <= central[15:12];
		Ty <= central[11:8];
		 r <= radius[7:4];
		insideA <= inside_t; //delay
     end
     InC:
     begin
          Tx <= central[7:4];
		Ty <= central[3:0];
		 r <= radius[3:0];
		insideB <= inside_t;
     end
     COUNTING:
     begin
          if(x <= 8)
          begin
               if(y <= 8)
               begin
                    case(mode)
                    Mode1:
                    begin
                         if(insideA)
                         begin
                              candidate <= candidate + 1;
                         end
                    end
                    Mode2:
                    begin
                         if(insideA && insideB) 
                         begin
                              candidate <= candidate + 1;
                         end
                    end
                    Mode3:
                    begin
                         if((insideA && !insideB) || (!insideA && insideB))
                         begin
                              candidate <= candidate + 1;
                         end
                    end
                    Mode4:
                    begin
                         if((insideA && insideB && !inside_t) || (!insideA && insideB && inside_t) || (insideA && !insideB && inside_t))
                         begin
                              candidate <= candidate + 1;
                         end
                    end
                    endcase
                    y <= y+1;
               end
               else //y=8
               begin
                    x <= x+1;
                    y <= 1;
               end
          end
          else //x,y=8
          begin
               valid <= 1;
          end
     end
     DONE:
     begin
          if(valid)
          begin
               x <= 1;
               y <= 1;
               valid <= 0;
               busy <= 0;
               candidate <= 0;
          end
     end

     endcase

end

endmodule
