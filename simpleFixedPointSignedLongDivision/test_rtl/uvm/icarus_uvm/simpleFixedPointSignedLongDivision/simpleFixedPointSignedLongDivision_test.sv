class simpleFixedPointSignedLongDivision_test extends uvm_test;
    `uvm_component_utils(simpleFixedPointSignedLongDivision_test)
    
    simpleFixedPointSignedLongDivision_env env;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = simpleFixedPointSignedLongDivision_env::type_id::create("env", this);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        #1000;
        phase.drop_objection(this);
    endtask
endclass