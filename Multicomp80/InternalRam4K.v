module InternalRam4K
(
	input [7:0] data,
	input [11:0] address,
	input wren, clock,
	output [7:0] q
);

	reg [7:0] ram[4095:0];
	reg [11:0] addr_reg;
	
	always @ (posedge clock)
	begin
		if (wren)
			ram[address] <= data;
		
		addr_reg <= address;
	end
		
	assign q = ram[addr_reg];
endmodule
