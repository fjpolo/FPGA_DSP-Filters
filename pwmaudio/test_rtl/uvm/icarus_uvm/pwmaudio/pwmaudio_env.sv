class pwmaudio_env extends uvm_env;
    `uvm_component_utils(pwmaudio_env)
    
    pwmaudio_agent agent;
    pwmaudio_scoreboard scoreboard;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = pwmaudio_agent::type_id::create("agent", this);
        scoreboard = pwmaudio_scoreboard::type_id::create("scoreboard", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.mon_ap.connect(scoreboard.mon_imp);
    endfunction
endclass