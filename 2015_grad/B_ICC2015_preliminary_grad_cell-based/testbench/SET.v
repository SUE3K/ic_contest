`define is_in(x,y,i,j,r) ((i-x)*(i-x) + (j-y)*(j-y) <= r*r)
module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate;

reg [1:0] reg_mode;
reg [1:0] state;
reg [3:0] Ax,Ay,Bx,By,Cx,Cy;
reg [3:0] ra,rb,rc;
reg [7:0] i; // x座標點
reg [7:0] j; // y座標點

always @(posedge clk or posedge rst) 
begin
     if (rst) 
     begin
          busy <= 0;
          valid <= 0;
          i<=1;
          j<=1;
          candidate<=0;
     end 
     else 
     begin
          if(en)
          begin
               Ax <= central[23:20];
               Ay <= central[19:16];
               Bx <= central[15:12];
               By <= central[11:8];
               Cx <= central[7:4];
               Cy <= central[3:0];
               ra <= radius[11:8];
               rb <= radius[7:4];
               rc <= radius[3:0];
               reg_mode <= mode;
               i<=1;
               j<=1;
               busy <=1; //start process 
               candidate <= 0;
          end
          else state<=state;

     if(valid == 1) //output時
     begin
          i <= 1;
          j <= 1;
          valid <= 0;
          busy <= 0;
          candidate <= 0;
     end
     else
         if(busy)  // mode0
         begin
              case(reg_mode)

              2'b00:
              begin
                   if(i <= 8)
                   begin
                        if(j <= 8)
                        begin
                             if(`is_in(Ax,Ay,i,j,ra))
                             begin
                                  candidate <= candidate + 1;
                             end
                             else state<=state;
                             j <= j+1;
                        end
                        else //y=8
                        begin
                             i <= i+1;
                             j <= 1;
                        end
                   end
                   else //x,y=8
                   begin
                        valid <= 1;
                   end
              end
              
              2'b01: //A intersection B
              begin
                   if(i <= 8)
                   begin
                        if(j <= 8)
                        begin
                             if(`is_in(Ax,Ay,i,j,ra) && `is_in(Bx,By,i,j,rb))
                             begin
                                  candidate <= candidate + 1;
                             end
                             else state<=state;
                             j <= j+1;
                        end
                        else //y=8
                        begin
                             i <= i+1;
                             j <= 1;
                        end
                   end
                   else
                   begin
                        valid <= 1;
                   end
              end

              2'b10: //(A union B)-(A intersection B)
              begin
                   if(i <= 8)
                   begin
                        if(j <= 8)
                        begin
                             if(`is_in(Ax,Ay,i,j,ra) && !`is_in(Bx,By,i,j,rb))
                             begin
                                  candidate <= candidate + 1;
                             end
                             else 
                             if(!`is_in(Ax,Ay,i,j,ra) && `is_in(Bx,By,i,j,rb))
                             begin
                                  candidate <= candidate + 1;
                             end
                             j <= j+1;
                        end
                        else //y=8
                        begin
                             i <= i+1;
                             j <= 1;
                        end
                   end
                   else
                   begin
                        valid <= 1;
                   end
              end
   
              2'b11: //(A union B)-(A intersection B)
              begin
                   if(i <= 8)
                   begin
                        if(j <= 8)
                        begin
                             if(`is_in(Ax,Ay,i,j,ra) && `is_in(Bx,By,i,j,rb) && !`is_in(Cx,Cy,i,j,rc))
                             begin
                                  candidate <= candidate + 1;
                             end
                             else 
                             if((`is_in(Ax,Ay,i,j,ra) && `is_in(Cx,Cy,i,j,rc) && !`is_in(Bx,By,i,j,rb)) || (`is_in(Cx,Cy,i,j,rc) && `is_in(Bx,By,i,j,rb) && !`is_in(Ax,Ay,i,j,ra)))
                             begin
                                  candidate <= candidate + 1;
                             end
                             else state<=state;
                             j <= j+1;
                        end
                        else //y=8
                        begin
                             i <= i+1;
                             j <= 1;
                        end
                   end
                   else
                   begin
                        valid <= 1;
                   end
              end

              endcase
         end
         else state<=state;

     end
end

endmodule


