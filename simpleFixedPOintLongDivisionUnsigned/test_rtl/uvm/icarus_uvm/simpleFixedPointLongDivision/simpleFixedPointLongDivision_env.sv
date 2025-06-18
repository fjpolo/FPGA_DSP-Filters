class simpleFixedPointLongDivision_env extends uvm_env;
    `uvm_component_utils(simpleFixedPointLongDivision_env)
    
    simpleFixedPointLongDivision_agent agent;
    simpleFixedPointLongDivision_scoreboard scoreboard;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = simpleFixedPointLongDivision_agent::type_id::create("agent", this);
        scoreboard = simpleFixedPointLongDivision_scoreboard::type_id::create("scoreboard", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.mon_ap.connect(scoreboard.mon_imp);
    endfunction
endclass