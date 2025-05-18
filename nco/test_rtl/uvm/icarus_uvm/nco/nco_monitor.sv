class nco_monitor extends uvm_monitor;
    `uvm_component_utils(nco_monitor)
    
    virtual nco_if vif;
    uvm_analysis_port #(nco_transaction) mon_ap;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_ap = new("mon_ap", this);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        forever begin
            nco_transaction trans = nco_transaction::type_id::create("trans");
            @(vif.mon_cb);
            trans.reset_n = vif.mon_cb.reset_n;
            trans.data_in = vif.mon_cb.data_in;
            trans.data_out = vif.mon_cb.data_out;
            mon_ap.write(trans);
        end
    endtask
endclass