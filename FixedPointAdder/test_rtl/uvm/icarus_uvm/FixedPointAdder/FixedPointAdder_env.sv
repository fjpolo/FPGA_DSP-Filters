class FixedPointAdder_env extends uvm_env;
    `uvm_component_utils(FixedPointAdder_env)
    
    FixedPointAdder_agent agent;
    FixedPointAdder_scoreboard scoreboard;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = FixedPointAdder_agent::type_id::create("agent", this);
        scoreboard = FixedPointAdder_scoreboard::type_id::create("scoreboard", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.mon_ap.connect(scoreboard.mon_imp);
    endfunction
endclass