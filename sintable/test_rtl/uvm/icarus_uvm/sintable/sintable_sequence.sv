class sintable_sequence extends uvm_sequence #(sintable_transaction);
    `uvm_object_utils(sintable_sequence)
    
    function new(string name = "sintable_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        sintable_transaction trans;
        
        // Apply reset
        trans = sintable_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = sintable_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass