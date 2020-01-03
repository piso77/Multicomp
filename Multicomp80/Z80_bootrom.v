module Z80_BASIC_ROM(clka, addra, douta);

  input [11:0] addra;
  output reg [7:0] douta;
  input clka;
  
  reg [7:0] rom[0:4096];

  always @(posedge clka)
  begin
	douta <= rom[addra];
  end
  
  initial
        $readmemh("bootrom.mem", rom);
  
endmodule
