`timescale 1ns/10ps
/*
 * IC Contest Computational System (CS)
*/
module CS(Y, X, reset, clk);

input clk, reset; 
input [7:0] X;
output reg[9:0] Y;

  reg [15:0] sum;   // 32-bit accumulator to store the sum
  reg [7:0] X_Series[8:0];
  reg [8:0] APaverage;
  integer i;

//equation 1,2
  always @(posedge clk) begin
    if (reset) begin
      sum <= 0;
      for(i=0; i<9; i=i+1)begin
      X_Series[i]<=0;
    end
  end
    else begin
      for(i=0; i<9; i=i+1)
      // Accumulate the sum
      X_Series[0]<=X;
      sum <= sum + X_Series[i];
    end
  end

  always @(*) begin
    APaverage = 0;
        for(i=0; i<9; i=i+1)
            if( X_Series[i] >= APaverage && X_Series[i]<(sum/9))begin //X小於平均同時
            APaverage = X_Series[i];
            end
  end 

  always @(negedge clk)begin
    Y <= ((APaverage*9)+sum)>>3;
  end

endmodule