class nco_sequence extends uvm_sequence #(nco_transaction);
    `uvm_object_utils(nco_sequence)
    
    function new(string name = "nco_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        nco_transaction trans;
        
        // Apply reset
        trans = nco_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = nco_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass