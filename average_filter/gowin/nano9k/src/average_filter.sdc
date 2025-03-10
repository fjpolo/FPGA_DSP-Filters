# Clock Definition
create_clock -name clk -period 10.0 [get_ports {clk}] # Adjust period as needed

# Input Delays
# set_input_delay -clock clk -max 1.0 [get_ports {data_in}]
# set_input_delay -clock clk -max 1.0 [get_ports {i_ce}]

# Output Delays
# set_output_delay -clock clk -max 1.0 [get_ports {data_out}]
# set_output_delay -clock clk -max 1.0 [get_ports {o_ce}]

# False Paths (if needed)
# set_false_path -from [get_ports {reset_n}] -to [get_ports {data_out}]

# Multicycle Paths (if needed)
# set_multicycle_path -setup -end -from [get_ports {i_ce}] -to [get_ports {data_out}] 2