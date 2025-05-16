class hsFIRcheap_sequence extends uvm_sequence #(hsFIRcheap_transaction);
    `uvm_object_utils(hsFIRcheap_sequence)
    
    function new(string name = "hsFIRcheap_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        hsFIRcheap_transaction trans;
        
        // Apply reset
        trans = hsFIRcheap_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = hsFIRcheap_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass