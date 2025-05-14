class hsFIR_sequence extends uvm_sequence #(hsFIR_transaction);
    `uvm_object_utils(hsFIR_sequence)
    
    function new(string name = "hsFIR_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        hsFIR_transaction trans;
        
        // Apply reset
        trans = hsFIR_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = hsFIR_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass