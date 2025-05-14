class hsFIR_driver extends uvm_driver #(hsFIR_transaction);
    `uvm_component_utils(hsFIR_driver)
    
    virtual hsFIR_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            vif.drv_cb.reset_n <= req.reset_n;
            vif.drv_cb.data_in <= req.data_in;
            @(vif.drv_cb);
            seq_item_port.item_done();
        end
    endtask
endclass